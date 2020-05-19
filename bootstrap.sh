#!/bin/sh
#
# WARNING: this script will destroy data on the selected disk.
#
# Set font:
#
#   $ setfont sun12x22
#
# Set keyboard layout:
#
#   $ loadkeys dk
#
# Connect to wifi:
#
#   $ rfkill unblock wlan
#   $ ip address # note wifi interface, e.g. wlp3s0
#   $ cat <<EOF > wpa_supplicant.conf
#     network={
#       ssid="<My-SSID>"
#       key_mgmt=WPA-PSK
#       psk="<SSID-pass>"
#     }
#     EOF	
#   $ wpa_supplicant -c wpa_supplicant.conf -i <interface> -B
#   $ dhclient -v <interface>
#   $ ping -c 3 gnu.org # test connection
#
# Execute this script:
#
#   $ guix install curl
#   $ curl -sL https://git.io/Jfu61 -o bootstrap.sh
#   $ chmod +x boostrap.sh
#   $ ./boostrap.sh <password> <password>
#
# @@@@@@@ WHEN DONE:
#
# Log in as passwordless root, then use `passwd` to set a 
# password for the root account and the user account.
#
# When done, reboot

if [ -z "$1" ] || [ -z "$2" ];
then
	echo "Must provide password arguments, exiting."
	exit 1
fi

if [ "$1" != "$2" ];
then
	echo "Passwords did not match, exiting."
	exit 1
fi

password="$1"

set -uo pipefail
trap 's=$?; echo "$0: Error on line "$LINENO": $BASH_COMMAND"; exit $s' ERR

curl -sL https://git.io/JfuIH -o config.scm
curl -sL https://git.io/JfuIS -o channels.scm

### Set up logging ###
#exec 1> >(tee "stdout.log")
#exec 2> >(tee "stderr.log")

### Setup the disk and partitions ###
device="/dev/sda"
boot_size=538
swap_multiplier=2
mem_size=$(free --mebi | awk '/Mem:/ {print $2}')
swap_size=$(($mem_size * $swap_multiplier))
boot_end=$(( $boot_size + 1 ))MiB

parted --script "${device}" -- mklabel gpt \
  mkpart ESP fat32 1Mib ${boot_size}MiB \
  set 1 boot on \
  mkpart primary ext4 $boot_end 100%

part_boot="${device}1"
part_root="${device}2"

wipefs "${part_boot}"
wipefs "${part_root}"

echo -n "$password" | cryptsetup luksFormat $part_root -
echo -n "$password" | cryptsetup open --type luks $part_root cryptroot -
mkfs.ext4 -L cryptroot /dev/mapper/cryptroot

mount LABEL=cryptroot /mnt

dd if=/dev/zero of=/mnt/swapfile bs=1MiB count=$swap_size status=progress
chmod 600 /mnt/swapfile
mkswap /mnt/swapfile
swapon /mnt/swapfile

mkfs.vfat -F32 $part_boot
mkdir -p /mnt/boot/efi
mount $part_boot /mnt/boot/efi

herd start cow-store /mnt

cp config.scm /etc/config.scm
cp channels.scm /etc/guix/channels.scm

mkdir -p /mnt/etc/guix
cp config.scm /mnt/etc/config.scm
cp channels.scm /mnt/etc/guix/channels.scm

guix pull
hash -r

guix system init /mnt/etc/config.scm /mnt

reboot
