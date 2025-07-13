#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# 41-binary-tools.sh - Binary tools installation (REQUIRES SUDO)
# =============================================================================
# This script installs various binary tools: zoxide, httpie, tokei, and glow.
# USAGE: sudo ./41-binary-tools.sh
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

echo "Installing binary tools for user: $TARGET_USER"

##############################################################################
# Install Rust toolchain (needed for tokei)
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
# Install zoxide (smart cd replacement)
##############################################################################
print_section "Installing zoxide"

if ! sudo -u "$TARGET_USER" command -v zoxide >/dev/null 2>&1; then
    echo "Installing zoxide..."
    sudo -u "$TARGET_USER" bash -c 'curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash'

    # Add zoxide initialization to .zshrc
    sudo -u "$TARGET_USER" bash <<EOF
if ! grep -q 'zoxide init' "$TARGET_ZSHRC" 2>/dev/null; then
    echo 'eval "\$(zoxide init zsh)"  # zoxide smart cd' >> "$TARGET_ZSHRC"
fi
EOF

    echo "✔ zoxide installed"
else
    echo "✔ zoxide already installed"
fi

##############################################################################
# Install httpie via pipx
##############################################################################
print_section "Installing httpie"

if ! sudo -u "$TARGET_USER" pipx list | grep -q "httpie"; then
    echo "Installing httpie..."
    sudo -u "$TARGET_USER" pipx install httpie
    echo "✔ httpie installed"
else
    echo "✔ httpie already installed"
fi

##############################################################################
# Install tokei via cargo
##############################################################################
print_section "Installing tokei"

# Use cargo to install tokei
if ! sudo -u "$TARGET_USER" command -v tokei >/dev/null 2>&1; then
    echo "Installing tokei..."
    sudo -u "$TARGET_USER" bash -c 'source ~/.cargo/env && cargo install tokei'
    echo "✔ tokei installed"
else
    echo "✔ tokei already installed"
fi

##############################################################################
# Install glow via snap
##############################################################################
print_section "Installing glow"

if ! command -v glow >/dev/null 2>&1; then
    echo "Installing glow..."
    snap install glow
    echo "✔ glow installed"
else
    echo "✔ glow already installed"
fi

##############################################################################
# Add useful aliases
##############################################################################
print_section "Setting up aliases"

ZSH_ALIASES="$TARGET_HOME/.zsh_aliases"

# Source utilities for update_alias function
source "$(dirname "$0")/utils.sh"

# zoxide aliases
update_alias "cd" "z" "$ZSH_ALIASES"
update_alias "cdi" "zi" "$ZSH_ALIASES"  # interactive cd

# httpie aliases
update_alias "http" "http" "$ZSH_ALIASES"
update_alias "https" "https" "$ZSH_ALIASES"

echo "✔ Aliases configured"

echo -e "\n✔ Binary tools setup complete!"
echo "Available tools:"
echo "  - zoxide: Smart cd replacement (z, zi commands)"
echo "  - httpie: Modern HTTP client (http, https commands)"
echo "  - tokei: Code statistics tool"
echo "  - glow: Terminal markdown reader"
echo ""
echo "Usage:"
echo "  - z <directory>: Smart directory navigation"
echo "  - zi: Interactive directory selection"
echo "  - http GET api.github.com: Make HTTP requests"
echo "  - tokei: Show code statistics"
echo "  - glow README.md: View markdown files"
echo ""
echo "💡 Restart your terminal or run 'source ~/.zshrc' to use new tools"