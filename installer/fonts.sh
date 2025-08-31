#!/bin/bash

set -euxo pipefail

install_fonts() {
	echo "Installing fonts."
	echo "[fonts] Installing powerline fonts."
	mkdir -p ~/.fonts/
	git clone https://github.com/powerline/fonts.git --depth=1 /tmp/fonts
	pushd /tmp/fonts
	./install.sh
	popd
	rm -rf /tmp/fonts

	echo "[fonts] Installing nerd fonts."
	git clone https://github.com/ryanoasis/nerd-fonts.git --depth=1 /tmp/fonts
	pushd /tmp/fonts
	./install.sh
	popd
	rm -rf /tmp/fonts
	fc-cache -vf
}

install_fonts
