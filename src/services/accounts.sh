#!/usr/bin/env bash
# src/services/accounts.sh

if [[ -n "${OATHKEEPER_ACCOUNTS_LOADED:-}" ]]; then
    return 0 2> /dev/null
fi
OATHKEEPER_ACCOUNTS_LOADED=true

# -------------------------------
# Layer: Infrastructure / File Helpers
# -------------------------------
# Functions dealing with filesystem objects and storage mechanics
# These are internal helpers, not part of the public API.

accounts::file::get_pathname() {
    # Return the full path to a GPG-encrypted account file.
    #
    # Args:
    #     account (str): The account name (without extension).
    #
    # Returns:
    #     str: Absolute path “$OATHKEEPER_DIR/<account>.gpg”.
    #
    # Example:
    #     accounts::file::get_pathname "github"
    #     # -> “/home/user/.oathkeeper/github.gpg”

    local account=$1
    printf '%s/%s.gpg' "$OATHKEEPER_DIR" "$account"
}

accounts::file::list() {
    # List every GPG-encrypted account file in $OATHKEEPER_DIR.
    #
    # Returns:
    #     0 on success; one path per line.
    #     $OATHKEEPER_ERR_ACCOUNT_NOT_FOUND if the directory does not exist.

    [[ -d "$OATHKEEPER_DIR" ]] || return "$OATHKEEPER_ERR_ACCOUNT_NOT_FOUND"
    printf '%s\n' "$OATHKEEPER_DIR"/*.gpg 2> /dev/null
}

accounts::file::extract_accounts() {
    # Strip directory and .gpg extension from a list of files, then sort.
    #
    # Args:
    #     files (array): Absolute or relative paths to *.gpg files.
    #
    # Returns:
    #     Sorted list of account names (basenames without .gpg), one per line.
    #
    # Example:
    #     mapfile -t names < <(accounts::file::extract_accounts "${files[@]}")

    local files=("$@")
    for file in "${files[@]}"; do
        [[ -f "$file" ]] || continue
        basename "$file" .gpg
    done | sort
}

# -------------------------------
# Layer: Domain / Secret Helpers
# -------------------------------
# Internal helpers that implement domain logic for secrets.
# Operates on domain concepts (TOTP secrets), but not exposed as public API.

accounts::secret::read() {
    # Obtain a TOTP secret interactively or via argument/stdin.
    #
    # Args:
    #     secret (str|"-"): "-" reads from stdin; empty string triggers prompt.
    #     account (str): Account name used in the prompt.
    #
    # Returns:
    #     str: The non-empty secret on stdout.
    #     $OATHKEEPER_ERR_EMPTY_SECRET if nothing provided.
    #
    # Example:
    #     secret=$(accounts::secret::read "" "github")

    local secret=$1
    local account=$2

    if [[ $secret == "-" ]]; then
        secret=$(cat)
    elif [[ -z $secret ]]; then
        secret=$(ui::prompt_secret "$account")
    fi

    [[ -n $secret ]] || return "$OATHKEEPER_ERR_EMPTY_SECRET"
    echo "$secret"
}

accounts::secret::normalize() {
    # Sanitize and validate a Base32-encoded TOTP secret.
    #
    # Args:
    #     secret (str): Raw secret string.
    #
    # Returns:
    #     str: Upper-case, whitespace-stripped, valid Base32 secret on stdout.
    #     $OATHKEEPER_ERR_INVALID_BASE32 on validation failure.

    local secret=$1
    secret=$(tr -d '[:space:]' <<< "$secret" | tr '[:lower:]' '[:upper:]')
    validators::base32 "$secret" || return "$OATHKEEPER_ERR_INVALID_BASE32"
    echo "$secret"
}

accounts::secret::encrypt() {
    # Encrypt a plaintext TOTP secret to disk.
    #
    # Args:
    #     secret (str): Raw secret to store.
    #     account (str): Account name (determines filename).
    #
    # Returns:
    #     str: Absolute path of the created *.gpg file on stdout.
    #     $OATHKEEPER_ERR_ENCRYPT_FAILED on GPG failure.

    local secret=$1
    local account=$2

    local pathname
    pathname=$(accounts::file::get_pathname "$account")

    echo "$secret" | gpg --symmetric --cipher-algo AES256 \
        --output "$pathname" 2> /dev/null ||
        return "$OATHKEEPER_ERR_ENCRYPT_FAILED"

    chmod 600 "$pathname"
    echo "$pathname"
}

accounts::secret::decrypt() {
    # Decrypt and validate a stored TOTP secret.
    #
    # Args:
    #     account (str): Account whose secret should be retrieved.
    #
    # Returns:
    #     str: Upper-case, whitespace-stripped, valid Base32 secret on stdout.
    #     $OATHKEEPER_ERR_ACCOUNT_NOT_FOUND if file missing.
    #     $OATHKEEPER_ERR_DECRYPT_FAILED on GPG failure.
    #     $OATHKEEPER_ERR_INVALID_BASE32 if decrypted content isn't Base32.

    local account=$1

    local pathname
    pathname=$(accounts::file::get_pathname "$account")
    [[ -f $pathname ]] || return "$OATHKEEPER_ERR_ACCOUNT_NOT_FOUND"

    local secret
    if ! secret=$(gpg --quiet --decrypt "$pathname" 2> /dev/null); then
        return "$OATHKEEPER_ERR_DECRYPT_FAILED"
    fi

    secret=$(tr -d '[:space:]' <<< "$secret" | tr '[:lower:]' '[:upper:]')
    validators::base32 "$secret" || return "$OATHKEEPER_ERR_INVALID_BASE32"
    echo "$secret"
}

# -------------------------------
# Layer: Public API
# -------------------------------
# Functions intended to be called by end users or external modules.
# These compose infrastructure and domain helpers into high-level operations.

accounts::add() {
    # Create and persist a new TOTP account.
    #
    # Args:
    #     account (str): Account identifier (will become filename).
    #     secret (str|optional): Pre-shared secret; if empty or "-" the user
    #                            is prompted interactively.
    #
    # Returns:
    #     0 on success, appropriate $OATHKEEPER_ERR_* code otherwise.
    #
    # Example:
    #     accounts::add "github" "JBSWY3DPEHPK3PXP"

    local account="${1:-}"
    local secret="${2:-}"

    validators::path_component::is_safe "$account" ||
        return "$OATHKEEPER_ERR_INVALID_ACCOUNT_NAME"
    mkdir -p "$OATHKEEPER_DIR" ||
        return "$OATHKEEPER_ERR_ACCOUNT_DIR_CREATION_FAILED"

    secret=$(accounts::secret::read "$secret" "$account") || return $?
    secret=$(accounts::secret::normalize "$secret") || return $?
    accounts::secret::encrypt "$secret" "$account" || return $?

    loggers::info "Successfully added account: $account"
    return "$OATHKEEPER_ERR_NONE"
}

accounts::list() {
    # List stored account names, optionally filtered by prefix.
    #
    # Args:
    #     filter (str|optional): If supplied, only accounts whose name
    #                            starts with this string are returned.
    #
    # Returns:
    #     Sorted newline-separated list of account names on stdout.
    #     Appropriate $OATHKEEPER_ERR_* code on failure.
    #
    # Examples:
    #     accounts::list              # all accounts
    #     accounts::list personal     # personal-github, personal-gitlab, …
    #     accounts::list work-        # work-github, work-aws, …

    local filter=${1:-}
    local files=()
    mapfile -t files < <(accounts::file::list) || return $?

    local accounts
    accounts=$(accounts::file::extract_accounts "${files[@]}")

    if [[ -n $filter ]]; then
        accounts=$(grep -E "^${filter}" <<< "$accounts")
    fi

    echo "$accounts"
    loggers::info "Successfully listed accounts"
    return "$OATHKEEPER_ERR_NONE"
}

accounts::otp::generate() {
    # Compute the current TOTP code for the requested account.
    #
    # Args:
    #     account (str): Existing account name.
    #
    # Returns:
    #     6-digit TOTP code on stdout.
    #     Appropriate $OATHKEEPER_ERR_* code on any failure.

    local account="$1"
    validators::path_component::is_safe "$account" ||
        return "$OATHKEEPER_ERR_INVALID_ACCOUNT_NAME"

    local secret
    secret=$(accounts::secret::decrypt "$account") || return $?

    oathtool --totp -b "$secret"
    unset secret

    loggers::info "Successfully generated OTP for account: $account"
    return "$OATHKEEPER_ERR_NONE"
}
