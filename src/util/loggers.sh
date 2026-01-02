#!/usr/bin/env bash
# src/util/loggers.sh

# --- Guard against double source ---
if [[ -n "${OATHKEEPER_LOGGERS_LOADED:-}" ]]; then
    return 0 2> /dev/null
fi
OATHKEEPER_LOGGERS_LOADED=true

# ANSI colors (self-contained; core no longer exports these)
readonly OATHKEEPER_RED=$'\033[0;31m'
# readonly OATHKEEPER_GREEN=$'\033[0;32m'
readonly OATHKEEPER_YELLOW=$'\033[0;33m'
# readonly OATHKEEPER_BLUE=$'\033[0;34m'
readonly OATHKEEPER_MAGENTA=$'\033[0;35m'
readonly OATHKEEPER_CYAN=$'\033[0;36m'
readonly OATHKEEPER_RESET=$'\033[0m'

# --- Color Configuration ---
# ANSI codes can be overridden by the environment
declare -gA _LOG_COLORS=(
    [error]="${OATHKEEPER_RED:-}"
    [warning]="${OATHKEEPER_YELLOW:-}"
    [info]="${OATHKEEPER_CYAN:-}"
    [debug]="${OATHKEEPER_MAGENTA:-}"
)

loggers::format() {
    # Internal: colorise and prefix a log line for stderr.
    #
    # Args:
    #   type (str): key into _LOG_COLORS (error|warning|info|debug)
    #   message (str): literal text to print
    #
    # Side-effects:
    #   Writes to stderr, no colour codes if _LOG_COLORS[type] empty.

    local type="$1"
    local message="$2"

    # Safe printf: treat message literally, no % interpretation
    printf "%s%s:%s %s\n" "${_LOG_COLORS[$type]:-}" "${type^}" \
        "$OATHKEEPER_RESET" "$message" >&2
}

loggers::log_message() {
    # Internal: emit timestamped log line to file and/or verbose console.
    #
    # Args:
    #   message (str): raw text to log
    #   level (str): INFO|WARN|ERROR|CRITICAL|DEBUG
    #
    # Side-effects:
    #   Appends to LOG_FILE if set, prints to stderr if VERBOSE=true.

    local message="$1"
    local level="${2:-INFO}"
    local timestamp

    # Bash 4.2+ timestamp (avoids 'date' fork)
    printf -v timestamp '%(%Y-%m-%d %H:%M:%S)T' -1
    local formatted_message="[$timestamp] [$level] $message"

    # Verbose console output
    if [[ "${VERBOSE:-false}" == "true" ]]; then
        printf "%s\n" "$formatted_message" >&2
    fi

    # File logging (no ANSI colors)
    if [[ -n "${LOG_FILE:-}" ]]; then
        printf "%s\n" "$formatted_message" >> "$LOG_FILE"
    fi
}

# --- Public API ---

loggers::info() {
    # Log informational message.
    #
    # Args:
    #   message (str): text to display

    loggers::format "info" "$1"
    loggers::log_message "$1" "INFO"
}

loggers::warn() {
    # Log warning message.
    #
    # Args:
    #   message (str): text to display

    loggers::format "warning" "$1"
    loggers::log_message "$1" "WARN"
}

loggers::error() {
    # Log error message (non-fatal).
    #
    # Args:
    #   message (str): text to display

    loggers::format "error" "$1"
    loggers::log_message "$1" "ERROR"
}

loggers::critical() {
    # Log critical error message (fatal context).
    #
    # Args:
    #   message (str): text to display

    loggers::format "error" "$1"
    loggers::log_message "$1" "CRITICAL"
}

loggers::debug() {
    # Log debug message (no-op unless DEBUG=true).
    #
    # Args:
    #   message (str): text to display

    [[ "${DEBUG:-false}" == "true" ]] || return 0
    loggers::format "debug" "$1"
    loggers::log_message "$1" "DEBUG"
}
