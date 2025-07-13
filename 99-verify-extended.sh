#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# 99-verify-extended.sh - Extended tools verification (NO SUDO)
# =============================================================================
# This script verifies that extended tools are properly installed.
# Run this after running extended installation scripts.
# USAGE: ./99-verify-extended.sh (as regular user)
# =============================================================================

# Source utilities
source "$(dirname "$0")/utils.sh"

# Check if running with sudo (should NOT be)
check_not_root

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

# Function to check if a command exists and optionally run it
check_command() {
    local cmd="$1"
    local test_cmd="${2:-}"
    local description="$3"
    local comprehensive="${4:-false}"

    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    if command -v "$cmd" >/dev/null 2>&1; then
        if [[ "$comprehensive" == "true" && -n "$test_cmd" ]]; then
            # Run comprehensive test
            if eval "$test_cmd" >/dev/null 2>&1; then
                echo -e "${GREEN}✓${NC} $description"
                PASSED_CHECKS=$((PASSED_CHECKS + 1))
            else
                echo -e "${RED}✗${NC} $description (command exists but test failed)"
                FAILED_CHECKS=$((FAILED_CHECKS + 1))
            fi
        else
            # Simple existence check
            echo -e "${GREEN}✓${NC} $description"
            PASSED_CHECKS=$((PASSED_CHECKS + 1))
        fi
    else
        echo -e "${RED}✗${NC} $description (command not found)"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
    fi
}

echo "🔍 VPS Extended Tools Verification"
echo "=================================="
echo

##############################################################################
# Extended Rust CLI Tools
##############################################################################
print_section "Extended Rust CLI Tools"

check_command "rustc" "rustc --version" "Rust compiler"
check_command "cargo" "cargo --version" "Rust package manager"
check_command "fd" "fd --version" "fd file finder"
check_command "delta" "delta --version" "git-delta diff viewer"
check_command "procs" "procs --version" "procs process viewer"
check_command "tokei" "tokei --version" "tokei code statistics"

##############################################################################
# Extended Python CLI Tools
##############################################################################
print_section "Extended Python CLI Tools"

check_command "pipx" "pipx --version" "pipx Python CLI installer" true
check_command "glances" "glances --version" "glances system monitor" true
check_command "http" "http --version" "httpie HTTP client" true
check_command "glow" "glow --version" "glow markdown reader" true

##############################################################################
# Extended Aliases and PATH
##############################################################################
print_section "Extended Aliases and PATH"

# Check if extended aliases work
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
if alias fd >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} fd alias (fd find)"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    echo -e "${RED}✗${NC} fd alias not found"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi

TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
if alias http >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} http alias (httpie)"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    echo -e "${RED}✗${NC} http alias not found"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi

TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
if alias https >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} https alias (httpie)"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    echo -e "${RED}✗${NC} https alias not found"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi

# Check PATH components
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
if echo "$PATH" | grep -q "$HOME/.cargo/bin"; then
    echo -e "${GREEN}✓${NC} ~/.cargo/bin in PATH"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    echo -e "${YELLOW}⚠${NC} ~/.cargo/bin not in PATH (may need terminal restart)"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi

##############################################################################
# Summary
##############################################################################
echo
echo "📊 Extended Tools Verification Summary"
echo "======================================"
echo -e "Total checks: $TOTAL_CHECKS"
echo -e "${GREEN}Passed: $PASSED_CHECKS${NC}"
echo -e "${RED}Failed: $FAILED_CHECKS${NC}"
echo

if [[ $FAILED_CHECKS -eq 0 ]]; then
    echo -e "${GREEN}🎉 All extended tools checks passed!${NC}"
    echo
    echo "💡 Extended tools available:"
    echo "  - Rust tools: fd, delta, procs, tokei"
    echo "  - Python tools: pipx, glances, httpie"
    echo "  - Markdown: glow"
    echo "  - Try: fd <pattern>, procs, tokei, glances"
    echo "  - HTTP: http GET api.github.com"
    echo "  - Read: glow README.md"
    echo "  - Git diff now uses delta automatically"
    exit 0
else
    echo -e "${YELLOW}⚠️  Some extended tools checks failed.${NC}"
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
    echo "💡 Most issues are resolved by restarting your terminal."
    exit 0
fi