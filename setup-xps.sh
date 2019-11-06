#!/usr/bin/env bash
#
# This is based on the pre-install script:  
# https://github.com/bcachet/ansible-arch-dell-xps13
# Every time I install Arch, I keep thinking I should
# have a script for this point. Searching for an Ansible
# setup to use as a template got me this info.
#
# I have removed a few items just to make it easy to do and
# simplify the process. The original used the logical volume 
# manager and an encrypted 
# filesystem. We would have to mess around with the 
# modules and regenerate the initramfs to support it. You
# can look at the reference script to see how that is set up.
#

VOLUME_NAME="xps"
HOST_NAME="xps13"
MEM_SIZE=16
SWAP_SIZE=2
DEVICE="/dev/nvme0n1"
MAPPING_NAME="root"
KEYMAP=us
FONT="sun12x22"
COUNTRY="CA"

# Configure
setfont ${FONT}
#loadkeys ${KEYMAP}

# We need network access to get the script, but this should be done already
#wifi-menu

timedatectl set-ntp true

# Prepare disk
echo "Erasing any existing partitions..."
wipefs -a /dev/${DEVICE} 2>&1 

echo "Partitioning..."
## Partition
parted --script ${DEVICE} \
       mklabel gpt \
       mkpart ESP fat32 1MiB 513MiB \
       mkpart primary swap 514Mib 2561MiB \
       mkpart primary ext4 514MiB 100% \
       set 1 boot on
       
#echo "Setting up disk encryption..."
## Encryption with LUKS
#cryptsetup luksFormat ${DEVICE}p2
#cryptsetup open ${DEVICE}p2 ${MAPPING_NAME}

#echo "LVM creation..."
## LVM
#pvcreate /dev/mapper/${MAPPING_NAME}
#vgcreate ${VOLUME_NAME} /dev/mapper/${MAPPING_NAME}
#lvcreate -L 100G ${VOLUME_NAME} -n root
#lvcreate -L ${SWAP_SIZE}G ${VOLUME_NAME} -n swap
#lvcreate -l 100%FREE ${VOLUME_NAME} -n home

echo "Formatting partitions..."
## Format
mkfs.fat -F32 /dev/${DEVICE}p1
mkfs.ext4 /dev/${DEVICE}p3
#mkfs.ext4 /dev/mapper/${VOLUME_NAME}-home
mkswap /dev/${DEVICE}p2

echo "Mounting partitions..."
## Mount
## Changed from original
#mount /dev/mapper/${VOLUME_NAME}-root /mnt
mount /dev/${DEVICE}p3 /mnt
mkdir -p /mnt/{home,boot}
mount /dev/${DEVICE}p3 /mnt
mount /dev/${DEVICE}p1 /mnt/boot
swapon /dev/${DEVICE}p2
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
         dhclient \
         linux \
         linux-firmware

# Configuring installation
echo "Creating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab
echo "Chrooting to new system..."
arch-chroot /mnt << "END"

sed -i 's/#en_US/en_US' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

## Timezone
echo "Setting timezone..."
ln -sf /usr/share/zoneinfo/Canada/Eastern /etc/localtime
hwclock --systohc --utc

echo "Enabling DHCP client..."
systemctl enable dhcpd.service

## vconsole

echo FONT=${FONT} > /etc/vconsole.conf
echo KEYMAP=${KEYMAP} >> /etc/vconsole.conf

## Hostname

echo ${HOST_NAME} > /etc/hostname
echo "127.0.0.1 localhost" > /etc/hosts
echo "127.0.1.1 ${HOST_NAME}.localdomain ${HOST_NAME}" >> /etc/hosts

## Enable services

systemctl enable NetworkManager
systemctl enable dhcpd

# Don't need to do this right now
## mkinitcpio (generate initramfs)
#sed -i 's/^HOOKS=.*/HOOKS="base systemd autodetect keyboard sd-vconsole modconf block sd-encrypt sd-lvm2 filesystems fsck"'
#mkinitcpio -P

## Bootloader

bootctl install --path=/boot

cat > /boot/loader/loader.conf <<EOL
timeout 10
default arch
editor 1
EOL

UUID=cryptsetup luksUUID /dev/${DEVICE}p2
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

END

umount -R /mnt
reboot
