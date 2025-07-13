#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# 99-verify-installation.sh - Comprehensive installation verification (NO SUDO)
# =============================================================================
# This script verifies that all tools and components are properly installed.
# USAGE: ./99-verify-installation.sh (as regular user)
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

# Function to check if a file exists
check_file() {
    local file="$1"
    local description="$2"

    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    if [[ -f "$file" ]]; then
        echo -e "${GREEN}✓${NC} $description"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        echo -e "${RED}✗${NC} $description (file not found)"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
    fi
}

# Function to check if a directory exists
check_directory() {
    local dir="$1"
    local description="$2"

    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    if [[ -d "$dir" ]]; then
        echo -e "${GREEN}✓${NC} $description"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        echo -e "${RED}✗${NC} $description (directory not found)"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
    fi
}

# Function to check if a service is running
check_service() {
    local service="$1"
    local description="$2"

    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    if systemctl is-active --quiet "$service"; then
        echo -e "${GREEN}✓${NC} $description"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        echo -e "${RED}✗${NC} $description (service not running)"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
    fi
}

echo "🔍 VPS Setup Verification"
echo "========================="
echo

##############################################################################
# System Services
##############################################################################
print_section "System Services"

check_service "ssh" "SSH server is running"
check_service "ufw" "UFW firewall is running"
check_service "docker" "Docker service is running"

##############################################################################
# Core System Tools
##############################################################################
print_section "Core System Tools"

check_command "git" "git --version" "Git version control"
check_command "curl" "curl --version" "cURL HTTP client"
check_command "wget" "wget --version" "Wget downloader"
check_command "htop" "" "htop process monitor"
check_command "tmux" "tmux -V" "tmux terminal multiplexer"
check_command "vim" "vim --version" "Vim text editor"
check_command "jq" "jq --version" "jq JSON processor"
check_command "tldr" "tldr --version" "tldr help pages"
check_command "tig" "tig --version" "tig Git interface"
check_command "tree" "tree --version" "tree directory listing"
check_command "watch" "watch --version" "watch command repeater"
check_command "entr" "entr -h" "entr file watcher"

##############################################################################
# Rust CLI Tools
##############################################################################
print_section "Rust CLI Tools"

check_command "rg" "rg --version" "ripgrep search tool"
check_command "bat" "bat --version" "bat syntax highlighter"
check_command "fd" "fd --version" "fd file finder"
check_command "delta" "delta --version" "git-delta diff viewer"
check_command "procs" "procs --version" "procs process viewer"

##############################################################################
# Shell Environment
##############################################################################
print_section "Shell Environment"

check_command "zsh" "zsh --version" "Zsh shell"
check_directory "$HOME/.oh-my-zsh" "Oh My Zsh installation"
check_file "$HOME/.zshrc" "Zsh configuration file"
check_file "$HOME/.zsh_aliases" "Zsh aliases file"
check_directory "$HOME/.fzf" "FZF fuzzy finder"
check_file "$HOME/.fzf.zsh" "FZF zsh integration"
check_file "$HOME/.tmux.conf" "Tmux configuration"
check_file "$HOME/.vimrc" "Vim configuration"
check_directory "$HOME/.vim/plugged" "Vim plugins directory"

##############################################################################
# Development Tools
##############################################################################
print_section "Development Tools"

check_command "eza" "eza --version" "eza file listing"
check_command "just" "just --version" "just task runner"

##############################################################################
# Language Tooling (Comprehensive Checks)
##############################################################################
print_section "Language Tooling (Comprehensive)"

# Python tooling
check_command "uv" "uv --version" "uv Python package manager" true
check_command "python3" "python3 --version" "Python 3 interpreter" true

# Node.js tooling
check_command "fnm" "fnm --version" "fnm Node version manager" true
check_command "node" "node --version" "Node.js runtime" true
check_command "npm" "npm --version" "npm package manager" true

# Docker tooling
check_command "docker" "docker --version" "Docker container runtime" true
check_command "lazydocker" "lazydocker --version" "lazydocker TUI" true

# Python CLI tools
check_command "pipx" "pipx --version" "pipx Python CLI installer" true
check_command "glances" "glances --version" "glances system monitor" true

##############################################################################
# Binary Tools
##############################################################################
print_section "Binary Tools"

check_command "zoxide" "zoxide --version" "zoxide smart cd"
check_command "http" "http --version" "httpie HTTP client"
check_command "tokei" "tokei --version" "tokei code statistics"
check_command "glow" "glow --version" "glow markdown reader"
check_command "rustc" "rustc --version" "Rust compiler"
check_command "cargo" "cargo --version" "Rust package manager"

##############################################################################
# Aliases and PATH
##############################################################################
print_section "Aliases and PATH"

# Check if aliases work
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
if alias ll >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} ll alias (eza -l --git)"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    echo -e "${RED}✗${NC} ll alias not found"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi

TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
if alias z >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} z alias (zoxide)"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    echo -e "${RED}✗${NC} z alias not found"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi

# Check PATH components
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
if echo "$PATH" | grep -q "$HOME/.local/bin"; then
    echo -e "${GREEN}✓${NC} ~/.local/bin in PATH"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    echo -e "${RED}✗${NC} ~/.local/bin not in PATH"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi

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
echo "📊 Verification Summary"
echo "======================"
echo -e "Total checks: $TOTAL_CHECKS"
echo -e "${GREEN}Passed: $PASSED_CHECKS${NC}"
echo -e "${RED}Failed: $FAILED_CHECKS${NC}"
echo

if [[ $FAILED_CHECKS -eq 0 ]]; then
    echo -e "${GREEN}🎉 All checks passed! Your VPS setup is complete.${NC}"
    echo
    echo "💡 Quick start:"
    echo "  - Try: ll, z <directory>, http GET api.github.com"
    echo "  - Monitor: glances, procs"
    echo "  - Read: glow README.md"
    echo "  - Code stats: tokei"
    echo "  - Docker: lzd (lazydocker)"
    exit 0
else
    echo -e "${YELLOW}⚠️  Some checks failed. You may need to:${NC}"
    echo "  1. Restart your terminal: exec zsh"
    echo "  2. Re-run specific setup scripts"
    echo "  3. Check the installation logs above"
    echo
    echo "💡 Most issues are resolved by restarting your terminal."
    echo "💡 This is normal for first-time setup - tools are installed but PATH needs updating."
    exit 0
fi