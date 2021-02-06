# LEMP stack: nginx + databases {postgresql, mariadb or both} + php-fpm
```bash
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
```
