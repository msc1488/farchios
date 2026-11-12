#!/usr/bin/env bash
# shellcheck disable=SC2034
#
# FarchiOs — archiso profile definition
# Документация: https://wiki.archlinux.org/title/Archiso
#

iso_name="farchios"
iso_label="FARCHIOS_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"
iso_publisher="FarchiOs Project <https://farchios.dev>"
iso_application="FarchiOs — Live / Gaming / Install"
iso_version="$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y.%m.%d)"
install_dir="arch"
buildmodes=('iso')

# BIOS + UEFI. systemd-boot выбран вместо GRUB для UEFI: быстрее и проще.
bootmodes=('bios.syslinux' 'uefi.systemd-boot')

pacman_conf="pacman.conf"
airootfs_image_type="squashfs"

# xz + bcj x86 даёт хороший компромисс «размер/распаковка» для игрового ISO.
airootfs_image_tool_options=('-comp' 'xz' '-Xbcj' 'x86' '-b' '1M' '-Xdict-size' '1M')

bootstrap_tarball_compression=('zstd' '-c' '-T0' '--auto-threads=logical' '--long' '-19')

file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/etc/gshadow"]="0:0:400"
  ["/root"]="0:0:750"
  ["/root/.automated_script.sh"]="0:0:755"
  ["/root/customize_airootfs.sh"]="0:0:755"
  ["/usr/local/bin/farchios"]="0:0:755"
  ["/usr/local/bin/farchios-firstboot"]="0:0:755"
  ["/usr/local/bin/farchios-postinstall"]="0:0:755"
  ["/usr/local/bin/farchios-gpu-setup"]="0:0:755"
)
