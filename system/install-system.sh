#!/usr/bin/env bash
# install-system.sh — apply the system/ layer, i.e. everything outside $HOME.
#
# system/ mirrors the filesystem root:
#   system/usr/local/bin/foo        -> /usr/local/bin/foo
#   system/etc/udev/rules.d/bar.rules -> /etc/udev/rules.d/bar.rules
#
# Restoring is a copy, the same idea install.sh uses for $HOME. Nothing here
# is enforced from the repo at runtime: this pushes files once, like a config
# manager would.
#
# Usage:
#   sudo ./system/install-system.sh --dry-run
#   sudo ./system/install-system.sh
#   sudo ./system/install-system.sh --resize-zram   # also swapoff/restart now
#
# Exit codes: 0 ok, 1 not root, 2 bad flag.

set -euo pipefail

SYSTEM_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="/var/backups/dotfiles-system-$(date +%Y%m%d-%H%M%S)"

DRY_RUN=0
RESIZE_ZRAM=0

for arg in "$@"; do
  case "$arg" in
    --dry-run)     DRY_RUN=1 ;;
    --resize-zram) RESIZE_ZRAM=1 ;;
    -h|--help)     sed -n '2,19p' "$0"; exit 0 ;;
    *) echo "unknown flag: $arg" >&2; exit 2 ;;
  esac
done

log() { printf '%s\n' "$*"; }
run() { if (( DRY_RUN )); then log "  [dry-run] $*"; else "$@"; fi; }

if (( ! DRY_RUN )) && [[ $EUID -ne 0 ]]; then
  echo "jalankan dengan sudo" >&2
  exit 1
fi

backup() {
  local dst="$1"
  [[ -e "$dst" ]] || return 0
  run mkdir -p "$BACKUP_DIR/$(dirname "${dst#/}")"
  run cp -a "$dst" "$BACKUP_DIR/${dst#/}"
}

# --- 1. mirror system/{etc,usr,boot} onto / ---------------------------------
for tree in etc usr boot; do
  [[ -d "$SYSTEM_DIR/$tree" ]] || continue
  while IFS= read -r -d '' src; do
    dst="/${src#"$SYSTEM_DIR"/}"
    cmp -s "$src" "$dst" 2>/dev/null && continue
    log "==> $dst"
    backup "$dst"
    run install -Dm "$(stat -c %a "$src")" "$src" "$dst"
  done < <(find "$SYSTEM_DIR/$tree" -type f -print0)
done

# --- 2. /etc/default/grub ---------------------------------------------------
# Arch has no /etc/default/grub.d, so this file is never shipped whole: cmdline
# tokens are appended and plain variables rewritten in place, leaving
# machine-specific settings (GRUB_TIMEOUT, saved default) untouched.
GRUB_DEFAULT=/etc/default/grub
GRUB_CHANGED=0
GRUB_BACKED=0

grub_write() {  # stdin -> /etc/default/grub, backing up once
  if (( DRY_RUN )); then
    cat > /dev/null
    return 0
  fi
  if (( ! GRUB_BACKED )); then
    backup "$GRUB_DEFAULT"
    GRUB_BACKED=1
  fi
  local tmp
  tmp="$(mktemp)"
  cat > "$tmp"
  install -m 644 "$tmp" "$GRUB_DEFAULT"
  rm -f "$tmp"
}

if [[ -f $GRUB_DEFAULT ]]; then
  mapfile -t wanted < <(grep -vE '^[[:space:]]*(#|$)' "$SYSTEM_DIR/grub-cmdline.conf" || true)
  current="$(sed -nE 's/^GRUB_CMDLINE_LINUX_DEFAULT="(.*)"$/\1/p' "$GRUB_DEFAULT")"
  add=""
  for tok in "${wanted[@]}"; do
    [[ " $current " == *" $tok "* ]] && continue
    add+=" $tok"
  done

  if [[ -z $add ]]; then
    log "==> kernel cmdline sudah lengkap"
  else
    log "==> GRUB_CMDLINE_LINUX_DEFAULT +=$add"
    GRUB_CHANGED=1
    awk -v val="$current$add" '
      /^GRUB_CMDLINE_LINUX_DEFAULT=/ && !done {
        printf "GRUB_CMDLINE_LINUX_DEFAULT=\"%s\"\n", val; done = 1; next
      }
      { print }
      END { if (!done) printf "GRUB_CMDLINE_LINUX_DEFAULT=\"%s\"\n", val }
    ' "$GRUB_DEFAULT" | grub_write
  fi

  if [[ -f "$SYSTEM_DIR/grub-settings.conf" ]]; then
    while IFS= read -r line; do
      [[ $line =~ ^[[:space:]]*(#|$) ]] && continue
      key="${line%%=*}"
      val="${line#*=}"
      val="${val#\"}"; val="${val%\"}"
      now="$(sed -nE "s/^${key}=\"?([^\"]*)\"?\$/\1/p" "$GRUB_DEFAULT" | head -1)"
      if [[ $now == "$val" ]]; then
        log "==> $key sudah benar"
        continue
      fi
      log "==> $key: ${now:-(belum ada)} -> $val"
      GRUB_CHANGED=1
      awk -v k="$key" -v v="$val" '
        index($0, k "=") == 1 { printf "%s=\"%s\"\n", k, v; found = 1; next }
        { print }
        END { if (!found) printf "%s=\"%s\"\n", k, v }
      ' "$GRUB_DEFAULT" | grub_write
    done < "$SYSTEM_DIR/grub-settings.conf"
  fi

  if (( GRUB_CHANGED )); then
    run grub-mkconfig -o /boot/grub/grub.cfg
  fi
else
  log "!! /etc/default/grub tidak ada — konfigurasi GRUB dilewati"
fi

# --- 3. live reload ---------------------------------------------------------
run systemctl daemon-reload
run udevadm control --reload
run sysctl --system

for unit in power-policy.service battery-threshold.service; do
  [[ -f "$SYSTEM_DIR/etc/systemd/system/$unit" ]] || continue
  run systemctl enable --now "$unit"
done

# zram needs a device recreate, not a reload: the size lives in a generator.
if [[ -d $SYSTEM_DIR/etc/systemd ]] && (( RESIZE_ZRAM )); then
  run swapoff /dev/zram0
  run systemctl restart systemd-zram-setup@zram0.service
elif [[ -d $SYSTEM_DIR/etc/systemd ]]; then
  log "==> zram: ukuran baru berlaku setelah reboot (atau --resize-zram)"
fi

# SDDM reads its config and theme at startup. Restarting it would kill the
# running session, so this is deliberately a note, not an action.
if [[ -d "$SYSTEM_DIR/etc/sddm.conf.d" ]]; then
  log "==> SDDM: config/tema dipakai saat SDDM start berikutnya (logout/reboot)"
fi

if [[ -d $BACKUP_DIR ]]; then
  log "==> File lama dibackup ke $BACKUP_DIR"
fi

cat <<'EOF'

==> Selesai. Sisa langkah manual:
  1. Reboot untuk kernel cmdline + tema GRUB (transparent_hugepage=madvise).
     Cek setelahnya: cat /sys/kernel/mm/transparent_hugepage/enabled
  2. Cek zram: zramctl  (DISKSIZE harus ~75% RAM)
  3. Cek unit: systemctl status power-policy battery-threshold
  4. Tema SDDM dipakai setelah logout/reboot berikutnya.
EOF
