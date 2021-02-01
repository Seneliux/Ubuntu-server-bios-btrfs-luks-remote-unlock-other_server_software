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

# MySQL
Will be later....
