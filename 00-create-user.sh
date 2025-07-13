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