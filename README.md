# blarblirblur-dotfiles

Personal **Niri + Noctalia** rice, shell and app configs, kept as a
**restore kit** for when I move to a new machine.

Layout mirrors `$HOME` so restoring is a copy, not a puzzle:

| Path in repo | Lands at |
| --- | --- |
| `config/` | `~/.config/` |
| `home/` | `~/` (`.zshrc`, `.zshenv`, `.zprofile`, `.gitconfig`, `.Xresources`) |
| `state/` | `~/.local/state/` (Noctalia `settings.toml`, `state.toml`, `wallpaper_shuffle.json`) |
| `agents/` | `~/.agents/` |
| `themes/` | `~/.themes/` |

## What's inside

- **Niri**: `config.kdl` + `noctalia.kdl` + `monitor.kdl`, a `dms/` module set and `Keybinds.conf`
- **Noctalia**: shell config (`config.toml`) and restorable state
- **Terminal / TUI**: `kitty/`, `btop/`, `fastfetch/`, `zathura/`, `starship.toml`, `fontconfig/`
- **Toolkit theming**: `gtk-3.0/`, `gtk-4.0/`, `Kvantum/`, `qt5ct/`, `qt6ct/`, `themes/Flat-Remix-*`
- **Xdg glue**: portals conf, `mimeapps.list`, `user-dirs.dirs`, `xdg-terminals.list`
- **Shell + git**: `home/.zshrc` and friends (oh-my-zsh based)
- **AI tooling**: `config/opencode/` (no `node_modules`), `agents/`
- `config/systemd/user/hermes-gateway.service` (paths use the `%h` specifier)

Verified before every push: no credentials, no history, no machine state.

## Requirements

Arch / CachyOS, `base-devel`, and a Wayland-capable GPU. This setup assumes
`niri` **≥ 25.x** with blur support; on a distro without a bleeding-edge repo
install `niri-git` instead.

Fonts come from packages, never from files: `ttf-jetbrains-mono-nerd`,
`noto-fonts-emoji`, `otf-space-grotesk`.

## Install

```bash
git clone https://github.com/rifqieali/blarblirblur-dotfiles ~/dotfiles
cd ~/dotfiles
./install.sh --dry-run     # see exactly what would be touched
./install.sh               # packages, then configs (asks before overwriting)
```

`install.sh` backs up any file it would overwrite into
`~/.dotfiles-backup-<timestamp>/`. Flags: `--dry-run`, `--no-packages`, `--force`.

Package sets are curated, not a dump of `pacman -Qqe`:

- `packages/niri-core.txt` — the rice itself (official repos)
- `packages/apps.txt` — daily apps (official repos)
- `packages/aur.txt` — AUR only: `yay -S --needed - < packages/aur.txt`

## After install (manual, by design)

1. **Monitors.** Open `~/.config/niri/config.kdl` and set your output name,
   mode and scale. `monitor.kdl` here is this machine's layout only — a note,
   not a promise.
2. **Display manager.** `sudo systemctl enable --now sddm`.
3. **Session services.** `systemctl --user enable --now pipewire wireplumber`,
   then re-login so portals and `xwayland-satellite` pick up the session.
4. **Wallpapers.** `./scripts/wallpapers.sh` clones the reference collection
   into `~/Pictures/Wallpapers`. Your own URLs go in
   `scripts/wallpapers.personal.txt` (gitignored), then run with `--with-personal`.
5. **Credentials — none live here.** Recreate them: `gh auth login`, a fresh
   SSH key, `opencode auth login`, and `export CONTEXT7_API_KEY=...` for the
   Context7 MCP header.
6. **Shell.** `chsh -s /usr/bin/zsh`.

## Deliberately excluded

- Monitor outputs, wallpaper files, and Noctalia notification/clipboard history
- Credentials: `~/.ssh`, `~/.gnupg`, `~/.config/gh`, Context7 token, gh keyring
- `~/.icons` (≈660 MB — reinstall via package)
- Leftovers from the previous desktop: Hyprland, Caelsetia, illogical-impulse, KDE
- `node_modules/` anywhere; app data and caches in general

If something is missing, it was almost certainly a decision, not an oversight.
