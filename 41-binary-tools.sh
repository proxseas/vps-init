#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# 41-binary-tools.sh - Binary tools installation (REQUIRES SUDO)
# =============================================================================
# This script installs core binary tools: zoxide and glow.
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
# Install lazygit (Git TUI)
##############################################################################
print_section "Installing lazygit"

if ! command -v lazygit >/dev/null 2>&1; then
    echo "Installing lazygit..."
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | \
        grep -Po '"tag_name": *"v\K[^"]*')
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    tar xf lazygit.tar.gz lazygit
    sudo install lazygit -D -t /usr/local/bin/
    rm -f lazygit.tar.gz lazygit  # cleanup
    echo "✔ lazygit installed"
else
    echo "✔ lazygit already installed"
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

# lazygit alias
update_alias "lg" "lazygit" "$ZSH_ALIASES"

echo "✔ Aliases configured"

echo -e "\n✔ Binary tools setup complete!"
echo "Available tools:"
echo "  - zoxide: Smart cd replacement (z, zi commands)"
echo "  - lazygit: Git TUI (lg command)"
echo ""
echo "Usage:"
echo "  - z <directory>: Smart directory navigation"
echo "  - zi: Interactive directory selection"
echo "  - lg: Launch lazygit Git TUI"
echo ""
echo "💡 Restart your terminal or run 'source ~/.zshrc' to use new tools"
echo ""
echo "🚀 Extended Tools Available:"
echo "  - For advanced Rust CLI tools: sudo ./42-rust-tools-extended.sh"
echo "  - For Python CLI tools: sudo ./32-python-tools-extended.sh"