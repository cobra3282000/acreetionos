# AcreetionOS Recovery System

A Windows-Recovery-Environment (WinRE)-style safety net for AcreetionOS, built
on **Timeshift** snapshots and a self-contained recovery partition. It works at
three layers, so there is always a way back in:

```
┌─────────────────────────────────────────────────────────────────────────┐
│ Layer 3: USB ISO (outermost)                                            │
│   Boot media carries its own GRUB + kernel + airootfs.sfs.              │
│   Works even if every disk bootloader is destroyed.                     │
│   "AcreetionOS Recovery Environment" boot entry → full TUI toolkit.     │
├─────────────────────────────────────────────────────────────────────────┤
│ Layer 2: Recovery partition on disk ("ACRECOVERY", ext4)                │
│   Own GRUB + gzip'd copies of kernel/initramfs/microcode.               │
│   Chainloaded by the MAIN bootloader only — never boots by itself.      │
│   Entered via F9 in GRUB, or automatically after a failed boot.         │
├─────────────────────────────────────────────────────────────────────────┤
│ Layer 1: Installed system                                               │
│   Timeshift RSYNC snapshots configured at install (postinstall.sh).     │
│   recordfail boot tracking + acreetion-boot-success.service.            │
│   pacman hook keeps recovery-partition kernels in sync.                 │
└─────────────────────────────────────────────────────────────────────────┘
```

Theme palette everywhere is the AcreetionOS brand: green `#2ecc71` on dark
`#121212`, taken from the website's `styles.css` (acreetionos-code.github.io).

---

## 1. How to get into recovery

| Situation | What happens |
|---|---|
| You want it manually | Press **F9** while the GRUB menu is showing → chainloads into the recovery environment |
| Last boot failed | GRUB sees the uncleared `recordfail` flag and **automatically** starts recovery after a short countdown |
| The system won't boot at all / GRUB on disk is gone | Boot the USB stick → its own independent bootloader offers "AcreetionOS Recovery Environment" |
| GRUB is misconfigured but intact (BIOS) | Boot menu → "Boot existing OS" chainloads your disk directly |
| Desktop still works | Live session has an "AcreetionOS Recovery" launcher; installed systems can run `sudo acreetion-recovery` in a terminal |

---

## 2. The recovery TUI — `acreetion-recovery`

`/usr/bin/acreetion-recovery` is a whiptail menu application themed with
NEWT_COLORS plus a VT100 palette remap (`ESC ]P…` escapes), so the whole TTY
renders in brand colors with no extra dependencies.

It auto-detects installed Linux systems (any distro with `/etc/os-release`) by
briefly mounting each candidate partition read-only, then mounts the chosen one
read-write at `/mnt/acreetion-recovery` and binds `/dev`, `/proc`, `/sys` for
chroot operations.

Menu actions:

| Action | Implementation |
|---|---|
| Restore from snapshot | Runs `timeshift --restore` inside the target via arch-chroot; offers initramfs + grub.cfg rebuild afterwards |
| Browse / manage snapshots | `timeshift --list` in-chroot |
| Create snapshot NOW | `timeshift --create --scripted --tags D --comments …`; auto-runs setup if unconfigured |
| Set up automatic backups | Writes `/etc/timeshift/timeshift.json` (RSYNC mode), adds automounting fstab entry when a dedicated storage partition is picked |
| Repair packages | Re-inits pacman keyring, refreshes archlinux-keyring, full `-Syyu`, fixes missing files reported by `pacman -Qk` |
| Check & repair filesystems | Unmounts target, runs `fsck -fy` on the root device |
| Reinstall bootloader | UEFI: mounts ESP, `grub-install --target=x86_64-efi --bootloader-id=AcreetionOS` (+ i386-efi best effort); BIOS: installs to every disk MBR; regenerates `grub.cfg` with os-prober enabled for dual-boot |
| Regenerate /etc/fstab | `genfstab -U`, old file kept as `fstab.recovery-backup` |
| Reset user password | Picks an account from `/etc/passwd`, chroot `passwd` |
| Configure network | `nmtui` |
| Hardware information | `inxi -Fxxxz` (falls back to fastfetch/lsblk) |
| View system logs | `journalctl --directory=<target>/var/log/journal` |
| Shells | Chroot shell *inside* the installed system, or live shell |

Every operation streams output to the screen and appends to
`/tmp/acreetion-recovery.log`.

---

## 3. Boot entries (ISO media)

Added to both bootloaders so any machine can reach recovery:

* `grub/grub.cfg` — "AcreetionOS Recovery Environment" entry boots the live
  system with `acreetion_recovery=1 systemd.unit=acreetion-recovery.target`;
  BIOS-only "Boot existing OS" chainloads `(hd0)` for quick returns to a
  misconfigured-but-intact install.
* `syslinux/archiso_sys-linux.cfg` — matching recovery label.

The systemd side of that command line:

* `acreetion-recovery.target` — replaces the default boot target; pulls only
  sysinit, networking and the TUI service. Never starts lightdm/Cinnamon.
* `acreetion-recovery.service` — runs the TUI on tty1
  (`ConditionKernelCommandLine=acreetion_recovery=1` gates it), conflicts with
  display-manager and getty@tty1, and clears the main system's `recordfail`
  flag as part of startup (see §5).

---

## 4. The recovery partition

`/usr/bin/acreetion-recovery-setup` provisions it during install (and can be
run anytime from a live USB to retrofit existing machines).

### Layout

```
ACRECOVERY  (ext4, ~512MiB)
├── vmlinuz-linux.gz            ← gzip -9 copies of /boot (GRUB gzio loads
├── initramfs-linux.img.gz        them transparently; fallback initramfs is
├── intel-ucode.img.gz [amd]     deliberately not copied)
├── EFI/BOOT/BOOTX64.EFI        ← its own GRUB (UEFI; i386 too)
├── boot/grub/{grub.cfg,grubenv,fonts,*.mod}   (its own config/modules)
└── (BIOS: GRUB also embedded into the partition boot sector)
```

### How the main bootloader uses it

`45_acreetion-recovery` (a grub.d script installed into `/etc/grub.d`)
regenerates into the MAIN `grub.cfg`:

```grub
menuentry 'AcreetionOS Recovery Environment (F9)' --hotkey=f9 --id 'acreetion-recovery' {
    # UEFI variant:
    search --no-floppy --fs-uuid --set=recovery_part <ACRECOVERY-UUID>
    chainloader /EFI/BOOT/BOOTX64.EFI
    # BIOS variant:
    search --no-floppy --fs-uuid --set=root <ACRECOVERY-UUID>
    chainloader +1
}
```

GRUB natively supports function-key hotkeys (`hotkey_aliases[]` maps `"f9"` →
`GRUB_TERM_KEY_F9`), so F9 genuinely works. This is pure **chainloading** —
the same mechanism Windows' BCD uses to hand off to WinRE.

### Safety guards (`--auto` mode)

Only creates a partition when provably safe:

* scans `parted -ms unit B print free` for the largest genuine unpartitioned gap ≥ 512MiB;
* refuses MBR disks with no free partition slot, LVM/RAID/LUKS-style roots,
  or missing plain filesystem types;
* never resizes, moves, or touches existing partitions; exits 0 with printed
  guidance when conditions aren't met (so installs are never blocked).

Other modes: `--device /dev/partX` (use an existing partition — will be
formatted), `--sync-kernels` (refresh payload only), bare run = interactive.

---

## 5. Automatic failover (recordfail)

Ported from Ubuntu's proven pattern, implemented entirely with our own scripts:

```
boot attempt starts          06_acreetion-default entry calls acreetion_recordfail()
                             → recordfail=1 saved into /boot/grub/grubenv

system boots successfully    acreetion-boot-success.service (multi-user.target.wants)
                             → grub-editenv unset recordfail

system crashed / hung        flag survives the crash
→ NEXT BOOT                  45_acreetion-recovery sees recordfail=1
                             → default flips to the chainload entry,
                               countdown message explains why
```

Notes:

* `06_acreetion-default` emits the primary menu entry (before `10_linux`) and
  setup sets `GRUB_DEFAULT="acreetion-default"` so the tracked entry is what
  actually boots.
* Entering recovery clears the flag (a successful recovery boot counts as
  success), so after you fix things and reboot, the normal path is tried
  again — if it fails again, failover re-triggers. No loops.
* The flag lives in the standard grubenv block; `boot_once` semantics prevent
  writes during one-shot boots.

---

## 6. Keeping kernels in sync

`/etc/pacman.d/hooks/acreetion-recovery-sync.hook` fires after every `linux`
package upgrade and runs `acreetion-recovery-setup --sync-kernels`, which
re-copies + recompresses the current kernel/initramfs/microcode onto
ACRECOVERY. It silently no-ops when no recovery partition exists, and never
fails a pacman transaction.

---

## 7. Timeshift integration

* `postinstall.sh` (runs once on the fresh install) writes
  `/etc/timeshift/timeshift.json`: RSYNC mode, sensible excludes
  (caches, Downloads, Trash), retention 5 daily / 3 weekly / 2 monthly /
  1 yearly, first-run snapshot enabled.
* Snapshots land on the root filesystem by default; users can move storage to
  a dedicated disk later via Timeshift's GUI or the recovery TUI's
  "Set up automatic backups".

---

## 8. How it gets built into the ISO

Standard archiso pipeline (`./build.sh`):

1. **pacstrap** installs everything in `packages.x86_64`, including the
   recovery set: `timeshift testdisk ddrescue fsarchiver gparted dialog libnewt inxi`.
2. **airootfs overlay copy** places every file under `airootfs/` at its exact
   final path — binaries, systemd units, enablement symlinks (e.g.
   `etc/systemd/system/multi-user.target.wants/acreetion-boot-success.service`),
   desktop launcher, icon, grub.d templates in `/usr/share/acreetion-recovery/`.
3. **profiledef.sh** `file_permissions` explicitly chmods the two binaries
   (`/usr/bin/acreetion-recovery`, `/usr/bin/acreetion-recovery-setup`) 0755.
4. Root filesystem is squashed (xz); GRUB/SYSLINUX configs are templated
   (`%INSTALL_DIR%`, `%ARCHISO_UUID%`) onto the ISO 9660 image.

Nothing here changes mkinitcpio — the ISO recovery path reuses the stock
kernel/initramfs pair; only kernel cmdline differs.

### File inventory (this branch)

| Path | Purpose |
|---|---|
| `airootfs/usr/bin/acreetion-recovery` | The recovery TUI |
| `airootfs/usr/bin/acreetion-recovery-setup` | Provision/manage ACRECOVERY |
| `airootfs/usr/share/acreetion-recovery/grub-recovery.cfg.in` | Template for the partition's own grub.cfg |
| `airootfs/usr/share/acreetion-recovery/grub.d/06_acreetion-default` | Main-grub tracked default entry + recordfail function |
| `airootfs/usr/share/acreetion-recovery/grub.d/45_acreetion-recovery` | Main-grub F9 chainload entry + auto-failover block |
| `airootfs/usr/lib/systemd/system/acreetion-recovery.{target,service}` | Boot-time recovery target/TUI |
| `airootfs/usr/lib/systemd/system/acreetion-boot-success.service` | Clears recordfail on healthy boots |
| `airootfs/etc/pacman.d/hooks/acreetion-recovery-sync.hook` | Kernel sync on upgrades |
| `airootfs/usr/share/applications/acreetion-recovery.desktop` | Live-session launcher |
| `grub/grub.cfg`, `syslinux/archiso_sys-linux.cfg` | ISO boot entries |

---

## 9. Maintenance & troubleshooting

* **Re-provision manually**: `sudo acreetion-recovery-setup` (interactive) —
  safe to re-run; it reformats ACRECOVERY and refreshes everything.
* **After restoring a snapshot**, always let the TUI rebuild initramfs+GRUB
  (it offers this automatically).
* **F9 does nothing?** Some firmwares intercept F9 for their own boot menu —
  use the firmware's boot-menu key to make sure GRUB owns input, then press
  F9 inside the GRUB menu. The recovery entry is also selectable normally.
* **No recovery partition was created** (no free space at install time): boot
  any AcreetionOS USB later and run `sudo acreetion-recovery-setup`, or free
  space and rerun on the installed system.
* **Secure Boot note**: chainloading the second GRUB requires Secure Boot to
  be disabled or your own keys enrolled (the distribution ships unsigned
  bootloaders).
* **Session log** for any failed operation: `/tmp/acreetion-recovery.log`
  inside the recovery environment.

## 10. Privacy note

Unrelated but shipped alongside: `acreetionos-countme` is a strictly opt-in
weekly anonymous ping (random UUID + OS version). Off unless accepted at
install; toggle with `sudo acreetionos-countme enable|disable|status`.
