#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# 32-python-cli-tools.sh - Python CLI tools installation (REQUIRES SUDO)
# =============================================================================
# This script installs pipx and Python CLI tools like glances and procs.
# USAGE: sudo ./32-python-cli-tools.sh
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

echo "Installing Python CLI tools for user: $TARGET_USER"

##############################################################################
# Install pipx for Python CLI tools
##############################################################################
print_section "Installing pipx"

# Install pipx system-wide (also installs python3-pip as dependency)
apt update
apt install -y pipx

# Ensure pipx is configured for the target user
sudo -u "$TARGET_USER" pipx ensurepath

echo "✔ pipx installed and configured"

##############################################################################
# Install Python CLI tools via pipx
##############################################################################
print_section "Installing Python CLI tools"

# Install glances (basic monitoring tool)
if ! sudo -u "$TARGET_USER" pipx list | grep -q "glances"; then
    echo "Installing glances..."
    sudo -u "$TARGET_USER" pipx install glances
    echo "✔ glances installed"
else
    echo "✔ glances already installed"
fi

# Install procs (modern ps replacement)
if ! sudo -u "$TARGET_USER" pipx list | grep -q "procs"; then
    echo "Installing procs..."
    sudo -u "$TARGET_USER" pipx install procs
    echo "✔ procs installed"
else
    echo "✔ procs already installed"
fi

echo -e "\n✔ Python CLI tools setup complete!"
echo "Available tools:"
echo "  - pipx: Python CLI tool installer"
echo "  - glances: System monitoring tool"
echo "  - procs: Modern ps replacement"
echo ""
echo "Usage:"
echo "  - glances: System monitoring dashboard"
echo "  - procs: Better process listing"
echo "  - pipx install <tool>: Install Python CLI tools"
echo ""
echo "💡 Tools are installed in ~/.local/bin and should be in your PATH"