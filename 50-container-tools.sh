#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# 50-container-tools.sh - Container tools installation (REQUIRES SUDO)
# =============================================================================
# This script installs Docker and lazydocker.
# USAGE: sudo ./50-container-tools.sh
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

echo "Installing container tools for user: $TARGET_USER"

##############################################################################
# Docker Engine
##############################################################################
print_section "Installing Docker"

if ! command -v docker >/dev/null; then
    echo "Installing Docker..."
    apt-get update
    apt-get install -y ca-certificates curl gnupg lsb-release

    # Add Docker GPG key & repo
    install -d -m0755 /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
        | gpg --dearmor -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc

    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
        https://download.docker.com/linux/ubuntu \
        $(. /etc/os-release && echo $VERSION_CODENAME) stable" \
        | tee /etc/apt/sources.list.d/docker.list >/dev/null

    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io
    usermod -aG docker "$TARGET_USER"

    echo "✔ Docker installed and $TARGET_USER added to docker group"
else
    echo "✔ Docker already installed"
fi

##############################################################################
# Lazydocker
##############################################################################
print_section "Installing lazydocker"

# ---- START DEBUG BLOCK ----
echo "--- LAZYDOCKER DEBUG ---"
echo "[Info] Running check as user: $(whoami)"
echo "[Info] Target user for installation is: $TARGET_USER"

if command -v lazydocker >/dev/null; then
    LAZYDOCKER_PATH=$(which lazydocker)
    echo "[Debug] 'which lazydocker' for root points to: $LAZYDOCKER_PATH"
    echo "[Debug] Permissions for that file are:"
    ls -l "$LAZYDOCKER_PATH"
else
    echo "[Debug] 'command -v lazydocker' failed for root."
fi

echo "[Debug] Now, attempting to run '--version' as TARGET_USER..."
if sudo -u "$TARGET_USER" lazydocker --version >/dev/null 2>&1; then
    echo "[Debug] SUCCESS: Target user '$TARGET_USER' CAN run lazydocker."
else
    echo "[Debug] FAILURE: Target user '$TARGET_USER' CANNOT run lazydocker. This is the problem."
fi
echo "--- END DEBUG ---"
# ---- END DEBUG BLOCK ----

if ! command -v lazydocker >/dev/null || ! lazydocker --version >/dev/null 2>&1; then
    echo "Installing lazydocker..."

    # Download and install lazydocker
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"

    # Get latest release URL
    RELEASE_URL=$(curl -s https://api.github.com/repos/jesseduffield/lazydocker/releases/latest | grep "browser_download_url.*Linux_x86_64.tar.gz" | cut -d '"' -f 4)

    # Download and extract
    curl -sL "$RELEASE_URL" | tar xz

    # Install to /usr/local/bin
    install lazydocker /usr/local/bin/lazydocker

    # Ensure proper permissions
    chmod +x /usr/local/bin/lazydocker

    # Verify installation works
    if ! /usr/local/bin/lazydocker --version >/dev/null 2>&1; then
        echo "❌ Error: lazydocker installation failed - binary not working"
        exit 1
    fi

    # Clean up
    cd - >/dev/null
    rm -rf "$TEMP_DIR"

    # Add alias for target user
    echo "alias lzd='lazydocker'" >> "$TARGET_HOME/.zsh_aliases"

    echo "✔ lazydocker installed and alias lzd added"
else
    echo "✔ lazydocker already installed"
fi

echo -e "\n✔ Container tools setup complete!"
echo "Available tools:"
echo "  - Docker: Container runtime"
echo "  - lazydocker: Docker TUI (lzd alias)"
echo ""
echo "Usage:"
echo "  - docker ps: List containers"
echo "  - lzd: Launch lazydocker TUI"
echo ""
echo "💡 You may need to restart your terminal or re-login for Docker group membership to take effect"
