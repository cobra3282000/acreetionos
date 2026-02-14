
wifi-connection

cp /mkinitcpio/mkinitcpio.conf /etc/mkinitcpio.conf
# Don't copy archiso.conf - Calamares will read from it and copy archiso hooks to installed system
# cp /mkinitcpio/archiso.conf /etc/mkinitcpio.conf.d/archiso.conf

pacman -Sy 

sudo pacman -S calamares-config --noconfirm --overwrite '*'

calamares -d 8 > /root/calamares.log


