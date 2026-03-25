#!/bin/bash

# ==============================================================================
# ARCH LINUX DOTFILES RESTORE SCRIPT
# ==============================================================================
# This script is designed to be run on a fresh Arch Linux installation.
# It will update your system, install your packages, and link your configs.

# Stop the script completely if any critical command fails
set -e 

echo "======================================================="
echo " Phase 1: Setting up Directories"
echo "======================================================="

# Find out exactly where this script is saved on your computer.
# We look at the folder the script is in (scripts/), and go up one level (..)
# to find the main dotfiles repository folder.
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Found dotfiles repository at: $DOTFILES_DIR"

echo "======================================================="
echo " Phase 2: System Preparation & Multilib"
echo "======================================================="

# In your last error, 'lib32-mesa' failed because the 32-bit repo was disabled.
# This command safely enables the [multilib] repository in pacman.conf.
echo "Enabling multilib repository for 32-bit packages..."
sudo sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf

# Update the system with the new repository enabled
echo "Updating system databases..."
sudo pacman -Syu --noconfirm

# Install the essential tools needed to download and build packages
echo "Installing git and base-devel..."
sudo pacman -S --needed --noconfirm git base-devel

echo "======================================================="
echo " Phase 3: Installing the AUR Helper (Paru)"
echo "======================================================="

# Check if paru is already installed. If it isn't, download and build it.
if ! command -v paru &> /dev/null; then
    echo "Paru not found. Building paru from the AUR..."
    # Remove the temp folder if it exists from a previous failed run
    rm -rf /tmp/paru  
    git clone https://aur.archlinux.org/paru.git /tmp/paru
    cd /tmp/paru
    makepkg -si --noconfirm
    # Go back to the dotfiles directory when finished
    cd "$DOTFILES_DIR"
else
    echo "Paru is already installed. Moving on!"
fi

echo "======================================================="
echo " Phase 4: Installing Packages"
echo "======================================================="
# NOTE: We temporarily disable 'set -e' here. This means if ONE package in 
# your text file doesn't exist anymore, the script will skip it and keep 
# going, instead of crashing the entire script.
set +e

echo "Installing official Arch packages from pkglist-explicit.txt..."
# Read the text file and pass the list of names directly to pacman
sudo pacman -S --needed --noconfirm - < "$DOTFILES_DIR/pkglist-explicit.txt"

echo "Installing AUR packages from pkglist-aur.txt..."
# Read the text file and pass the list of names directly to paru
paru -S --needed --noconfirm - < "$DOTFILES_DIR/pkglist-aur.txt"

# Re-enable strict error checking for the rest of the script
set -e

echo "======================================================="
echo " Phase 5: Restoring Configuration Files"
echo "======================================================="

echo "Creating necessary local folders..."
mkdir -p ~/.config ~/.local/bin

echo "Symlinking folders into ~/.config/..."
# Look at every item inside your repo's 'config' folder
for item in "$DOTFILES_DIR/config/"*; do
    # Make sure the item actually exists (prevents errors if the folder is empty)
    if [ -e "$item" ]; then
        # Create a symbolic link from the repo to your actual ~/.config folder
        ln -sfn "$item" ~/.config/$(basename "$item")
        echo " -> Linked $(basename "$item")"
    fi
done

echo "Symlinking scripts into ~/.local/bin/..."
for item in "$DOTFILES_DIR/local/"*; do
    if [ -e "$item" ]; then
        ln -sfn "$item" ~/.local/$(basename "$item")
        echo " -> Linked $(basename "$item")"
    fi
done

echo "Making sure local scripts are executable..."
chmod +x "$DOTFILES_DIR/local/bin/"* || true

echo "Symlinking bash shell configuration..."
ln -sf "$DOTFILES_DIR/.bashrc" ~/.bashrc

echo "======================================================="
echo " Phase 6: Wrapping Up"
echo "======================================================="

echo "Install script has finished!"
echo "Please remember to manually enable your services, for example:"
echo "  sudo systemctl enable --now NetworkManager"
echo "  sudo systemctl enable --now bluetooth"
echo "  sudo systemctl enable --now sddm"
