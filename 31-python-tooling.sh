#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# 31-python-tooling.sh - Python tooling setup (REQUIRES SUDO)
# =============================================================================
# This script installs Python build dependencies and uv (Python package manager).
# USAGE: sudo ./31-python-tooling.sh
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

echo "Installing Python tooling for user: $TARGET_USER"

##############################################################################
# System-wide Python build tooling
##############################################################################
print_section "Python Build Dependencies"

apt update
apt install -y \
  make build-essential curl wget llvm tk-dev libssl-dev zlib1g-dev \
  libbz2-dev libreadline-dev libsqlite3-dev libncurses5-dev libncursesw5-dev \
  xz-utils libffi-dev liblzma-dev python3-venv jq unzip

##############################################################################
# Lightweight Python tooling: Astral-sh **uv**
##############################################################################
print_section "Python Package Manager (uv)"

# Install uv as the target user
sudo -u "$TARGET_USER" bash -c 'curl -Ls https://astral.sh/uv/install.sh | bash'

# Ensure uv is on PATH (the installer drops it into ~/.local/bin)
sudo -u "$TARGET_USER" bash <<EOF
if ! grep -q 'uv install path' "$TARGET_ZSHRC" 2>/dev/null; then
  echo 'export PATH="\$HOME/.local/bin:\$PATH"  # uv install path' >> "$TARGET_ZSHRC"
fi
EOF

echo "✔  uv installed."

echo -e "\n✔  Python tooling setup complete!"
echo "To use uv:"
echo "1. Open a new terminal or run: exec zsh"
echo "2. Test: uv --version"
echo "3. Create projects with: uv init myproject && cd myproject && uv venv"