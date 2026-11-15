# system/

Everything the rice needs that does **not** live in `$HOME`.

`install.sh` only ever writes inside the home directory — that is deliberate,
so a restore never needs root. This directory is the other half: the small
system layer that used to exist only on the machine itself, and would have
been lost on a reinstall.

`system/` mirrors the filesystem root, so paths are readable at a glance:

| Path in repo | Lands at |
| --- | --- |
| `system/usr/local/bin/` | `/usr/local/bin/` |
| `system/etc/systemd/system/` | `/etc/systemd/system/` |
| `system/etc/systemd/zram-generator.conf` | `/etc/systemd/zram-generator.conf` |
| `system/etc/udev/rules.d/` | `/etc/udev/rules.d/` |
| `system/etc/sysctl.d/` | `/etc/sysctl.d/` |
| `system/etc/*.conf` | `/etc/` |

`grub-cmdline.conf` is the exception: Arch has no `/etc/default/grub.d`, so
`install-system.sh` appends the tokens to the existing
`GRUB_CMDLINE_LINUX_DEFAULT` instead of shipping the whole file.

## Apply

```bash
sudo ./system/install-system.sh --dry-run   # see what would change
sudo ./system/install-system.sh             # files, units, sysctl, grub
sudo ./system/install-system.sh --resize-zram
```

`install.sh --system` calls the same script. Existing files are compared
first and backed up to `/var/backups/dotfiles-system-<timestamp>/`.

## What is here

- **Memory**: `zram-generator.conf` (75% RAM) and `transparent_hugepage=madvise`
  in `grub-cmdline.conf`. Both come from one incident: a browser content
  process reached 4.1 GiB, swap hit 0 kB, and the kernel OOM killer took the
  browser down. Details in the PR that introduced this directory.
- **Power**: `power-policy` daemon + unit keeps `power-profiles-daemon` as the
  source of truth and applies hardware policy (`power-apply`); `power-mode` is
  the CLI bound to `Mod+Shift+B`; `battery-threshold` enforces the ThinkPad
  charge window from `battery-threshold.conf`.
- **USB**: `usb-automount` + `@.service` + udev rule mounts flash drives and
  external disks by size/rotational hint (`usb-automount.conf`). udev does not
  mount; it only asks systemd for the unit, because systemd 262 sandboxes
  udev away from mount(2).
- **Sysctl**: `99-power-savings.conf` disables the NMI watchdog.

## Machine-specific values

`etc/usb-automount.conf` carries the UUID of one external HDD, and
`etc/battery-threshold.conf` assumes a ThinkPad charge window. Both are safe
no-ops elsewhere (the UUID simply never matches, the unit is skipped when
`BAT0` is absent), but check them on a new machine.
