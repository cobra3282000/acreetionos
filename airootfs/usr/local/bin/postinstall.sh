#!/bin/bash -e
# NOTE: -e means any command that fails (returns non-zero) will abort this
# script immediately with exit code 1, EXCEPT the pacman calls guarded by
# has_inet, which are skipped (not errored) when there's no internet.
#
##############################################################################
#
#  PostInstall is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 3 of the License, or
#  (at your discretion) any later version.
#
#  PostInstall is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
##############################################################################

 name=$(ls -1 /home)
 REAL_NAME=/home/$name

# checks for a working internet connection before running pacman commands
# so the script doesn't error out for users installing offline
has_inet() {
    ping -c 1 -W 2 archlinux.org &>/dev/null
}

# genfstab -U / > /etc/fstab

#cp /cinnamon-configs/cinnamon-stuff/bin/* /bin/
#cp /cinnamon-configs/cinnamon-stuff/usr/bin/* /usr/bin/
#cp -r /cinnamon-configs/cinnamon-stuff/usr/share/* /usr/share/

mkdir -p /home/$name/.config
mkdir -p /home/$name/.config/nemo
#mkdir -p /home/$name/.local/share/cinnamon/extensions

#cp -r /cinnamon-configs/cinnamon-stuff/extensions/* /home/$name/.local/share/cinnamon/extensions

#cp -r /cinnamon-configs/cinnamon-stuff/nemo/* /home/$name/.config/nemo

cp -r /cinnamon-configs/cinnamon-stuff/.config/* /home/$name/.config/

mkdir -p /home/$name/.config/autostart

cp -r /cinnamon-configs/dd.desktop /home/$name/.config/autostart

chown -R $name:$name /home/$name/.config
chown -R $name:$name /middle.png
#mv /middle.png /home/$USER

cp -r /cinnamon-configs/.bashrc /home/$name/.bashrc
cp -r /cinnamon-configs/.bashrc /root
cp -r /cinnamon-configs/AcreetionOS.txt /root
cp -r /cinnamon-configs/AcreetionOS.txt /home/$name/AcreetionOS.txt

mv /resolv.conf /etc/resolv.conf
chattr +i /etc/resolv.conf
chattr +i /etc/os-release

# create python fix!

#mkdir -p /usr/lib/python3.13/site-packages/six
#touch /usr/lib/python3.13/site-packages/six/__init__.py
#cp /usr/lib/python3.12/site-packages/six.py /usr/lib/python3.13/site-packages/six/six.py

# cp /archiso.conf /etc/mkinitcpio.conf.d/archiso.conf

# mkdir /home/$name/.local/share/cinnamon

# cp -r /cinnamon-configs/cinnamon-stuff/extensions /home/$name/.local/share/cinnamon/

cp /cinnamon-configs/AcreetionOS.txt /home/$name/

mkdir -p /usr/share/backgrounds
cp -r /backgrounds /usr/share/backgrounds
rm -rf /backgrounds

# chsh -s /bin/bash root

echo "Defaults pwfeedback" | sudo EDITOR='tee -a' visudo >/dev/null 2>&1

#cp -r /cinnamon-configs/spices/* /home/$name/.config/cinnamon/spices/
cp /etc/pacman2.conf pacman.conf
cp /mkinitcpio/mkinitcpio.conf /etc/mkinitcpio.conf
# Don't copy archiso.conf - it's only for the live ISO
# cp /mkinitcpio/archiso.conf /etc/mkinitcpio.conf.d/archiso.conf
cp /cinnamon-configs/.nanorc /home/$name/.nanorc

# Create placeholder dm-initramfs.rules for archiso hook compatibility
# mkdir -p /usr/lib/initcpio/udev
# echo "# Placeholder file for archiso hook compatibility" > /usr/lib/initcpio/udev/11-dm-initramfs.rules
# echo "# dm-initramfs rules not needed since lvm2 is not included in this ISO" >> /usr/lib/initcpio/udev/11-dm-initramfs.rules

# Remove archiso config if it exists
rm -f /etc/mkinitcpio.conf.d/archiso.conf

rm -rf /mkinitcpio
rm -rf cinnamon-configs

#sudo pacman -S updater --noconfirm --overwrite '*'

chown $name:$name /home/$name/.nanorc

# copy the new pacman over full of color!

# setup new pacman with ping home
# no data is collected only perpose of seeing how many users we have no date will be sold or used!

if has_inet; then
    sudo pacman -S pacman --noconfirm --overwrite '*'
else
    echo "No internet connection detected, skipping pacman self-update."
fi

# fix lightdm issue after install

rm -rf /etc/systemd/system/display-manager.service
systemctl enable lightdm.service
systemctl daemon-reload

# updating backbrounds to work correctly setting permissions

chmod 755 /usr/share/backgrounds
find /usr/share/backgrounds -type d -exec chmod 755 {} \;
find /usr/share/backgrounds -type f -exec chmod 644 {} \;

# rm /etc/xdg/autostart/calamares.desktop

# install check for amd network fix.

if has_inet; then
    pacman -S amdnetworkfix --noconfirm
else
    echo "No internet connection detected, skipping amdnetworkfix install."
fi

# schedule initramfs regeneration for first boot via desktop autostart
touch /var/lib/mkinitcpio-firstboot-pending
printf '%%wheel ALL=(root) NOPASSWD: /usr/local/bin/firstboot-initramfs-root.sh\n' > /etc/sudoers.d/firstboot-mkinitcpio
chmod 440 /etc/sudoers.d/firstboot-mkinitcpio

##############################################################################
# Recovery system: give the fresh install Timeshift snapshots from day one so
# users can always roll back via "AcreetionOS Recovery Environment".
# Snapshots are stored on the root filesystem (RSYNC mode) by default; users
# can move them to a dedicated disk later with Timeshift or the recovery tool.
##############################################################################
if command -v timeshift >/dev/null 2>&1; then
    ROOT_UUID=$(findmnt -rno UUID -T / 2>/dev/null | head -n1)
    mkdir -p /etc/timeshift
    if [ ! -f /etc/timeshift/timeshift.json ]; then
        python3 - "$ROOT_UUID" > /etc/timeshift/timeshift.json <<'PY'
import json, sys, os
cfg = {
    "backup_device_uuid": sys.argv[1] if len(sys.argv) > 1 else "",
    "parent_device_uuid": "",
    "do_first_run_snapshots": True,
    "exclude_app_patterns": [],
    "exclude_patterns": [
        "/root/.cache/**", "/home/*/.cache/**", "/home/*/Downloads/**",
        "/home/*/.local/share/Trash/**", "/var/tmp/**", "/var/crash/**"
    ],
    "include_folders_config": [],
    "exclude_restore_targets": [],
    "remove_old_snapshots": True,
    "count_of_daily": 5, "count_of_weekly": 3, "count_of_monthly": 2,
    "count_of_yearly": 1, "stop_cron_emails": True,
    "btrfs_mode": False, "rsync_options": "", "snapshots_full_device_uuid": ""
}
json.dump(cfg, open("/etc/timeshift/timeshift.json", "w"), indent=2)
PY
    fi
fi

exit 0

