#!/usr/bin/env bash
# install.sh — restore this dotfiles repo onto a new Arch/CachyOS machine.
#
# Usage:
#   ./install.sh              # full install: packages + configs (asks before overwrite)
#   ./install.sh --dry-run    # print what would happen, touch nothing
#   ./install.sh --no-packages
#   ./install.sh --force      # overwrite without asking
#
# The repo layout maps 1:1 onto $HOME:
#   config/      -> ~/.config/
#   home/        -> ~/            (dotfiles)
#   state/       -> ~/.local/state/
#   agents/      -> ~/.agents/
#   themes/      -> ~/.themes/

set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

DRY_RUN=0
INSTALL_PACKAGES=1
FORCE=0

for arg in "$@"; do
  case "$arg" in
    --dry-run)     DRY_RUN=1 ;;
    --no-packages) INSTALL_PACKAGES=0 ;;
    --force)       FORCE=1 ;;
    -h|--help)     sed -n '2,20p' "$0"; exit 0 ;;
    *) echo "unknown flag: $arg" >&2; exit 2 ;;
  esac
done

log()  { printf '%s\n' "$*"; }
run()  { if (( DRY_RUN )); then log "  [dry-run] $*"; else "$@"; fi; }

# copy_tree <src> <dst> : mirror src into dst, backing up collisions first
copy_tree() {
  local src="$1" dst="$2"
  log "==> $src -> $dst"
  ( cd "$src" && find . -mindepth 1 -print0 ) | while IFS= read -r -d '' rel; do
    local s="$src/$rel" d="$dst/$rel"
    if [[ -d "$s" ]]; then
      run mkdir -p "$d"
      continue
    fi
    if [[ -e "$d" ]] && ! cmp -s "$s" "$d"; then
      if (( FORCE )); then
        :
      elif [[ -t 0 ]]; then
        read -r -p "    overwrite $d ? [y/N] " ans
        [[ "$ans" == [yY]* ]] || { log "    skipped"; continue; }
      fi
      run mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
      run cp -a "$d" "$BACKUP_DIR/$rel"
    fi
    run mkdir -p "$(dirname "$d")"
    run cp -a "$s" "$d"
  done
}

if (( INSTALL_PACKAGES )); then
  log "==> Packages (official repos)"
  run sudo pacman -S --needed - < "$REPO_DIR/packages/niri-core.txt"
  run sudo pacman -S --needed - < "$REPO_DIR/packages/apps.txt"

  if command -v yay >/dev/null 2>&1; then
    log "==> Packages (AUR)"
    run yay -S --needed - < "$REPO_DIR/packages/aur.txt"
  else
    log "!! yay not found — install it and then run:"
    log "   yay -S --needed - < $REPO_DIR/packages/aur.txt"
  fi
fi

copy_tree "$REPO_DIR/config" "$HOME/.config"
copy_tree "$REPO_DIR/home"   "$HOME"
copy_tree "$REPO_DIR/state"  "$HOME/.local/state"
copy_tree "$REPO_DIR/agents" "$HOME/.agents"
copy_tree "$REPO_DIR/themes" "$HOME/.themes"

if [[ -d "$BACKUP_DIR" ]]; then
  log "==> Previous files backed up to $BACKUP_DIR"
fi

cat <<'EOF'

==> Manual steps (cannot be automated)
  1. Edit ~/.config/niri/config.kdl  -> set your monitor output name/scale/mode.
  2. Enable display manager:  sudo systemctl enable --now sddm
  3. Session services:        systemctl --user enable --now pipewire wireplumber
     (a user session restart / re-login is usually needed)
  4. Wallpapers:              ./scripts/wallpapers.sh
  5. Credentials are NOT in this repo. Re-auth by hand:
       gh auth login
       ssh-keygen -t ed25519 -C "you@host"  (then add the pubkey)
       opencode auth login / context7 API key -> export CONTEXT7_API_KEY=...
  6. Default shell:           chsh -s /usr/bin/zsh
EOF
