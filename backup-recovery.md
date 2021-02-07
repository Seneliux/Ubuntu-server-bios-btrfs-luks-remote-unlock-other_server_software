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
Create snapshot / backup of the root subvolume:
```bash
mkdir /backup
cd /run/btrfs-root
mkdir snapshots
btrfs sub create backup
mount /backup
btrfs sub snap -r root/ /run/btrfs-root/snapshots/root_fresh
# This is example hot to send snapshot to different location. It is possible to send read-only snapshots to the remote btrfs storage.
btrfs send /run/btrfs-root/snapshots/root_fresh/ | btrfs receive /backup/
```
This will not include other subvolumes like /home /opt, var/log and so on. Must snapshot (optimal: send to other physical disk) all important subvolumes.

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
cryptsetup luksOpen ${DISK}3 ${DM}3_crypt
mount /dev/mapper/${DM}3_crypt /mnt
cd /mnt
btrfs sub del root
# Choose one variant from two:
# First - recover from the (remote) location:
btrfs send snapshots/root_fresh/ | btrfs receive .
mv root_fresh root
# Second - snapshot subvolume from local file system (restore very quick):
btrfs sub snap snapshots/root_fresh root
reboot
```
Only / (root) must be recovered from live cd. Other subvolumes recovering simple:  
- stop services using subvolume;  
- delete subvolume;
- snapshot from the napshot / backup;  
- restart stoped services.
Example for postgresql subvolume:  
```bash
ps -ef | grep postgresql
service stop postgresql
cd /run/btrfs-root
btrfs sub del postgresql
btrfs sub snap snapshots/postgresql postgresql
service start postgresql
```
