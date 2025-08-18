#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# 42-rust-tools-extended.sh - Extended Rust tools installation via cargo (REQUIRES SUDO)
# =============================================================================
# This script installs Rust toolchain and extended Rust CLI tools via cargo.
# This is an OPTIONAL script - run manually if you want these tools.
# USAGE: sudo ./42-rust-tools-extended.sh
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
TARGET_ZSHRC="$TARGET_HOME/.zshrc"

echo "Installing extended Rust CLI tools for user: $TARGET_USER"

##############################################################################
# Install Rust toolchain
##############################################################################
print_section "Installing Rust toolchain"

# Install Rust system packages
apt update
apt install -y rustc cargo

# Install Rust via rustup for the target user (more up-to-date)
if ! sudo -u "$TARGET_USER" command -v rustup >/dev/null 2>&1; then
    echo "Installing rustup for user $TARGET_USER..."
    sudo -u "$TARGET_USER" bash -c 'curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y'

    # Add cargo/bin to PATH in .zshrc
    sudo -u "$TARGET_USER" bash <<EOF
if ! grep -q 'cargo/bin' "$TARGET_ZSHRC" 2>/dev/null; then
    echo 'export PATH="\$HOME/.cargo/bin:\$PATH"  # Rust cargo path' >> "$TARGET_ZSHRC"
fi
EOF

    echo "✔ Rust toolchain installed"
else
    echo "✔ Rust toolchain already installed"
fi

##############################################################################
# Install extended Rust CLI tools via cargo
##############################################################################
print_section "Installing extended Rust CLI tools"

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

# Install extended Rust CLI tools (rg and bat are now in core)
install_cargo_tool "fd" "fd-find"
install_cargo_tool "delta" "git-delta"
install_cargo_tool "procs" "procs"
install_cargo_tool "tokei" "tokei"
install_cargo_tool "eza" "eza"

##############################################################################
# Set up aliases for tools
##############################################################################
print_section "Setting up aliases"

ZSH_ALIASES="$TARGET_HOME/.zsh_aliases"

# fd alias (avoid confusion with apt's fdfind)
update_alias "fd" "fd" "$ZSH_ALIASES"

# Add conditional eza aliases
if ! grep -q '# Prefer eza over ls' "$ZSH_ALIASES" 2>/dev/null; then
    sudo -u "$TARGET_USER" bash -c "cat >> '$ZSH_ALIASES'" <<'EOF'

# Prefer eza over ls if available
if command -v eza >/dev/null 2>&1; then
  alias ls='eza'
  alias ll='eza -l --git'
  alias la='eza -la --git'
else
  alias ll='ls -lah'
fi
EOF
fi

echo "✔ Rust tool aliases configured"

echo -e "\n✔ Extended Rust CLI tools setup complete!"
echo "Available tools:"
echo "  - fd: Fast find replacement"
echo "  - delta: Better git diff viewer"
echo "  - procs: Modern ps replacement"
echo "  - tokei: Code statistics tool"
echo "  - eza: Modern ls replacement"
echo ""
echo "Usage:"
echo "  - fd <pattern>: Fast file search"
echo "  - git diff (uses delta automatically)"
echo "  - procs: Modern process viewer"
echo "  - tokei: Show code statistics"
echo "  - ls, ll, la (will use eza if installed)"
echo ""
echo "💡 All tools are installed via cargo with latest versions"
echo "💡 Restart your terminal or run 'source ~/.zshrc' to use tools"