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

# --- Internal: format message for console ---
loggers::format() {
    local type="$1"
    local message="$2"

    # Safe printf: treat message literally, no % interpretation
    printf "%s%s:%s %s\n" "${_LOG_COLORS[$type]:-}" "${type^}" \
        "$OATHKEEPER_RESET" "$message" >&2
}

# --- Internal: log to file + verbose ---
loggers::log_message() {
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
    loggers::format "info" "$1"
    loggers::log_message "$1" "INFO"
}

loggers::warn() {
    loggers::format "warning" "$1"
    loggers::log_message "$1" "WARN"
}

loggers::error() {
    loggers::format "error" "$1"
    loggers::log_message "$1" "ERROR"
}

loggers::critical() {
    loggers::format "error" "$1"
    loggers::log_message "$1" "CRITICAL"
}

loggers::debug() {
    [[ "${DEBUG:-false}" == "true" ]] || return 0
    loggers::format "debug" "$1"
    loggers::log_message "$1" "DEBUG"
}
