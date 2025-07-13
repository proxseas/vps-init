#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# 15-configure-ssh-security.sh - SSH security hardening (REQUIRES SUDO)
# =============================================================================
# This script hardens SSH security by disabling password authentication.
# It verifies SSH keys are properly configured before making changes.
# USAGE: sudo ./15-configure-ssh-security.sh [username]
# =============================================================================

# Source utilities
source "$(dirname "$0")/utils.sh"

# Check if running with sudo
check_root

# Determine target user
if [[ -n "${1:-}" ]]; then
    TARGET_USER="$1"
elif [[ -n "${SUDO_USER:-}" ]]; then
    TARGET_USER="$SUDO_USER"
else
    echo "❌ Error: No target user specified." >&2
    echo "Usage: sudo ./15-configure-ssh-security.sh [username]" >&2
    echo "Or run with sudo from the target user account." >&2
    exit 1
fi

TARGET_HOME="/home/$TARGET_USER"
SSH_CONFIG="/etc/ssh/sshd_config"

echo "Configuring SSH security for user: $TARGET_USER"

##############################################################################
# Verify SSH key setup
##############################################################################
print_section "Verifying SSH key configuration"

# Check if user has SSH authorized_keys
if [[ ! -f "$TARGET_HOME/.ssh/authorized_keys" ]]; then
    echo "❌ Error: No SSH keys found for user $TARGET_USER" >&2
    echo "Please set up SSH keys before running this script:" >&2
    echo "1. On your local machine: ssh-keygen (if you don't have keys)" >&2
    echo "2. Copy your public key: ssh-copy-id $TARGET_USER@<server-ip>" >&2
    echo "3. Test login: ssh $TARGET_USER@<server-ip>" >&2
    echo "4. Then run this script again" >&2
    exit 1
fi

# Check if authorized_keys has content
if [[ ! -s "$TARGET_HOME/.ssh/authorized_keys" ]]; then
    echo "❌ Error: SSH authorized_keys file is empty for user $TARGET_USER" >&2
    echo "Please add your SSH public key to $TARGET_HOME/.ssh/authorized_keys" >&2
    exit 1
fi

# Check permissions
if [[ $(stat -c "%a" "$TARGET_HOME/.ssh") != "700" ]]; then
    echo "Fixing SSH directory permissions..."
    chmod 700 "$TARGET_HOME/.ssh"
fi

if [[ $(stat -c "%a" "$TARGET_HOME/.ssh/authorized_keys") != "600" ]]; then
    echo "Fixing SSH authorized_keys permissions..."
    chmod 600 "$TARGET_HOME/.ssh/authorized_keys"
fi

echo "✔ SSH keys properly configured for user $TARGET_USER"

##############################################################################
# Test SSH connection
##############################################################################
print_section "Testing SSH connection"

echo "⚠️  IMPORTANT: Before disabling password authentication, please verify:"
echo "1. You can connect via SSH with your key: ssh $TARGET_USER@<server-ip>"
echo "2. You have sudo access with your key-based connection"
echo "3. You have another way to access the server if something goes wrong"
echo ""
read -p "Have you verified SSH key login works? (y/N): " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Aborted: Please test SSH key login first" >&2
    echo "Test with: ssh $TARGET_USER@<server-ip>" >&2
    exit 1
fi

##############################################################################
# Configure SSH security
##############################################################################
print_section "Configuring SSH security"

# Backup original config
if [[ ! -f "$SSH_CONFIG.backup" ]]; then
    echo "Creating backup of SSH config..."
    cp "$SSH_CONFIG" "$SSH_CONFIG.backup"
fi

# Configure SSH settings
echo "Updating SSH configuration..."

# Disable password authentication
if grep -q "^PasswordAuthentication" "$SSH_CONFIG"; then
    sed -i 's/^PasswordAuthentication.*/PasswordAuthentication no/' "$SSH_CONFIG"
else
    echo "PasswordAuthentication no" >> "$SSH_CONFIG"
fi

# Disable empty passwords
if grep -q "^PermitEmptyPasswords" "$SSH_CONFIG"; then
    sed -i 's/^PermitEmptyPasswords.*/PermitEmptyPasswords no/' "$SSH_CONFIG"
else
    echo "PermitEmptyPasswords no" >> "$SSH_CONFIG"
fi

# Disable root login
if grep -q "^PermitRootLogin" "$SSH_CONFIG"; then
    sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' "$SSH_CONFIG"
else
    echo "PermitRootLogin no" >> "$SSH_CONFIG"
fi

# Enable public key authentication (should be default)
if grep -q "^PubkeyAuthentication" "$SSH_CONFIG"; then
    sed -i 's/^PubkeyAuthentication.*/PubkeyAuthentication yes/' "$SSH_CONFIG"
else
    echo "PubkeyAuthentication yes" >> "$SSH_CONFIG"
fi

# Disable challenge-response authentication
if grep -q "^ChallengeResponseAuthentication" "$SSH_CONFIG"; then
    sed -i 's/^ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/' "$SSH_CONFIG"
else
    echo "ChallengeResponseAuthentication no" >> "$SSH_CONFIG"
fi

# Disable Kerberos authentication
if grep -q "^KerberosAuthentication" "$SSH_CONFIG"; then
    sed -i 's/^KerberosAuthentication.*/KerberosAuthentication no/' "$SSH_CONFIG"
else
    echo "KerberosAuthentication no" >> "$SSH_CONFIG"
fi

# Disable GSSAPI authentication
if grep -q "^GSSAPIAuthentication" "$SSH_CONFIG"; then
    sed -i 's/^GSSAPIAuthentication.*/GSSAPIAuthentication no/' "$SSH_CONFIG"
else
    echo "GSSAPIAuthentication no" >> "$SSH_CONFIG"
fi

echo "✔ SSH security configuration updated"

##############################################################################
# Restart SSH service
##############################################################################
print_section "Restarting SSH service"

echo "Testing SSH configuration..."
if ! sshd -t; then
    echo "❌ Error: SSH configuration is invalid" >&2
    echo "Restoring backup..." >&2
    cp "$SSH_CONFIG.backup" "$SSH_CONFIG"
    exit 1
fi

echo "Restarting SSH service..."
systemctl restart ssh

# Verify service is running
if systemctl is-active --quiet ssh; then
    echo "✔ SSH service restarted successfully"
else
    echo "❌ Error: SSH service failed to restart" >&2
    echo "Restoring backup..." >&2
    cp "$SSH_CONFIG.backup" "$SSH_CONFIG"
    systemctl restart ssh
    exit 1
fi

echo -e "\n✔ SSH security hardening complete!"
echo "Security changes applied:"
echo "  - Password authentication: DISABLED"
echo "  - Root login: DISABLED"
echo "  - Public key authentication: ENABLED"
echo "  - Empty passwords: DISABLED"
echo "  - Challenge-response auth: DISABLED"
echo ""
echo "⚠️  IMPORTANT SECURITY NOTES:"
echo "  - Password login is now DISABLED"
echo "  - Only SSH key authentication is allowed"
echo "  - Root login is DISABLED"
echo "  - Backup config saved to: $SSH_CONFIG.backup"
echo ""
echo "💡 Test your SSH connection now:"
echo "   ssh $TARGET_USER@<server-ip>"
echo ""
echo "🔐 Your server is now more secure!"