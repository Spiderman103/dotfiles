#!/bin/bash
# restore.sh
# Run this on a fresh Arch install to restore your setup

set -e  # stop on any error

# Dynamically get the parent directory of where this script is located
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> Updating system and installing base-devel..."
sudo pacman -Syu --noconfirm
sudo pacman -S --needed --noconfirm git base-devel

echo "==> Installing paru (AUR helper)..."
if ! command -v paru &> /dev/null; then
    rm -rf /tmp/paru  # Clean up in case of a previous failed run
    git clone https://aur.archlinux.org/paru.git /tmp/paru
    cd /tmp/paru && makepkg -si --noconfirm
    cd "$DOTFILES"
else
    echo "Paru is already installed, skipping..."
fi

echo "==> Installing explicit packages..."
# Using xargs is often safer for package lists to handle spaces/newlines correctly
xargs -a "$DOTFILES/pkglist-explicit.txt" sudo pacman -S --needed --noconfirm

echo "==> Installing AUR packages..."
xargs -a "$DOTFILES/pkglist-aur.txt" paru -S --needed --noconfirm

echo "==> Restoring configs via symlinks..."
mkdir -p ~/.config ~/.local/bin

# Symlink all folders inside config/ to ~/.config/
for dir in "$DOTFILES/config/"*; do
    [ -e "$dir" ] || continue # Skip if empty
    ln -sfn "$dir" ~/.config/$(basename "$dir")
done

# Symlink all files/folders inside local/ to ~/.local/
for item in "$DOTFILES/local/"*; do
    [ -e "$item" ] || continue
    ln -sfn "$item" ~/.local/$(basename "$item")
done

echo "==> Setting permissions on local bin..."
chmod +x "$DOTFILES/local/bin/"* || true # Run on the actual files in the repo

echo "==> Restoring shell config..."
ln -sf "$DOTFILES/.bashrc" ~/.bashrc
# ln -sf "$DOTFILES/.zshrc" ~/.zshrc  # uncomment if using zsh

echo "==> Enabling system services..."
# IMPORTANT: Add the services you rely on here! Examples below:
# sudo systemctl enable --now NetworkManager
# sudo systemctl enable --now bluetooth

echo "==> Done. Log out and back in to apply changes."
