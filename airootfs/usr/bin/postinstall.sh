#!/bin/bash -e

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

echo "Starting AcreetionOS post-installation configuration..."

name=$(ls -1 /home)
echo "Configuring system for user: $name"

echo "Creating user configuration directories..."
mkdir -p /home/$name/.config
mkdir -p /home/$name/.config/nemo
mkdir -p /home/$name/.local/share/cinnamon/extensions

echo "Copying Cinnamon desktop configuration..."
cp -r /cinnamon-configs/cinnamon-stuff/.config/* /home/$name/.config/

echo "Setting up autostart applications..."
mkdir -p /home/$name/.config/autostart
cp -r /cinnamon-configs/dd.desktop /home/$name/.config/autostart

echo "Setting file ownership for user configuration..."
chown -R $name:$name /home/$name/.config
chown -R $name:$name /middle.png

echo "Copying shell and system configuration files..."
cp -r /cinnamon-configs/.bashrc /home/$name/.bashrc
cp -r /cinnamon-configs/.bashrc /root
cp -r /cinnamon-configs/AcreetionOS.txt /root
cp -r /cinnamon-configs/AcreetionOS.txt /home/$name/AcreetionOS.txt

echo "Configuring system DNS and file attributes..."
mv /resolv.conf /etc/resolv.conf
chattr +i /etc/resolv.conf
chattr +i /etc/os-release

echo "Copying AcreetionOS documentation..."
cp /cinnamon-configs/AcreetionOS.txt /home/$name/

echo "Setting up system backgrounds..."
mkdir -p /usr/share/backgrounds
cp -r /backgrounds /usr/share/backgrounds
rm -rf /backgrounds

echo "Configuring sudo password feedback..."
echo "Defaults pwfeedback" | sudo EDITOR='tee -a' visudo >/dev/null 2>&1

echo "Updating system configuration files..."
cp /mkinitcpio/mkinitcpio.conf /etc/mkinitcpio.conf
# Don't copy archiso.conf - it's only for the live ISO
# cp /mkinitcpio/archiso.conf /etc/mkinitcpio.conf.d/archiso.conf
cp /cinnamon-configs/.nanorc /home/$name/.nanorc

# Create placeholder dm-initramfs.rules for archiso hook compatibility
mkdir -p /usr/lib/initcpio/udev
echo "# Placeholder file for archiso hook compatibility" > /usr/lib/initcpio/udev/11-dm-initramfs.rules
echo "# dm-initramfs rules not needed since lvm2 is not included in this ISO" >> /usr/lib/initcpio/udev/11-dm-initramfs.rules

# Remove archiso config if it exists
rm -f /etc/mkinitcpio.conf.d/archiso.conf

echo "Cleaning up temporary files..."
rm -rf /mkinitcpio
rm -rf cinnamon-configs

echo "AcreetionOS post-installation configuration completed successfully!"
