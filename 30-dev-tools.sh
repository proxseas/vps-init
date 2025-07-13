#!/usr/bin/env bash
set -euo pipefail

# NOTE: This script depends on 20-shell-env.sh being run first

# Check if zsh is installed (from previous script)
if ! command -v zsh >/dev/null; then
  echo "Error: zsh not found. Please run 20-shell-env.sh first." >&2
  exit 1
fi

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
fi

# 2) just (task runner)
if ! command -v just >/dev/null; then
  sudo snap install just --classic
fi

# 3) Create complete aliases file
ZSH_ALIASES="$HOME/.zsh_aliases"
cat > "$ZSH_ALIASES" <<'EOF'
# General
alias q='exit'
alias reloadzsh='source ~/.zshrc'
alias editzsh='vim ~/.zshrc'

# Directory listing (eza)
alias ls='eza'
alias ll='eza -l --git'
alias la='eza -la --git'

# Python venv (uv)
alias mkvenv='uv venv .venv'
alias actvenv='source .venv/bin/activate'
alias takevenv='uv venv .venv && source .venv/bin/activate && echo "Activated new uv venv"'

# Tmux
alias tl='tmux ls'
alias ta='tmux attach'

# Docker helper
alias lzd='lazydocker'
EOF

echo "✔  Dev-tools & aliases created in $ZSH_ALIASES"
