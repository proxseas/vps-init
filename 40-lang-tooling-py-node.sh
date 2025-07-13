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

# Determine target user (the user who ran sudo)
if [[ -n "${SUDO_USER:-}" ]]; then
    TARGET_USER="$SUDO_USER"
    TARGET_HOME="/home/$TARGET_USER"
    TARGET_ZSHRC="$TARGET_HOME/.zshrc"
else
    echo "❌ Error: SUDO_USER not set. Run with sudo, not as root directly." >&2
    exit 1
fi

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
sudo -u "$TARGET_USER" bash -c "grep -q 'uv install path' \"$TARGET_ZSHRC\" 2>/dev/null || echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"  # uv install path' >> \"$TARGET_ZSHRC\""

echo "✔  uv installed."

##############################################################################
# 2.  Node toolchain – switch from slow **nvm** to fast **fnm**
#     (cargo binary; no subshell 'source' gymnastics)
##############################################################################
# ---- install fnm (fast Node version manager) ----
sudo -u "$TARGET_USER" bash -c 'curl -fsSL https://fnm.vercel.app/install | bash'

# add to .zshrc if missing
sudo -u "$TARGET_USER" bash -c "grep -q 'fnm env' \"$TARGET_ZSHRC\" 2>/dev/null || cat >> \"$TARGET_ZSHRC\" <<'EOF'
# ---- fnm ----
export PATH=\"\$HOME/.local/share/fnm:\$PATH\"   # fnm binary lives here
eval \"\$(fnm env --use-on-cd)\"
EOF"

echo "✔  fnm installed."

##############################################################################
# 3.  Optional: first-time tool versions
##############################################################################
# Fast latest LTS Node and corepack front-end (pnpm, yarn):
sudo -u "$TARGET_USER" bash -c "
  source \"$TARGET_ZSHRC\"             # bring fnm into current shell
  fnm install --lts
  corepack enable
"

# Example: create an isolated project with uv + Node:
#   mkdir demo && cd demo
#   uv venv              # Lightning-fast venv
#   fnm use --install    # Pick Node version per-dir via .node-version

echo -e "\nDone.  Open a new terminal or \`exec zsh\` to start using uv and fnm."
