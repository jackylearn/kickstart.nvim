#!/bin/bash
CURRENT_DIR=$(dirname $0)

# Modify if use different package manager
Pack="sudo apt install -y"

# Install Nvim dependencies
$Pack ninja-build gettext cmake unzip curl build-essential

NVIM=$(which nvim)
NVIM_BASE="/home/$(whoami)/Documents"
NVIM_DIR="$NVIM_BASE/neovim"
NVIM_VERSION="v0.12.2"

if [ -z "$NVIM" && ! -d $NVIM_DIR ]; then
	pushd $NVIM_BASE

	NVIM="https://github.com/neovim/neovim"
	git clone $NVIM $NVIM_DIR
	git checkout $NVIM_VERSION
	cd $NVIM_DIR
	make
	sudo make install

	popd
fi

# Install dependencies for some plugins
$Pack jq fzf bat ripgrep npm tmux golang cargo

# Install Python related
$Pack python3-venv python3-debugpy python3-pip

# Useful utility to calculate statistics about a codebase
TOKEI=$(which tokei)
if [ -z "$TOKEI" ]; then
	cargo install tokei # tokei is not found in apt repository
	echo 'export PATH="/home/$(whoami)/.cargo/bin":$PATH' >>"~/.bashrc"
	source "~/.bashrc"
fi

# Update the .tmux.conf
cp $CURRENT_DIR/tmux/.tmux.conf ~/
echo "~/.tmux.conf" is updated with the file in this repo.

# install the tpm if not installed yet
[ -d ~/.tmux ] || git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
cp $CURRENT_DIR/tmux/check_venv.sh ~/.tmux/
echo "Remember to install tpm plugin with <leader>I in tmux session"
