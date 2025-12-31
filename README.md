# Oathkeeper

**Oathkeeper** is a secure, command-line based OTP (One-Time Password) manager written in Bash. It leverages GPG for secure storage of secrets and `oathtool` for generating standard TOTP codes.

## Features

*   **Secure Storage:** All secrets are encrypted using GPG (AES256) and stored locally.
*   **Command Line Interface:** Simple and scriptable CLI for managing accounts and generating codes.
*   **Modular Architecture:** Designed with a modular structure for maintainability and extensibility.
*   **Zero Dependencies (Runtime):** Relies only on standard system tools (`gpg`, `oathtool`, `bash`).

## Prerequisites

Ensure you have the following installed on your system:

*   `bash` (version 4.0 or later recommended)
*   `gpg` (GnuPG)
*   `oathtool` (usually part of the `oath-toolkit` package)

## Installation

1.  Clone the repository:
    ```bash
    git clone https://github.com/yourusername/oathkeeper.git
    cd oathkeeper
    ```

2.  (Optional) Add the `src/core/main.sh` script to your PATH or create an alias:
    ```bash
    alias oathkeeper="$(pwd)/src/core/main.sh"
    ```

## Usage

### Adding an Account

To add a new OTP secret for an account:

```bash
oathkeeper add <account_name>
```

You will be prompted to enter the secret key securely. Alternatively, you can pipe the secret via stdin:

```bash
echo "YOUR_SECRET_KEY" | oathkeeper add <account_name> -
```

### Generating an OTP

To generate a One-Time Password for an account:

```bash
oathkeeper <account_name>
```

### Listing Accounts

To list all stored accounts:

```bash
oathkeeper list
```

## Configuration

Oathkeeper uses a configuration file located at `~/.config/oathkeeper/config` (or defined by `$OATHKEEPER_CONFIG`).

Default settings:
*   **Storage Directory:** `~/.oathkeeper`
*   **Pinentry Program:** `pinentry`

## Development

### Running Tests & Linting

This project uses a `Makefile` to manage development tasks.

*   **Linting:** Run `ShellCheck` on all scripts.
    ```bash
    make lint-shell
    ```
*   **Formatting:** Check and apply formatting using `shfmt`.
    ```bash
    make format-shell
    ```
*   **CI Checks:** Run all checks (linting, formatting, line length).
    ```bash
    make ci
    ```

## License

[MIT License](LICENSE)
