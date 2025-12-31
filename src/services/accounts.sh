#!/usr/bin/env bash
# src/services/accounts.sh

if [[ -n "${OATHKEEPER_ACCOUNTS_LOADED:-}" ]]; then
    return 0 2> /dev/null
fi
OATHKEEPER_ACCOUNTS_LOADED=true

# -------------------------------
# Add a new account with secret
# -------------------------------
accounts::add() {
    local account="${1:-}" secret="${2:-}"
    [[ -n $account ]] || return "$OATHKEEPER_ERR_INVALID_ACCOUNT_NAME"
    validators::account_name "$account" ||
        return "$OATHKEEPER_ERR_INVALID_ACCOUNT_NAME"

    mkdir -p "$OATHKEEPER_DIR"

    if [[ ${secret:-} == "-" ]]; then
        secret=$(cat)
    elif [[ -z $secret ]]; then
        secret=$(ui::prompt_secret "$account")
    fi
    [[ -n $secret ]] || return "$OATHKEEPER_ERR_EMPTY_SECRET"

    secret=$(tr -d '[:space:]' <<< "$secret" | tr '[:lower:]' '[:upper:]')
    validators::base32 "$secret" ||
        return "$OATHKEEPER_ERR_INVALID_BASE32"

    <<< "$secret" gpg --symmetric --cipher-algo AES256 \
        --output "$OATHKEEPER_DIR/$account.gpg" 2> /dev/null ||
        return "$OATHKEEPER_ERR_ENCRYPT_FAILED"
    chmod 600 "$OATHKEEPER_DIR/$account.gpg"

    loggers::info "Successfully added account: $account"
    return "$OATHKEEPER_ERR_NONE"
}

# -------------------------------
# List all stored accounts
# -------------------------------
accounts::list() {
    [[ -d $OATHKEEPER_DIR ]] || return "$OATHKEEPER_ERR_ACCOUNT_NOT_FOUND"

    local accounts
    accounts=$(printf '%s\n' "$OATHKEEPER_DIR"/*.gpg |
        xargs -n1 basename -s .gpg | sort)

    echo "$accounts"
    loggers::info "Successfully listed accounts"
    return "$OATHKEEPER_ERR_NONE"
}

# -------------------------------
# Generate OTP for an account
# -------------------------------
accounts::generate() {
    local account="$1"

    validators::account_name "$account" ||
        return "$OATHKEEPER_ERR_INVALID_ACCOUNT_NAME"

    local secret_file="$OATHKEEPER_DIR/$account.gpg"
    [[ -f $secret_file ]] || return "$OATHKEEPER_ERR_ACCOUNT_NOT_FOUND"

    local secret
    if ! secret=$(gpg --quiet --decrypt "$secret_file" 2> /dev/null); then
        return "$OATHKEEPER_ERR_DECRYPT_FAILED"
    fi

    secret=$(tr -d '[:space:]' <<< "$secret" | tr '[:lower:]' '[:upper:]')
    validators::base32 "$secret" || return "$OATHKEEPER_ERR_INVALID_BASE32"

    oathtool --totp -b "$secret"
    loggers::info "Successfully generated OTP for account: $account"
    return "$OATHKEEPER_ERR_NONE"
}
