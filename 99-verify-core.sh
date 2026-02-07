#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# 99-verify-core.sh - Core installation verification (NO SUDO)
# =============================================================================
# This script verifies that all core tools and components are properly installed.
# USAGE: ./99-verify-core.sh [--verbose] (as regular user)
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

# Function to check if a command exists (with shell context)
check_command() {
    local cmd="$1"
    local description="$2"
    local is_function="${3:-false}"

    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    local result=false
    if [[ "$is_function" == "true" ]]; then
        # Check for shell function (needs shell context)
        if zsh -c "source ~/.zshrc 2>/dev/null && type $cmd" >/dev/null 2>&1; then
            result=true
        fi
    else
        # Check for command/binary with full environment context
        if zsh -c "source ~/.zshrc 2>/dev/null && command -v $cmd" >/dev/null 2>&1 || command -v "$cmd" >/dev/null 2>&1; then
            result=true
        fi
    fi

    if [[ "$result" == "true" ]]; then
        [[ "$VERBOSE" == "true" ]] && echo -e "${GREEN}✓${NC} $description"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        [[ "$VERBOSE" == "true" ]] && echo -e "${RED}✗${NC} $description"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        FAILED_ITEMS+=("$description")
    fi
}

# Function to check if a file exists
check_file() {
    local file="$1"
    local description="$2"

    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    if [[ -f "$file" ]]; then
        [[ "$VERBOSE" == "true" ]] && echo -e "${GREEN}✓${NC} $description"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        [[ "$VERBOSE" == "true" ]] && echo -e "${RED}✗${NC} $description"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        FAILED_ITEMS+=("$description")
    fi
}

# Function to check if a directory exists
check_directory() {
    local dir="$1"
    local description="$2"

    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    if [[ -d "$dir" ]]; then
        [[ "$VERBOSE" == "true" ]] && echo -e "${GREEN}✓${NC} $description"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        [[ "$VERBOSE" == "true" ]] && echo -e "${RED}✗${NC} $description"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        FAILED_ITEMS+=("$description")
    fi
}

# Function to check if a file contains specific content
check_file_content() {
    local file="$1"
    local pattern="$2"
    local description="$3"

    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    if [[ -f "$file" ]] && grep -q "$pattern" "$file" 2>/dev/null; then
        [[ "$VERBOSE" == "true" ]] && echo -e "${GREEN}✓${NC} $description"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        [[ "$VERBOSE" == "true" ]] && echo -e "${RED}✗${NC} $description"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        FAILED_ITEMS+=("$description")
    fi
}

# Function to check if a service is running
check_service() {
    local service="$1"
    local description="$2"

    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    if systemctl is-active --quiet "$service"; then
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

    # Use zsh instead of bash and ensure proper context loading
    if zsh -c "source ~/.zshrc 2>/dev/null && alias $alias_name" >/dev/null 2>&1; then
        [[ "$VERBOSE" == "true" ]] && echo -e "${GREEN}✓${NC} $description"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        [[ "$VERBOSE" == "true" ]] && echo -e "${RED}✗${NC} $description"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        FAILED_ITEMS+=("$description")
    fi
}

echo "🔍 VPS Core Setup Verification"
echo "=============================="
[[ "$VERBOSE" == "true" ]] && echo

# System Services
[[ "$VERBOSE" == "true" ]] && print_section "System Services"
check_service "ssh" "SSH server"
check_service "ufw" "UFW firewall"
check_service "docker" "Docker service"

# Core System Tools
[[ "$VERBOSE" == "true" ]] && print_section "Core System Tools"
check_command "git" "Git"
check_command "curl" "cURL"
check_command "wget" "Wget"
check_command "htop" "htop"
check_command "tmux" "tmux"
check_command "vim" "Vim"
check_command "jq" "jq"
check_command "tldr" "tldr"
check_command "tig" "tig"
check_command "tree" "tree"
check_command "watch" "watch"
check_command "entr" "entr"

# Core CLI Tools
[[ "$VERBOSE" == "true" ]] && print_section "Core CLI Tools"
check_command "rg" "ripgrep"
if command -v batcat >/dev/null 2>&1; then
    check_command "batcat" "bat (as batcat)"
elif command -v bat >/dev/null 2>&1; then
    check_command "bat" "bat"
else
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    [[ "$VERBOSE" == "true" ]] && echo -e "${RED}✗${NC} bat syntax highlighter"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
    FAILED_ITEMS+=("bat syntax highlighter")
fi

# Shell Environment
[[ "$VERBOSE" == "true" ]] && print_section "Shell Environment"
check_command "zsh" "Zsh shell"
check_directory "$HOME/.oh-my-zsh" "Oh My Zsh"
check_file "$HOME/.zshrc" "Zsh config"
check_file "$HOME/.zsh_aliases" "Zsh aliases"
check_directory "$HOME/.fzf" "FZF"
check_file "$HOME/.fzf.zsh" "FZF integration"
check_file_content "$HOME/.zshrc" "bindkey '\^P' fzf-file-widget" "FZF Ctrl+P keybinding"
check_file_content "$HOME/.zshrc" "_zi_widget" "Zoxide Ctrl+O widget"
check_file "$HOME/.tmux.conf" "Tmux config"
check_file "$HOME/.vimrc" "Vim config"
check_directory "$HOME/.vim/plugged" "Vim plugins"
check_file_content "$HOME/.vimrc" "inoremap jk <Esc>" "Vim quick escape mappings"

# Development Tools
[[ "$VERBOSE" == "true" ]] && print_section "Development Tools"
check_command "eza" "eza"
check_command "just" "just"

# Language Tooling
[[ "$VERBOSE" == "true" ]] && print_section "Language Tooling"
check_command "uv" "uv (Python)"
check_command "python3" "Python 3"
check_command "fnm" "fnm (Node)"
check_command "node" "Node.js"
check_command "npm" "npm"
check_command "docker" "Docker"
# Check lazydocker with more specific path checking
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
# Check in multiple ways: command -v, direct path, and with shell context
if command -v lazydocker >/dev/null 2>&1 || \
   [[ -f "/usr/local/bin/lazydocker" && -x "/usr/local/bin/lazydocker" ]] || \
   zsh -c "source ~/.zshrc 2>/dev/null && command -v lazydocker" >/dev/null 2>&1; then
    [[ "$VERBOSE" == "true" ]] && echo -e "${GREEN}✓${NC} lazydocker"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    [[ "$VERBOSE" == "true" ]] && echo -e "${RED}✗${NC} lazydocker"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
    FAILED_ITEMS+=("lazydocker")
fi

# Core Binary Tools
[[ "$VERBOSE" == "true" ]] && print_section "Core Binary Tools"
check_command "zoxide" "zoxide"
check_command "lazygit" "lazygit"

# SSH and Git Configuration
[[ "$VERBOSE" == "true" ]] && print_section "SSH and Git Configuration"
check_file "$HOME/.ssh/id_rsa" "SSH private key"
check_file "$HOME/.ssh/id_rsa.pub" "SSH public key"

# Check Git configuration
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
if git config --global user.name >/dev/null 2>&1 && git config --global user.email >/dev/null 2>&1; then
    [[ "$VERBOSE" == "true" ]] && echo -e "${GREEN}✓${NC} Git configuration (name & email)"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    [[ "$VERBOSE" == "true" ]] && echo -e "${RED}✗${NC} Git configuration (name & email)"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
    FAILED_ITEMS+=("Git configuration")
fi

# Aliases and Functions
[[ "$VERBOSE" == "true" ]] && print_section "Aliases and Functions"
check_alias "ll" "ll alias (eza)"
check_command "z" "z function (zoxide)" "true"
check_alias "lg" "lg alias (lazygit)"

# PATH
[[ "$VERBOSE" == "true" ]] && print_section "PATH"
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
# Check both current PATH and shell-loaded PATH
if echo "$PATH" | grep -q "$HOME/.local/bin" || zsh -c "source ~/.zshrc 2>/dev/null && echo \$PATH" 2>/dev/null | grep -q "$HOME/.local/bin"; then
    [[ "$VERBOSE" == "true" ]] && echo -e "${GREEN}✓${NC} ~/.local/bin in PATH"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    [[ "$VERBOSE" == "true" ]] && echo -e "${RED}✗${NC} ~/.local/bin not in PATH"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
    FAILED_ITEMS+=("~/.local/bin in PATH")
fi

# Summary
echo
echo "📊 Core Verification Summary"
echo "============================"
echo -e "Core tools: ${GREEN}$PASSED_CHECKS${NC}/$TOTAL_CHECKS passing"

if [[ $FAILED_CHECKS -eq 0 ]]; then
    echo -e "${GREEN}🎉 All core tools verified successfully!${NC}"
    echo
    echo "💡 Quick start:"
    echo "  - ll, z <directory>, rg <pattern>, bat <file>"
    echo "  - Git: lg (lazygit)"
    echo "  - Docker: lzd (lazydocker)"
    echo
    echo "🚀 Install extended tools:"
    echo "  - sudo ./32-python-tools-extended.sh"
    echo "  - sudo ./42-rust-tools-extended.sh"
else
    echo -e "${YELLOW}⚠️  $FAILED_CHECKS tools need attention:${NC}"
    for item in "${FAILED_ITEMS[@]}"; do
        echo "  • $item"
    done
    echo
    if [[ -n "${SUDO_USER:-}" ]] || [[ "${DURING_SETUP:-}" == "true" ]]; then
        if [[ $FAILED_CHECKS -ge 5 ]]; then
            echo "💡 Many tools not detected during initial setup - this is normal!"
            echo "💡 Environment isn't fully loaded. After user login, most tools should work."
        else
            echo "💡 During setup, some tools may not be detected due to environment context"
        fi
        echo "💡 To verify properly: log in as user and run './99-verify-core.sh'"
    else
        echo "💡 Most issues resolve with: exec zsh"
        echo "💡 For missing tools, re-run setup scripts"
    fi
fi

exit 0