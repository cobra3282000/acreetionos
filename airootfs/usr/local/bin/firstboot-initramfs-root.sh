#!/bin/bash
mkinitcpio -P
rm -f /var/lib/mkinitcpio-firstboot-pending
rm -f /etc/sudoers.d/firstboot-mkinitcpio
rm -f /etc/xdg/autostart/mkinitcpio-firstboot.desktop
