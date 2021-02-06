# Databases
# Postgresql
Edit file `/etc/fstab` by copying with and subvolume, pasting and modifying one line:
```properties
UUID=some-random-value /var/lib/postgresql btrfs defaults,noatime,commit=120,space_cache,compress=zstd:5,subvol=postgresql 0 2
```


```bash
cd /run/btrfs-root
btrfs sub create postgresql
chattr +C postgresql
mkdir /var/lib/postgresql
chattr +C /var/lib/postgresql
mount /var/lib/postgresql
apt install -y postgresql postgresql-contrib
sudo -u postgres psql
```

Optimal. Now you are connected to postgres server. Add user with all permissions for pgadmin. This is safest than using user `postgres`:
```bash
CREATE ROLE username WITH LOGIN SUPERUSER PASSWORD 'password';
```
To exit the postgre server, type `\q`

Allow `user` to connect to the server from outside (Change *12* to installed postgresql version):
```bash
echo 'host all USER 0.0.0.0/0 md5' >> /etc/postgresql/12/main/pg_hba.conf
```
Edit the file `/etc/postgresql/12/main/postgresql.conf` and change line 
```properties
#listen_addresses = 'localhost'
```
to
```properties
listen_addresses = '*'
```
Restart postgresql server:
```bash
service postgresql restart
```

# MySQL
Will be later....
