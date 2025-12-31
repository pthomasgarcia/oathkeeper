SHELL := /usr/bin/env bash

# --- Variables ---
# Finds all relevant shell files in current directory, excluding hidden files and tests
SHELL_FILES := $(shell find . -type f \( -name "*.sh" -o -name "*.bash" \) -not -path "./tests/*" -not -path "./.git/*")

# Flags
SHFMT_FLAGS      := -i 4 -ci -sr -ln bash
SHELLCHECK_FLAGS := -S style -x -s bash

# --- Targets ---
.PHONY: lint-shell format-shell format-check check-line-length ci tools

# Verify tools exist locally
tools:
	@command -v shellcheck >/dev/null || { echo "shellcheck not found"; exit 1; }
	@command -v shfmt >/dev/null || { echo "shfmt not found"; exit 1; }

# Linting
lint-shell: tools
	@if [ -z "$(SHELL_FILES)" ]; then \
		echo "No shell scripts found."; \
	else \
		shellcheck $(SHELLCHECK_FLAGS) $(SHELL_FILES); \
		echo "ShellCheck passed."; \
	fi

# Line length check (80 chars)
check-line-length:
	@echo "Checking line lengths (max 80 characters)..."
	@errors=0; \
	for file in $(SHELL_FILES); do \
		long_lines=$$(grep -n ".\{81,\}" "$$file"); \
		if [ -n "$$long_lines" ]; then \
			echo "File $$file has lines exceeding 80 characters:"; \
			echo "$$long_lines"; \
			errors=1; \
		fi; \
	done; \
	[ $$errors -eq 0 ] || exit 1
	@echo "Line length check passed."

# Check formatting (no write)
format-check: tools
	@if [ -z "$(SHELL_FILES)" ]; then \
		echo "No shell scripts found."; \
	else \
		shfmt -d $(SHFMT_FLAGS) $(SHELL_FILES); \
	fi

# Auto-format locally
format-shell: tools
	@if [ -z "$(SHELL_FILES)" ]; then \
		echo "No files to format."; \
	else \
		shfmt -w $(SHFMT_FLAGS) $(SHELL_FILES); \
		echo "Formatting complete."; \
	fi

# CI target
ci: lint-shell check-line-length format-check
	@echo "All CI checks passed."
