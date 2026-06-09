#!/bin/bash
[ -f /var/lib/mkinitcpio-firstboot-pending ] || exit 0

(
    sudo /usr/local/bin/firstboot-initramfs-root.sh
    echo "100"
) | zenity \
    --progress \
    --title="AcreetionOS - First Boot Setup" \
    --text="Configuring network drivers for your hardware.\n\nThis may take up to 60 seconds, please wait..." \
    --pulsate \
    --auto-close \
    --no-cancel \
    --width=450

zenity \
    --info \
    --title="First Boot Setup Complete" \
    --text="Network drivers have been configured successfully.\n\nYour system will reboot in 10 seconds." \
    --no-wrap \
    --timeout=10 \
    --width=350

systemctl reboot
