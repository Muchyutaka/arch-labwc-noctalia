# arch-labwc-noctalia

A lean Wayland desktop for Arch Linux: **labwc** + **Noctalia v5**, Catppuccin `foot`, and a colour scheme that follows the wallpaper. No GNOME/KDE stack — about 400 MB RAM idle.

![Desktop](assets/screenshots/desktop.jpg)

| Wallpaper picker (`Super+w`) | Launcher (`Super+Space`) |
|---|---|
| ![Wallpaper picker](assets/screenshots/wallpaper.jpg) | ![Launcher](assets/screenshots/launcher.jpg) |

| Control centre (`Super+s`) | Add your own wallpaper (`Super+Alt+w`) |
|---|---|
| ![Control centre](assets/screenshots/control-center.jpg) | ![Add wallpaper](assets/screenshots/add-wallpaper.jpg) |

## Features

- **labwc** — 4 workspaces, 10 px gaps, thumbnail switcher, keyboard resize
- **Noctalia v5** — floating translucent bar, launcher, control centre, notifications; palette derived from the wallpaper
- **foot** — Catppuccin Mocha, JetBrains Mono Nerd Font, 0.96 alpha
- **hyfetch** on login with a clean Arch logo
- **Screenshots** — region / fullscreen / window, saved to `~/Pictures` and clipboard
- **Wallpapers** — picker, next/previous, and an "add your own" file chooser
- **Files** — Nautilus, MTP, archive manager
- **Flatpak** — installed; add Flathub with `flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo`
- **Optional apps** — Discord, Brave, LocalSend, Antumbra/Penumbra, Brokkr Flash, developer extras; each one is asked about at install time

## Requirements

- Arch Linux, x86_64
- Wayland-capable GPU (Intel/AMD; NVIDIA untested)
- ~2 GB free disk
- A user in the `wheel` group with `sudo`

## Install

```bash
git clone https://github.com/Muchyutaka/arch-labwc-noctalia.git
cd arch-labwc-noctalia
./install.sh
```

The installer adds the base packages, copies the dotfiles (backing up anything it replaces), asks about **each optional app** (default: no), downloads five free-use wallpapers, then asks **once** about enabling services.

| Flag | Effect |
|---|---|
| `--no-packages` | dotfiles + wallpapers only |
| `--no-system` | skip enabling services / display manager |
| `--no-wallpapers` | skip the wallpaper downloads |
| `--optional` | install every optional app without asking |
| `--no-optional` | skip all optional apps without asking |
| `--yes, -y` | assume yes for every prompt (including optional apps) |
| `--system -y` | non-interactive, everything |

After it finishes, log out and back in, then choose **labwc** at the `ly` prompt.

## Optional apps

The default install asks about each one; press **Enter** to skip. None are required for the desktop or the keybinds.

| App | Installed as |
|---|---|
| Discord | `discord` (official repo) |
| Brave | `brave-bin` (AUR) |
| LocalSend | `localsend-bin` (AUR) |
| Antumbra / Penumbra | GitHub release → `~/.local/bin/antumbra` + `penumbra` symlink |
| Brokkr Flash | GitHub AppImage → `~/Applications/Brokkr.AppImage` + `brokkr-flash` wrapper (`fuse2` is installed for it) |
| Developer extras | `android-tools`, `scrcpy`, `opencode` |

Non-interactive choices:

```bash
./install.sh --optional      # install all of the above
./install.sh --no-optional   # skip all of them
```

Install or update the two user-local tools later:

```bash
./scripts/install-antumbra.sh
./scripts/install-brokkr.sh
```

Antumbra and Brokkr talk to USB devices. If access is denied, add udev rules for your device; this repo does not install any.

## Keybinds

| Key | Action |
|---|---|
| `Super+Space` | Launcher |
| `Super+s` | Control centre |
| `Super+,` | Noctalia settings |
| `Super+w` | Wallpaper picker |
| `Super+Shift+w` | Next wallpaper |
| `Super+Alt+w` | Add your own wallpaper |
| `Super+z` / `Super+f` | Brave (if installed) / Nautilus |
| `Super+q` | Close window |
| `Super+Shift+f` | Fullscreen |
| `Super+Ctrl+Shift+f` | Maximize |
| `Super+1..4` | Switch workspace |
| `Super+Shift+1..4` | Move window to workspace |
| `Super+Page Up/Down` | Previous / next workspace |
| `Super+Ctrl+Arrow` | Resize window (add `Shift` to shrink) |
| `Print` / `Shift+Print` / `Ctrl+Print` | Region / fullscreen / window screenshot |
| Media + brightness keys | Volume and backlight |

Scroll-wheel workspace switching is deliberately disabled.

## Wallpapers

The picker browses `~/Pictures/Wallpapers`, so your own images sit next to the downloaded set in `free-use/`.

- `Super+w` — picker
- `Super+Shift+w` — next wallpaper (includes subfolders)
- `Super+Alt+w` — **Add Wallpaper**: file chooser copies the image into `~/Pictures/Wallpapers` and applies it
- Or just drop images into `~/Pictures/Wallpapers` and reopen the picker
- `noctalia msg wallpaper-set /path/to/image.jpg` — set an exact file

Noctalia derives the whole palette from the active wallpaper, so the bar and panels recolour immediately. The five Unsplash photos are downloaded at install time, never bundled — see [WALLPAPERS.md](WALLPAPERS.md).

## What the installer changes

Home directory (existing files are backed up as `*.bak.<timestamp>`):

```
~/.config/labwc/rc.xml
~/.config/labwc/autostart
~/.config/noctalia/settings.toml
~/.config/foot/foot.ini
~/.config/hyfetch.json
~/.config/hyfetch/arch_clean.txt
~/.local/bin/wallpaper-add
~/.local/share/applications/wallpaper-add.desktop
~/.bashrc                       (hyfetch + ~/.local/bin PATH blocks)
~/Pictures/Wallpapers/          (free-use/ holds the downloaded photos)
```

Optional apps, only when you select them:

```
~/.local/bin/antumbra + penumbra
~/Applications/Brokkr.AppImage
~/.local/bin/brokkr-flash
~/.local/share/applications/brokkr-flash.desktop
```

System, only if you accept the prompt:

```
systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable ly@tty1
```

That is all. The repo applies **no tuning** — no sysctl, udev, kernel parameters, zram, I/O scheduler, `/etc/fstab`, bootloader, or partition changes.

## Repo layout

```
install.sh                          installer
packages/                           base / intel / optional package lists
config/                             dotfiles copied into $HOME
scripts/wallpaper-add               "add your own wallpaper" file picker
scripts/fetch-wallpapers.sh         downloads the five free-use wallpapers
scripts/install-antumbra.sh         optional Antumbra (MTK) binary
scripts/install-brokkr.sh           optional Brokkr Flash AppImage
scripts/install-system.sh           enables services + display manager
assets/screenshots/                 README screenshots
WALLPAPERS.md                       wallpaper sources + licence
```

## Troubleshooting

**Bar is unstyled or the wrong colour**
```bash
noctalia msg config-reload
noctalia msg wallpaper-set ~/Pictures/Wallpapers/free-use/01-milky-way-peaks.jpg
```

**Wallpaper picker is empty** — the downloads may have failed:
```bash
./scripts/fetch-wallpapers.sh
```

**Antumbra or Brokkr download failed** — GitHub may be rate-limiting the API; re-run:
```bash
./scripts/install-antumbra.sh
./scripts/install-brokkr.sh
```

**No polkit password dialog when mounting a disk** — make sure `polkit-gnome` is installed and the agent starts from `~/.config/labwc/autostart`.

**hyfetch does not appear** — it only runs in a new interactive bash shell; open a new terminal.

**No sound**
```bash
systemctl --user enable --now pipewire pipewire-pulse wireplumber
```

## Credits

- [labwc](https://labwc.github.io/)
- [Noctalia](https://docs.noctalia.dev/)
- [Catppuccin](https://catppuccin.com/)
- Wallpapers from [Unsplash](https://unsplash.com/) (Unsplash License, downloaded at install time)

## License

MIT — see [LICENSE](LICENSE). No wallpaper image is included in this repository; the installer downloads them from Unsplash. Screenshots show the desktop with a user-supplied wallpaper.
