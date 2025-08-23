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

# Adds a block of shell functions using heredoc with marker system
add_functions_block() {
    local file="$1"
    local marker="$2"

    touch "$file"

    # Only add if marker doesn't exist
    if ! grep -q "$marker" "$file" 2>/dev/null; then
        if [[ "$marker" == "AWK_HELPERS" ]]; then
            cat >> "$file" << EOF

# $marker
function awkn {
  cmd="awk '{print \\\$$1}'"
  eval "\$cmd"
}

function awklast {
  cmd="awk '{print \\\$NF}'"
  eval "\$cmd"
}
EOF
        elif [[ "$marker" == "TIMESTAMP_HELPERS" ]]; then
            cat >> "$file" << EOF

# $marker
## human-friendly ts function
## Examples:
## * some_app | tee "\$(ts a.txt)"
## * touch "\$(ts notes.md)"
## * vim "\$(ts scratch.md)"
ts() { date +%Y-%m-%d_%H-%M-%S | xargs -I{} printf "%s_%s\n" {} "\$1"; }
EOF
        fi
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