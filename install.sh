#!/usr/bin/env bash
#
# arch-labwc-noctalia installer
#
# Reproduces this desktop on a fresh Arch Linux install:
#   labwc + Noctalia v5, Catppuccin-flavoured foot, hyfetch on login,
#   screenshot keybinds, and a handful of enabled services.
#
# Safety:
#   * nothing is deleted; existing files are backed up as <file>.bak.<stamp>
#   * system-level changes are opt-in and only touch files listed in README
#   * no bootloader, partition table, or fstab changes
#
set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"

WITH_PACKAGES=1
WITH_SYSTEM="ask"
WITH_WALLPAPERS=1
WITH_OPTIONAL="ask"
ASSUME_YES=0

# ── pretty output ────────────────────────────────────────────────────────────
if [[ -t 1 ]]; then
  C_RESET=$'\033[0m'; C_BLUE=$'\033[34m'; C_GREEN=$'\033[32m'
  C_YELLOW=$'\033[33m'; C_RED=$'\033[31m'; C_BOLD=$'\033[1m'
else
  C_RESET=''; C_BLUE=''; C_GREEN=''; C_YELLOW=''; C_RED=''; C_BOLD=''
fi
info() { printf '%s==>%s %s\n' "$C_BLUE" "$C_RESET" "$*"; }
ok()   { printf '%s  ok%s %s\n' "$C_GREEN" "$C_RESET" "$*"; }
warn() { printf '%swarn%s %s\n' "$C_YELLOW" "$C_RESET" "$*"; }
die()  { printf '%serr %s%s\n' "$C_RED" "$C_RESET" "$*" >&2; exit 1; }

usage() {
  cat <<EOF
${C_BOLD}arch-labwc-noctalia installer${C_RESET}

Usage: ./install.sh [options]

Options:
  --no-packages    Skip pacman/AUR installation (configs only)
  --no-system      Skip enabling services and the display manager
  --no-wallpapers  Skip downloading the five free-use wallpapers
  --optional       Install every optional app without asking
  --no-optional    Skip all optional apps without asking
  --system         Enable services and display manager without asking
  --yes, -y        Assume "yes" for every prompt
  -h, --help       Show this help

Without flags the script installs the base desktop + dotfiles + wallpapers,
asks about each optional app (default: no), then asks once whether to apply
the system-level setup.
EOF
}

while (($#)); do
  case "$1" in
    --no-packages)   WITH_PACKAGES=0 ;;
    --no-system)     WITH_SYSTEM=0 ;;
    --no-wallpapers) WITH_WALLPAPERS=0 ;;
    --optional)      WITH_OPTIONAL=1 ;;
    --no-optional)   WITH_OPTIONAL=0 ;;
    --system)        WITH_SYSTEM=1 ;;
    --yes|-y)      ASSUME_YES=1 ;;
    -h|--help)     usage; exit 0 ;;
    *) die "unknown option: $1 (try --help)" ;;
  esac
  shift
done

# ── preflight ────────────────────────────────────────────────────────────────
[[ $EUID -eq 0 ]] && die "Run this as your normal user, not as root."
[[ -f /etc/arch-release ]] || warn "This does not look like Arch Linux. Continuing anyway."
command -v sudo >/dev/null 2>&1 || die "sudo is required. Install it and add yourself to wheel first."
command -v pacman >/dev/null 2>&1 || die "pacman not found."

info "Repository: $REPO_DIR"
info "Home:       $HOME"

# ── packages ─────────────────────────────────────────────────────────────────
install_list() {
  local file=$1
  [[ -f $file ]] || return 0
  local -a pkgs
  mapfile -t pkgs < <(grep -vE '^[[:space:]]*(#|$)' "$file")
  ((${#pkgs[@]})) || return 0
  info "Installing ${#pkgs[@]} package(s) from ${file##*/}"
  sudo pacman -S --needed --noconfirm "${pkgs[@]}"
  ok "${file##*/} done"
}

ensure_yay() {
  if command -v yay >/dev/null 2>&1; then
    ok "yay already installed"
    return
  fi
  local dir="$HOME/.cache/arch-labwc-noctalia/yay-bin-$STAMP"
  mkdir -p "$(dirname "$dir")"
  info "Bootstrapping yay-bin from the AUR"
  git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$dir"
  ( cd "$dir" && makepkg -si --noconfirm )
  ok "yay installed"
}

install_pacman_pkgs() {
  local -a pkgs=("$@")
  ((${#pkgs[@]})) || return 0
  info "Installing package(s): ${pkgs[*]}"
  sudo pacman -S --needed --noconfirm "${pkgs[@]}"
  ok "package installation done"
}

install_aur_pkgs() {
  local -a pkgs=("$@")
  ((${#pkgs[@]})) || return 0
  ensure_yay
  info "Installing AUR package(s): ${pkgs[*]}"
  yay -S --needed --noconfirm \
      --answerclean None --answerdiff None --answeredit None \
      "${pkgs[@]}"
  ok "AUR packages done"
}

# Ask about one optional app. --optional installs it, --no-optional skips it,
# -y answers yes, and a non-interactive stdin keeps the default (no).
ask_optional() {
  local label=$1 detail=$2 answer
  [[ $WITH_OPTIONAL == 0 ]] && return 1
  [[ $WITH_OPTIONAL == 1 || $ASSUME_YES -eq 1 ]] && return 0
  [[ -t 0 ]] || return 1
  read -r -p "  Install ${label}? (${detail}) [y/N] " answer || answer=""
  [[ ${answer,,} == y* ]]
}

if [[ $WITH_PACKAGES -eq 0 && $WITH_OPTIONAL == 1 ]]; then
  warn "--optional has no effect with --no-packages"
fi

if [[ $WITH_PACKAGES -eq 1 ]]; then
  install_list "$REPO_DIR/packages/base.txt"
  if grep -qi 'genuineintel' /proc/cpuinfo 2>/dev/null; then
    install_list "$REPO_DIR/packages/intel.txt"
  else
    info "Non-Intel CPU, skipping packages/intel.txt"
  fi

  # ── optional apps: one question each, default no ───────────────────────────
  optional_pacman=()
  optional_aur=()
  optional_scripts=()
  want_dev_extras=0

  if [[ $WITH_OPTIONAL == 0 ]]; then
    info "Skipping optional apps (--no-optional)"
  else
    echo
    if [[ $WITH_OPTIONAL == 1 ]]; then
      info "Installing all optional apps (--optional)"
    else
      info "Optional apps: press Enter to skip any"
    fi
    ask_optional "Discord" "chat client" && optional_pacman+=(discord)
    ask_optional "Brave" "browser, from the AUR" && optional_aur+=(brave-bin)
    ask_optional "LocalSend" "AirDrop-style file sharing, from the AUR" \
      && optional_aur+=(localsend-bin)
    ask_optional "Amberol" "music player, with extra codecs" \
      && optional_pacman+=(amberol gst-libav)
    ask_optional "Antumbra / Penumbra" "MTK flash tool, installed to ~/.local/bin" \
      && optional_scripts+=(install-antumbra.sh)
    if ask_optional "Brokkr Flash" "Samsung flashing tool, installed to ~/Applications"; then
      optional_scripts+=(install-brokkr.sh)
      optional_pacman+=(fuse2)   # the AppImage needs FUSE
    fi
    ask_optional "Developer extras" "android-tools, scrcpy, opencode" \
      && want_dev_extras=1
    echo
  fi

  ((${#optional_pacman[@]})) && install_pacman_pkgs "${optional_pacman[@]}"
  ((${#optional_aur[@]})) && install_aur_pkgs "${optional_aur[@]}"
  [[ $want_dev_extras -eq 1 ]] && install_list "$REPO_DIR/packages/optional.txt"

  for script in "${optional_scripts[@]}"; do
    if "$REPO_DIR/scripts/$script"; then
      ok "optional app installed via scripts/$script"
    else
      warn "scripts/$script failed, re-run it later"
    fi
  done
else
  info "Skipping package installation (--no-packages)"
fi

# ── dotfiles ─────────────────────────────────────────────────────────────────
install_file() {
  local src=$1 dst=$2
  mkdir -p "$(dirname "$dst")"
  if [[ -f $dst ]] && cmp -s "$src" "$dst"; then
    ok "unchanged $dst"
    return
  fi
  if [[ -e $dst ]]; then
    cp -a "$dst" "$dst.bak.$STAMP"
    warn "backed up $dst -> $dst.bak.$STAMP"
  fi
  install -m 0644 "$src" "$dst"
  ok "installed $dst"
}

render() { sed "s|__HOME__|$HOME|g" "$1" > "$2"; }

# Install a template after substituting __HOME__, optionally forcing a mode.
install_rendered() {
  local src=$1 dst=$2 mode=${3:-0644} tmp
  tmp="$(mktemp)"
  render "$src" "$tmp"
  install_file "$tmp" "$dst"
  chmod "$mode" "$dst"
  rm -f "$tmp"
}

# Install a file and make it executable (scripts).
install_exec() {
  install_file "$1" "$2"
  chmod 0755 "$2"
}

info "Installing dotfiles"
install_rendered "$REPO_DIR/config/labwc/rc.xml"        "$HOME/.config/labwc/rc.xml"
install_file     "$REPO_DIR/config/labwc/autostart"     "$HOME/.config/labwc/autostart"
install_file     "$REPO_DIR/config/foot/foot.ini"       "$HOME/.config/foot/foot.ini"
install_file     "$REPO_DIR/config/hyfetch/arch_clean.txt" "$HOME/.config/hyfetch/arch_clean.txt"

install_rendered "$REPO_DIR/config/noctalia/settings.toml" "$HOME/.config/noctalia/settings.toml"
install_rendered "$REPO_DIR/config/hyfetch.json.in"        "$HOME/.config/hyfetch.json"
install_rendered "$REPO_DIR/config/applications/wallpaper-add.desktop.in" \
                 "$HOME/.local/share/applications/wallpaper-add.desktop"
install_exec     "$REPO_DIR/scripts/wallpaper-add"         "$HOME/.local/bin/wallpaper-add"
install_exec     "$REPO_DIR/scripts/screen-record"         "$HOME/.local/bin/screen-record"
command -v update-desktop-database >/dev/null 2>&1 \
  && update-desktop-database "$HOME/.local/share/applications" >/dev/null 2>&1 || true

# hyfetch on every new interactive shell (idempotent)
BASHRC="$HOME/.bashrc"
touch "$BASHRC"
if grep -q 'arch-labwc-noctalia' "$BASHRC"; then
  ok "~/.bashrc already has the hyfetch block"
else
  cat >> "$BASHRC" <<'EOF'

# >>> arch-labwc-noctalia >>>
# Pin the clean Arch logo and trimmed output, even after `hyfetch -c`.
# Colours stay changeable: hyfetch -c, or hyfetch -p <preset>.
hyfetch() {
    command hyfetch \
        --ascii-file "$HOME/.config/hyfetch/arch_clean.txt" \
        --args="--structure Title:Separator:OS:Kernel:Uptime:WM:CPU:GPU:Memory:Disk:Battery:LocalIp" \
        "$@"
}

# Show system info once per terminal session
if [[ -z ${HYFETCH_SHOWN:-} ]] && command -v hyfetch >/dev/null; then
    hyfetch
    export HYFETCH_SHOWN=1
fi
# <<< arch-labwc-noctalia <<<
EOF
  ok "added hyfetch block to ~/.bashrc"
fi

# Make user-local tools (wallpaper-add, antumbra, brokkr-flash) available.
if grep -q 'arch-labwc-noctalia PATH' "$BASHRC"; then
  ok "~/.bashrc already adds ~/.local/bin to PATH"
else
  cat >> "$BASHRC" <<'EOF'

# >>> arch-labwc-noctalia PATH >>>
case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) export PATH="$HOME/.local/bin:$PATH" ;;
esac
# <<< arch-labwc-noctalia PATH <<<
EOF
  ok "added ~/.local/bin to PATH in ~/.bashrc"
fi

# ── wallpaper ────────────────────────────────────────────────────────────────
# No wallpaper is bundled (copyright). Five free-use photos are downloaded
# from Unsplash at install time; Noctalia's own default is used if that fails.
WALL_ROOT="$HOME/Pictures/Wallpapers"
WALL_DIR="$WALL_ROOT/free-use"
mkdir -p "$WALL_ROOT"
command -v xdg-user-dirs-update >/dev/null 2>&1 && xdg-user-dirs-update >/dev/null 2>&1 || true

if [[ $WITH_WALLPAPERS -eq 1 ]]; then
  info "Downloading five free-use wallpapers"
  if "$REPO_DIR/scripts/fetch-wallpapers.sh" --dir "$WALL_DIR"; then
    ok "wallpapers in $WALL_DIR"
  else
    warn "wallpaper download failed, run scripts/fetch-wallpapers.sh later"
  fi
else
  info "Skipping wallpaper download (--no-wallpapers)"
fi

if command -v noctalia >/dev/null 2>&1 && noctalia msg wallpaper-get >/dev/null 2>&1; then
  # The picker browses the parent folder, so your own images show up next to
  # the downloaded free-use set (which stays in free-use/).
  noctalia msg config-set wallpaper.directory "\"$WALL_ROOT\"" >/dev/null 2>&1 || true
  noctalia msg config-set wallpaper.automation.recursive true >/dev/null 2>&1 || true

  # On a fresh install Noctalia still shows its own default image. Replace it
  # with the first downloaded wallpaper; never touch a wallpaper already set.
  current="$(noctalia msg wallpaper-get 2>/dev/null || true)"
  if [[ -z $current || $current == /usr/share/noctalia/assets/noctalia-wallpaper.png ]]; then
    first=""
    if [[ -d $WALL_DIR ]]; then
      for candidate in "$WALL_DIR"/*.jpg "$WALL_DIR"/*.jpeg "$WALL_DIR"/*.png "$WALL_DIR"/*.webp; do
        if [[ -f $candidate ]]; then first=$candidate; break; fi
      done
    fi
    if [[ -n $first ]]; then
      noctalia msg wallpaper-set "$first" >/dev/null 2>&1 && ok "wallpaper set to ${first##*/}"
    fi
  fi

  noctalia msg color-scheme-set wallpaper vibrant >/dev/null 2>&1 && ok "palette follows the wallpaper (vibrant)"
else
  warn "Noctalia is not running. Pick a wallpaper with Super+w after login"
fi

# ── system-level (opt-in) ────────────────────────────────────────────────────
if [[ $WITH_SYSTEM == ask ]]; then
  if [[ $ASSUME_YES -eq 1 ]]; then
    WITH_SYSTEM=1
  else
    echo
    printf '%sApply system-level setup?%s\n' "$C_BOLD" "$C_RESET"
    cat <<'EOF'
  * enable NetworkManager and Bluetooth
  * enable ly as the display manager on tty1

No tuning is applied: no sysctl, udev, kernel, zram or storage changes.
EOF
    read -r -p "Apply now? [y/N] " answer
    [[ ${answer,,} == y* ]] && WITH_SYSTEM=1 || WITH_SYSTEM=0
  fi
fi

if [[ $WITH_SYSTEM == 1 ]]; then
  info "Running system setup (sudo will prompt)"
  sudo "$REPO_DIR/scripts/install-system.sh"
else
  info "Skipping system setup (run scripts/install-system.sh later if you want it)"
fi

# ── validation ───────────────────────────────────────────────────────────────
echo
if command -v noctalia >/dev/null 2>&1; then
  noctalia config validate >/dev/null 2>&1 && ok "Noctalia config is valid" || warn "Noctalia config validation failed"
fi
if command -v foot >/dev/null 2>&1; then
  foot --check-config >/dev/null 2>&1 && ok "foot config is valid" || warn "foot config check failed"
fi

# ── summary ──────────────────────────────────────────────────────────────────
cat <<EOF

${C_BOLD}Done.${C_RESET}

Next steps:
  1. Log out and back in (or reboot) so labwc picks up the new config.
  2. At the ly prompt, choose ${C_BOLD}labwc${C_RESET}.
  3. Super+Space opens the launcher, Super+s the control centre.

Screen recording:
  Super+Shift+r  start or stop a recording, saved in ~/Videos/Recordings

Wallpapers:
  Super+w        wallpaper picker
  Super+Shift+w  next wallpaper
  Super+Alt+w    add your own wallpaper (file picker)
  Five free-use photos live in ~/Pictures/Wallpapers/free-use/
  Your own images can be dropped in ~/Pictures/Wallpapers

Optional apps (install anytime):
  ./install.sh --optional            install all optional apps
  ./scripts/install-antumbra.sh      Antumbra + penumbra symlink
  ./scripts/install-brokkr.sh        Brokkr Flash AppImage + wrapper

If Noctalia looks unstyled on first login, run:
  noctalia msg config-reload
EOF
