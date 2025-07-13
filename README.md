## Initial steps
apt update && apt install -y git
git clone https://github.com/proxseas/vps-init.git /opt/vps-setup
cd /opt/vps-setup/scripts

# Option A: argument
./00-create-user.sh newusername

# Option B: env-var
NEW_USER=newusername ./00-create-user.sh

## Next - switch to new user & run the rest of the scripts
su - newusername
cd /opt/vps-setup/scripts

# now run the rest, e.g.
bash 10-base-system.sh
bash 20-shell-env.sh