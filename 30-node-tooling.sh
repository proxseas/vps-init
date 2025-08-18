#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# 30-node-tooling.sh - Node.js tooling setup (REQUIRES SUDO)
# =============================================================================
# This script installs fnm (fast Node version manager) and Node.js.
# USAGE: sudo ./30-node-tooling.sh
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

echo "Installing Node.js tooling for user: $TARGET_USER"

##############################################################################
# Node toolchain – switch from slow **nvm** to fast **fnm**
##############################################################################
print_section "Node.js Tooling (fnm)"

# ---- install fnm (fast Node version manager) ----
sudo -u "$TARGET_USER" bash -c 'curl -fsSL https://fnm.vercel.app/install | bash'

# Add explicit fnm initialization to .zshrc (more reliable than installer)
sudo -u "$TARGET_USER" bash <<EOF
if ! grep -q 'fnm init' "$TARGET_ZSHRC" 2>/dev/null; then
    cat >> "$TARGET_ZSHRC" <<'FNMEOF'

# fnm init (quiet)
FNM_PATH="\$HOME/.local/share/fnm"
if [ -d "\$FNM_PATH" ]; then
  export PATH="\$FNM_PATH:\$PATH"
  eval "\$(fnm env)"
fi
FNMEOF
fi
EOF

echo "✔  fnm installed."

##############################################################################
# Optional: first-time tool versions
##############################################################################
print_section "Installing Node.js LTS"

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

echo -e "\n✔  Node.js tooling setup complete!"
echo "To use fnm and Node.js:"
echo "1. Open a new terminal or run: exec zsh"
echo "2. Test: fnm --version && node --version"
echo "3. Your PATH has been updated in ~/.zshrc"