# LEMP stack: nginx + databases {postgresql, mariadb or both} + php-fpm

Edit file `/etc/fstab` by copying one lide with subvolume, pasting and modifying it:
```properties
UUID=some.random-symbols /etc/nginx btrfs defaults,noatime,commit=120,space_cache,compress=zstd:3,subvol=nginx 0 2
```

```bash
cd /run/btrfs-root
btrfs sub create nginx
mkdir /etc/nginx
mount /etc/nginx
apt install -y nginx
ufw allow 'Nginx Full'
```
If server does not support ipv6, then edit `/etc/nginx/site-available/default` by removing the line ` listen [::]:80 default_server;` and restart nginx service:
```bash
service nginx restart
```
Install free SSL ceritification tool:
```bash
apt install -y python3-certbot-nginx
# This will safe SSL certificates together with nginx config in the nginx subvolume
mv /etc/letsencrypt /etc/nginx
ln -s /etc/nginx/letsencrypt /etc/letsencrypt
certbot -d YOURHOST --nginx
chown -R www-data:www-data /var/www/html/
```
