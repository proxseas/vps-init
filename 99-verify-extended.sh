#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# 99-verify-extended.sh - Extended tools verification (NO SUDO)
# =============================================================================
# This script verifies that extended tools are properly installed.
# Run this after running extended installation scripts.
# USAGE: ./99-verify-extended.sh [--verbose] (as regular user)
# =============================================================================

# Source utilities
source "$(dirname "$0")/utils.sh"

# Check if running with sudo (should NOT be)
check_not_root

# Parse arguments
VERBOSE=false
if [[ "${1:-}" == "--verbose" ]]; then
    VERBOSE=true
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
FAILED_ITEMS=()

# Function to check if a command exists
check_command() {
    local cmd="$1"
    local description="$2"

    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    if command -v "$cmd" >/dev/null 2>&1; then
        [[ "$VERBOSE" == "true" ]] && echo -e "${GREEN}✓${NC} $description"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        [[ "$VERBOSE" == "true" ]] && echo -e "${RED}✗${NC} $description"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        FAILED_ITEMS+=("$description")
    fi
}

# Function to check alias (with shell context)
check_alias() {
    local alias_name="$1"
    local description="$2"

    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    # Source shell config and check alias
    if bash -c "source ~/.zshrc 2>/dev/null; alias $alias_name" >/dev/null 2>&1; then
        [[ "$VERBOSE" == "true" ]] && echo -e "${GREEN}✓${NC} $description"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        [[ "$VERBOSE" == "true" ]] && echo -e "${RED}✗${NC} $description"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        FAILED_ITEMS+=("$description")
    fi
}

echo "🔍 VPS Extended Tools Verification"
echo "=================================="
[[ "$VERBOSE" == "true" ]] && echo

# Extended Rust CLI Tools
[[ "$VERBOSE" == "true" ]] && print_section "Extended Rust CLI Tools"
check_command "rustc" "Rust compiler"
check_command "cargo" "Rust package manager"
check_command "fd" "fd file finder"
check_command "delta" "git-delta diff viewer"
check_command "procs" "procs process viewer"
check_command "tokei" "tokei code statistics"

# Extended Python CLI Tools
[[ "$VERBOSE" == "true" ]] && print_section "Extended Python CLI Tools"
check_command "pipx" "pipx Python CLI installer"
check_command "glances" "glances system monitor"
check_command "http" "httpie HTTP client"
check_command "glow" "glow markdown reader"

# Extended Aliases
[[ "$VERBOSE" == "true" ]] && print_section "Extended Aliases"
check_alias "fd" "fd alias"
check_alias "http" "http alias"
check_alias "https" "https alias"
check_alias "y" "y (yazi) alias"

# PATH for extended tools
[[ "$VERBOSE" == "true" ]] && print_section "Extended PATH"
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
if echo "$PATH" | grep -q "$HOME/.cargo/bin"; then
    [[ "$VERBOSE" == "true" ]] && echo -e "${GREEN}✓${NC} ~/.cargo/bin in PATH"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    [[ "$VERBOSE" == "true" ]] && echo -e "${YELLOW}⚠${NC} ~/.cargo/bin not in PATH (may need terminal restart)"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
    FAILED_ITEMS+=("~/.cargo/bin in PATH")
fi

# Summary
echo
echo "📊 Extended Tools Verification Summary"
echo "======================================"
echo -e "Extended tools: ${GREEN}$PASSED_CHECKS${NC}/$TOTAL_CHECKS passing"

if [[ $FAILED_CHECKS -eq 0 ]]; then
    echo -e "${GREEN}🎉 All extended tools verified successfully!${NC}"
    echo
    echo "💡 Extended tools available:"
    echo "  - Rust: fd, delta, procs, tokei"
    echo "  - Python: pipx, glances, httpie"
    echo "  - Markdown: glow"
    echo "  - Try: fd <pattern>, procs, tokei, glances, glow README.md"
    echo "  - HTTP: http GET api.github.com"
    echo "  - Git diff now uses delta automatically"
else
    echo -e "${YELLOW}⚠️  $FAILED_CHECKS extended tools need attention:${NC}"
    for item in "${FAILED_ITEMS[@]}"; do
        echo "  • $item"
    done
    echo
    echo "This may indicate:"
    echo "  - Extended scripts haven't been run yet"
    echo "  - Tools need PATH refresh (restart terminal)"
    echo "  - Installation issues with extended tools"
    echo
    echo "💡 To install extended tools:"
    echo "  - sudo ./32-python-tools-extended.sh"
    echo "  - sudo ./42-rust-tools-extended.sh"
    echo
    echo "💡 Most issues resolve with: exec zsh"
fi

exit 0