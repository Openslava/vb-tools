#!/usr/bin/env bash
# Minimal systemd + cron setup for WSL (Ubuntu 22.04, Oracle Linux 8/9)

set -euo pipefail

echo "### 07_set_system.sh - Setting up systemd and cron..."

msg() { printf '%s\n' "$*"; }
die() { msg "[ERROR] $*"; exit 1; }

[ "$(id -u)" -eq 0 ] || die "Run as root: sudo $0"

# 1) Ensure systemd is enabled in /etc/wsl.conf (sed-only edits)
conf=/etc/wsl.conf
if [ ! -f "$conf" ]; then
  printf "[boot]\nsystemd=true\n" > "$conf"
elif grep -q '^\[boot\]' "$conf" 2>/dev/null; then
  # Replace existing systemd=... or insert if missing within [boot]
  if sed -n '/^\[boot\]/,/^\[/{/^[[:space:]]*systemd[[:space:]]*=/p}' "$conf" | grep -q .; then
    sed -i '/^\[boot\]/,/^\[/{s/^[[:space:]]*systemd[[:space:]]*=.*/systemd=true/}' "$conf"
  else
    sed -i '/^\[boot\]/a systemd=true' "$conf"
  fi
else
  printf "\n[boot]\nsystemd=true\n" >> "$conf"
fi
msg "[OK] Ensured systemd=true in $conf"

# 2) Update package index (with yum user_agent workaround)
PKGMGR="$(command -v apt-get || command -v yum || command -v dnf || true)"
if [ -n "$PKGMGR" ]; then
    if ! "$PKGMGR" -y update; then
        # Workaround for certain yum environments requiring a user_agent
        if [ "$(basename "$PKGMGR")" = "yum" ]; then
            grep -qxF 'user_agent=curl/7.61.1' /etc/yum.conf || echo 'user_agent=curl/7.61.1' >> /etc/yum.conf
            "$PKGMGR" -y update || true
        fi
    fi
fi

# 3) Install cron (cronie on RPM, cron on Debian/Ubuntu)
svc="cron"
if command -v apt-get >/dev/null 2>&1; then
  # apt-get index already updated above
  "$PKGMGR" install -y cron
else
  [ -n "$PKGMGR" ] || die "Unsupported package manager. Install cron manually."
  "$PKGMGR" install -y cronie
  svc="crond"
fi
msg "[OK] Installed service: $svc"

# 4) Start/enable cron
if [ -f /proc/1/comm ] && grep -qi systemd /proc/1/comm; then
  systemctl enable --now "$svc" || systemctl restart "$svc" || true
  systemctl is-active --quiet "$svc" && msg "[OK] $svc is active" || msg "[WARN] $svc not active yet"
else
  msg "[WARN] systemd not active (PID 1). Starting $svc temporarily. Run 'wsl --shutdown' from Windows to enable systemd."
  if command -v service >/dev/null 2>&1; then service "$svc" start || true; else [ -x "/etc/init.d/$svc" ] && "/etc/init.d/$svc" start || true; fi
fi

msg "[DONE] Systemd configured and cron set up. If not active, run: wsl --shutdown"
