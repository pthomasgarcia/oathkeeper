#!/usr/bin/env bash
# src/util/validators.sh

if [[ -n "${OATHKEEPER_VALIDATORS_LOADED:-}" ]]; then
    return 0 2> /dev/null
fi
OATHKEEPER_VALIDATORS_LOADED=true

validators::base32() {
    # Check whether a string contains only valid Base32 characters.
    #
    # Args:
    #     string  (str): string to test
    #
    # Returns:
    #     0  valid Base32 alphabet (A-Z, 2-7, padding =)
    #     1  otherwise

    local string=$1
    if [[ ! $string =~ ^[A-Z2-7=]+$ ]]; then
        return 1
    fi

    return 0
}

validators::path_component::is_safe() {
    # Validate an application-managed pathname component.
    #
    # This enforces a restricted filesystem policy suitable for user-supplied
    # identifiers that will be mapped to files or directories created by
    # the application.
    #
    # Args:
    #   string (str): user input to verify
    #
    # Returns:
    #   0  safe for use as a pathname component
    #   1  unsafe
    #
    # Note:
    #   Not suitable for validating arbitrary filesystem paths or existing
    #   filenames.

    local string=$1

    if [[ -z $string ]]; then
        return 1
    fi

    if [[ ! $string =~ ^[A-Za-z0-9._-]+$ ]]; then
        return 1
    fi

    if [[ $string == .* ]]; then
        return 1
    fi

    if [[ $string == *..* ]]; then
        return 1
    fi

    return 0
}
