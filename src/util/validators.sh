#!/usr/bin/env bash
# src/util/validators.sh

if [[ -n "${OATHKEEPER_VALIDATORS_LOADED:-}" ]]; then
    return 0 2> /dev/null
fi
OATHKEEPER_VALIDATORS_LOADED=true

validators::account_name() {
    # Validate the syntax of an account identifier.
    #
    # Rules:
    #   - non-empty
    #   - allowed chars: A-Z a-z 0-9 . _ -
    #   - no leading dot
    #   - no ".." (directory traversal)
    #
    # Args:
    #     name (str): proposed account name
    #
    # Returns:
    #     0  valid
    #     1  invalid

    local name=$1
    [[ -n $name ]] || return 1
    [[ $name =~ ^[A-Za-z0-9._-]+$ ]] || return 1
    [[ $name != .* ]] || return 1   # forbid leading dot
    [[ $name != *..* ]] || return 1 # forbid traversal patterns
    return 0
}

# -------------------------------
# Validate Base32 strings
# -------------------------------
# Pure: returns 0 if valid, 1 otherwise
validators::base32() {
    [[ $1 =~ ^[A-Z2-7=]+$ ]] || return 1
}

# -------------------------------
# Validate that dependencies exist
# -------------------------------
# Pure: returns 0 if all commands exist, 1 otherwise
validators::dependencies() {
    local cmd
    for cmd in gpg oathtool; do
        command -v "$cmd" > /dev/null 2>&1 || return 1
    done
    return 0
}
