# Install basic utils
```bash
sudo apt update && sudo apt install curl git -y
```

# Make ssh key and add github
```bash
ssh-keygen
```

# Clone this repo
```bash
git clone git@github.com:ryantam626/bootstrap-workstation.git
```

# Install nix
```bash
curl -L https://nixos.org/nix/install | sh -s -- --daemon
```

# Install home manager
```bash
nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
nix-channel --update
nix-shell '<home-manager>' -A install
```

# Enable flake support
```bash
nixconf=~/.config/nix/nix.conf
mkdir -p $(dirname $nixconf)
echo "experimental-features = nix-command flakes" > $nixconf
```

# Set up user permissions and system configuration so KMonad can run as a regular user.
```bash
# Add current user to input group (read access to physical input devices)
sudo usermod -a -G input $USER

# Create 'uinput' group if it doesn't exist (write access to virtual input device)
sudo groupadd -f uinput
sudo usermod -a -G uinput $USER

# Set udev rule to give group write permissions to /dev/uinput
echo 'KERNEL=="uinput", MODE="0664", GROUP="uinput", OPTIONS+="static_node=uinput"' | sudo tee /etc/udev/rules.d/90-uinput.rules

# Load uinput kernel module at boot
echo 'uinput' | sudo tee /etc/modules-load.d/uinput.conf

# Load uinput module immediately
sudo modprobe uinput

# Apply udev rule changes
sudo udevadm control --reload-rules && sudo udevadm trigger
```

# Activate home manager

```bash
cd ~/bootstrap-workstation
home-manager switch --flake .
```

# Change default shell to zsh (home-manager is not capable to managing this)

```bash
command -v zsh | sudo tee -a /etc/shells
sudo chsh -s "$(command -v zsh)" "${USER}"
```

# Install my window manager

Requires task, so reboot first.

```bash
mkdir -p ~/workspace/personal
cd ~/workspace/personal
git clone git@github.com:ryantam626/sage-window-manager.git
cd sage-window-manager
task dev-setup
```
