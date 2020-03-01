#!/bin/bash
## WARNING: this script will destroy data on the selected disk.
##
## While I was looking for a better script, I ran across this one
## from: https://disconnected.systems/blog/archlinux-installer/#other-useful-bits
## It is easier to follow than the other one and seems to be better written.
## 
## I'm using the git.io URL shortner to make this easier to copy. Realistically,
## this is a terrible security issue to arbitrarilly take a shortened URL and
## pipe it through bash. The author of the original script did it this way:
##   curl -sL https://git.io/vAoV8 | bash
##
## While I'm up for a little risk, this is not quite what I had in mind. A
## slightly saner method:
##   curl -sL https://git.io/JeaYz > xps-setup.sh
## Examine the file you doenloaded for malicious entries and if happy, run it 
## with bash
##   bash xps-setup.sh
##

set -uo pipefail
trap 's=$?; echo "$0: Error on line "$LINENO": $BASH_COMMAND"; exit $s' ERR

MIRRORLIST_URL="https://www.archlinux.org/mirrorlist/?country=CA&protocol=https&use_mirror_status=on"

pacman -Sy --noconfirm pacman-contrib

echo "Updating mirror list"
curl -s "$MIRRORLIST_URL" | \
    sed -e 's/^#Server/Server/' -e '/^#/d' | \
    rankmirrors -n 5 - > /etc/pacman.d/mirrorlist

### Get infomation from user ###
hostname=$(dialog --stdout --inputbox "Enter hostname" 0 0) || exit 1
clear
: ${hostname:?"hostname cannot be empty"}

user=$(dialog --stdout --inputbox "Enter admin username" 0 0) || exit 1
clear
: ${user:?"user cannot be empty"}

password=$(dialog --stdout --passwordbox "Enter admin password" 0 0) || exit 1
clear
: ${password:?"password cannot be empty"}
password2=$(dialog --stdout --passwordbox "Enter admin password again" 0 0) || exit 1
clear
[[ "$password" == "$password2" ]] || ( echo "Passwords did not match"; exit 1; )

devicelist=$(lsblk -dplnx size -o name,size | grep -Ev "boot|rpmb|loop" | tac)
device=$(dialog --stdout --menu "Select installtion disk" 0 0 0 ${devicelist}) || exit 1
clear

### Set up logging ###
exec 1> >(tee "stdout.log")
exec 2> >(tee "stderr.log")

timedatectl set-ntp true

### Setup the disk and partitions ###
swap_size=$(free --mebi | awk '/Mem:/ {print $2}')
swap_end=$(( $swap_size + 129 + 1 ))MiB

parted --script "${device}" -- mklabel gpt \
  mkpart ESP fat32 1Mib 129MiB \
  set 1 boot on \
  mkpart primary linux-swap 129MiB ${swap_end} \
  mkpart primary ext4 ${swap_end} 100%

# Simple globbing was not enough as on one device I needed to match /dev/mmcblk0p1 
# but not /dev/mmcblk0boot1 while being able to match /dev/sda1 on other devices.
part_boot="$(ls ${device}* | grep -E "^${device}p?1$")"
part_swap="$(ls ${device}* | grep -E "^${device}p?2$")"
part_root="$(ls ${device}* | grep -E "^${device}p?3$")"

wipefs "${part_boot}"
wipefs "${part_swap}"
wipefs "${part_root}"

mkfs.vfat -F32 "${part_boot}"
mkswap "${part_swap}"
mkfs.f2fs -f "${part_root}"

swapon "${part_swap}"
mount "${part_root}" /mnt
mkdir /mnt/boot
mount "${part_boot}" /mnt/boot

pacstrap /mnt \
         base \
         base-devel \
         f2fs-tools \
         iw \
         dialog \
         wpa_supplicant \
         dhcpcd \
         dhclient \
         net-tools \
         linux \
         linux-firmware \
         git \
         netctl \
         vim \
         zsh

genfstab -t PARTUUID /mnt >> /mnt/etc/fstab
echo "${hostname}" > /mnt/etc/hostname

arch-chroot /mnt bootctl install

cat <<EOF > /mnt/boot/loader/loader.conf
default arch
EOF

cat <<EOF > /mnt/boot/loader/entries/arch.conf
title    Arch Linux
linux    /vmlinuz-linux
initrd   /initramfs-linux.img
options  root=PARTUUID=$(blkid -s PARTUUID -o value "$part_root") rw video=1024x768
EOF

# make some changes in the new system

arch-chroot /mnt << "END"

# Locale configuration
localectl set-locale en_US-UTF-8
localectl set-keymap us

## Timezone
ln -sf /usr/share/zoneinfo/Canada/Eastern /etc/localtime
hwclock --systohc --utc

# Generate the new kernel
pacman -S --noconfirm linux linux-firmware

# Get an address after booting
systemctl enable dhcpcd.service

# Enable the wheel group for sudo
LINE=$(grep -n %wheel /etc/sudoers | grep -v NOPASSWD | awk -F: '{ print $1}')
sed -i "${LINE}s/^# //" /etc/sudoers

# Set the password for root and the first user you created.
echo "${user}:${password}" | chpasswd
echo "root:${password}" | chpasswd

# Disable "predictable" naming for interfaces
ln -s /dev/null /etc/udev/rules.d/80-net-setup-link.rules

# set zsh for user and root
useradd -mU -s /usr/bin/zsh -G wheel,uucp,video,audio,storage,games,input "$user"
chsh -s /usr/bin/zsh

### vconsole - necessary?
echo "FONT=sun12x22" > /mnt/etc/vconsole.conf
echo "KEYMAP=us" >> /mnt/etc/vconsole.conf

END

#### vconsole - necessary?
#echo "FONT=sun12x22" > /mnt/etc/vconsole.conf
#echo "KEYMAP=us" >> /mnt/etc/vconsole.conf

#arch-chroot /mnt useradd -mU -s /usr/bin/zsh -G wheel,uucp,video,audio,storage,games,input "$user"
#arch-chroot /mnt chsh -s /usr/bin/zsh

## Enable the wheel group for sudo
#LINE=$(grep -n %wheel /mnt/etc/sudoers | grep -v NOPASSWD | awk -F: '{ print $1}')
#sed -i "${LINE}s/^# //" /mnt/etc/sudoers

# stack smashing error when I did this recently, odd...
## Set the password for root and the first user you created.
#echo "${user}:${password}" | chpasswd --root /mnt
#echo "root:${password}" | chpasswd --root /mnt
