# Databases
# Postgresql
```bash
cd /run/btrfs-root
btrfs sub create root/var/lib/postgresql
chattr +C root/var/lib/postgresql
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
echo 'host all USER 0.0.0.0 md5' >> /etc/postgresql/12/main/pg_hba.conf
```
Edit the file `/etc/postgresql/12/main/postgresql.conf` and change line 
```properties
#listen_addresses = 'localhost'
```
to
```properties
listen_addresses = '*'
```


# MySQL
Will be later....
