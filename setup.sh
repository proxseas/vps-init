#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Master VPS Setup Script
# =============================================================================
# Runs all setup scripts in the correct order with proper privileges
#
# Usage:
#   ./setup.sh                    # Run as regular user (after creating user)
#   sudo ./setup.sh               # Run as root (handles everything)
#   NEW_USER=username ./setup.sh  # Specify user to create/configure
# =============================================================================

# Start timing
SECONDS=0

echo "🚀 Starting VPS Setup Process"
echo "=============================="

# Check if we're in the right directory
if [[ ! -f "00-create-user.sh" ]]; then
    echo "❌ Error: Please run this script from the directory containing setup scripts"
    exit 1
fi

# Determine target user
if [[ -n "${NEW_USER:-}" ]]; then
    TARGET_USER="$NEW_USER"
elif [[ $EUID -eq 0 ]]; then
    # Running as root - need to know which user to configure
    echo "❌ Error: When running as root, specify target user:"
    echo "Usage: NEW_USER=username ./setup.sh"
    exit 1
else
    # Running as regular user - configure current user
    TARGET_USER="$USER"
fi

# Function to run script with privilege check
run_script() {
    local script="$1"
    local needs_sudo="$2"
    local run_as_user="${3:-}"

    if [[ ! -f "$script" ]]; then
        echo "⚠️  Skipping $script (not found)"
        return 0
    fi

    echo
    echo "📦 Running $script..."

    if [[ -n "$run_as_user" ]]; then
        # Run as specific user
        sudo -u "$run_as_user" "./$script"
    elif [[ "$needs_sudo" == "true" ]]; then
        if [[ $EUID -eq 0 ]]; then
            # Already root
            "./$script"
        else
            # Need sudo
            sudo "./$script"
        fi
    else
        # Run as current user
        "./$script"
    fi

    echo "✅ $script completed"
}

# Run scripts in order
echo "Phase 1: System Setup (requires root)"

# Only run user creation if we're root and user doesn't exist
if [[ $EUID -eq 0 ]]; then
    if ! getent passwd "$TARGET_USER" >/dev/null; then
        echo "Creating user: $TARGET_USER"
        echo "📦 Running 00-create-user.sh..."
        env CALLED_FROM_SETUP="true" NEW_USER="$TARGET_USER" "./00-create-user.sh" && echo "✅ 00-create-user.sh completed" || echo "❌ 00-create-user.sh failed"
    else
        echo "✅ User $TARGET_USER already exists, skipping creation"
    fi
else
    echo "⚠️  Skipping user creation (not running as root)"
fi

run_script "10-base-system.sh" "true"

echo
echo "Phase 2: User Environment (as user: $TARGET_USER)"
if [[ $EUID -eq 0 ]]; then
    # Running as root - switch to target user
    run_script "20-shell-env.sh" "false" "$TARGET_USER"
    run_script "21-tmux-config.sh" "false" "$TARGET_USER"
    run_script "22-vim-config.sh" "false" "$TARGET_USER"
    run_script "23-fzf-config.sh" "false" "$TARGET_USER"
    run_script "40-dev-tools.sh" "false" "$TARGET_USER"
else
    # Running as regular user
    run_script "20-shell-env.sh" "false"
    run_script "21-tmux-config.sh" "false"
    run_script "22-vim-config.sh" "false"
    run_script "23-fzf-config.sh" "false"
    run_script "40-dev-tools.sh" "false"
fi

echo
echo "Phase 3: Development Tools (requires root)"

# Pass target user info to scripts that need it
if [[ $EUID -eq 0 ]]; then
    echo "📦 Running 30-node-tooling.sh..."
    env TARGET_USER_FROM_SETUP="$TARGET_USER" "./30-node-tooling.sh" && echo "✅ 30-node-tooling.sh completed" || echo "❌ 30-node-tooling.sh failed"

    echo "📦 Running 31-python-tooling.sh..."
    env TARGET_USER_FROM_SETUP="$TARGET_USER" "./31-python-tooling.sh" && echo "✅ 31-python-tooling.sh completed" || echo "❌ 31-python-tooling.sh failed"

    echo "📦 Running 32-python-cli-tools.sh..."
    env TARGET_USER_FROM_SETUP="$TARGET_USER" "./32-python-cli-tools.sh" && echo "✅ 32-python-cli-tools.sh completed" || echo "❌ 32-python-cli-tools.sh failed"

    echo "📦 Running 41-binary-tools.sh..."
    env TARGET_USER_FROM_SETUP="$TARGET_USER" "./41-binary-tools.sh" && echo "✅ 41-binary-tools.sh completed" || echo "❌ 41-binary-tools.sh failed"

    echo "📦 Running 42-rust-tools.sh..."
    env TARGET_USER_FROM_SETUP="$TARGET_USER" "./42-rust-tools.sh" && echo "✅ 42-rust-tools.sh completed" || echo "❌ 42-rust-tools.sh failed"

    echo "📦 Running 50-container-tools.sh..."
    env TARGET_USER_FROM_SETUP="$TARGET_USER" "./50-container-tools.sh" && echo "✅ 50-container-tools.sh completed" || echo "❌ 50-container-tools.sh failed"
else
    run_script "30-node-tooling.sh" "true"
    run_script "31-python-tooling.sh" "true"
    run_script "32-python-cli-tools.sh" "true"
    run_script "41-binary-tools.sh" "true"
    run_script "42-rust-tools.sh" "true"
    run_script "50-container-tools.sh" "true"
fi

echo
echo "Phase 4: Verification"
if [[ $EUID -eq 0 ]]; then
    # Run verification but don't let it terminate setup.sh
    sudo -u "$TARGET_USER" "./99-verify-installation.sh" || echo "⚠️  Verification completed with warnings"
else
    # Run verification but don't let it terminate setup.sh
    ./99-verify-installation.sh || echo "⚠️  Verification completed with warnings"
fi

echo
echo "🎉 VPS Setup Complete!"
echo "======================"
echo "⏱️  Total setup time: ${SECONDS} seconds"
echo ""
if [[ $EUID -eq 0 ]]; then
    echo "✅ Setup completed for user: $TARGET_USER"
    echo ""
    echo "To start using your new shell environment as $TARGET_USER:"
    echo "1. Switch to user: su - $TARGET_USER"
    echo "2. Or SSH as: ssh $TARGET_USER@<your-server>"
else
    echo "✅ Setup completed for user: $USER"
    echo ""
    echo "To start using your new shell environment:"
    echo "1. Switch to zsh: exec zsh"
    echo "2. Or restart your terminal"
fi
echo "3. New terminals will automatically use zsh"
echo "4. Your aliases and tools are ready to use!"
echo ""
echo "💡 If verification showed warnings, most issues are resolved by:"
echo "   - Restarting your terminal: exec zsh"
echo "   - Re-running: source ~/.zshrc"