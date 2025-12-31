#!/usr/bin/env bash
# src/lib/config.sh

# Configuration Module for Oathkeeper
# Usage: source this file, then call config::init

if [[ -n "${OATHKEEPER_CONFIG_LOADED:-}" ]]; then
    return 0 2> /dev/null
fi
OATHKEEPER_CONFIG_LOADED=true

# Initialize Oathkeeper configuration
config::init() {
    local file="${OATHKEEPER_CONFIG:-$HOME/.config/oathkeeper/config}"

    # Load user configuration if it exists
    if [[ -f "$file" ]]; then
        # shellcheck source=/dev/null
        source "$file"
    fi

    # Set defaults if not specified in config
    readonly OATHKEEPER_DIR="${OATHKEEPER_DIR:-$HOME/.oathkeeper}"
    readonly OATHKEEPER_PINENTRY="${OATHKEEPER_PINENTRY:-pinentry}"
    readonly OATHKEEPER_GPG_TTY="${OATHKEEPER_GPG_TTY:-$(tty)}"

    export OATHKEEPER_GPG_TTY
    umask 077
}
