#!/usr/bin/env bash
# src/lib/ui.sh

if [[ -n "${OATHKEEPER_UI_LOADED:-}" ]]; then
    return 0 2> /dev/null
fi
OATHKEEPER_UI_LOADED=true

ui::prompt_secret() {
    local account=$1
    "$OATHKEEPER_PINENTRY" --ttyname "$OATHKEEPER_GPG_TTY" \
        --no-tty-echo << EOF | sed -n '/^D /{s/^D //;p;}'
SETPROMPT OTP secret for '$account'
GETPIN
EOF
}
