#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# 42-rust-tools.sh - Rust tools installation via cargo (REQUIRES SUDO)
# =============================================================================
# This script installs Rust CLI tools via cargo for latest versions.
# USAGE: sudo ./42-rust-tools.sh
# =============================================================================

# Source utilities
source "$(dirname "$0")/utils.sh"

# Check if running with sudo
check_root

# Determine target user (the user who ran sudo OR from setup.sh)
if [[ -n "${SUDO_USER:-}" ]]; then
    TARGET_USER="$SUDO_USER"
elif [[ -n "${TARGET_USER_FROM_SETUP:-}" ]]; then
    TARGET_USER="$TARGET_USER_FROM_SETUP"
    echo "Using target user from setup.sh: $TARGET_USER"
else
    echo "❌ Error: No target user specified." >&2
    echo "Run with sudo, or ensure TARGET_USER_FROM_SETUP is set when called from setup.sh." >&2
    exit 1
fi

TARGET_HOME="/home/$TARGET_USER"

echo "Installing Rust CLI tools for user: $TARGET_USER"

##############################################################################
# Install Rust CLI tools via cargo
##############################################################################
print_section "Installing Rust CLI tools"

# Function to install cargo tool if not already installed
install_cargo_tool() {
    local tool_name="$1"
    local crate_name="${2:-$tool_name}"

    if ! sudo -u "$TARGET_USER" command -v "$tool_name" >/dev/null 2>&1; then
        echo "Installing $tool_name..."
        sudo -u "$TARGET_USER" bash -c "source ~/.cargo/env && cargo install $crate_name"
        echo "✔ $tool_name installed"
    else
        echo "✔ $tool_name already installed"
    fi
}

# Install core Rust CLI tools
install_cargo_tool "rg" "ripgrep"
install_cargo_tool "bat" "bat"
install_cargo_tool "fd" "fd-find"
install_cargo_tool "delta" "git-delta"
install_cargo_tool "procs" "procs"

##############################################################################
# Set up aliases for renamed tools
##############################################################################
print_section "Setting up aliases"

ZSH_ALIASES="$TARGET_HOME/.zsh_aliases"

# bat alias (Ubuntu's apt version is called 'batcat')
update_alias "bat" "bat" "$ZSH_ALIASES"

# ripgrep alias
update_alias "rg" "rg" "$ZSH_ALIASES"

# fd alias (avoid confusion with apt's fdfind)
update_alias "fd" "fd" "$ZSH_ALIASES"

echo "✔ Rust tool aliases configured"

echo -e "\n✔ Rust CLI tools setup complete!"
echo "Available tools:"
echo "  - rg (ripgrep): Fast grep replacement"
echo "  - bat: Cat with syntax highlighting"
echo "  - fd: Fast find replacement"
echo "  - delta: Better git diff viewer"
echo "  - procs: Modern ps replacement"
echo ""
echo "💡 All tools are installed via cargo with latest versions"
echo "💡 Restart your terminal or run 'source ~/.zshrc' to use tools"