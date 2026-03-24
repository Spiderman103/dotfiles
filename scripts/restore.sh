#!/bin/bash
# restore.sh
# Run this on a fresh Arch install to restore your setup

set -e  # stop on any error

DOTFILES=~/spDotfiles

echo "==> Installing paru (AUR helper)..."
sudo pacman -S --needed git base-devel
git clone https://aur.archlinux.org/paru.git /tmp/paru
cd /tmp/paru && makepkg -si
cd ~

echo "==> Installing explicit packages..."
sudo pacman -S --needed - < "$DOTFILES/pkglist-explicit.txt"

echo "==> Installing AUR packages..."
paru -S --needed - < "$DOTFILES/pkglist-aur.txt"

echo "==> Restoring configs..."
mkdir -p ~/.config ~/.local/bin
cp -r "$DOTFILES/config/"* ~/.config/
cp -r "$DOTFILES/local/"* ~/.local/

echo "==> Setting permissions on local bin..."
chmod +x ~/.local/bin/*

echo "==> Restoring shell config..."
cp "$DOTFILES/.bashrc" ~/
# cp "$DOTFILES/.zshrc" ~/  # uncomment if using zsh

echo "==> Done. Log out and back in to apply changes."
