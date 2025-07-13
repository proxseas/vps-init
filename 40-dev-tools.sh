#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# 40-dev-tools.sh - Development tools and aliases setup (NO SUDO)
# =============================================================================
# This script installs eza, just, and sets up useful aliases.
# USAGE: ./40-dev-tools.sh (as regular user)
# =============================================================================

# Source utilities
source "$(dirname "$0")/utils.sh"

# Check if running with sudo (should NOT be)
check_not_root

##############################################################################
# Development Tools Installation
##############################################################################
print_section "Development Tools"

# 1) eza keyring & repo
if ! command -v eza >/dev/null; then
  KEYRING="/etc/apt/keyrings/eza.gpg"
  LIST="/etc/apt/sources.list.d/eza.list"

  # ensure keyring dir
  sudo install -d -m 0755 /etc/apt/keyrings

  # download the key
  wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc \
    | sudo gpg --dearmor -o "$KEYRING"

  # remove any old conflicting file
  sudo rm -f /etc/apt/sources.list.d/gierens.list

  # add the repo if missing
  if ! grep -Rqs "^deb .\+gierens\.de" /etc/apt/sources.list.d; then
    echo "deb [signed-by=$KEYRING] http://deb.gierens.de stable main" \
      | sudo tee "$LIST" >/dev/null
  fi

  sudo chmod 644 "$KEYRING" "$LIST"
  sudo apt update
  sudo apt install -y eza
  echo "✔ eza installed"
else
  echo "✔ eza already installed"
fi

# 2) just (task runner)
if ! command -v just >/dev/null; then
  sudo snap install just --classic
  echo "✔ just installed"
else
  echo "✔ just already installed"
fi

##############################################################################
# Aliases Setup
##############################################################################
print_section "Setting up aliases"

ZSH_ALIASES="$HOME/.zsh_aliases"

# General aliases
update_alias "q" "exit" "$ZSH_ALIASES"
update_alias "reloadzsh" "source ~/.zshrc" "$ZSH_ALIASES"
update_alias "editzsh" "vim ~/.zshrc" "$ZSH_ALIASES"

# Directory listing (eza)
update_alias "ls" "eza" "$ZSH_ALIASES"
update_alias "ll" "eza -l --git" "$ZSH_ALIASES"
update_alias "la" "eza -la --git" "$ZSH_ALIASES"

# Python venv (uv)
update_alias "mkvenv" "uv venv .venv" "$ZSH_ALIASES"
update_alias "actvenv" "source .venv/bin/activate" "$ZSH_ALIASES"
update_alias "takevenv" "uv venv .venv && source .venv/bin/activate && echo 'Activated new uv venv'" "$ZSH_ALIASES"

# Tmux
update_alias "tl" "tmux ls" "$ZSH_ALIASES"
update_alias "ta" "tmux attach" "$ZSH_ALIASES"

# Docker helper
update_alias "lzd" "lazydocker" "$ZSH_ALIASES"

echo "✔ Aliases configured in $ZSH_ALIASES"

echo -e "\n🎉 Development tools setup complete!"
echo "Available tools:"
echo "  - eza: Modern ls replacement"
echo "  - just: Task runner"
echo "  - bat: Modern cat with syntax highlighting (installed by system setup)"
echo ""
echo "Available aliases:"
echo "  - ls, ll, la: Directory listing with eza"
echo "  - q: Quick exit"
echo "  - tl, ta: Tmux shortcuts"
echo "  - mkvenv, actvenv, takevenv: Python virtual env helpers"
echo "  - lzd: Lazydocker shortcut"
echo ""
echo "💡 Restart your terminal or run 'source ~/.zshrc' to use aliases"