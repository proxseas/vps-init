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

# plugins (including z for fallback to z.sh)
for p in zsh-autosuggestions zsh-syntax-highlighting zsh-history-substring-search; do
  if [ ! -d "$ZSH_CUSTOM/plugins/$p" ]; then
    git clone --depth=1 "https://github.com/zsh-users/$p" "$ZSH_CUSTOM/plugins/$p"
  fi
done

# enable plugins in ~/.zshrc (z plugin for fallback)
if grep -q '^plugins=' "$ZSHRC"; then
  sed -i 's/^plugins=.*/plugins=(git z zsh-autosuggestions zsh-syntax-highlighting history-substring-search)/' "$ZSHRC"
else
  echo 'plugins=(git z zsh-autosuggestions zsh-syntax-highlighting history-substring-search)' >> "$ZSHRC"
fi

# Remove old explicit syntax-highlighting source line
sed -i '/source.*zsh-syntax-highlighting.*zsh-syntax-highlighting\.zsh/d' "$ZSHRC"

# misc zsh tweaks
grep -q '^EDITOR=' "$ZSHRC" 2>/dev/null || cat >> "$ZSHRC" <<'EOF'

# User preferences
EDITOR='vim'
setopt cdablevars
export TERM='xterm-256color'

# Custom prompt with username (hostname truncated at first dash, no colon)
PROMPT='%F{cyan}%n%f@%F{yellow}${${(%):-%m}%%-*}%f %F{green}%~%f '

# auto-ls on cd functionality removed

# load aliases if present
[ -f ~/.zsh_aliases ] && source ~/.zsh_aliases

## human-friendly ts function
## Examples:
## * some_app | tee "$(ts a.txt)"
## * touch "$(ts notes.md)"
## * vim "$(ts scratch.md)"
ts() { date +%Y-%m-%d_%H-%M-%S | xargs -I{} printf "%s_%s\n" {} "$1"; }

# Suspend widget and keybind tweaks
suspend-widget() { builtin suspend }
zle -N suspend-widget
# Keybind tweaks
bindkey -r '^[l'               # free Alt+l
bindkey -M emacs '^Z' suspend-widget
bindkey -M viins '^Z' suspend-widget

# zoxide init (with z.sh fallback) - will be added by binary-tools script if installed
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
elif [[ -f "$HOME/z.sh" ]]; then
  source "$HOME/z.sh"
fi

# zsh-syntax-highlighting is handled by oh-my-zsh plugins system
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