dconf load /org/cinnamon/ < /cinnamon.dconf
dconf load /org/gnome/terminal/ < /terminal-settings

cp /usr/bin/pacman2 /usr/bin/pacman

rm $HOME/.config/autostart/dd.desktop
cp /cinnamon-configs/.bashrc /root

