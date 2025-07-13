# VPS Setup Scripts

Automated scripts for setting up a new VPS with development tools and user environment.

# How best to READ *me* (this README.md file)
Use `batcat`

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

- **System Setup**: Firewall (ufw), SSH server, essential packages
- **Shell Environment**: zsh, oh-my-zsh, fzf, vim with plugins
- **Development Tools**: eza, just, useful aliases
- **Language Tooling**: Python (uv), Node.js (fnm)
- **Python CLI Tools**: pipx, glances
- **Rust CLI Tools**: ripgrep, bat, fd, git-delta, procs (installed via cargo)
- **Binary Tools**: zoxide, httpie, tokei, glow
- **Container Tools**: Docker, lazydocker

## Script Details

### Scripts Overview

**Root/Sudo Required:**
```bash
sudo ./00-create-user.sh      # Create new user account
sudo ./10-base-system.sh      # System packages, firewall, SSH
sudo ./30-node-tooling.sh     # Node.js (fnm) setup
sudo ./31-python-tooling.sh   # Python (uv) setup
sudo ./32-python-cli-tools.sh # Python CLI tools (pipx, glances)
sudo ./41-binary-tools.sh     # Binary tools (zoxide, httpie, tokei, glow)
sudo ./42-rust-tools.sh       # Rust CLI tools (ripgrep, bat, fd, git-delta, procs)
sudo ./50-container-tools.sh  # Docker and container tools
```

**User Scripts (No Sudo):**
```bash
./20-shell-env.sh        # Configure zsh and oh-my-zsh
./21-tmux-config.sh      # Configure tmux
./22-vim-config.sh       # Configure vim with plugins
./23-fzf-config.sh       # Configure fuzzy finder
./40-dev-tools.sh        # Install eza, just, setup aliases
./99-verify-installation.sh # Verify all tools are installed
```

### Runtime Checks

Each script includes automatic privilege validation:
- **Sudo scripts**: Exit with error if not run with sudo
- **User scripts**: Exit with error if run with sudo

## After Setup

```bash
# Switch to zsh to use your new environment
exec zsh

# Test your tools
uv --version
fnm --version
node --version
ll  # eza-powered directory listing
```

## Manual Execution (Advanced)

If you prefer to run scripts individually:

```bash
# 1. Create user (as root) - automatically switches to user
sudo ./00-create-user.sh myusername
# You're now user 'myusername' in /opt/vps-init

# 2. Configure user environment
./20-shell-env.sh
./30-dev-tools.sh

# 3. Switch back to root for system tools
exit  # back to root
cd /opt/vps-init
sudo ./10-base-system.sh
sudo ./40-lang-tooling-py-node.sh
sudo ./50-container-tools.sh
```

## Notes

- Scripts are numbered in execution order
- The master `setup.sh` handles privilege switching automatically
- Your shell environment is configured in `~/.zshrc` and `~/.zsh_aliases`
- Tools are installed to `~/.local/bin` and added to PATH

## Tool Installation Strategy

This setup uses the optimal installation method for each tool:

### **via apt (System Package Manager)**
- **System tools**: git, curl, wget, htop, tmux, vim, jq
- **Terminal utilities**: tldr, tig, tree, watch, entr
- **Reason**: System integration, dependency management, stability

### **via cargo (Rust Package Manager)**
- **Rust CLI tools**: ripgrep (rg), bat, fd, git-delta, procs
- **Reason**: Latest versions, better performance, proper Rust toolchain integration

### **via pipx (Python CLI Installer)**
- **Python tools**: glances, httpie
- **Reason**: Isolated Python environments, user-level installation

### **via snap/binary installation**
- **Standalone tools**: glow, zoxide, tokei
- **Reason**: Latest versions when not available in other repositories

### **via custom installers**
- **Language managers**: fnm (Node.js), uv (Python)
- **Reason**: Official installation methods, latest versions

This approach ensures you get the latest versions of development tools while maintaining system stability.