#!/bin/bash

set -euxo pipefail

install_jetbrains_toolbox() {
	VERSION="2.8.1.52155"

	echo "Installing JetBrains Toolbox ${VERSION}."
	echo "[jetbrains-toolbox] Downloading."
	mkdir -p /tmp/jetbrains-toolbox
	wget https://download.jetbrains.com/toolbox/jetbrains-toolbox-${VERSION}.tar.gz -P /tmp/jetbrains-toolbox
	wget https://download.jetbrains.com/toolbox/jetbrains-toolbox-${VERSION}.tar.gz.sha256 -P /tmp/jetbrains-toolbox

	echo "[jetbrains-toolbox] Checksum."
	pushd /tmp/jetbrains-toolbox
	sha256sum -c jetbrains-toolbox-${VERSION}.tar.gz.sha256

	echo "[jetbrains-toolbox] Unzip."
	mkdir -p ~/.local/opt
	tar xzf jetbrains-toolbox-*.tar.gz -C ~/.local/opt
	popd
	rm -rf /tmp/jetbrains-toolbox

	echo "[jetbrains-toolbox] Symlink."
	mkdir -p ~/.local/bin
	ln -sf ~/.local/opt/jetbrains-toolbox-${VERSION}/bin/jetbrains-toolbox ~/.local/bin/jetbrains-toolbox
}

install_jetbrains_toolbox
