#!/bin/bash

# ==============================================================================
# ARCH LINUX DOTFILES RESTORE SCRIPT
# Nargin's Setup - UCF / HackUCF
# ==============================================================================
# Run this on a fresh Arch install to rebuild your entire environment.
# Usage: bash restore.sh
# ==============================================================================

set -euo pipefail  # e=exit on error, u=error on undefined vars, o=pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

ok()   { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
fail() { echo -e "${RED}[FAIL]${NC} $1"; exit 1; }

# ==============================================================================
# GUARD: Do NOT run as root
# ==============================================================================
if [ "$EUID" -eq 0 ]; then
    fail "Do not run this script as root. Run as your normal user with sudo access."
fi

# ==============================================================================
# Phase 1: Locate Dotfiles Directory
# ==============================================================================
echo ""
echo "======================================================="
echo " Phase 1: Locating Dotfiles Directory"
echo "======================================================="

# Script lives in dotfiles/scripts/ — go up one level to get dotfiles root
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ok "Dotfiles repo found at: $DOTFILES_DIR"

# Pull latest from git so configs are up to date
echo "Pulling latest dotfiles from GitHub..."
git -C "$DOTFILES_DIR" pull --ff-only || warn "Git pull failed — continuing with local files."

# ==============================================================================
# Phase 2: System Update + Multilib
# ==============================================================================
echo ""
echo "======================================================="
echo " Phase 2: System Prep + Multilib"
echo "======================================================="

echo "Enabling multilib for 32-bit packages (needed for Steam, Wine, etc.)..."
sudo sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
ok "Multilib enabled."

echo "Running full system update..."
sudo pacman -Syu --noconfirm
ok "System up to date."

echo "Installing git + base-devel (required to build AUR packages)..."
sudo pacman -S --needed --noconfirm git base-devel
ok "Base tools ready."

# ==============================================================================
# Phase 3: AUR Helper (Paru)
# ==============================================================================
echo ""
echo "======================================================="
echo " Phase 3: AUR Helper — Paru"
echo "======================================================="

if command -v paru &> /dev/null; then
    ok "Paru already installed. Skipping."
else
    echo "Installing paru from AUR..."
    rm -rf /tmp/paru-build
    git clone https://aur.archlinux.org/paru.git /tmp/paru-build
    # makepkg CANNOT be run from /tmp on some systems due to noexec — build in home
    cp -r /tmp/paru-build ~/paru-build
    cd ~/paru-build
    makepkg -si --noconfirm
    cd "$DOTFILES_DIR"
    rm -rf ~/paru-build
    ok "Paru installed."
fi

# ==============================================================================
# Phase 4: Package Installation
# ==============================================================================
echo ""
echo "======================================================="
echo " Phase 4: Installing Packages"
echo "======================================================="

# Disable exit-on-error here — a missing package shouldn't kill the whole script
set +e

EXPLICIT_LIST="$DOTFILES_DIR/pkglist-explicit.txt"

if [ -f "$EXPLICIT_LIST" ]; then
    echo "Installing official packages from pkglist-explicit.txt..."
    sudo pacman -S --needed --noconfirm - < "$EXPLICIT_LIST"
    ok "Official packages done."
else
    warn "pkglist-explicit.txt not found — skipping official packages."
fi

# Re-enable strict error checking
set -e

# ==============================================================================
# Phase 5: Symlink Configs
# ==============================================================================
echo ""
echo "======================================================="
echo " Phase 5: Symlinking Config Files"
echo "======================================================="

mkdir -p ~/.config ~/.local/bin

# Safe symlink function — replaces existing files/links without crashing
safe_link() {
    local src="$1"
    local dst="$2"
    # If it exists but is NOT a symlink (real file), back it up
    if [ -e "$dst" ] && [ ! -L "$dst" ]; then
        warn "Backing up existing file: $dst -> $dst.bak"
        mv "$dst" "$dst.bak"
    fi
    ln -sfn "$src" "$dst"
    ok "Linked: $(basename "$dst")"
}

# ~/.config/* symlinks
if [ -d "$DOTFILES_DIR/config" ]; then
    echo "Symlinking ~/.config entries..."
    for item in "$DOTFILES_DIR/config/"*; do
        [ -e "$item" ] && safe_link "$item" "$HOME/.config/$(basename "$item")"
    done
else
    warn "No config/ folder found in dotfiles — skipping."
fi

# ~/.local/* symlinks (bin, share, etc.)
if [ -d "$DOTFILES_DIR/local" ]; then
    echo "Symlinking ~/.local entries..."
    for item in "$DOTFILES_DIR/local/"*; do
        [ -e "$item" ] && safe_link "$item" "$HOME/.local/$(basename "$item")"
    done
else
    warn "No local/ folder found in dotfiles — skipping."
fi

# Make local/bin scripts executable
if [ -d "$HOME/.local/bin" ]; then
    chmod +x "$HOME/.local/bin/"* 2>/dev/null || true
    ok "Local bin scripts marked executable."
fi

# Shell config symlinks
[ -f "$DOTFILES_DIR/.bashrc" ] && safe_link "$DOTFILES_DIR/.bashrc" "$HOME/.bashrc"
[ -f "$DOTFILES_DIR/.zshrc"  ] && safe_link "$DOTFILES_DIR/.zshrc"  "$HOME/.zshrc"
[ -f "$DOTFILES_DIR/.bash_profile" ] && safe_link "$DOTFILES_DIR/.bash_profile" "$HOME/.bash_profile"

# ==============================================================================
# Phase 6: Enable System Services
# ==============================================================================
echo ""
echo "======================================================="
echo " Phase 6: Enabling System Services"
echo "======================================================="

# Add or remove services from this list based on what you actually use
SERVICES=(
    "NetworkManager"
    "bluetooth"
    "sddm"
)

for svc in "${SERVICES[@]}"; do
    if systemctl list-unit-files | grep -q "^${svc}.service"; then
        sudo systemctl enable --now "$svc" && ok "Enabled: $svc" || warn "Failed to enable: $svc"
    else
        warn "Service not found (maybe not installed yet): $svc"
    fi
done

# ==============================================================================
# Done
# ==============================================================================
echo ""
echo "======================================================="
echo " ALL DONE — Setup Complete"
echo "======================================================="
echo ""
echo "Next steps:"
echo "  1. Reboot your machine: sudo reboot"
echo "  2. Log back in and verify your WM/DE loaded correctly"
echo "  3. Check any services that warned above"
echo ""
ok "Restore complete. Welcome back."
