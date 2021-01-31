# Create 3G swap file
```bash
cd /run/btrfs-root
btrfs sub create swap
truncate -s 0 swap/swapfile
chattr +C swap/swapfile 
btrfs property set swap/swapfile compression none
fallocate -l 3G swap/swapfile
chmod 600 swap/swapfile
mkswap swap/swapfile 
mkdir root/swap
```
Edit fstab. Copy one line of btrfs pool, and add one more line. Swap section of the file `/etc/fstab` will must be like:  
```properties
UUID=some_random_value / btrfs /swap btrfs noatime,commit=30,subvol=swap 0 0
/swap/swapfile none swap defaults 0 0
```

# Use zswap
Edit the file `/etc/default/grub`by adding to the line`GRUB_CMDLINE_LINUX_DEFAULT=` these values:
```properties
zswap.enabled=1 zswap.compressor=lz4 zswap.max_pool_percent=25 zswap.zpool=z3fold
```

```bash
echo z3fold >> /etc/initramfs-tools/modules
update-initramfs -k all -c
update-grub
```

After rebooting system check swap existence / usage:
```bash
free -h
grep -R . /sys/module/zswap/parameters
```
