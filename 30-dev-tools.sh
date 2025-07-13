#!/usr/bin/env bash
set -euo pipefail

# 1) eza (modern ls)
sudo mkdir -p /etc/apt/keyrings
wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc \
  | sudo gpg --dearmor -o /etc/apt/keyrings/eza.gpg
echo "deb [signed-by=/etc/apt/keyrings/eza.gpg] http://deb.gierens.de stable main" \
  | sudo tee /etc/apt/sources.list.d/eza.list
sudo chmod 644 /etc/apt/keyrings/eza.gpg /etc/apt/sources.list.d/eza.list
sudo apt update
sudo apt install -y eza

# 2) just (task runner)
sudo snap install just --classic

# 3) aliases
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

# Tmux
alias tl='tmux ls'
alias ta='tmux attach'

# Python virtualenv helpers
alias mkvenv='python3 -m venv .venv'
alias actvenv='source .venv/bin/activate'
alias takevenv='mkvenv && actvenv && echo "Activated new venv"'

# Misc
alias lzd='lazydocker'
EOF

echo "✔  Dev-tools & aliases installed in $ZSH_ALIASES"