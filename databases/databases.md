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
chown postgres:postgres /var/lib/postgresql
ufw allow 5432/tcp
sudo -u postgres psql
```

Optimal. Now you are connected to postgres server. Add user with all permissions for pgadmin. This is safest than using user `postgres`:
```bash
CREATE ROLE username WITH LOGIN SUPERUSER PASSWORD 'password';
```
To exit the postgre server, type `\q`


Allow `$USER` to connect to the server from outside (Change *12* to installed postgresql version):
```bash
echo 'host all $USER 0.0.0.0/0 md5' >> /etc/postgresql/12/main/pg_hba.conf
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
Requirements: running nginx instance (see LEMP.md). nginx will be reverse proxy to gunicorn + pgadmin4. 

```bash
wget https://raw.githubusercontent.com/Seneliux/Ubuntu-server-bios-btrfs-luks-remote-unlock/main/databases/pgadmin.sh && chmod +x pgadmin.sh
./pgadmin.sh
```
Add at the nginx enabled site this block and restart the nginx service. Change two variables OPTIMAL_SUBFOLDER or delete it, and YOUR_HOST. Direcotry OPTIMAL_SUBFOLDER/pgadmin4 not exist on storage, do not create it.
```properties
location /OPTIMAL_SUBFOLDER/pgadmin4/ {
        limit_except GET POST { deny  all; }
                include proxy_params;
                proxy_pass http://unix:/tmp/pgadmin4.sock;
                proxy_set_header X-Script-Name /OPTIMAL_SUBFOLDER/pgadmin4;
                add_header Referer "https://YOUR_HOST";
                access_log /var/log/nginx/pgadmin4.access.log custom;
                error_log /var/log/nginx/pgadmin4_error.log warn;
        }
```


## MySQL
Will be later....
For PHP support, install 
```bash
php-mysql
```
Optimal. phpMyadmin

 apt install -y phpmyadmin php-mbstring php-zip php-gd php-json php-curl
 
 At promp do not select apache or lighthttp. Later at the promp choose configure, and do not create password.
 
 ln -s /usr/share/phpmyadmin /var/www/html/$YOUR_DOMAIN/$OPTIMAL_DIRECTORY/phpmyadmin
 
 sudo mariadb
 
 GRANT ALL ON *.* TO 'admin'@'localhost' IDENTIFIED BY 'password' WITH GRANT OPTION;
flush privileges;
quit
