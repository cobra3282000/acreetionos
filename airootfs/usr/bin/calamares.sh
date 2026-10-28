#!/bin/bash
# Connect to Wi-Fi if needed before starting installer
wifi-connection

# Ensure we have the latest mkinitcpio config for the live system
cp /mkinitcpio/mkinitcpio.conf /etc/mkinitcpio.conf
# Don't copy archiso.conf - Calamares will read from it and copy archiso hooks to installed system
# cp /mkinitcpio/archiso.conf /etc/mkinitcpio.conf.d/archiso.conf

# Refresh keyring and pacman, then make sure pacman itself and Calamares config are up to date
sudo pacman-key --init
sudo pacman -Syy
sudo pacman -S pacman --noconfirm --overwrite '*'
sudo pacman -S calamares-config --noconfirm --overwrite '*'

# Launch Calamares with debug output to /root/calamares.log
calamares -d 8 > /root/calamares.log
