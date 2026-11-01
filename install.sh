#!/usr/bin/env bash
#
# arch-labwc-noctalia — installer
#
# Reproduces this desktop on a fresh Arch Linux install:
#   labwc + Noctalia v5, Catppuccin-flavoured foot, hyfetch on login,
#   screenshot keybinds, and a handful of enabled services.
#
# Safe by design:
#   * never deletes anything — existing files are backed up as <file>.bak.<stamp>
#   * system-level changes are opt-in and only touch files listed in README
#   * no bootloader, partition table or fstab changes, ever
#
set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"

WITH_PACKAGES=1
WITH_SYSTEM="ask"
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
  --no-packages   Skip pacman/AUR installation (configs only)
  --no-system     Skip enabling services and the display manager
  --system        Enable services and display manager without asking
  --yes, -y       Assume "yes" for every prompt
  -h, --help      Show this help

Without flags the script installs packages + dotfiles, then asks once
whether to apply the system-level setup.
EOF
}

while (($#)); do
  case "$1" in
    --no-packages) WITH_PACKAGES=0 ;;
    --no-system)   WITH_SYSTEM=0 ;;
    --system)      WITH_SYSTEM=1 ;;
    --yes|-y)      ASSUME_YES=1 ;;
    -h|--help)     usage; exit 0 ;;
    *) die "unknown option: $1 (try --help)" ;;
  esac
  shift
done

# ── preflight ────────────────────────────────────────────────────────────────
[[ $EUID -eq 0 ]] && die "Run this as your normal user, not as root."
[[ -f /etc/arch-release ]] || warn "This does not look like Arch Linux — continuing anyway."
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

install_aur() {
  local -a pkgs
  mapfile -t pkgs < <(grep -vE '^[[:space:]]*(#|$)' "$REPO_DIR/packages/aur.txt")
  ((${#pkgs[@]})) || return 0
  info "Installing AUR package(s): ${pkgs[*]}"
  yay -S --needed --noconfirm \
      --answerclean None --answerdiff None --answeredit None \
      "${pkgs[@]}"
  ok "AUR packages done"
}

if [[ $WITH_PACKAGES -eq 1 ]]; then
  install_list "$REPO_DIR/packages/base.txt"
  if grep -qi 'genuineintel' /proc/cpuinfo 2>/dev/null; then
    install_list "$REPO_DIR/packages/intel.txt"
  else
    info "Non-Intel CPU — skipping packages/intel.txt"
  fi
  ensure_yay
  install_aur
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

info "Installing dotfiles"
install_file "$REPO_DIR/config/labwc/rc.xml"              "$HOME/.config/labwc/rc.xml"
install_file "$REPO_DIR/config/labwc/autostart"           "$HOME/.config/labwc/autostart"
install_file "$REPO_DIR/config/noctalia/settings.toml"    "$HOME/.config/noctalia/settings.toml"
install_file "$REPO_DIR/config/foot/foot.ini"             "$HOME/.config/foot/foot.ini"
install_file "$REPO_DIR/config/hyfetch/arch_clean.txt"    "$HOME/.config/hyfetch/arch_clean.txt"

hyfetch_tmp="$(mktemp)"
render "$REPO_DIR/config/hyfetch.json.in" "$hyfetch_tmp"
install_file "$hyfetch_tmp" "$HOME/.config/hyfetch.json"
rm -f "$hyfetch_tmp"

# hyfetch on every new interactive shell (idempotent)
BASHRC="$HOME/.bashrc"
touch "$BASHRC"
if grep -q 'arch-labwc-noctalia' "$BASHRC"; then
  ok "~/.bashrc already has the hyfetch block"
else
  cat >> "$BASHRC" <<'EOF'

# >>> arch-labwc-noctalia >>>
# Show system info once per terminal session
if [[ -z ${HYFETCH_SHOWN:-} ]] && command -v hyfetch >/dev/null; then
    hyfetch
    export HYFETCH_SHOWN=1
fi
# <<< arch-labwc-noctalia <<<
EOF
  ok "added hyfetch block to ~/.bashrc"
fi

# ── wallpaper ────────────────────────────────────────────────────────────────
# No wallpaper is bundled (copyright). Noctalia uses its own default at
# /usr/share/noctalia/assets/noctalia-wallpaper.png until you set one.
command -v xdg-user-dirs-update >/dev/null 2>&1 && xdg-user-dirs-update >/dev/null 2>&1 || true

if command -v noctalia >/dev/null 2>&1 && noctalia msg wallpaper-get >/dev/null 2>&1; then
  noctalia msg color-scheme-set wallpaper vibrant >/dev/null 2>&1 && ok "palette follows the wallpaper (vibrant)"
else
  warn "Noctalia is not running — colours apply on next login"
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

If Noctalia looks unstyled on first login, run:
  noctalia msg config-reload

No wallpaper is bundled — Noctalia shows its default until you set one:
  noctalia msg wallpaper-set /path/to/image.png
EOF
