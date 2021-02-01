# Ubuntu-server-bios-btrfs-luks-remote-unlock
Ubuntu encrypted server,  BTRFS file system, BIOS firmware.  
For security reason ALL users, including root, will be locked. One possibility to login to the server - specifying the correct user name and SSH key.

# Requirements
- BIOS firmware. Not all VPS providers pretend an UEFI firmware. It is easy to adjust an `install.sh` script by adding efi partition, but this is not covered here.  - Booted VPS from Debian-Live 9. Maybe will be fine to boot the newer Debian live OS  or even Ubuntu deriative, but this is not tested. Only difference in software versions at the installing stage. `Cryptsetup` must be > 2.x 
- Generated RSA keys for the remote unlocking. Not covered here hot to generate ssh keypairs. Dropbear supports only RSA. It is enought one key for all, different keys to connect from the different devices.
- Optimal. Generated SSH keys for the connection to server. Maybe the same dropbear keys.  

# Some notes
Backup, BACKUP and one more time **BACKUP!!!!!** All data will be destroyed, do backups. Always.  
Install script will create `Huge pages`, about 3GB (3x1024/2+extra 500 = 2036). If your system do not need Huge pages, remove line in the file `install.sh`or set different value:  
>echo vm.nr_hugepages = 2036 >> /etc/sysctl.conf  

Btrfs compression ratio. I perform some test, and saw that no very big difference on freshly installed system between compression level 4 and 15. Sometimes even worst result using compress-force. Without compression freshly installed system takes 1.5G, after compression at level 4 it uses only 762M (df -h info). There is special tool to calculate compression rate:
```bash
apt install -y btrfs-compsize
compsize /run/btrfs-root
```

# How-to
ssh to your live system.  
Run this code:
```bash
wget https://raw.githubusercontent.com/Seneliux/Remote-unlock-Ubuntu-btrfs-bios/main/install.sh && chmod +x install.sh
```
Edit a variables in the file `install.sh` and run it:
```bash
./install.sh
```
The server will be installed and rebooted. SSH to it using `DROPBEAR_PORT` and `DROPBEAR_KEYS`. User: root. 
```bash
ssh -i $DROPBEAR_KEYS -p $DROPBEAR_PORT root@VPS
```
At commandt promt enter you will be asked to unlock cryptodisk:  
> Please unlock disk ....crypt  

Enter `the unpredictable unique very strong disk encryption passphrase`  
Storage will unlock, and now ssh to server by using `$USER`, `$SSH_KEYS` and `$SSH_PORT`:  
```bash
ssh -i $SSH_KEYS -p $SSH_PORT $USER@VPS
```
Copy this to the terminal line by line or all. The only line where must change value is timezone.
```bash
ufw allow openssh
yes | ufw enable
apt update
export DEBIAN_FRONTEND=noninteractive
apt upgrade -y -o Dpkg::Options::="--force-confold" --allow-remove-essential
timedatectl set-timezone Europe/Berlin
btrfs filesystem defragment -rczstd /
```
That all. Now you can [install Minecraft server](https://github.com/Seneliux/MinecraftSystemdUnit) :D
