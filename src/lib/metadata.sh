#!/usr/bin/env bash
# src/lib/metadata.sh

if [[ -n "${OATHKEEPER_METADATA_LOADED:-}" ]]; then
    return 0 2> /dev/null
fi
OATHKEEPER_METADATA_LOADED=true

# Application metadata exported to all modules
export OATHKEEPER_NAME="oathkeeper"
export OATHKEEPER_VERSION="0.1.0"
export OATHKEEPER_DESCRIPTION="Encrypted TOTP manager with GPG"
