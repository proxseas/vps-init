#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# 20-shell-env.sh - Basic shell environment setup (NO SUDO)
# =============================================================================
# This script configures zsh and oh-my-zsh for the current user.
# USAGE: ./20-shell-env.sh (as regular user)
# =============================================================================

# Check if running with sudo (should NOT be)
if [[ $EUID -eq 0 ]]; then
    echo "❌ Error: This script should NOT be run with sudo" >&2
    echo "Usage: ./20-shell-env.sh (as regular user)" >&2
    echo "This script configures the current user's shell environment." >&2
    exit 1
fi

# NOTE: Run this script before other user environment scripts

# ---- 0. Ensure we're on Ubuntu and have sudo ----
if ! command -v apt >/dev/null; then
  echo "This script is for Debian/Ubuntu." >&2
  exit 1
fi

# ---- 1. Oh My Zsh ----
# install zsh if missing (should already be installed by system setup)
if ! command -v zsh >/dev/null; then
  echo "zsh not found. Run 10-base-system.sh first." >&2
  exit 1
fi

# non-interactive OMZ install
export RUNZSH=no CHSH=no
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

ZSHRC="$HOME/.zshrc"
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# plugins
for p in zsh-autosuggestions zsh-syntax-highlighting zsh-history-substring-search; do
  if [ ! -d "$ZSH_CUSTOM/plugins/$p" ]; then
    git clone --depth=1 "https://github.com/zsh-users/$p" "$ZSH_CUSTOM/plugins/$p"
  fi
done

# enable plugins in ~/.zshrc
if grep -q '^plugins=' "$ZSHRC"; then
  sed -i 's/^plugins=.*/plugins=(git zsh-autosuggestions zsh-syntax-highlighting history-substring-search)/' "$ZSHRC"
else
  echo 'plugins=(git zsh-autosuggestions zsh-syntax-highlighting history-substring-search)' >> "$ZSHRC"
fi

# ensure syntax-highlighting is sourced after OMZ
grep -q 'zsh-syntax-highlighting.zsh' "$ZSHRC" 2>/dev/null \
  || sed -i "/^source .*oh-my-zsh\.sh/a source $ZSH_CUSTOM/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" "$ZSHRC"

# misc zsh tweaks
grep -q '^EDITOR=' "$ZSHRC" 2>/dev/null || cat >> "$ZSHRC" <<'EOF'

# User preferences
EDITOR='vim'
setopt cdablevars
export TERM='xterm-256color'

# Custom prompt with username
PROMPT='%F{cyan}%n%f@%F{yellow}%m%f:%F{green}%~%f%# '

# auto-ls on cd
autoload -U add-zsh-hook
add-zsh-hook -Uz chpwd (){ ls -a; }

# load aliases if present
[ -f ~/.zsh_aliases ] && source ~/.zsh_aliases
EOF

# ---- 2. Make Zsh the default shell ----
if [ "$(basename "$SHELL")" != "zsh" ]; then
  echo "Changing default shell to zsh..."
  sudo chsh -s "$(command -v zsh)" "$USER"
  echo 'source ~/.zshrc' >> "$HOME/.zprofile"
  echo "✔ Default shell changed to zsh"
  echo "⚠️  NOTE: Current session is still bash. To switch immediately, run: exec zsh"
else
  echo "✔ Default shell is already zsh"
fi

echo -e "\n✔  Basic shell environment setup complete."
echo -e "💡 To start using zsh immediately: exec zsh"