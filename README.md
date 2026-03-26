# Nargin's Dotfiles
> Arch Linux setup | Mango WM

Zero to working setup in one script. If your machine dies or you switch to a new one, this repo gets you back up and running fast.

---

## What's In Here

| Folder / File | What It Does |
|---|---|
| `config/` | All your `~/.config` entries (kitty, sway, rofi, mango) |
| `local/` | Your `~/.local/bin` scripts |
| `pkglist-explicit.txt` | Official Arch packages |
| `pkglist-aur.txt` | AUR packages |
| `.bashrc` | Shell config |
| `.bash_profile` | Login shell config |
| `scripts/restore.sh` | The install script — runs everything |

---

## Fresh Machine? Start Here

### Step 1 — Install Arch Base

Boot the Arch ISO and run the guided installer:

```bash
archinstall
```

**Settings that matter:**
- Create your user account with sudo access
- **Do NOT pick a desktop environment** — your dotfiles handle that
- Enable NetworkManager when prompted
- Any filesystem is fine (ext4 works)

Reboot when it's done and log in as your user.

---

### Step 2 — Clone This Repo

```bash
git clone https://github.com/Spiderman103/dotfiles.git ~/dotfiles
```

---

### Step 3 — Run the Restore Script

```bash
bash ~/dotfiles/scripts/restore.sh
```

That's it. The script handles everything from here:

- Enables multilib (32-bit support)
- Full system update
- Installs `paru` (AUR helper)
- Installs all your packages (official + AUR)
- Symlinks all your configs
- Enables system services

---

### Step 4 — Reboot

```bash
sudo reboot
```

Log back in — your full setup should be there.

---

## If Something Fails Mid-Script

Run the script with logging so you can scroll through the full output:

```bash
bash ~/dotfiles/scripts/restore.sh 2>&1 | tee ~/restore.log
```

Then read it:

```bash
less ~/restore.log
```

The script is built to **warn and continue** on non-critical failures (like one bad package), so it won't stop over something small. Only actual system-level errors will stop it.

---

## Keeping Your Package Lists Updated

When you install something new and want it to be part of your restore, run these on your working machine:

```bash
# Save official packages
pacman -Qqen > ~/dotfiles/pkglist-explicit.txt

# Save AUR packages
pacman -Qqem > ~/dotfiles/pkglist-aur.txt

# Push to GitHub
git -C ~/dotfiles add pkglist-explicit.txt pkglist-aur.txt
git -C ~/dotfiles commit -m "update package lists"
git -C ~/dotfiles push
```

Do this any time you add something you want to keep.

---

## Updating Your Dotfiles

Made changes to a config file? Push them:

```bash
git -C ~/dotfiles add .
git -C ~/dotfiles commit -m "your message here"
git -C ~/dotfiles push
```

The restore script auto-pulls the latest version when it runs, so you're always restoring from the most current state.

---

## System Services Enabled by Script

| Service | What It's For |
|---|---|
| `NetworkManager` | Internet / WiFi |
| `bluetooth` | Bluetooth devices |
| `sddm` | Display / login manager |

To add more, edit the `SERVICES` array inside `scripts/restore.sh`.

---

## My Setup

- **OS:** Arch Linux
- **WM:** Mango
- **Terminal:** Kitty
- **Shell:** Bash
- **Launcher:** Rofi
