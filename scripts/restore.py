#!/usr/bin/env python3
import subprocess
import os
import sys
from pathlib import Path

# ==============================================================================
# Helper Functions
# ==============================================================================
def run(command, ignore_errors=False):
    """Runs a terminal command. If it fails and ignore_errors is False, it stops the script."""
    print(f"\n[Running] -> {command}")
    # We use shell=True so we can pass exact terminal commands
    result = subprocess.run(command, shell=True)
    
    if result.returncode != 0:
        if ignore_errors:
            print(f"[Warning] Command failed, but continuing anyway: {command}")
        else:
            print(f"[Fatal Error] Script stopped because this command failed: {command}")
            sys.exit(1)

def symlink_safe(source, target):
    """Creates a symlink safely, replacing it if it already exists."""
    if target.is_symlink() or target.exists():
        target.unlink() # Delete the existing file/link
    
    target.symlink_to(source)
    print(f"Linked: {target.name}")

# ==============================================================================
# Phase 1: Setup Paths
# ==============================================================================
print("\n=== Phase 1: Setting up paths ===")
# This finds the main dotfiles folder (one level up from where this script is)
script_dir = Path(__file__).resolve().parent
dotfiles_dir = script_dir.parent
home_dir = Path.home()

print(f"Dotfiles repository found at: {dotfiles_dir}")

# ==============================================================================
# Phase 2: System Prep & Multilib
# ==============================================================================
print("\n=== Phase 2: System Prep ===")
print("Enabling multilib repository...")
run('sudo sed -i "/\\[multilib\\]/,/Include/s/^#//" /etc/pacman.conf')

print("Updating system databases...")
run("sudo pacman -Syu --noconfirm")

print("Installing base build tools...")
run("sudo pacman -S --needed --noconfirm git base-devel")

# ==============================================================================
# Phase 3: AUR Helper (Paru)
# ==============================================================================
print("\n=== Phase 3: Installing Paru ===")
# Check if paru is already installed
if subprocess.run("command -v paru", shell=True, capture_output=True).returncode != 0:
    print("Building Paru...")
    run("rm -rf /tmp/paru")
    run("git clone https://aur.archlinux.org/paru.git /tmp/paru")
    run("cd /tmp/paru && makepkg -si --noconfirm")
else:
    print("Paru is already installed. Skipping!")

# ==============================================================================
# Phase 4: Installing Packages
# ==============================================================================
print("\n=== Phase 4: Installing Packages ===")
explicit_file = dotfiles_dir / "pkglist-explicit.txt"
aur_file = dotfiles_dir / "pkglist-aur.txt"

# We set ignore_errors=True here so one bad package doesn't crash the whole setup
if explicit_file.exists():
    print("Installing Official Packages...")
    run(f"sudo pacman -S --needed --noconfirm - < {explicit_file}", ignore_errors=True)

if aur_file.exists():
    print("Installing AUR Packages...")
    run(f"paru -S --needed --noconfirm - < {aur_file}", ignore_errors=True)

# ==============================================================================
# Phase 5: Restoring Configs (Symlinks)
# ==============================================================================
print("\n=== Phase 5: Symlinking Configs ===")
config_dir = home_dir / ".config"
local_bin_dir = home_dir / ".local" / "bin"

# Create directories if they don't exist
config_dir.mkdir(parents=True, exist_ok=True)
local_bin_dir.mkdir(parents=True, exist_ok=True)

# Link ~/.config folders
print("\nLinking .config directories...")
for item in (dotfiles_dir / "config").iterdir():
    target = config_dir / item.name
    symlink_safe(item, target)

# Link ~/.local/ folders
print("\nLinking .local files...")
for item in (dotfiles_dir / "local").iterdir():
    target = home_dir / ".local" / item.name
    symlink_safe(item, target)

# Make local bin scripts executable
run(f"chmod +x {local_bin_dir}/*", ignore_errors=True)

# Link bashrc
print("\nLinking shell config...")
symlink_safe(dotfiles_dir / ".bashrc", home_dir / ".bashrc")

print("\n=== Done! ===")
print("Setup complete. Remember to enable your systemd services (NetworkManager, bluetooth, etc.)")
