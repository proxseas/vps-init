#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# 40-lang-tooling-py-node.sh - Language tooling setup (REQUIRES SUDO)
# =============================================================================
# This script installs Python and Node.js tooling.
# USAGE: sudo ./40-lang-tooling-py-node.sh
# =============================================================================

# Check if running with sudo
if [[ $EUID -ne 0 ]]; then
    echo "❌ Error: This script must be run with sudo" >&2
    echo "Usage: sudo ./40-lang-tooling-py-node.sh" >&2
    exit 1
fi

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

echo "Installing language tooling for user: $TARGET_USER"

##############################################################################
# 0.  System-wide build tooling
##############################################################################
apt update
apt install -y \
  make build-essential curl wget llvm tk-dev libssl-dev zlib1g-dev \
  libbz2-dev libreadline-dev libsqlite3-dev libncurses5-dev libncursesw5-dev \
  xz-utils libffi-dev liblzma-dev python3-venv jq unzip

##############################################################################
# 1.  Lightweight Python tooling:  Astral-sh **uv**
#     (fast pip/venv replacement, no shims needed)
##############################################################################
# Install uv as the target user
sudo -u "$TARGET_USER" bash -c 'curl -Ls https://astral.sh/uv/install.sh | bash'

# Ensure uv is on PATH (the installer drops it into ~/.local/bin)
sudo -u "$TARGET_USER" bash <<EOF
if ! grep -q 'uv install path' "$TARGET_ZSHRC" 2>/dev/null; then
  echo 'export PATH="\$HOME/.local/bin:\$PATH"  # uv install path' >> "$TARGET_ZSHRC"
fi
EOF

echo "✔  uv installed."

##############################################################################
# 2.  Node toolchain – switch from slow **nvm** to fast **fnm**
#     (cargo binary; no subshell 'source' gymnastics)
##############################################################################
# ---- install fnm (fast Node version manager) ----
sudo -u "$TARGET_USER" bash -c 'curl -fsSL https://fnm.vercel.app/install | bash'

# Note: fnm installer automatically adds configuration to .zshrc
echo "✔  fnm installed."

##############################################################################
# 3.  Optional: first-time tool versions
##############################################################################
# Fast latest LTS Node and corepack front-end (pnpm, yarn):
# Use here-document to avoid complex escaping
sudo -u "$TARGET_USER" bash <<EOF
export PATH="$TARGET_HOME/.local/share/fnm:\$PATH"

# Check if fnm binary exists
if [[ -x "$TARGET_HOME/.local/share/fnm/fnm" ]]; then
  eval "\$($TARGET_HOME/.local/share/fnm/fnm env --use-on-cd)"
  fnm install --lts || echo 'fnm install failed, continuing...'
  corepack enable || echo 'corepack enable failed, continuing...'
else
  echo 'fnm binary not found, skipping Node.js installation'
fi
EOF

# Example: create an isolated project with uv + Node:
#   mkdir demo && cd demo
#   uv venv              # Lightning-fast venv
#   fnm use --install    # Pick Node version per-dir via .node-version

echo -e "\n✔  Language tooling setup complete!"
echo "To use uv and fnm:"
echo "1. Open a new terminal or run: exec zsh"
echo "2. Test: uv --version && fnm --version && node --version"
echo "3. Your PATH has been updated in ~/.zshrc"
