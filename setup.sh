#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Master VPS Setup Script
# =============================================================================
# Runs all setup scripts in the correct order with proper privileges
#
# Usage:
#   ./setup.sh                           # Run as regular user (after creating user)
#   sudo ./setup.sh                      # Run as root (handles everything)
#   NEW_USER=username ./setup.sh         # Specify user to create/configure
#   ./setup.sh --skip containers         # Skip specific steps
#   ./setup.sh -S node,verify            # Skip multiple steps (short form)
#   ./setup.sh --only user-env           # Run only specific steps
#   ./setup.sh -O system,dev-tools       # Run only specified groups
#
# Supported IDs for --skip/-S and --only/-O:
#   Fine-grained: node, python, binaries, containers, verify
#   Groups: system, user-env, dev-tools
# =============================================================================

# Start timing
SECONDS=0

# Parse command-line arguments
SKIP_LIST=()
ONLY_LIST=()

while [[ $# -gt 0 ]]; do
    case $1 in
        --skip|-S)
            if [[ -n "${2:-}" ]]; then
                IFS=',' read -ra SKIP_LIST <<< "$2"
                shift 2
            else
                echo "❌ Error: --skip requires a comma-separated list of IDs"
                exit 1
            fi
            ;;
        --only|-O)
            if [[ -n "${2:-}" ]]; then
                IFS=',' read -ra ONLY_LIST <<< "$2"
                shift 2
            else
                echo "❌ Error: --only requires a comma-separated list of IDs"
                exit 1
            fi
            ;;
        *)
            echo "❌ Error: Unknown argument: $1"
            echo "Usage: ./setup.sh [--skip|-S <ids>] [--only|-O <ids>]"
            exit 1
            ;;
    esac
done

# Check mutual exclusivity
if [[ ${#SKIP_LIST[@]} -gt 0 && ${#ONLY_LIST[@]} -gt 0 ]]; then
    echo "❌ Error: --skip and --only cannot be used together"
    exit 1
fi

echo "🚀 Starting VPS Setup Process"
echo "=============================="

# Check if we're in the right directory
if [[ ! -f "00-create-user.sh" ]]; then
    echo "❌ Error: Please run this script from the directory containing setup scripts"
    exit 1
fi

# Helper function: Check if a step should run based on --skip/--only flags
should_run() {
    local id="$1"

    # If ONLY_LIST is set, only run if ID is in the list
    if [[ ${#ONLY_LIST[@]} -gt 0 ]]; then
        for only_id in "${ONLY_LIST[@]}"; do
            # Trim whitespace
            only_id=$(echo "$only_id" | xargs)
            if [[ "$only_id" == "$id" ]]; then
                return 0
            fi
        done
        return 1
    fi

    # If SKIP_LIST is set, skip if ID is in the list
    if [[ ${#SKIP_LIST[@]} -gt 0 ]]; then
        for skip_id in "${SKIP_LIST[@]}"; do
            # Trim whitespace
            skip_id=$(echo "$skip_id" | xargs)
            if [[ "$skip_id" == "$id" ]]; then
                return 1
            fi
        done
    fi

    # Default: run the step
    return 0
}

# Helper function: Check if any of multiple IDs should run
should_run_any() {
    for id in "$@"; do
        if should_run "$id"; then
            return 0
        fi
    done
    return 1
}

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
if should_run "system"; then
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
else
    echo "⏭️  Skipping Phase 1: System Setup"
fi

if should_run "user-env"; then
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
else
    echo
    echo "⏭️  Skipping Phase 2: User Environment"
fi

echo
echo "Phase 3: Development Tools (requires root)"

# Pass target user info to scripts that need it
if [[ $EUID -eq 0 ]]; then
    if should_run_any "node" "dev-tools"; then
        echo "📦 Running 30-node-tooling.sh..."
        env TARGET_USER_FROM_SETUP="$TARGET_USER" "./30-node-tooling.sh" && echo "✅ 30-node-tooling.sh completed" || echo "❌ 30-node-tooling.sh failed"
    else
        echo "⏭️  Skipping 30-node-tooling.sh"
    fi

    if should_run_any "python" "dev-tools"; then
        echo "📦 Running 31-python-tooling.sh..."
        env TARGET_USER_FROM_SETUP="$TARGET_USER" "./31-python-tooling.sh" && echo "✅ 31-python-tooling.sh completed" || echo "❌ 31-python-tooling.sh failed"
    else
        echo "⏭️  Skipping 31-python-tooling.sh"
    fi

    if should_run_any "binaries" "dev-tools"; then
        echo "📦 Running 41-binary-tools.sh..."
        env TARGET_USER_FROM_SETUP="$TARGET_USER" "./41-binary-tools.sh" && echo "✅ 41-binary-tools.sh completed" || echo "❌ 41-binary-tools.sh failed"
    else
        echo "⏭️  Skipping 41-binary-tools.sh"
    fi

    if should_run_any "containers" "dev-tools"; then
        echo "📦 Running 50-container-tools.sh..."
        env TARGET_USER_FROM_SETUP="$TARGET_USER" "./50-container-tools.sh" && echo "✅ 50-container-tools.sh completed" || echo "❌ 50-container-tools.sh failed"
    else
        echo "⏭️  Skipping 50-container-tools.sh"
    fi
else
    if should_run_any "node" "dev-tools"; then
        run_script "30-node-tooling.sh" "true"
    else
        echo "⏭️  Skipping 30-node-tooling.sh"
    fi

    if should_run_any "python" "dev-tools"; then
        run_script "31-python-tooling.sh" "true"
    else
        echo "⏭️  Skipping 31-python-tooling.sh"
    fi

    if should_run_any "binaries" "dev-tools"; then
        run_script "41-binary-tools.sh" "true"
    else
        echo "⏭️  Skipping 41-binary-tools.sh"
    fi

    if should_run_any "containers" "dev-tools"; then
        run_script "50-container-tools.sh" "true"
    else
        echo "⏭️  Skipping 50-container-tools.sh"
    fi
fi

if should_run "verify"; then
    echo
    echo "Phase 4: Verification"
    if [[ $EUID -eq 0 ]]; then
        # Run verification but don't let it terminate setup.sh
        env DURING_SETUP="true" sudo -u "$TARGET_USER" "./99-verify-core.sh" || echo "⚠️  Verification completed with warnings"
    else
        # Run verification but don't let it terminate setup.sh
        env DURING_SETUP="true" ./99-verify-core.sh || echo "⚠️  Verification completed with warnings"
    fi
else
    echo
    echo "⏭️  Skipping Phase 4: Verification"
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
echo ""
echo "🚀 Extended Tools Available (Optional):"
echo "========================================"
echo "The following scripts install additional tools that are slower to install:"
echo "• sudo ./32-python-tools-extended.sh    # httpie, glances + pipx"
echo "• sudo ./42-rust-tools-extended.sh      # fd, git-delta, procs, tokei + rust toolchain"
echo ""
echo "🔐 Security Hardening Available:"
echo "• sudo ./15-configure-ssh-security.sh   # Disable password auth, harden SSH"
echo ""
echo "📋 To verify extended tools after installation:"
echo "• ./99-verify-extended.sh                # Verify optional tools"