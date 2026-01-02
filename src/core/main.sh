#!/usr/bin/env bash
# src/core/main.sh

set -euo pipefail
IFS=$'\n\t'

# -------------------------------
# PREVENTION: Guard against double source
# -------------------------------
if [[ -n "${OATHKEEPER_LOADED:-}" ]]; then
    return 0 2> /dev/null
fi
OATHKEEPER_LOADED=true

OATHKEEPER_ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"

# -------------------------------
# # CLEANUP: Resource management and cleanup handlers
# -------------------------------
cleanup() {
    # Remove sensitive runtime variables and clean up temporary files.
    #
    # Side-effects:
    #   - Unsets OATHKEEPER_SECRET_IN_MEMORY
    #   - Deletes paths listed in OATHKEEPER_TEMP_FILES
    #
    # Note:
    #   Registered as EXIT/INT/TERM trap; never call directly.

    unset OATHKEEPER_SECRET_IN_MEMORY 2> /dev/null || true

    if [ -n "${OATHKEEPER_TEMP_FILES:-}" ]; then
        rm -f "${OATHKEEPER_TEMP_FILES[@]}" 2> /dev/null || true
    fi
}
trap cleanup EXIT INT TERM

# -------------------------------
# MODULE LOADER: Strict manifest-based
# -------------------------------

while IFS= read -r line || [[ -n $line ]]; do
    line=${line%%#*}             # Remove comments
    line=${line##+([[:space:]])} # Remove leading whitespace

    [[ -z $line ]] && continue # Skip empty lines

    if [[ $line == /* ]]; then # Check if line starts with /
        m="$line"              # Absolute path
    else
        m="$OATHKEEPER_ROOT_DIR/$line" # Relative path
    fi

    [[ -f $m ]] || {
        echo "Module missing: $m"
        exit 1
    }

    # shellcheck source=/dev/null
    source "$m"
done < "$OATHKEEPER_ROOT_DIR/module.manifest"

# Initialize config via service
config::init

# -------------------------------
# USAGE & VERSION
# -------------------------------

main::usage() {
    # Display concise CLI help message.
    #
    # Returns:
    #   Human-readable usage text on stdout.

    cat << EOF
${OATHKEEPER_NAME} – ${OATHKEEPER_DESCRIPTION}

Usage:
  ${OATHKEEPER_NAME} <account>    generate OTP
  ${OATHKEEPER_NAME} add <name>   add secret (prompted; use "-" to read stdin)
  ${OATHKEEPER_NAME} list | -l    list accounts
  ${OATHKEEPER_NAME} version      display version
  ${OATHKEEPER_NAME} help         this text
EOF
}

main::version() {
    # Display program name, version string, and description.
    #
    # Returns:
    #   Single-line version info on stdout.

    printf "%s %s\n%s\n" \
        "$OATHKEEPER_NAME" \
        "$OATHKEEPER_VERSION" \
        "$OATHKEEPER_DESCRIPTION"
}

# -------------------------------
# DISPATCHER: Command routing and execution
# -------------------------------

main::dispatch() {
    # Route sub-commands to their respective handlers.
    #
    # Args:
    #   cmd (str): First positional argument; determines routing.
    #   ...    : Remaining arguments passed to the chosen handler.
    #
    # Supported commands:
    #   add, list|-l, version|--version|-v, help|--help|-h, <account>

    local cmd=${1:-}
    shift || true

    case $cmd in
        add) accounts::add "$@" ;;
        list | -l) accounts::list ;;
        version | --version | -v) main::version ;;
        help | --help | -h) main::usage ;;
        *) accounts::otp::generate "$cmd" ;;
    esac
}

# -------------------------------
# ENTRY POINT: Main execution flow
# -------------------------------
main() {
    # Entry point: validate dependencies, parse arguments, and execute command.
    #
    # Returns:
    #   0 on success, non-zero on error or missing dependency.
    #
    # Side-effects:
    #   Exits the process on critical failures.

    if [[ $# -eq 0 ]]; then
        main::usage
        loggers::error "No command provided"
        exit 1
    fi

    # Enforce required binaries
    for cmd in gpg oathtool; do
        command -v "$cmd" > /dev/null 2>&1 || {
            loggers::critical "Required binary missing: $cmd"
            exit 1
        }
    done

    main::dispatch "$@"
}

main "$@"
