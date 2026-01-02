#!/usr/bin/env bash
# src/lib/ui.sh

if [[ -n "${OATHKEEPER_UI_LOADED:-}" ]]; then
    return 0 2> /dev/null
fi
OATHKEEPER_UI_LOADED=true

ui::prompt_secret() {
    # Interactively prompt for a TOTP secret using the configured pinentry
    # program.
    #
    # Args:
    #     account (str): Display name shown in the prompt.
    #
    # Returns:
    #     Plain-text secret on stdout (no trailing newline).
    #
    # Side-effects:
    #     Blocks until user input is received via pinentry.
    #
    # Note:
    #     Requires OATHKEEPER_PINENTRY and OATHKEEPER_GPG_TTY to be set.

    local account=$1
    "$OATHKEEPER_PINENTRY" --ttyname "$OATHKEEPER_GPG_TTY" \
        --no-tty-echo << EOF | sed -n '/^D /{s/^D //;p;}'
SETPROMPT OTP secret for '$account'
GETPIN
EOF
}
