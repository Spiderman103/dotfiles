#!/bin/bash
# restore.sh
# Run this on a fresh Arch install to restore everything

echo "Installing paru (AUR helper)..."
sudo pacman -S --needed git base-devel
git clone https://aur.archlinux.org/paru.git /tmp/paru
cd /tmp/paru && makepkg -si
cd ~

echo "Installing packages..."
sudo pacman -S --needed - < ~/dotfiles/pkglist-explicit.txt

echo "Installing AUR packages..."
paru -S --needed - < ~/dotfiles/pkglist-aur.txt

echo "Restoring configs..."
mkdir -p ~/.config ~/.local/bin
cp -r ~/dotfiles/config/* ~/.config/
cp -r ~/dotfiles/local/bin/* ~/.local/bin/
chmod +x ~/.local/bin/*

echo "Restoring shell config..."
cp ~/dotfiles/.bashrc ~/
# cp ~/dotfiles/.zshrc ~/   # uncomment if using zsh

echo "Done. Log out and back in."
