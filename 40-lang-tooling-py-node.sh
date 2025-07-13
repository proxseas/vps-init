#!/usr/bin/env bash
set -euo pipefail

##############################################################################
# 0.  System-wide build tooling
##############################################################################
sudo apt update
sudo apt install -y \
  make build-essential curl wget llvm tk-dev libssl-dev zlib1g-dev \
  libbz2-dev libreadline-dev libsqlite3-dev libncurses5-dev libncursesw5-dev \
  xz-utils libffi-dev liblzma-dev python3-venv jq unzip

##############################################################################
# 1.  Lightweight Python tooling:  Astral-sh **uv**
#     (fast pip/venv replacement, no shims needed)
##############################################################################
curl -Ls https://astral.sh/uv/install.sh | bash

# Ensure uv is on PATH (the installer drops it into ~/.local/bin)
grep -q 'uv install path' ~/.zshrc 2>/dev/null || \
  echo 'export PATH="$HOME/.local/bin:$PATH"  # uv install path' >> ~/.zshrc

echo "✔  uv installed."

##############################################################################
# 2.  Node toolchain – switch from slow **nvm** to fast **fnm**
#     (cargo binary; no subshell ‘source’ gymnastics)
##############################################################################
# ---- install fnm (fast Node version manager) ----
curl -fsSL https://fnm.vercel.app/install | bash

# add to .zshrc if missing
grep -q 'fnm env' ~/.zshrc 2>/dev/null || cat >> ~/.zshrc <<'EOF'
# ---- fnm ----
export PATH="$HOME/.local/share/fnm:$PATH"   # fnm binary lives here
eval "$(fnm env --use-on-cd)"
EOF

echo "✔  fnm installed."

##############################################################################
# 3.  Optional: first-time tool versions
##############################################################################
# Fast latest LTS Node and corepack front-end (pnpm, yarn):
source ~/.zshrc             # bring fnm into current shell
fnm install --lts
corepack enable

# Example: create an isolated project with uv + Node:
#   mkdir demo && cd demo
#   uv venv              # Lightning-fast venv
#   fnm use --install    # Pick Node version per-dir via .node-version

echo -e "\nDone.  Open a new terminal or \`exec zsh\` to start using uv and fnm."
