#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   NEW_USER=<username> ./00-create-user.sh
#     or
#   ./00-create-user.sh <username>

# determine NEW_USER
if [[ -n "${NEW_USER:-}" ]]; then
  :
elif [[ $# -ge 1 ]]; then
  NEW_USER="$1"
else
  echo "ERROR: must supply new username via NEW_USER=… or as first argument"
  exit 1
fi

# must be root
if [[ "$(id -u)" -ne 0 ]]; then
  echo "ERROR: run as root"
  exit 1
fi

# skip if already exists
if getent passwd "$NEW_USER" >/dev/null; then
  echo "➜  user '$NEW_USER' already exists, skipping creation"
else
  adduser --disabled-password --gecos "" "$NEW_USER"
  usermod -aG sudo "$NEW_USER"
  echo "$NEW_USER ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/$NEW_USER
  echo "➜  created sudo user '$NEW_USER'"
fi

# copy whatever keys root has
SSH_DIR="/home/$NEW_USER/.ssh"
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

if [[ -f /root/.ssh/authorized_keys ]]; then
  cp /root/.ssh/authorized_keys "$SSH_DIR/authorized_keys"
  chown -R "$NEW_USER":"$NEW_USER" "$SSH_DIR"
  chmod 600 "$SSH_DIR/authorized_keys"
  echo "➜  copied SSH keys into $SSH_DIR/authorized_keys"
else
  echo "⚠️  /root/.ssh/authorized_keys not found — no keys copied"
fi

echo "✔  user setup complete. You can now:  ssh $NEW_USER@<VPS_IP>"

# Only do automated user switching if not called from setup.sh
if [[ "${CALLED_FROM_SETUP:-}" != "true" ]]; then
  # Automated flow: switch to user and navigate to setup directory
  echo ""
  echo "🚀 Switching to user '$NEW_USER' and navigating to setup directory..."
  echo "=================================================================================="

  # Switch to the new user with a clear welcome message
  exec su - "$NEW_USER" -c "
  cd /opt/vps-init

  echo '✅ Successfully switched to user: '$NEW_USER''
  echo '📁 Current directory: '$(pwd)''
  echo ''
  echo '🎯 Next Steps:'
  echo '  1. Run the master setup script (recommended):'
  echo '     ./setup.sh'
  echo ''
  echo '  2. Or run individual scripts step by step:'
  echo '     ./20-shell-env.sh                    # Configure shell environment'
  echo '     ./30-dev-tools.sh                    # Install development tools'
  echo '     sudo ./40-lang-tooling-py-node.sh   # Install Python/Node.js'
  echo '     sudo ./50-container-tools.sh        # Install Docker tools'
  echo ''
  echo '📋 Available scripts:'
  ls -1 *.sh | head -10
  echo ''
  echo '💡 Tip: Start with \"./setup.sh\" for the complete automated setup!'
  echo '=================================================================================='
  echo ''

  # Start interactive shell in the setup directory
  exec bash
  "
else
  echo "➜  Continuing with automated setup..."
fi