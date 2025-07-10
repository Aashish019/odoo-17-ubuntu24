#!/bin/bash
set -e

# Check required env vars
if [ -z "$ODOO_PG_PASSWORD" ]; then
  echo "ERROR: ODOO_PG_PASSWORD is not set"
  exit 1
fi
if [ -z "$ODOO_SUBDOMAIN" ]; then
  echo "ERROR: ODOO_SUBDOMAIN is not set"
  exit 1
fi
if [ -z "$ODOO_EMAIL" ]; then
  echo "ERROR: ODOO_EMAIL is not set"
  exit 1
fi

DOMAIN="${ODOO_SUBDOMAIN}.mcmillan.solutions"

# Step 1: Update and install essentials
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y openssh-server fail2ban python3-pip python3-dev libxml2-dev libxslt1-dev \
 zlib1g-dev libsasl2-dev libldap2-dev build-essential libssl-dev libffi-dev libmysqlclient-dev \
 libjpeg-dev libpq-dev libjpeg8-dev liblcms2-dev libblas-dev libatlas-base-dev npm git nginx \
 apache2-utils certbot python3-certbot-nginx wget node-less

sudo npm install -g less less-plugin-clean-css

# Step 2: PostgreSQL setup
sudo apt-get install -y postgresql
sudo -u postgres psql -c "CREATE USER odoo17 WITH CREATEDB ENCRYPTED PASSWORD '${ODOO_PG_PASSWORD}';" || true
sudo -u postgres psql -c "ALTER USER odoo17 WITH SUPERUSER;" || true

# Step 3: Odoo user and code setup
sudo adduser --system --home=/opt/odoo --group odoo || true
sudo chown -R odoo: /opt/odoo || true
sudo su - odoo -s /bin/bash -c "if [ ! -d /opt/odoo/.git ]; then git clone https://github.com/odoo/odoo --depth 1 --branch 17.0 --single-branch /opt/odoo; else cd /opt/odoo && git pull; fi"

# Step 4: Python virtual environment
sudo mkdir -p /opt/venv
sudo apt-get install -y python3.12-venv
sudo python3 -m venv /opt/venv/odoo17-venv
source /opt/venv/odoo17-venv/bin/activate
sudo pip3 install --upgrade pip
sudo pip3 install -r /opt/odoo/requirements.txt

# Step 5: wkhtmltopdf install
wget https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-2/wkhtmltox_0.12.6.1-2.jammy_amd64.deb
sudo apt install -f ./wkhtmltox_0.12.6.1-2.jammy_amd64.deb

# Step 6: Odoo config
sudo cp /opt/odoo/debian/odoo.conf /etc/odoo.conf
sudo tee /etc/odoo.conf > /dev/null <<EOF
[options]
admin_passwd = admin
db_host = localhost
db_port = 5432
db_user = odoo17
db_password = ${ODOO_PG_PASSWORD}
addons_path = /opt/odoo/addons
logfile = /var/log/odoo/odoo17.log
proxy_mode = True
EOF

sudo chown odoo: /etc/odoo.conf
sudo chmod 640 /etc/odoo.conf

sudo mkdir -p /var/log/odoo
sudo chown odoo:root /var/log/odoo

# Step 7: Systemd service
sudo tee /etc/systemd/system/odoo.service > /dev/null <<EOF
[Unit]
Description=Odoo
Documentation=http://www.odoo.com

[Service]
Type=simple
User=odoo
ExecStart=/opt/venv/odoo17-venv/bin/python3 /opt/odoo/odoo-bin -c /etc/odoo.conf

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now odoo.service

# Step 8: Nginx config
sudo rm -f /etc/nginx/sites-enabled/default
sudo sed -i 's/^# server_names_hash_bucket_size/server_names_hash_bucket_size/' /etc/nginx/nginx.conf || true

sudo tee /etc/nginx/sites-available/${DOMAIN} > /dev/null <<EOF
upstream odoo {
    server 127.0.0.1:8069;
}
upstream odoochat {
    server 127.0.0.1:8072;
}
server {
    listen 80;
    server_name ${DOMAIN} www.${DOMAIN};

    proxy_read_timeout 720s;
    proxy_connect_timeout 720s;
    proxy_send_timeout 720s;

    proxy_set_header X-Forwarded-Host \$host;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header X-Real-IP \$remote_addr;

    access_log /var/log/nginx/odoo.access.log;
    error_log /var/log/nginx/odoo.error.log;

    location / {
        proxy_redirect off;
        proxy_pass http://odoo;
    }

    location /web/database/manager {
        auth_basic "Zone protegée";
        auth_basic_user_file /etc/nginx/.htpasswd;
        proxy_redirect off;
        proxy_pass http://odoo;
    }

    location /longpolling {
        proxy_pass http://odoochat;
    }

    gzip_types text/css text/plain application/json application/javascript;
    gzip on;
}
EOF

sudo ln -sf /etc/nginx/sites-available/${DOMAIN} /etc/nginx/sites-enabled/

# Step 9: Setup basic auth for db manager
echo "admin:$(openssl passwd -apr1 'Master@nginx#17')" | sudo tee /etc/nginx/.htpasswd > /dev/null

sudo nginx -t
sudo systemctl restart nginx

# Step 10: SSL certbot
sudo certbot --nginx -d ${DOMAIN} -d www.${DOMAIN} --non-interactive --agree-tos -m ${ODOO_EMAIL}

# Step 11: Restart Odoo service
sudo systemctl restart odoo.service

echo "✅ Odoo 17 installed successfully on https://${DOMAIN}"
