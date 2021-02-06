# System and user data backups and recovery
## Backups

How to backup btrfs subvolumes explained in a nice [Fedora Magazine article](https://fedoramagazine.org/btrfs-snapshots-backup-incremental/).  
Here directory `/.snapshots` will be used for snapshots, and subvolume `backup`, mounted at `/backup` for copies of snapshots.  
Better to send the snapshots to the different physical location, but here backup strategies not covered.  
Snapshot dont include nested snapshots or subvolumes, it creates only empty directory.
So to perform snapshot of subvolume `/var/log`, must run command `btrfs sub create root/var/log /.snapshots` 

Edit file  `/etc/fstab` by copying any included subvolume line, and edit it like example:
```properties
UUID=some_random_symbols   /backup  btrfs defaults,noatime,commit=30,space_cache,compress=zstd:4,subvol=backup 0 2
```
Run theses commands:
```bash
mkdir /{.snapshots,backup}
cd /run/btrfs-root
btrfs sub create backup
mount /backup
btrfs sub snap -r root/ /.snapshots/root_fresh
btrfs send /.snapshots/root_fresh/ | btrfs receive /backup/
```
Now we can sleep better without stress - if somethong goes wrong, will be posibble revert to last good snapshoped state.

## Recovery
Boot from live cd, decrypt storage:
Below is the example how to revocer root subvolume:
```bash
if [[ $(lsblk |  grep -vE "NAME|tmpfs|cdrom|loop|mapper" | awk '{print $1}' | head -n 1) != sda  ]]; then
  export DISK="/dev/nvme0n1"
else
  export DISK="/dev/sda"
fi
  DISKP="${DISK}$( if [[ "$DISK" =~ "nvme" ]]; then echo "p"; fi )"
DM="${DISK##*/}"
mount /dev/mapper/${DM}3_crypt /mnt
cd /mnt
btrfs sub del root
btrfs sub snap 
```
