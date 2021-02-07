apt install -y build-essential
apt install -y python3-wheel python3-pip python3-venv
cd /var/www
python3 -m venv pgadmin4
mkdir pgadmin4/data
source pgadmin4/bin/activate
pip3 install wheel
pip install pgadmin4
cat > pgadmin4/lib/python3.8/site-packages/pgadmin4/config_local.py << EOF
import os
DATA_DIR = '/var/www/pgadmin4/data'
LOG_FILE = '/var/log/nginx/pgadmin4.log'
SQLITE_PATH = os.path.join(DATA_DIR, 'pgadmin4.db')
SESSION_DB_PATH = os.path.join(DATA_DIR, 'sessions')
STORAGE_DIR = os.path.join(DATA_DIR, 'storage')
EOF
python3 pgadmin4/lib/python3.8/site-packages/pgadmin4/setup.py
pip install gunicorn
deactivate
chown -R www-data:www-data /var/www/pgadmin4
touch /var/log/nginx/pgadmin4.log
chown -R www-data:www-data /var/log/nginx/pgadmin4.log
cat > /etc/systemd/system/pgadmin4.service << EOF
[Unit]

Description=pgAdmin4 service
After=network.target

[Service]
User=www-data
Group=www-data
Environment="PATH=/var/www/pgadmin4/venv/bin"
ExecStart=/var/www/pgadmin4/bin/gunicorn --bind unix:/tmp/pgadmin4.sock --workers=1 --threads=25 --chdir /var/www/pgadmin4/lib/python3.8/site-packages/pgadmin4 pgAdmin4:app

[Install]
WantedBy=multi-user.target
EOF
systemctl start pgadmin4
systemctl enable pgadmin4
