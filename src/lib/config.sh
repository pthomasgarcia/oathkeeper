#!/usr/bin/env bash
# src/lib/config.sh

# Configuration Module for Oathkeeper
# Usage: source this file, then call config::init

if [[ -n "${OATHKEEPER_CONFIG_LOADED:-}" ]]; then
    return 0 2> /dev/null
fi
OATHKEEPER_CONFIG_LOADED=true

config::init() {
    # Load user configuration and apply safe defaults.
    #
    # Config file searched (in order):
    #   - $OATHKEEPER_CONFIG if set
    #   - $HOME/.config/oathkeeper/config otherwise
    #
    # Sets readonly globals:
    #   OATHKEEPER_DIR      – storage directory for encrypted secrets
    #   OATHKEEPER_PINENTRY – pinentry program for GPG passphrase prompts
    #   OATHKEEPER_GPG_TTY  – TTY to attach gpg-agent to
    #
    # Side-effects:
    #   - Sources config file if present
    #   - Exports OATHKEEPER_GPG_TTY
    #   - Sets umask 077 for restrictive file creation
    #
    # Returns:
    #   0 always

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
