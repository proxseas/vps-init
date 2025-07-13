#!/usr/bin/env bash

# =============================================================================
# VPS Setup Utilities
# =============================================================================
# Common functions used across multiple setup scripts
# Source this file: source "$(dirname "$0")/utils.sh"
# =============================================================================

# Adds or updates a single alias in the given file
update_alias() {
    local name="$1"
    local value="$2"
    local file="$3"

    # Create file if it doesn't exist
    touch "$file"

    # If the alias already exists, replace its definition
    if grep -qE "^alias ${name}=" "$file" 2>/dev/null; then
        sed -i "s|^alias ${name}=.*|alias ${name}='${value}'|" "$file"
    else
        # Otherwise append it
        echo "alias ${name}='${value}'" >> "$file"
    fi
}

# Check if running with correct privileges
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "❌ Error: This script must be run with sudo" >&2
        echo "Usage: sudo ./$0" >&2
        exit 1
    fi
}

check_not_root() {
    if [[ $EUID -eq 0 ]]; then
        echo "❌ Error: This script should NOT be run with sudo" >&2
        echo "Usage: ./$0 (as regular user)" >&2
        exit 1
    fi
}

# Print section headers
print_section() {
    local title="$1"
    echo ""
    echo "# ---- $title ----"
}

# Log with timestamp (optional utility)
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}