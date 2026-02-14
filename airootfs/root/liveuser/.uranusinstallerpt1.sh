#!/usr/bash
echo '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
echo '!                                  Welcome to the Acreetion Installer                              !'
echo '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'

echo 'You can only run this script on Arch Linux or derivatives' \n
\n
echo 'You are going to need to know the name of your drive ie: sda, sdb, etc, for this script to work. You can find it by' \n
echo 'Secure boot and fastboot is not supported by this script! You need to turn it off in your bios!'

## Introduction

read -t 5 -p 'Please check that you are on Arch Linux or an derivative'

## Making sure the user is on the internet
echo 'Checking to see if you are on the Internet'
if ping -c 1 google.com > /dev/null 2>&1; then
  echo "You are connected to the internet."
else
  read -t 5 -p "You are not connected to the internet. You will be putting you into a Utility to connecto the internet"
  nmtui
fi

## Setting time and date
  echo 'You have a choice between the following timezones: Los_Angeles, Chicago, Columbus, New_York'
  read PRINT
  #echo $PRINT 
  printf "%s" "Enter your timezone: "
  
  case $PRINT in 
      Chicago)
         echo 'You set your timezone to Chicago'
         timedatectl set-timezone America/Chicago
        ;;
      New_York)
         echo 'You set your timezone to New York'
         timedatectl set-timezone America/New_York
        ;;
      Colombus)
         echo 'You set your timezone to Colombus'
         timedatectl set-timezone America/Colombus
        ;;
      Los_Angeles)
         echo 'You set your timezone to Los_Angeles'
         timedatectl set-timezone America/Los_Angeles
        ;;
      *)
        #echo $PRINT
        echo -e '\nThis is not a valid timezone. Try again'
        ;;
  esac

## Checking that NetworkManager exists
echo 'Checking that NetworkManager exists and then installing if it is not here'
if  [ pacman -Qq | grep networkmanager > /dev/null ]; then
      echo "NetworkManager is installed"
    else
      echo 'NetworkManager is is not installed, installing NetworkManager'
         pacman -Syyu networkmanager
fi

## Checking that sed exists
echo 'Checking that sed exists and then installing if it is not here'
if  [ pacman -Qq | grep sed > /dev/null ]; then
      echo "sed is installed"
    else
      echo 'sed is is not installed, installing sed'
         pacman -Syyu sed
fi

## Increasing the amount of parallel downloads
echo 'editing the pacman.conf to increase the amount of parallel downloads to 100'
find=5
replace=100
sed "s/$find/$replace/" /etc/pacman.conf

## Checking that curl exists [experimental]
echo 'Checking that curl exists and then installing if it is not here'
if  [ pacman -Qq | grep curl > /dev/null ]; then
      echo "curl is installed"
    else
      echo 'curl is is not installed, installing curl'
         pacman -Syyu curl
fi

## Optimizing mirrors
echo 'Optimizing your mirrors'
echo 'Checking that pacman-contrib is installed, if not, installing it'
if  [ pacman -Qq | grep pacman-contrib > /dev/null ]; then
        read -t 3 -p 'pacman-contrib is installed.' && cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup && sed -i 's/^#Server/Server/' /etc/pacman.d/mirrorlist.backup &&  rankmirrors -n 6 /etc/pacman.d/mirrorlist.backup > /etc/pacman.d/mirrorlist && aria2c -c -j 16 -x 16 -s 16 -k "https://archlinux.org/mirrorlist/?country=FR&country=GB&protocol=https&use_mirror_status=on" | sed -e 's/^#Server/Server/' -e '/^#/d' | rankmirrors -n 5 - &&
          if  [ pacman -Qq | grep reflector > /dev/null ]; then
            echo "reflector is installed"
          else
            echo 'reflector is is not installed, installing relector'
                pacman -Syyu reflector && systemctl enable reflector && reflector
          fi
    else
      echo 'pacman-contrib is not installed, installing pacman-contrib'
         read -t 3 -p 'This is going to take a second, be patient.' && pacman -Syyu pacman-contrib && cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup && sed -i 's/^#Server/Server/' /etc/pacman.d/mirrorlist.backup &&  rankmirrors -n 6 /etc/pacman.d/mirrorlist.backup > /etc/pacman.d/mirrorlist && curl "https://archlinux.org/mirrorlist/?country=FR&country=GB&protocol=https&use_mirror_status=on" | sed -e 's/^#Server/Server/' -e '/^#/d' | rankmirrors -n 5 - &&
          if  [ pacman -Qq | grep > /dev/null ]; then
            echo "reflector is installed"
          else
            echo 'reflector is is not installed, installing relector'
                pacman -Syyu refector && systemctl enable reflector && reflector
          fi
fi

#echo '64 is UEFI and 32 is legacy'
#cat /sys/firmware/efi/fw_platform_size > uefibios.txt
#if [cat uefibios.txt = 64]
#  echo 'You are using a UEFI System. You will need to use GPT.'
#else
#  echo 'You are using legacy. You will need to use MBR'
#fi


# Listing the drives available and giving the user a chance to look at the drive name.  
echo 'Listing the disks on system. Look for the drive you are wanting to use.'
lsblk
read -t 10 -p "Go ahead and look for your drive name."

read -t 10 -p 'Would you like to automatically partiion your disk, or would you manually like to partition your disk with cfdisk? You can enter manual or auto' DISK
if [$DISK = 'auto'] then 
  # The script will look for and nvme drive if not there, it will have the user specific why drive they have. 
  if [fdisk -l = "/dev/nvme0n*"]  then
   read -p "Do you want to wipe Drive /dev/sda?" yn
  1  case $yn in
      yes ) echo 'This will WIPE Your NVME Drive. You have 5 seconds to cancel with Ctrl C.' && sleep 5s && echo 'Wiping Drive' && parted -s /dev/nvme0n* mklabel gpt \
                                                   mkpart primary 34 1000 \
                                                   mkpart primary 1001 30% \
                                                   mkpart primary 30% 100% \
                                                   print \
                                                   echo 'Wiping and Formatting /dev/nvme0n*'
                                                   mkfs.fat -F 32 /dev/nvme0n1p1 && mkfs.ext4 /dev/nvme0n1p2 && mkfs.ext4 /dev/nvme0n1p3 \
                                                   mount /dev/nvme0n1p2 /mnt && mount --mkdir /dev/nvme0n1p1 /mnt/boot && mount /dev/nvme0n1p3 /mnt/home 
                                                        ;;
    
      no ) echo 'Skipping this section'
        ;;
      *) echo 'please say "yes" or "no"' && if [fdisk -l = "/dev/nvme0n*"]  then
                                            read -p "Do you want to wipe Drive /dev/sda?" yn
                                              case $yn in
                                                  yes ) echo 'This will WIPE Your NVME Drive. You have 5 seconds to cancel with Ctrl C.' && sleep 5s && echo 'Wiping Drive' \
                                                   parted -s /dev/nvme0n* mklabel gpt \
                                                   mkpart primary 34 1000 \
                                                   mkpart primary 1001 30% \
                                                   mkpart primary 30% 100% \
                                                   print \
                                                   echo 'Wiping and Formatting /dev/nvme0n*'
                                                   mkfs.fat -F 32 /dev/nvme0n1p1 && mkfs.ext4 /dev/nvme0n1p2 && mkfs.ext4 /dev/nvme0n1p3 \
                                                   mount /dev/nvme0n1p2 /mnt && mount --mkdir /dev/nvme0n1p1 /mnt/boot && mount /dev/nvme0n1p3 /mnt/home 
                                                        ;;
                                                  no )  echo 'Skipping this section'
                                                        ;; 
                                                   *)   break
                                                        ;;
                                              esac
                                              
  elif [fdisk -l != "/dev/nvme0n*"] then

   read -p "What drive are you trying to wipe?" DRIVE
    
    case $DRIVE in

        sda)
          parted -s /dev/sda mklabel gpt \
          mkpart primary 34 1000 \
          mkpart primary 1001 30% \
          mkpart primary 30% 100% \
          set 1 esp on \
          set 1 boot on \ 
          print 
          echo 'Wiping and Formatting /dev/sda'
          mkfs.fat -F 32 /dev/sda1 && mkfs.ext4 /dev/sda2 && mkfs.ext4 /dev/sda 
          mount /dev/sda2 /mnt && mount --mkdir /dev/sda1 /mnt/boot && mount /dev/sda3 /mnt/home
           ;;

        sdb)
          parted -s /dev/sdb mklabel gpt \
          mkpart primary 34 1000 \
          mkpart primary 1001 30% \
          mkpart primary 30% 100% \
          set 1 esp on \
          set 1 boot on \
          print 
          echo 'Wiping and Formatting /dev/sdb'
          mkfs.fat -F 32 /dev/sdb1 && mkfs.ext4 /dev/sdb2 && mkfs.ext4 /dev/sdb3
          mount /dev/sdb2 /mnt && mount --mkdir /dev/sdb1 /mnt/boot && mount /dev/sdb3 /mnt/home

           ;;

        sdc)
          parted -s /dev/sdc mklabel gpt \
          mkpart primary 34 1000 \
          mkpart primary 1001 30% \
          mkpart primary 30% 100% \
          set 1 esp on \
          set 1 boot on \
          print 
          echo 'Wiping and Formatting /dev/sdc'
          mkfs.fat -F 32 /dev/sdc1 && mkfs.ext4 /dev/sdc2 && mkfs.ext4 /dev/sdc3
          mount /dev/sdc2 /mnt && mount --mkdir /dev/sdc1 /mnt/boot && mount /dev/sdc3 /mnt/home

           ;;

        sdd)
          parted -s /dev/sdd mklabel gpt \
          mkpart primary 34 1000 \
          mkpart primary 1001 30% \
          mkpart primary 30% 100% \
          set 1 esp on \
          set 1 boot on \
          print 
          echo 'Wiping and Formatting /dev/sdd'
          mkfs.fat -F 32 /dev/sdd1 && mkfs.ext4 /dev/sdd2 && mkfs.ext4 /dev/sdd3
          mount /dev/sdd2 /mnt && mount --mkdir /dev/sdd1 /mnt/boot && mount /dev/sdd3 /mnt/home

           ;;

        vda)
          parted -s /dev/vda mklabel gpt \
          mkpart primary 34 1000 \
          mkpart primary 1001 30% \
          mkpart primary 30% 100% \
          set 1 esp on \
          set 1 boot on \
          print 
          echo 'Wiping and Formatting /dev/vda'
          mkfs.fat -F 32 /dev/vda1 && mkfs.ext4 /dev/vda2 && mkfs.ext4 /dev/vda3
          mount /dev/vda2 /mnt && mount --mkdir /dev/vda1 /mnt/boot && mount /dev/vda3 /mnt/home

           ;;

        mmcblk0*)
          parted -s /dev/mmcblk0 mklabel gpt \
          mkpart primary 34 1000 \
          mkpart primary 1001 30% \
          mkpart primary 30% 100% \
          set 1 esp on \
          set 1 boot on \
          print 
          echo 'Wiping and formatting /dev/mmcblk*'
          mkfs.fat -F 32 /dev/mmcblk0p1 && mkfs.ext4 /dev/mmcblk0p2 && mkfs.ext4 /dev/mmcblk0p3
          mount /dev/mmcblk0p2 /mnt && mount --mkdir /dev/mmcblk0p1 /mnt/boot && mount /dev/mmcblk0p3 /mnt/home

           ;;
  
        *) echo 'No valid drie.'
           ;;

    esac
 
  else echo 'No Valid Drives Found.'
  fi
else [$DISK = "manual"] then
  cfdisk && echo 'Make sure to make your file systems afterword with mkfs.(filesystem), and then go to the archwiki installation guide found at wiki.archlinux.org/title/Installation_guide'
fi

## Install base packages 
pacstrap -K /mnt base linux-zen linux-firmware uranusinstaller base-devel nano dhcpcd abiword adobe-source-code-pro-fonts adobe-source-sans-fonts adobe-source-serif-fonts alsa-firmware alsa-plugins alsa-utils amd-ucode android-tools android-udev appstream appstream-glib appstream-qt appstream-qt5 arc-gtk-theme arc-icon-theme arc-solid-gtk-theme arch-install-scripts archinstall arch-audit archiso archivetools archlinux-appstream-data archlinux-contrib archlinux-keyring archlinux-wallpaper ardour aria2 aspell audacity axel b43-fwcutter base base-devel bash bash-completion bcachefs-tools bind bison bitwarden blender blueberry bluefish bluez bluez-utils bolt breeze-gtk breeze-icons brltty broadcom-wl #broadwell-wl-dkms btrfs-progs calamares calibre cantarell-fonts cheese chromium cinnamon cinnamon-control-center cinnamon-desktop cinnamon-menus cinnamon-screensaver cinnamon-session cinnamon-settings-daemon cinnamon-translations ckbcomp clamav clamtk clonezilla cloud-init coreutils cpio cryptsetup #cuda #cuda-tools cups cups-browsed cups-filters cups-pdf cups-pk-helper curl curl-rustls darkhttpd darktable dart dbus dbus-docs dbus-glib dbxtool dconf dconf-editor ddgr ddrescue deja-dup deluge-gtk desktop-file-utils device-mapper dhclient dhcpcd dialog diffutils directx-headers discord distrobox dmidecode dmraid dnsmasq docker docker-buildx docker-compose docker-machine docker-scan downgrade dosfstools dracut duf e2fsprogs exfatprogs edk2-shell efibootmgr efitools element-desktop emacs-wayland endeavouros-mirrorlist endeavouros-keyring epiphany espeakup ethtool exfatprogs f2fs-tools fakeroot fastfetch fatresize ffmpeg ffmpegthumbs firewalld freetype2 nemo-terminal file-roller filezilla flatpak flatpak-builder flatpak-docs flatpak-xdg-utils font-manager foot-terminfo fsarchiver fuse2 fuse3 fwupd fwupd-docs fwupd-efi gamemode gcc gcc-libs gdm gedit gedit-plugins gimp gimp-nufraw gimp-plugin-gmic git glances gnome-keyring gnome-screenshot gnome-shell gnu-netcat gpart gparted gpm gptfdisk grml-zsh-config grub grsync gsfonts gst-libav gst-plugin-pipewire gst-plugins-bad gst-plugins-ugly gtk3 gtk4 gtkspell guake guvcview handbrake haveged hdparm hwdata hwdetect hwinfo hyperv ifuse img2pdf inetutils intel-compute-runtime intel-gmmlib intel-graphics-compiler intel-graphics-compiler intel-media-driver intel-ucode intel-undervolt inxi iptables-nft irssi iw iwd jdk17-openjdk jfsutils jre-openjdk jre21-openjdk kitty kitty-terminfo kodi ldns leafpad less lftp libadwaita libadwaita-docs libdvdcss libfido2 libgsf libopenraw libsmbios libusb-compat libva-intel-driver libva-mesa-driver libva-utils libva-vdpau-driver libvirt libvirt-glib linux-atm linux-firmware linux-firmware-marvell linux-zen linux-zen-docs linux-zen-headers livecd-sounds llvm logrotate lsb-release lsscsi lvm2 lynx lz4 man-db man-pages metacity mc mdadm meld memtest86+ memtest86+-efi mesa mesa-utils mesa-vdpau meson mkinitcpio mkinitcpio-archiso mkinitcpio-nfs-utils mlocate modemmanager mtools nano nano-syntax-highlighting nemo-emblems nemo-fileroller nemo-pastebin nemo-preview nemo-python nemo-qml-plugin-configuration nemo-qml-plugin-notifications nemo-seahorse nemo-share networkmanager networkmanager-openconnect networkmanager-openvpn nextcloud nextcloud-app-bookmarks nextcloud-app-calendar nextcloud-app-contacts nextcloud-app-deck nextcloud-app-mail nextcloud-app-news nextcloud-app-notes nextcloud-app-notify_push nextcloud-app-spreed nextcloud-app-tasks nextcloud-client nbd ndisc6 net-tools netctl nfs-utils nftables nilfs-utils nmap noto-fonts noto-fonts-emoji noto-fonts-extra npm nss-mdns ntfs-3g ntp nvidia nvidia-inst nvidia-utils nvme-cli open-iscsi open-vm-tools openconnect openh264 openpgp-card-tools openimagedenoise openssh openssl openvpn os-prober pacman-contrib partclone parted partimage partitionmanager pavucontrol pcsclite pdfgrep perl nemo-image-converter persepolis pipewire pipewire-alsa pipewire-audio pipewire-docs pipewire-ffado pipewire-jack pipewire-pulse pipewire-roc pipewire-session-manager pipewire-v4l2 pipewire-x11-bell pipewire-zeroconf pkgfile podman polkit-gnome poppler-glib power-profiles-daemon ppp pptpclient psensor python-capng python-packaging python-pyqt5 pv qemu-guest-agent rate-mirrors rebuild-detector reflector reflector-simple reiserfsprogs rp-pppoe rsync rnnoise rtkit rxvt-unicode-terminfo screen screengrab sdparm sequoia-sq sg3_utils smartmontools s-nail sof-firmware spice-vdagent squashfs-tools stress-ng sudo sysfsutils syslinux system-config-printer systemd-resolvconf systemd-sysvcompat tcpdump terminus-font testdisk texinfo thermald thunderbird thunderbird-ublock-origin tldr touchegg tmux tpm2-tools tpm2-tss ttf-bitstream-vera ttf-dejavu ttf-liberation ttf-opensans udftools ukui-wallpapers unrar unzip usb_modeswitch usbmuxd usbutils vi vim vkd3d virtualbox-guest-utils vpnc vulkan-intel vulkan-mesa-layers vulkan-radeon vulkan-swrast vulkan-virtio warpinator webrtc-audio-processing welcome which wireless-regdb wireless_tools wireplumber wpa_supplicant wvdial x265 x42-plugins xdg-user-dirs xdg-utils xed xf86-input-libinput xf86-video-amdgpu xf86-video-ati xf86-video-intel xf86-video-qxl xf86-input-vmmouse xf86-video-vmware xfsprogs xl2tpd xorg-server xorg-xdpyinfo xorg-xinit xorg-xinput xorg-xkill xorg-xrandr xorg-xwayland xz yay zsh

## Generate Fstab
mkdir /mnt/etc && genfstab -U /mnt >> /mnt/etc/fstab

## Chroot into Arch FS
arch-chroot /mnt /usr/bin/uranusinstallerpt2

##############################################################################################################

#######################################################################################################################

## Remind the user to not have Secure boot or fastboot enabled.
read -t 5 -p 'Remember that Secure boot and fastboot is not supported by this script! You need to turn it off in your BIOS/UEFI!'

## Unmounting and Rebooting while telling the user.
read -t 5 -p "Getting ready to reboot you into your environment."
cd / && umount -R /mnt && reboot

