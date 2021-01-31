# Remote-unlock-Ubuntu-btrfs-bios
Ubuntu encrypted server,  BTRFS file system, BIOS firmware

# Requirements
- BIOS firmware. Not all VPS providers pretend an UEFI firmware. It is easy to adjust an `install.sh` script by adding efi partition, but this is not covered here.  - Booted VPS from Debian-Live 9. Maybe will be fine to boot the newer Debian live OS  or even Ubuntu deriative, but this is not tested. Only difference in software versions at the installing stage. `Cryptsetup` must be > 2.x 
- Generated RSA keys for the remote unlocking. Not covered here hot to generate ssh keypairs. Dropbear supports only RSA.
- Optimal. Generated SSH keys for the connection to server. Maybe the same dropbear keys.  

# How-to
ssh to your live system.  
Run this code:
```bash
wget 
chmod +x install.sh
```
Edit a variables in the file `install.sh` and run it:
```bash
./install.sh
```
The server will be installed and rebooted. SSH to it using `DROPBEAR_PORT` and `DROPBEAR_KEYS`:  
`
ssh -i $DROPBEAR_KEYS $USER@VPS
`
