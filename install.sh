#!/bin/bash
HOST='hostname'
# First locale will be set to LANG=. In this case LANG=en_US.UTF-8
LOCALE='en_US.UTF-8 UTF-8;de_DE.UTF-8 UTF-8;lt_LT.UTF-8 UTF-8;ru_RU.UTF-8 UTF-8'
# focal = 20.04
DISTRO_NAME=focal
# The default SSH port is 22. For security reasons better to change;
SSH_PORT="12345"
# This port must be different from main ssh server.
DROPBEAR_PORT="1234"
STORAGE_PASS="the unpredictable unique very strong disk encryption passphrase"
# Dropbear supports RSA key. Put these public keys here, separating with the ";" (without spaces). Comments are optimal.
DROPBEAR_KEYS="ssh-rsa First_RSA_KEY comment_of_the_first_dropbear_key;ssh-rsa SECOND_RSA_KEX comment_of_the_second_dropbear_ke"
SSH_KEYS='ssh-ed25519 First_SSH_KEY comment_of_the_first_ssh_key;ssh-ed25519 Second_SSH_KEY comment_of_the_second_ssh_key'
# This will be the user in new system.
USER="username"
# BTRFS compress ratio. Without compression delete "4".
COMPRESS_RATIO=4
# Label for btrfs filesystem, cryptdisk,
LABEL="ubuntu"
INSTALL_DIR=/mnt


[[ ! -z "$COMPRESS_RATIO" ]] && COMPRESS_RATIO=,compress=zstd:${COMPRESS_RATIO}

if [[ $(lsblk |  grep -vE "NAME|tmpfs|cdrom|loop|mapper" | awk '{print $1}' | head -n 1) != sda  ]]; then
  export DISK="/dev/nvme0n1"
else
  export DISK="/dev/sda"
fi
  DISKP="${DISK}$( if [[ "$DISK" =~ "nvme" ]]; then echo "p"; fi )"
  DM="${DISK##*/}"

sgdisk --zap-all $DISK
sgdisk -n1:0:+2M -t1:ef02 -c1:bios_grub $DISK
sgdisk -n2:0:+386M -t2:8300 -c2:Boot $DISK
sgdisk -n3:0:0 -t3:BF01 -c3:Ubuntu $DISK
partprobe
sed -i 's/stretch main/bullseye main contrib/'  /etc/apt/sources.list.d/base.list
apt update
export DEBIAN_FRONTEND=noninteractive
apt install -o Dpkg::Options::="--force-confold" --allow-remove-essential -y initramfs-tools cryptsetup-initramfs debootstrap btrfs-progs

echo -n "$STORAGE_PASS" | cryptsetup -c aes-xts-plain64 --type luks2 --pbkdf argon2id -s 512 -h whirlpool --label $LABEL --use-random luksFormat ${DISK}3
echo -n "$STORAGE_PASS" | cryptsetup open ${DISK}3 ${DM}3_crypt
mkdir -p $INSTALL_DIR/btrfs-root
mkfs.btrfs -f -L $LABEL /dev/mapper/${DM}3_crypt
mount /dev/mapper/${DM}3_crypt $INSTALL_DIR/btrfs-root -o noatime,space_cache
mkdir -p $INSTALL_DIR/btrfs-root/
mkdir $INSTALL_DIR/btrfs-current
btrfs subvolume create $INSTALL_DIR/btrfs-root/root
btrfs subvolume create $INSTALL_DIR/btrfs-root/root/home
btrfs subvolume create $INSTALL_DIR/btrfs-root/root/opt
mount -o defaults,noatime,space_cache,subvol=root /dev/mapper/${DM}3_crypt $INSTALL_DIR/btrfs-current
mkdir -p $INSTALL_DIR/btrfs-current/var/
btrfs subvolume create $INSTALL_DIR/btrfs-root/root/var/cache
btrfs subvolume create $INSTALL_DIR/btrfs-root/root/var/mail
btrfs subvolume create $INSTALL_DIR/btrfs-root/root/var/log
btrfs subvolume create $INSTALL_DIR/btrfs-root/root/var/www
btrfs subvolume create $INSTALL_DIR/btrfs-root/root/var/spool
mkdir ${INSTALL_DIR}/btrfs-current/boot
yes | mkfs.ext4 ${DISK}2
mount ${DISK}2 ${INSTALL_DIR}/btrfs-current/boot
debootstrap --include nano,openssh-server $DISTRO_NAME $INSTALL_DIR/btrfs-current http://archive.ubuntu.com/ubuntu

echo $HOST > ${INSTALL_DIR}/btrfs-current/etc/hostname

cat > ${INSTALL_DIR}/btrfs-current/etc/apt/sources.list << EOLIST
deb http://de.archive.ubuntu.com/ubuntu/ ${DISTRO_NAME} main restricted universe multiverse
deb http://de.archive.ubuntu.com/ubuntu/ ${DISTRO_NAME}-updates main restricted universe multiverse
deb http://de.archive.ubuntu.com/ubuntu/ ${DISTRO_NAME}-security main restricted universe multiverse
deb http://de.archive.ubuntu.com/ubuntu/ ${DISTRO_NAME}-backports main restricted universe multiverse
EOLIST

cat > ${INSTALL_DIR}/btrfs-current/etc/netplan/01-netcfg.yaml << EOF
network:
    ethernets:
        $(ip link | awk -F: '$0 !~ "lo|vir|wl|^[^0-9]"{print $2;getline}'):
            addresses: [$(ip a | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p')/24]
            gateway4: $(ip r | awk '/default/ { print $3 }')
            nameservers:
                addresses: [9.9.9.9]
            dhcp4: no
    version: 2
EOF
echo ${LOCALE} | tr ";" "\n" > ${INSTALL_DIR}/btrfs-current/etc/locale.gen

if [[ $(lsblk |  grep -vE "NAME|tmpfs|cdrom|loop|mapper" | awk '{print $1}' | head -n 1) != sda  ]]; then
  echo "${DM}3_crypt UUID=$(blkid -s UUID -o value /dev/${DM}3) none luks,discard" > ${INSTALL_DIR}/btrfs-current/etc/crypttab
else
  echo "${DM}3_crypt UUID=$(blkid -s UUID -o value /dev/${DM}3) none luks" > ${INSTALL_DIR}/btrfs-current/etc/crypttab
fi
echo "UUID=$(blkid -s UUID -o value ${DISK}2) /boot ext4 x-systemd.idle-timeout=1min,x-systemd.automount,noauto,noatime 0 1" > ${INSTALL_DIR}/btrfs-current/etc/fstab


mkdir ${INSTALL_DIR}/btrfs-current/etc/dropbear-initramfs
echo ${DROPBEAR_KEYS} | tr ";" "\n" > ${INSTALL_DIR}/btrfs-current/etc/dropbear-initramfs/authorized_keys
chmod 600 ${INSTALL_DIR}/btrfs-current/etc/dropbear-initramfs/authorized_keys

echo DISK=${DISK} > ${INSTALL_DIR}/btrfs-current/root/variables
echo DM=${DM} >> ${INSTALL_DIR}/btrfs-current/root/variables
echo SSH_PORT=${SSH_PORT} >> ${INSTALL_DIR}/btrfs-current/root/variables
echo USER=${USER} >> ${INSTALL_DIR}/btrfs-current/recho ${SSH_KEYS} | tr ";" "\n" > /home/${USER}/.ssh/authorized_keysoot/variables
echo DROPBEAR_PORT=${DROPBEAR_PORT} >> ${INSTALL_DIR}/btrfs-current/root/variables
echo COMPRESS_RATIO=${COMPRESS_RATIO} >> ${INSTALL_DIR}/btrfs-current/root/variables
for name in proc sys dev dev/pts; do mount --bind /$name ${INSTALL_DIR}/btrfs-current/$name; done
cat << EOC | chroot ${INSTALL_DIR}/btrfs-current /usr/bin/env -i DISK=${DISK} DM=${DM} SSH_PORT=${SSH_PORT} USER=${USER} DROPBEAR_PORT=${DROPBEAR_PORT} COMPRESS_RATIO=${COMPRESS_RATIO} /bin/bash
source /root/variables
locale-gen --purge
update-locale LANG=$(sed -n '1p' /etc/locale.gen)
apt update
apt install -y linux-image-generic linux-headers-generic initramfs-tools grub-pc dropbear-initramfs btrfs-progs cryptsetup-initramfs ufw
systemctl enable ssh
grub-install $DISK
sed -i 's/ splash//' /etc/default/grub
sed -i 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="cryptdevice=UUID='"$(blkid -s UUID -o value ${DISK}3)"':'${DM}3'_crypt ipv6.disable=1 rootflags=subvol=\/root" /' /etc/default/grub
echo "vm.swappiness = 1" >> /etc/sysctl.conf
echo vm.nr_hugepages = 2036 >> /etc/sysctl.conf
netplan generate
useradd -m -s /bin/bash $USER
passwd -l root
passwd -l ${USER}
sed -i "s/#DROPBEAR_OPTIONS=/DROPBEAR_OPTIONS=\"-c \/bin\/cryptroot-unlock -p ${DROPBEAR_PORT}  -s -j -k -I 60\"/" /etc/dropbear-initramfs/config
sed -i "s/#Port 22/Port ${SSH_PORT}/" /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i "s/ports=22\/tcp/ports=${SSH_PORT}\/tcp/" /etc/ufw/applications.d/openssh-server
ufw app update all
echo "UUID=$(blkid -s UUID -o value /dev/mapper/${DM}3_crypt) / btrfs defaults,noatime,commit=120,space_cache${COMPRESS_RATIO},subvol=root 0 1" >> /etc/fstab
echo "UUID=$(blkid -s UUID -o value /dev/mapper/${DM}3_crypt) /run/btrfs-root btrfs defaults,noatime,commit=120,space_cache,nodev,nosuid,noexec${COMPRESS_RATIO} 0 0" >> /etc/fstab
echo "RESUME=none" >> /etc/initramfs-tools/conf.d/noresume.conf
update-initramfs -k all -c
update-grub
echo "${USER} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
cp /usr/share/systemd/tmp.mount /etc/systemd/system/
rm -rf /tmp/*
systemctl enable tmp.mount
systemctl enable ssh
addgroup $USER sudo
EOC
mkdir ${INSTALL_DIR}/btrfs-current/home/$USER/.ssh
echo ${SSH_KEYS} | tr ";" "\n" > ${INSTALL_DIR}/btrfs-current/home/$USER/.ssh/authorized_keys
chmod 700 ${INSTALL_DIR}/btrfs-current/root/.ssh
chmod 600 ${INSTALL_DIR}/btrfs-current/root/.ssh/authorized_keys
umount -R $INSTALL_DIR/btrfs-current/
umount -R $INSTALL_DIR/btrfs-root/
reboot
