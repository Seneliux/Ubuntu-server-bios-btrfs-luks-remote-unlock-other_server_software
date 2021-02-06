# Databases
## Postgresql
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
For PHP support, install 
```bash
apt install -y php-pgsql
```
### pgAdmin 
Optimal install web interface for PostgreSQL servers.
Requirements: running nginx instance (see LEMP.md).
```bash
apt install -y build-essentials
mkdir /var/www/html/admin
cd /var/www/html/$HOST/admin
python3 -m venv pgadmin4
cd pgadmin4
mkdir data
. bin/activate
pip install wheel
pip install pipreqs
pipreqs
pip install -r requirements.txt
pip install pgadmin4
nano lib/python3.8/site-packages/pgadmin4/config_local.py
```

Paste this:
```properties
import os
DATA_DIR = '/var/www/html/admin/pgadmin4/data'
LOG_FILE = '/var/log/pgadmin4.log'
SQLITE_PATH = os.path.join(DATA_DIR, 'pgadmin4.db')
SESSION_DB_PATH = os.path.join(DATA_DIR, 'sessions')
STORAGE_DIR = os.path.join(DATA_DIR, 'storage')
```
Run:
```bash
python3 lib/python3.8/site-packages/pgadmin4/setup.py
pip install gunicorn
deactivate
touch /var/log/nginx/pgadmin4.log
chown www-data:www-data /var/log/nginx/pgadmin4.log 
systemctl edit --full --force pgadmin4
```
Paste this:
```properties
[Unit]
Description=pgAdmin4 service
After=network.target

[Service]
User=www-data
Group=www-data
Environment="PATH=/var/www/html/admin/pgadmin4/venv/bin"
ExecStart=/var/www/html/admin/pgadmin4/bin/gunicorn --bind unix:/tmp/pgadmin4.sock --workers=1 --threads=25 --chdir /var/www/html/admin/pgadmin4/lib/python3.8/site-packages/pgadmin4 pgAdmin4:app

[Install]
WantedBy=multi-user.target
```
And enable/run new service:
```bash
systemctl start pgadmin4
systemctl enable pgadmin4
```

## MySQL
Will be later....
For PHP support, install 
```bash
php-mysql
```
