#!/usr/bin/env bash
# Regenerate initramfs explicitly — the mkinitcpio post-transaction hook
# segfaults in the pacstrap chroot, so we run it here via arch-chroot
# where /proc, /sys, and /dev are properly mounted.
set -e -u

mkinitcpio -p linux

# The airootfs overlay is copied in after pacstrap's package hooks already
# ran, so gschema overrides shipped in this repo (e.g. the branded wallpaper
# default) are never compiled unless we do it here.
glib-compile-schemas /usr/share/glib-2.0/schemas
