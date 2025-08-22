#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# 15-configure-ssh-security.sh - SSH keys, Git config & security hardening (REQUIRES SUDO)
# =============================================================================
# This script:
# 1. Generates SSH keys if they don't exist (RSA 4096)
# 2. Configures Git with smart defaults (username@hostname)
# 3. Hardens SSH security by disabling password authentication
# 4. Verifies SSH keys are properly configured before making changes
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
# Generate SSH keys if they don't exist
##############################################################################
print_section "Setting up SSH keys"

# Check if SSH key already exists
if [[ -f "$TARGET_HOME/.ssh/id_rsa" ]]; then
    echo "✔ SSH key already exists for user $TARGET_USER"
else
    echo "Generating SSH key for user $TARGET_USER..."

    # Create .ssh directory if it doesn't exist
    sudo -u "$TARGET_USER" mkdir -p "$TARGET_HOME/.ssh"
    sudo -u "$TARGET_USER" chmod 700 "$TARGET_HOME/.ssh"

    # Generate SSH key with smart defaults
    EMAIL="$TARGET_USER@$(hostname)"
    echo "Generating RSA 4096 key with email: $EMAIL"

    sudo -u "$TARGET_USER" ssh-keygen -t rsa -b 4096 -C "$EMAIL" -f "$TARGET_HOME/.ssh/id_rsa" -N ""

    echo "✔ SSH key generated successfully"
    echo "Public key location: $TARGET_HOME/.ssh/id_rsa.pub"
fi

##############################################################################
# Configure Git
##############################################################################
print_section "Configuring Git"

# Set Git user name and email using smart defaults
GIT_NAME="$TARGET_USER"
GIT_EMAIL="$TARGET_USER@$(hostname)"

echo "Setting Git configuration for user: $TARGET_USER"
echo "Name: $GIT_NAME"
echo "Email: $GIT_EMAIL"

sudo -u "$TARGET_USER" git config --global user.name "$GIT_NAME"
sudo -u "$TARGET_USER" git config --global user.email "$GIT_EMAIL"

echo "✔ Git configuration complete"

##############################################################################
# Verify SSH key setup
##############################################################################
print_section "Verifying SSH key configuration"

# Check if user has SSH authorized_keys
if [[ ! -f "$TARGET_HOME/.ssh/authorized_keys" ]]; then
    echo "❌ Error: No SSH authorized_keys found for user $TARGET_USER" >&2
    echo "SSH key has been generated, but you need to set up authorized_keys:" >&2
    echo "1. Copy your LOCAL public key to this server:" >&2
    echo "   ssh-copy-id $TARGET_USER@<server-ip>" >&2
    echo "2. OR manually add your public key to $TARGET_HOME/.ssh/authorized_keys" >&2
    echo "3. Test login: ssh $TARGET_USER@<server-ip>" >&2
    echo "4. Then run this script again to harden SSH security" >&2
    echo "" >&2
    echo "Generated server key is available at: $TARGET_HOME/.ssh/id_rsa.pub" >&2
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

echo -e "\n✔ SSH setup and security hardening complete!"
echo "Changes applied:"
echo "  - SSH key: Generated (RSA 4096) if not existing"
echo "  - Git config: Set with smart defaults ($TARGET_USER@$(hostname))"
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
echo "🔑 SSH Key Information:"
echo "  - Private key: $TARGET_HOME/.ssh/id_rsa"
echo "  - Public key: $TARGET_HOME/.ssh/id_rsa.pub"
echo ""
echo "🔧 Git Configuration:"
echo "  - Name: $TARGET_USER"
echo "  - Email: $TARGET_USER@$(hostname)"
echo ""
echo "💡 Test your SSH connection now:"
echo "   ssh $TARGET_USER@<server-ip>"
echo ""
echo "🔐 Your server is now more secure!"