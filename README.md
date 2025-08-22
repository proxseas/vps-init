# VPS Setup Scripts

Automated scripts for setting up a new VPS with development tools and user environment.

# How best to READ *me* (this README.md file)
Use `bat` (after core setup) or `glow`

## Prerequisites (As Root)

Before running any setup scripts, clone this repository:

```bash
apt update && apt install -y git
git clone https://github.com/proxseas/vps-init.git /opt/vps-init
cd /opt/vps-init
```

## Setup Options

### Option A: Fully Automated (Recommended)

Run everything as root with automatic user switching:

```bash
# As root - creates user and runs complete setup
NEW_USER=myusername ./setup.sh
```

### Option B: Step-by-Step Control

For more control over the process:

```bash
# 1. Create user account (as root)
# This automatically switches to the new user and navigates to /opt/vps-init
./00-create-user.sh myusername

# 2. You're now the new user in /opt/vps-init - run setup
./setup.sh
```

## What Gets Installed

### Core Setup (Fast - Essential Tools)
- **System Setup**: Firewall (ufw), SSH server, essential packages
- **Shell Environment**: zsh, oh-my-zsh, fzf, vim with plugins
- **Development Tools**: eza, just, ripgrep, bat (via apt)
- **Language Tooling**: Python (uv), Node.js (fnm)
- **Core Binary Tools**: zoxide, glow
- **Container Tools**: Docker, lazydocker

### Extended Setup (Slower - Optional Tools)
- **Rust CLI Tools**: fd, git-delta, procs, tokei + rust toolchain
- **Python CLI Tools**: pipx, glances, httpie

## Core vs Extended Philosophy

The setup is split into **core** (fast, essential) and **extended** (slower, optional) installations:

- **Core setup** installs tools you'll use daily and are quick to install
- **Extended setup** installs additional tools that take longer (Rust compilation, etc.)
- This allows you to get a working system quickly, then add extended tools later

## Script Details

### Core Scripts (Run automatically by setup.sh)

**Root/Sudo Required:**
```bash
sudo ./00-create-user.sh      # Create new user account
sudo ./10-base-system.sh      # System packages, firewall, SSH
sudo ./30-node-tooling.sh     # Node.js (fnm) setup
sudo ./31-python-tooling.sh   # Python (uv) setup
sudo ./41-binary-tools.sh     # Core binary tools (zoxide, glow)
sudo ./50-container-tools.sh  # Docker and container tools
```

**User Scripts (No Sudo):**
```bash
./20-shell-env.sh        # Configure zsh and oh-my-zsh
./21-tmux-config.sh      # Configure tmux
./22-vim-config.sh       # Configure vim with plugins
./23-fzf-config.sh       # Configure fuzzy finder
./40-dev-tools.sh        # Install eza, just, ripgrep, bat, setup aliases
./99-verify-core.sh      # Verify core tools are installed
```

### Extended Scripts (Run manually - Optional)

**Extended Tools (Optional):**
```bash
sudo ./32-python-tools-extended.sh  # pipx, glances, httpie
sudo ./42-rust-tools-extended.sh    # fd, git-delta, procs, tokei + rust toolchain
./99-verify-extended.sh              # Verify extended tools are installed
```

**Security Hardening (Optional):**
```bash
sudo ./15-configure-ssh-security.sh  # Generate SSH keys, configure Git, harden SSH
```

### Runtime Checks

Each script includes automatic privilege validation:
- **Sudo scripts**: Exit with error if not run with sudo
- **User scripts**: Exit with error if run with sudo

## After Core Setup

```bash
# Switch to zsh to use your new environment
exec zsh

# Test your core tools
uv --version
fnm --version
node --version
ll  # eza-powered directory listing
z   # smart cd with zoxide
rg  # ripgrep search
bat # syntax-highlighted cat
```

## Extended Tools Installation

After core setup, you can optionally install extended tools:

```bash
# Install extended Rust CLI tools (slower - compiles from source)
sudo ./42-rust-tools-extended.sh

# Install extended Python CLI tools
sudo ./32-python-tools-extended.sh

# Verify extended tools
./99-verify-extended.sh

# Generate SSH keys, configure Git, and harden SSH security
sudo ./15-configure-ssh-security.sh
```

## Tool Installation Strategy

This setup uses the optimal installation method for each tool:

### **Core Tools (via apt - Fast)**
- **System tools**: git, curl, wget, htop, tmux, vim, jq
- **Terminal utilities**: tldr, tig, tree, watch, entr
- **CLI tools**: ripgrep, bat (older versions but fast to install)
- **Reason**: System integration, dependency management, quick installation

### **Extended Tools (via cargo - Slower)**
- **Rust CLI tools**: fd, git-delta, procs, tokei + rust toolchain
- **Reason**: Latest versions, better performance, proper Rust toolchain integration

### **Extended Tools (via pipx - Slower)**
- **Python tools**: glances, httpie + pipx
- **Reason**: Isolated Python environments, user-level installation

### **Core Tools (via binary/custom)**
- **Binary tools**: zoxide, glow
- **Language managers**: fnm (Node.js), uv (Python)
- **Reason**: Official installation methods, latest versions

## Verification

- **Core verification**: `./99-verify-core.sh` - Checks essential tools
- **Extended verification**: `./99-verify-extended.sh` - Checks optional tools

## Manual Execution (Advanced)

If you prefer to run scripts individually:

```bash
# 1. Create user (as root) - automatically switches to user
sudo ./00-create-user.sh myusername
# You're now user 'myusername' in /opt/vps-init

# 2. Configure core user environment
./20-shell-env.sh
./40-dev-tools.sh

# 3. Switch back to root for system tools
exit  # back to root
cd /opt/vps-init
sudo ./10-base-system.sh
sudo ./31-python-tooling.sh
sudo ./41-binary-tools.sh
sudo ./50-container-tools.sh

# 4. Optional: Install extended tools
sudo ./32-python-tools-extended.sh
sudo ./42-rust-tools-extended.sh
```

## Notes

- Scripts are numbered in execution order
- The master `setup.sh` handles privilege switching automatically
- Your shell environment is configured in `~/.zshrc` and `~/.zsh_aliases`
- Tools are installed to `~/.local/bin` and added to PATH
- Extended tools install to `~/.cargo/bin` and are added to PATH

This approach ensures you get a working development environment quickly, with the option to add more powerful tools later.