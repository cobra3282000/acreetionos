1. Added back the init configs
2. Added Changes.md
3. Removed unnecessary packages in packages.x86_64
4. Fixed Startx
5. Added Mkinitcpio-firmware to add firmware to remove errors on boot.  
6. Switched back to squashfs for higher compression levels with XZ. EROFS doesn't provide the same level of compression.
7. Replaced Console with Mate Terminal because it works, added glu
8. Added xorg-xmessage
9. totally converted to acreetion os now days!  no not put arch repo's back in system will break its key ring!
10. Added the AcreetionOS Recovery Environment (branch `recovery`), a Windows-Recovery-style maintenance mode:
    - New boot menu entry "AcreetionOS Recovery Environment" in GRUB and SYSLINUX that boots the live system into
      `acreetion-recovery.target` (`acreetion_recovery=1 systemd.unit=acreetion-recovery.target`)
    - `acreetion-recovery` (TUI, whiptail) themed with the AcreetionOS website palette (#2ecc71 green on #121212 dark),
      including a VT console palette remap so the whole recovery TTY matches the brand
    - Tools: Timeshift snapshot restore/create/setup/browse, package repair (keyring + upgrade + broken deps),
      filesystem check (fsck), GRUB reinstall / boot repair (BIOS + UEFI with dual-boot os-prober),
      fstab regeneration, password reset, network setup (nmtui), hardware info, log viewer,
      chroot shell and live shell
    - Automatic detection and mounting of any installed Linux system (multi-boot aware)
    - systemd units: `acreetion-recovery.target` + `acreetion-recovery.service` (tty1)
    - Desktop launcher "AcreetionOS Recovery" in the live session
    - postinstall.sh now configures Timeshift (RSYNC snapshots) on fresh installs so recovery works from day one
    - New packages: timeshift, testdisk, ddrescue, fsarchiver, gparted, dialog, libnewt (whiptail), inxi
11. Added the WinRE-style Recovery Partition (`acreetion-recovery-setup`):
    - postinstall provisions an ~800MiB "ACRECOVERY" ext4 partition inside unpartitioned free space
      (strict guards: never touches existing partitions; skips safely when no space/slot)
    - the partition is fully self-contained: its own GRUB + copies of kernel/initramfs/microcode,
      so it works even when the main /boot is damaged
    - MAIN bootloader only CHAINLOADS it: F9 hotkey menu entry (GRUB native f-key hotkeys) or
      automatic failover via grubenv recordfail tracking (acreetion-boot-success.service clears
      the flag on successful boot; 06/45 grub.d scripts add the tracked default entry + fallback)
    - pacman hook keeps the partition's kernel copies in sync on linux upgrades
    - `--auto` / `--device <part>` / `--sync-kernels` modes; also usable from the live ISO to
      retrofit recovery onto existing installs

