#!/usr/bin/env bash
#
# This is based on the pre-install script:  
# https://github.com/bcachet/ansible-arch-dell-xps13
# Every time I install Arch, I keep thinking I should
# have a script for this point. Searching for an Ansible
# setup to use as a template got me this info.

VOLUME_NAME="xps"
HOST_NAME="xps13"
MEM_SIZE=16
SWAP_SIZE=2
DEVICE="/dev/nvme0n1"
MAPPING_NAME="xlvm"
# KEYMAP=us
FONT="sun12x22"
COUNTRY="CA"

# Configure
setfont ${FONT}
#loadkeys ${KEYMAP}

# We need network access to get the script, but this should be done already
#wifi-menu

timedatectl set-ntp true

# Prepare disk
echo "Erasing any eristing partitions..."
wipefs -a /dev/${DEVICE}

echo "Partitioning..."
## Partition
parted --script ${DEVICE} \
       mklabel gpt \
       mkpart ESP fat32 1MiB 513MiB \
       set 1 boot on \
       mkpart primary ext4 514MiB 100%

echo "Setting up disk encryption..."
## Encryption with LUKS
cryptsetup luksFormat ${DEVICE}p2
cryptsetup open ${DEVICE}p2 ${MAPPING_NAME}

echo "LVM creation..."
## LVM
pvcreate /dev/mapper/${MAPPING_NAME}
vgcreate ${VOLUME_NAME} /dev/mapper/${MAPPING_NAME}
lvcreate -L 100G ${VOLUME_NAME} -n root
lvcreate -L ${SWAP_SIZE}G ${VOLUME_NAME} -n swap
lvcreate -l 100%FREE ${VOLUME_NAME} -n home

echo "Formatting partitions..."
## Format
mkfs.fat -F32 /dev/nvme0n1p1
mkfs.ext4 /dev/mapper/${VOLUME_NAME}-root
mkfs.ext4 /dev/mapper/${VOLUME_NAME}-home
mkswap /dev/mapper/${VOLUME_NAME}-swap

echo "Mounting partitions..."
## Mount
## Changed from original
mount /dev/mapper/${VOLUME_NAME}-root /mnt
mkdir -p /mnt/{home,boot}
mount /dev/mapper/${VOLUME_NAME}-home /mnt/home
mount /dev/nvme0n1p1 /mnt/boot
swapon /dev/mapper/${VOLUME_NAME}-swap
echo "Displaying mount points..."
df -h
echo "All good?"
read 

# Installing base system

echo "Retrieving mirrors for ${COUNTRY}..."
## Generating mirrorlist
curl "https://www.archlinux.org/mirrorlist/?country=${COUNTRY}&protocol=https&ip_version=4&use_mirror_status=on" | sed -e 's/#Server/Server/g' > /etc/pacman.d/mirrorlist

echo "Pacstrapping system..."
## Install base + NetworkManager
pacstrap -i /mnt \
         base \
         base-devel \
         net-tools \
         dialog \
         wpa_supplicant \
         dhclient

# Configuring installation
echo "Creating fstab..."
genfstab -L /mnt >> /mnt/etc/fstab
echo "Chrooting to new system..."
arch-chroot /mnt

## Locale

echo "en_US.UTF-8" >> /etc/locale.gen
locale-gen
echo LANG=en_US.UTF-8 > /etc/locale.conf

## Timezone
echo "Setting timezone..."
ln -s -f /usr/share/zoneinfo/Canada/Eastern /etc/localtime
hwclock --systohc --utc

echo "Enabling DHCP client..."
systemctl enable dhcpd.service

## vconsole

echo FONT=${FONT} > /etc/vconsole.conf
echo KEYMAP=${KEYMAP} >> /etc/vconsole.conf

## Hostname

echo ${HOST_NAME} > /etc/hostname
echo "127.0.1.1 ${HOST_NAME}.localdomain ${HOST_NAME}" >> /etc/hosts

## Enable services

systemctl enable NetworkManager
systemctl enable dhcpd

## mkinitcpio (generate initramfs)

sed -i 's/^HOOKS=.*/HOOKS="base systemd autodetect keyboard sd-vconsole modconf block sd-encrypt sd-lvm2 filesystems fsck"'
mkinitcpio -p linux

## Bootloader

bootctl install --path=/boot

cat > /boot/loader/loader.conf <<EOL
timeout 10
default arch
editor 1
EOL

UUID=cryptsetup luksUUID /dev/nvme0n1p2
cat > /boot/loader/entries/arch.conf <<EOL
title Arch Linux
linux /vmlinuz-linux
initrd /intel-ucode.img
initrd /initramfs-linux.img
options rd.luks.uuid=${UUID} rd.luks.name=${UUID}=${MAPPING_NAME} root=/dev/mapper/${VOLUME_NAME}-root rw resume=/dev/mapper/${VOLUME_NAME}-swap ro intel_iommu=igfx_off
EOL

# Ansible

pacman -Sy ansible \
       git

# Reboot

exit
umount -R /mnt
reboot
