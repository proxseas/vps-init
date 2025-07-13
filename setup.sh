#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Master VPS Setup Script
# =============================================================================
# Runs all setup scripts in the correct order with proper privileges
# =============================================================================

echo "🚀 Starting VPS Setup Process"
echo "=============================="

# Check if we're in the right directory
if [[ ! -f "00-create-user.sh" ]]; then
    echo "❌ Error: Please run this script from the directory containing setup scripts"
    exit 1
fi

# Function to run script with privilege check
run_script() {
    local script="$1"
    local needs_sudo="$2"

    if [[ ! -f "$script" ]]; then
        echo "⚠️  Skipping $script (not found)"
        return 0
    fi

    echo
    echo "📦 Running $script..."

    if [[ "$needs_sudo" == "true" ]]; then
        sudo "./$script"
    else
        "./$script"
    fi

    echo "✅ $script completed"
}

# Run scripts in order
echo "Phase 1: System Setup (requires sudo)"
run_script "00-create-user.sh" "true"
run_script "10-base-system.sh" "true"

echo
echo "Phase 2: User Environment (no sudo)"
run_script "20-shell-env.sh" "false"
run_script "30-dev-tools.sh" "false"

echo
echo "Phase 3: Development Tools (requires sudo)"
run_script "40-lang-tooling-py-node.sh" "true"
run_script "50-container-tools.sh" "true"

echo
echo "🎉 VPS Setup Complete!"
echo "======================"
echo "To start using your new shell environment:"
echo "1. Switch to zsh: exec zsh"
echo "2. Or restart your terminal"
echo "3. New terminals will automatically use zsh"
echo "4. Your aliases and tools are ready to use!"