#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# 10-base-system.sh - System-level setup (REQUIRES SUDO)
# =============================================================================
# This script installs system packages, configures firewall, and sets up SSH.
# USAGE: sudo ./10-base-system.sh
# =============================================================================

# Check if running with sudo
if [[ $EUID -ne 0 ]]; then
    echo "❌ Error: This script must be run with sudo" >&2
    echo "Usage: sudo ./10-base-system.sh" >&2
    exit 1
fi

# Check if SUDO_USER is set (means run with sudo, not as root directly)
if [[ -z "${SUDO_USER:-}" ]]; then
    echo "⚠️  Warning: Running as root directly. Consider using 'sudo' instead." >&2
fi

apt update && apt upgrade -y

# Install and configure UFW for firewall management
apt install -y ufw
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw --force enable

# Install and configure SSH server and mosh for secure shell access
apt install -y openssh-server mosh
systemctl enable --now ssh
ufw allow 60000:61000/udp

# Install essential CLI tools for system management and development
apt install -y \
  git curl wget htop tmux vim ripgrep ncdu pv jq make build-essential bat

# Fix script permissions so regular user can run shell environment scripts
if [ -d "/opt/vps-init" ] && [ -n "${SUDO_USER:-}" ]; then
  echo "Setting up script permissions for user: $SUDO_USER"
  chown "$SUDO_USER:$SUDO_USER" /opt/vps-init/*.sh
  chmod +x /opt/vps-init/*.sh
  echo "✔ Scripts are now owned by $SUDO_USER and executable"
else
  echo "⚠ /opt/vps-init directory not found or not run with sudo - skipping permission fix"
fi