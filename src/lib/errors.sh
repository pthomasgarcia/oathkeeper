#!/usr/bin/env bash
# src/lib/errors.sh

if [[ -n "${OATHKEEPER_ERRORS_LOADED:-}" ]]; then
    return 0 2> /dev/null
fi
OATHKEEPER_ERRORS_LOADED=true

# Define error codes as constants
readonly OATHKEEPER_ERR_NONE=0
readonly OATHKEEPER_ERR_INVALID_ACCOUNT_NAME=101
readonly OATHKEEPER_ERR_ACCOUNT_NOT_FOUND=102
readonly OATHKEEPER_ERR_EMPTY_SECRET=103
readonly OATHKEEPER_ERR_INVALID_BASE32=104
readonly OATHKEEPER_ERR_DECRYPT_FAILED=105
readonly OATHKEEPER_ERR_ENCRYPT_FAILED=106
readonly OATHKEEPER_ERR_UNKNOWN=199

# Map error codes to messages (using constants in the mapping)
declare -A OATHKEEPER_ERROR_MESSAGES=(
    ["$OATHKEEPER_ERR_NONE"]="No error"
    ["$OATHKEEPER_ERR_INVALID_ACCOUNT_NAME"]="Invalid account name provided."
    ["$OATHKEEPER_ERR_ACCOUNT_NOT_FOUND"]="Account not found."
    ["$OATHKEEPER_ERR_EMPTY_SECRET"]="Secret cannot be empty."
    ["$OATHKEEPER_ERR_INVALID_BASE32"]="Secret is not valid Base32."
    ["$OATHKEEPER_ERR_DECRYPT_FAILED"]="Failed to decrypt secret."
    ["$OATHKEEPER_ERR_ENCRYPT_FAILED"]="Failed to encrypt secret."
    ["$OATHKEEPER_ERR_UNKNOWN"]="An unknown error occurred."
)

errors::message() {
    # Map an error code to its human-readable description.
    #
    # Args:
    #     code (int): Numeric error code defined in OATHKEEPER_ERROR_MESSAGES.
    #
    # Returns:
    #     Descriptive string on stdout.
    #     "Unknown error code: <code>" if the code is not registered.

    local code=$1
    if [[ -n "${OATHKEEPER_ERROR_MESSAGES[$code]:-}" ]]; then
        echo "${OATHKEEPER_ERROR_MESSAGES[$code]}"
    else
        echo "Unknown error code: $code"
    fi
}
