#!/usr/bin/env python3
import libcalamares

def run():
    """ Generate the initramfs with mkinitcpio """
    root_mount_point = libcalamares.globalstorage.value("rootMountPoint")
    
    return libcalamares.utils.chroot_call(['mkinitcpio', '-P'], root_mount_point)
