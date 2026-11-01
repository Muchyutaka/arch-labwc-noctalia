#!/usr/bin/env bash
#
# System-level setup for arch-labwc-noctalia.
# Called by install.sh, or run directly: sudo ./scripts/install-system.sh
#
# This only enables services and the display manager. It performs no tuning
# and changes no kernel, sysctl, udev or storage settings.
#
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  exec sudo -- "$0" "$@"
fi

info() { printf '==> %s\n' "$*"; }
ok()   { printf '  ok %s\n' "$*"; }
warn() { printf 'warn %s\n' "$*"; }

# ── services ────────────────────────────────────────────────────────────────
info "Enabling services"
for svc in NetworkManager bluetooth; do
  if systemctl list-unit-files --no-legend "$svc.service" 2>/dev/null | grep -q .; then
    systemctl enable --now "$svc.service" 2>/dev/null && ok "$svc" || warn "could not enable $svc"
  else
    warn "$svc not installed — skipping"
  fi
done

if command -v ly >/dev/null 2>&1; then
  current="$(readlink -f /etc/systemd/system/display-manager.service 2>/dev/null || true)"
  if [[ -z $current || $current == *ly* ]]; then
    systemctl enable ly@tty1.service 2>/dev/null && ok "ly enabled on tty1"
  else
    warn "another display manager is configured ($current) — leaving it alone"
  fi
else
  warn "ly not installed — start the session with 'labwc' from a TTY"
fi

cat <<'EOF'

System setup complete.

  * NetworkManager, Bluetooth and ly are enabled.
  * No tuning was applied — this repo ships plain, default settings.
EOF
