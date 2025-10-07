#!/usr/bin/env bash
# shellcheck disable=SC2034

iso_name="AcreetionOS"
iso_label="acreetionOS_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"
iso_publisher="Acreetion OS"
iso_application="Acreetion OS Install Media"
iso_version="1.0"
install_dir="arch"
buildmodes=('iso')
bootmodes=('bios.syslinux'
           'uefi.grub')
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'xz' '-Xbcj' 'x86' '-b' '1M' '-Xdict-size' '1M')
bootstrap_tarball_compression=('zstd' '-c' '-T0' '--auto-threads=logical' '--long' '-19')
file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/etc/gshadow"]="0:0:400"
  ["/root"]="0:0:750"
  ["/root/.automated_script.sh"]="0:0:755"
  ["/root/.gnupg"]="0:0:700"
  ["/usr/local/bin/choose-mirror"]="0:0:755"
  ["/usr/local/bin/Installation_guide"]="0:0:755"
  ["/usr/local/bin/livecd-sound"]="0:0:755"
  ["/usr/bin/calamares"]="0:0:755"
#  ["/usr/lib/calamares/modules/*"]="0:0:755"
  ["/root/cinstall"]="0:0:755"
  ["/root/cinstall2"]="0:0:755"
  ["/root/zone"]="0:0:755"
  ["/usr/bin/fixkeys.sh"]="0:0:755"
  ["/usr/bin/dd.sh"]="0:0:755"
  ["/usr/local/bin/postinstall.sh"]="0:0:755"
  ["/usr/bin/calamares.sh"]="0:0:755"
  ["/usr/local/bin/preinstall"]="0:0:755"
  ["/usr/local/bin/stormos-final"]="0:0:755"
  ["/usr/bin/wifi-connection.sh"]="0:0:755"
)
