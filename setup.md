# Install basic utils
sudo apt update && sudo apt install curl git -y

# Clone this repo

# Install nix
curl -L https://nixos.org/nix/install | sh -s -- --daemon

# Install home manager
nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
nix-channel --update
nix-shell '<home-manager>' -A install

# Enable flake support
nixconf=~/.config/nix/nix.conf
mkdir -p $(dirname $nixconf)
echo "experimental-features = nix-command flakes" > $nixconf


# =========== Do i need this??

# Add myself to input group so kmonad works
# Add yourself to input group
sudo usermod -a -G input $USER

# Create and add yourself to uinput group
sudo groupadd -f uinput
sudo usermod -a -G uinput $USER

# Set up udev rule for uinput
echo 'KERNEL=="uinput", MODE="0664", GROUP="uinput", OPTIONS+="static_node=uinput"' | sudo tee /etc/udev/rules.d/90-uinput.rules

# Load uinput module
echo 'uinput' | sudo tee /etc/modules-load.d/uinput.conf
sudo modprobe uinput

# Reload udev rules
sudo udevadm control --reload-rules && sudo udevadm trigger




# ==========

```bash
command -v zsh | sudo tee -a /etc/shells
sudo chsh -s "$(command -v zsh)" "${USER}"
```
