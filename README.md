# arch-labwc-noctalia

A small, fast Wayland desktop for Arch Linux: **labwc** (stacking compositor) + **Noctalia v5** (bar, launcher, control centre), with a Catppuccin terminal and a clean Arch logo in hyfetch.

> No wallpaper is bundled. The installer downloads five free-use photos from Unsplash into your home folder, and any wallpaper you set recolours the whole UI automatically. See [WALLPAPERS.md](WALLPAPERS.md).

No GNOME, no KDE, no Plasma services — about 400 MB of RAM at idle on a 2-core Celeron.

## What you get

| | |
|---|---|
| **Compositor** | labwc, 4 workspaces, 10 px window gaps, thumbnail switcher |
| **Shell / bar** | Noctalia v5: floating translucent bar, two capsule clusters, wallpaper-derived palette |
| **Terminal** | foot, Catppuccin Mocha, JetBrains Mono Nerd Font, 0.96 alpha |
| **Login info** | hyfetch with a clean Arch logo in the default cyan; recolour anytime with `hyfetch -c` |
| **Wallpapers** | five free-use Unsplash photos, picker on `Super+w`, palette follows the image |
| **Screenshots** | region / fullscreen / window, saved to `~/Pictures` + clipboard |
| **Files** | Nautilus, MTP support, archive manager |
| **Apps** | Brave, Discord, LocalSend (via AUR), Flatpak with Flathub |

## Requirements

- Arch Linux, x86_64 (a fresh install is fine)
- A Wayland-capable GPU (Intel/AMD; NVIDIA is untested)
- ~2 GB free disk — `brave-bin` and `discord` are the big ones
- A user in the `wheel` group with `sudo`

## Install

```bash
git clone https://github.com/Muchyutaka/arch-labwc-noctalia.git
cd arch-labwc-noctalia
./install.sh
```

The script installs packages, copies the dotfiles (backing up anything it replaces), downloads five free-use wallpapers, then asks **once** whether to enable the login services.

```
./install.sh --no-system      # dotfiles + packages + wallpapers
./install.sh --no-packages    # dotfiles + wallpapers only
./install.sh --no-wallpapers  # skip the downloads
./install.sh --system -y      # non-interactive, everything
```

After it finishes, log out and back in, then pick **labwc** at the `ly` prompt.

## Keybinds

| Key | Action |
|---|---|
| `Super+Space` | Launcher |
| `Super+s` | Control centre |
| `Super+,` | Noctalia settings |
| `Super+w` | Wallpaper picker |
| `Super+Shift+w` | Next wallpaper |
| `Super+z` | Brave |
| `Super+f` | Files (Nautilus) |
| `Super+q` | Close window |
| `Super+Shift+f` | Fullscreen |
| `Super+1..4` | Switch workspace |
| `Super+Shift+1..4` | Move window to workspace |
| `Super+Page Up/Down` | Previous / next workspace |
| `Print` | Region screenshot |
| `Shift+Print` | Fullscreen screenshot |
| `Ctrl+Print` | Window screenshot |
| `Super+Shift+s` | Region screenshot (backup bind) |
| Media / brightness keys | Volume and backlight via Noctalia |

Scroll-wheel workspace switching is deliberately disabled.

## What the installer changes

**Your home directory** (backed up as `*.bak.<timestamp>` if different):

```
~/.config/labwc/rc.xml
~/.config/labwc/autostart
~/.config/noctalia/settings.toml
~/.config/foot/foot.ini
~/.config/hyfetch.json
~/.config/hyfetch/arch_clean.txt
~/.bashrc                       (one guarded block appended)
~/Pictures/Wallpapers/free-use/ (five downloaded photos + CREDITS.md)
```

**System, only if you accept the prompt:**

```
systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable ly@tty1
```

That is the whole system change. This repo applies **no tuning**: it does not touch sysctl, udev rules, kernel parameters, zram, I/O schedulers, storage settings, `/etc/fstab`, the bootloader, or any partition.

## Customising

- **Wallpaper** — press `Super+w` for the picker, `Super+Shift+w` for the next one, or click the wallpaper icon in the bar. `scripts/fetch-wallpapers.sh` puts five free-use Unsplash photos in `~/Pictures/Wallpapers/free-use/` (nothing is bundled; see [WALLPAPERS.md](WALLPAPERS.md)). For a specific file: `noctalia msg wallpaper-set /path/to/image.png`. Noctalia derives the whole palette from the active wallpaper (`source = "wallpaper"`, scheme `vibrant`), so the bar recolours itself. If you overwrite the image file in place, re-run `wallpaper-set` — Noctalia watches its state file, not the image on disk.
- **Bar opacity** — `background_opacity` and the capsule `opacity` values in `~/.config/noctalia/settings.toml` (`0.0` transparent → `1.0` solid).
- **Terminal colours** — `~/.config/foot/foot.ini`.
- **hyfetch** — `~/.config/hyfetch.json`; `preset` is any comma-separated hex list, `custom_ascii_path` any ASCII art file. The shipped default is a single cyan (`#94e2d5`), which is the Arch logo's normal colour. Run `hyfetch -c` for the interactive configurator (pick any preset, including `rainbow`) — the `.bashrc` wrapper re-applies the clean logo and trimmed `--structure` afterwards, so the wizard only changes colours.
- **Keybinds** — `~/.config/labwc/rc.xml`.

Note: Noctalia has no real background blur on labwc (the compositor does not implement a blur protocol), so transparency is flat, not frosted.

## Repo layout

```
install.sh                    main installer
packages/                     base / intel / aur / optional package lists
config/                       dotfiles copied into $HOME
scripts/install-system.sh     enables services + display manager
scripts/fetch-wallpapers.sh   downloads the five free-use wallpapers
WALLPAPERS.md                 sources + licence for those photos
```

## Troubleshooting

**Bar is unstyled or the wrong colour**
```bash
noctalia msg config-reload
noctalia msg wallpaper-set /path/to/image.png
```

**The wallpaper picker is empty** — the downloads may have been skipped or failed:
```bash
./scripts/fetch-wallpapers.sh
```
Then reopen the picker with `Super+w`.

**No polkit password dialog when mounting a disk** — make sure `polkit-gnome` is installed and `~/.config/labwc/autostart` starts the agent (it does by default here).

**hyfetch does not appear** — it only runs in a *new* interactive bash shell; `exec bash` or open a new terminal.

**No sound** — `systemctl --user enable --now pipewire pipewire-pulse wireplumber`.

## Credits

- [labwc](https://labwc.github.io/)
- [Noctalia](https://docs.noctalia.dev/)
- [Catppuccin](https://catppuccin.com/)
- Wallpapers from [Unsplash](https://unsplash.com/) (Unsplash License, downloaded at install time)

## License

MIT — see [LICENSE](LICENSE). No wallpaper or third-party image is included in this repository; the installer downloads them from Unsplash.
