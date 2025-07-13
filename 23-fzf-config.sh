#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# 23-fzf-config.sh - FZF fuzzy finder setup (NO SUDO)
# =============================================================================
# This script installs and configures FZF for the current user.
# USAGE: ./23-fzf-config.sh (as regular user)
# =============================================================================

# Source utilities
source "$(dirname "$0")/utils.sh"

# Check if running with sudo (should NOT be)
check_not_root

# ---- FZF Installation ----
print_section "FZF Fuzzy Finder"

ZSHRC="$HOME/.zshrc"

if [ ! -d "$HOME/.fzf" ]; then
  echo "Installing FZF..."
  git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"

  # Install FZF with explicit answers to avoid hanging
  echo -e "y\ny\ny" | bash "$HOME/.fzf/install" --completion --key-bindings --no-update-rc || {
    echo "FZF installation failed, continuing..."
  }

  # Manually add FZF sourcing to ~/.zshrc since we used --no-update-rc
  if ! grep -q '.fzf.zsh' "$ZSHRC"; then
    echo '[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh' >> "$ZSHRC"
  fi
else
  echo "✔ FZF already installed"
fi

echo "✔ FZF configuration complete"
echo "💡 Use Ctrl+R for fuzzy history, Ctrl+T for fuzzy file search"