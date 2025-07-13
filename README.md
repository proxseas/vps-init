## Initial steps
apt update && apt install -y git
git clone https://github.com/proxseas/vps-init.git /opt/vps-setup
cd /opt/vps-setup/

# 1. Create user first (as root)
./00-create-user.sh <NEWUSERNAME>

# 2. Switch to new user and run setup
su - newuser
cd /opt/vps-init
./setup.sh  # This handles everything else

# now run the rest, e.g.
bash 10-base-system.sh
bash 20-shell-env.sh


# OVERVIEW
Scripts are numbered in execution order and include runtime privilege checks:

### Root/Sudo Required Scripts
```bash
sudo ./00-create-user.sh      # Create new user account
sudo ./10-base-system.sh      # Install system packages, configure firewall/SSH
sudo ./40-lang-tooling-py-node.sh  # Install Python, Node.js, and language tools
sudo ./50-container-tools.sh  # Install Docker and container tools
```

### User Scripts (No Sudo)
```bash
./20-shell-env.sh   # Configure zsh, oh-my-zsh, fzf, vim (as regular user)
./30-dev-tools.sh   # Install eza, just, setup aliases (as regular user)
```

## Runtime Checks

Each script includes automatic privilege validation:
- **Sudo scripts**: Will exit with error if not run with sudo
- **User scripts**: Will exit with error if run with sudo

## Complete Setup Flow

### Option A: Use Master Script (Recommended)
```bash
chmod +x setup.sh
./setup.sh
```
The master script runs all scripts in correct order with proper privileges.

### Option B: Manual Execution
1. `sudo ./00-create-user.sh` - Create user account
2. `sudo ./10-base-system.sh` - System setup + fix script permissions
3. `./20-shell-env.sh` - User shell environment
4. `./30-dev-tools.sh` - User development tools
5. `sudo ./40-lang-tooling-py-node.sh` - Language tooling
6. `sudo ./50-container-tools.sh` - Container tools