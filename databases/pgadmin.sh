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
