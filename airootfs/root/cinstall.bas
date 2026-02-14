$ScreenHide
$Console
_Dest _Console

Cls

Print
Print "Updating Pacman!"
Shell "pacman -Syy > null"
Print "done.."

Cls

Rem Declear Variables.


Dim drv$(500), drive$(100), zone$(1000), timezone$(25), dr$(25), part$(25)

Cls

Rem ChDir "/root/"

Print "Welcome to Acreetion OS!"
Print
Print "Written By: Darren W. Clift"
Print "            Johnathan Spiva"
Print
Print "Copyright (c) 2024"
Print

Rem gather user info


er1:

Rem gather partitios and drive info and break it up in to its variables

Shell "lsblk -Sr > temp.txt"

Open "i", #1, "temp.txt"

Rem Line Input #1, whatever$


tt = 0

While Not EOF(1)

    tt = tt + 1
    Line Input #1, dr$(tt)

Wend

Close #1

Rem break up into variables

For lp2 = 1 To tt

    drv$(lp2) = Mid$(dr$(lp2), 1, 3)
    drv2$(lp2) = dr$(lp2)

Next lp2

Shell "lsblk -Nr > temp.txt"

Open "i", #1, "temp.txt"

Rem Line Input #1, whatever$


tt = 0

While Not EOF(1)

    tt = tt + 1
    Line Input #1, dr$(tt)

Wend

Close #1

lp2 = lp2 - 1


For t = 1 To tt

    drv$(t + lp2) = Left$(dr$(t), 7)
    drv2$(t + lp2) = dr$(t)
Next t

total = lp2 + t - 1

Shell "rm temp.txt"

loop99:

Cls

Print "Choose Drive to install Acreetion OS on"
Print "**WARNING**: All Data On drive will be destroyed!"
Print "Including windows!!!!"
Print
Print

For xx = 1 To total

    Print Str$(xx) + "- " + drv2$(xx)

Next xx

Print

Do While se < 1 Or se > total

    Line Input "Which Drive: ", aa$
    se = Val(aa$)

Loop

dv$ = drv$(se)
 
Print
Do While ii$ = ""
    Line Input "Type Full Yes or No!   Are you 100 percent Sure? (Yes/No): ", ii$
Loop

ii$ = LCase$(ii$)

If ii$ = "no" Then
    ii$ = ""
    GoTo loop99
End If



Rem set up partitions.

aa$ = ""

Do While aa$ = ""

    Print
    Line Input "Do you want your home director in root? (Yes/No): ", aa$

Loop

aa$ = LCase$(aa$)

If aa$ = "y" Or aa$ = "yes" Then
    homepart$ = "y"
    path$ = "parted -s /dev/" + dv$ + " mklabel gpt mkpart primary 34 1000 mkpart primary 1001 100%"
End If

If aa$ = "n" Or aa$ = "no" Then

    homepart$ = "n"
    path$ = "parted -s /dev/" + dv$ + " mklabel gpt mkpart primary 34 1000 mkpart primary 1001 30% mkpart primary 30% 100%"

End If

Print

Rem create partitions and wipe disk.

ptname$ = "AcreetionOS"

Print
Print "Creating Partion now!"
Print path$
Shell path$
Print "Done."
Print
Print "Formating Partion EUFI"
path$ = "mkfs.fat -F 32 /dev/" + dv$ + "1 > null"
Print path$
Shell path$
Print "Done."
Print "Format Partion 2"
path$ = "mkfs.ext4 -F /dev/" + dv$ + "2 > null"
Shell path$
Print "done."

If homepart$ = "n" Then
    Print "Formating Partion Home"
    path$ = "mkfs.ext4 -F /dev/" + dv$ + "3 > null"
    Shell path$
    Print "Done."
End If

Rem Install base system

path3$ = "mount --mkdir /dev/" + dv$ + "2 /mnt/"
Print path3$
Shell path3$
path4$ = "mount --mkdir /dev/" + dv$ + "1 /mnt/boot"
Print path4$
Shell path4$
If homepart$ = "n" Then

    path5$ = "mount --mkdir /dev/" + dv$ + "3 /mnt/home"
    Print path5$
    Shell path5$

End If

Shell "mkdir /mnt/usr/bin/"
Shell "cp /usr/bin/zone /mnt/usr/bin/"


path2$ = "pacstrap -K /mnt base linux-zen linux-firmware uranusinstaller base-devel nano dhcpcd abiword adobe-source-code-pro-fonts adobe-source-sans-fonts adobe-source-serif-fonts alsa-firmware alsa-plugins alsa-utils amd-ucode android-tools android-udev appstream appstream-glib appstream-qt appstream-qt5 arc-gtk-theme arc-icon-theme arc-solid-gtk-theme arch-install-scripts archinstall arch-audit archiso archivetools archlinux-appstream-data archlinux-contrib archlinux-keyring archlinux-wallpaper ardour aria2 aspell audacity axel b43-fwcutter base base-devel bash bash-completion bcachefs-tools bind bison bitwarden blender blueberry bluefish bluez bluez-utils bolt breeze-gtk breeze-icons brltty broadcom-wl #broadwell-wl-dkms btrfs-progs calamares calibre cantarell-fonts cheese chromium cinnamon cinnamon-control-center cinnamon-desktop cinnamon-menus cinnamon-screensaver cinnamon-session cinnamon-settings-daemon cinnamon-translations ckbcomp clamav clamtk clonezilla cloud-init coreutils cpio cryptsetup #cuda #cuda-tools cups cups-browsed cups-filters cups-pdf cups-pk-helper curl curl-rustls darkhttpd darktable dart dbus dbus-docs dbus-glib dbxtool dconf dconf-editor ddgr ddrescue deja-dup deluge-gtk desktop-file-utils device-mapper dhclient dhcpcd dialog diffutils directx-headers discord distrobox dmidecode dmraid dnsmasq docker docker-buildx docker-compose docker-machine docker-scan downgrade dosfstools dracut duf e2fsprogs exfatprogs edk2-shell efibootmgr efitools element-desktop emacs-wayland endeavouros-mirrorlist endeavouros-keyring epiphany espeakup ethtool exfatprogs f2fs-tools fakeroot fastfetch fatresize ffmpeg ffmpegthumbs firewalld freetype2 nemo-terminal file-roller filezilla flatpak flatpak-builder flatpak-docs flatpak-xdg-utils font-manager foot-terminfo fsarchiver fuse2 fuse3 fwupd fwupd-docs fwupd-efi gamemode gcc gcc-libs gdm gedit gedit-plugins gimp gimp-nufraw gimp-plugin-gmic git glances gnome-keyring gnome-screenshot gnome-shell gnu-netcat gpart gparted gpm gptfdisk grml-zsh-config grub grsync gsfonts gst-libav gst-plugin-pipewire gst-plugins-bad gst-plugins-ugly gtk3 gtk4 gtkspell guake guvcview handbrake haveged hdparm hwdata hwdetect hwinfo hyperv ifuse img2pdf inetutils intel-compute-runtime intel-gmmlib intel-graphics-compiler intel-graphics-compiler intel-media-driver intel-ucode intel-undervolt inxi iptables-nft irssi iw iwd jdk17-openjdk jfsutils jre-openjdk jre21-openjdk kitty kitty-terminfo kodi ldns leafpad less lftp libadwaita libadwaita-docs libdvdcss libfido2 libgsf libopenraw libsmbios libusb-compat libva-intel-driver libva-mesa-driver libva-utils libva-vdpau-driver libvirt libvirt-glib linux-atm linux-firmware linux-firmware-marvell linux-zen linux-zen-docs linux-zen-headers livecd-sounds llvm logrotate lsb-release lsscsi lvm2 lynx lz4 man-db man-pages metacity mc mdadm meld memtest86+ memtest86+-efi mesa mesa-utils mesa-vdpau meson mkinitcpio mkinitcpio-archiso mkinitcpio-nfs-utils mlocate modemmanager mtools nano nano-syntax-highlighting nemo-emblems nemo-fileroller nemo-pastebin nemo-preview nemo-python nemo-qml-plugin-configuration nemo-qml-plugin-notifications nemo-seahorse nemo-share networkmanager networkmanager-openconnect networkmanager-openvpn nextcloud nextcloud-app-bookmarks nextcloud-app-calendar nextcloud-app-contacts nextcloud-app-deck nextcloud-app-mail nextcloud-app-news nextcloud-app-notes nextcloud-app-notify_push nextcloud-app-spreed nextcloud-app-tasks nextcloud-client nbd ndisc6 net-tools netctl nfs-utils nftables nilfs-utils nmap noto-fonts noto-fonts-emoji noto-fonts-extra npm nss-mdns ntfs-3g ntp nvidia nvidia-inst nvidia-utils nvme-cli open-iscsi open-vm-tools openconnect openh264 openpgp-card-tools openimagedenoise openssh openssl openvpn os-prober pacman-contrib partclone parted partimage partitionmanager pavucontrol pcsclite pdfgrep perl nemo-image-converter persepolis pipewire pipewire-alsa pipewire-audio pipewire-docs pipewire-ffado pipewire-jack pipewire-pulse pipewire-roc pipewire-session-manager pipewire-v4l2 pipewire-x11-bell pipewire-zeroconf pkgfile podman polkit-gnome poppler-glib power-profiles-daemon ppp pptpclient psensor python-capng python-packaging python-pyqt5 pv qemu-guest-agent rate-mirrors rebuild-detector reflector reflector-simple reiserfsprogs rp-pppoe rsync rnnoise rtkit rxvt-unicode-terminfo screen screengrab sdparm sequoia-sq sg3_utils smartmontools s-nail sof-firmware spice-vdagent squashfs-tools stress-ng sudo sysfsutils syslinux system-config-printer systemd-resolvconf systemd-sysvcompat tcpdump terminus-font testdisk texinfo thermald thunderbird thunderbird-ublock-origin tldr touchegg tmux tpm2-tools tpm2-tss ttf-bitstream-vera ttf-dejavu ttf-liberation ttf-opensans udftools ukui-wallpapers unrar unzip usb_modeswitch usbmuxd usbutils vi vim vkd3d virtualbox-guest-utils vpnc vulkan-intel vulkan-mesa-layers vulkan-radeon vulkan-swrast vulkan-virtio warpinator webrtc-audio-processing welcome which wireless-regdb wireless_tools wireplumber wpa_supplicant wvdial x265 x42-plugins xdg-user-dirs xdg-utils xed xf86-input-libinput xf86-video-amdgpu xf86-video-ati xf86-video-intel xf86-video-qxl xf86-input-vmmouse xf86-video-vmware xfsprogs xl2tpd xorg-server xorg-xdpyinfo xorg-xinit xorg-xinput xorg-xkill xorg-xrandr xorg-xwayland xz yay zsh"

Shell path2$

Rem make fstab file!

Shell "mkdir /mnt/etc/"
Shell "genfstab -U /mnt/"

Shell "cp /root/cinstall2 /mnt/usr/bin/cinstall2"
Shell "chmod +x /mnt/user/bin/cinstall2"

Shell "arch-chroot /mnt/ /usr/bin/cinstall2"

Print
Print "still in chroot"
End



