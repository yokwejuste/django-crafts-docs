---
icon: lucide/server
---

# VPS Deployment Guide

Complete guide to deploying Django applications on Virtual Private Servers (VPS), including AWS EC2, DigitalOcean Droplets, Linode, and other VPS providers.

## Overview

VPS deployment gives you full control over your server environment, allowing you to configure everything from the operating system to the web server. This guide covers deploying Django with PostgreSQL, Nginx, and Gunicorn.

## Server Requirements

### Minimum Specifications

- **CPU:** 1 vCPU
- **RAM:** 1 GB (2 GB recommended)
- **Storage:** 25 GB SSD
- **OS:** Ubuntu 22.04 LTS (recommended)

### Recommended Specifications for Production

- **CPU:** 2+ vCPUs
- **RAM:** 4+ GB
- **Storage:** 50+ GB SSD
- **OS:** Ubuntu 22.04 LTS or Debian 11

## AWS EC2 Setup

### Launch EC2 Instance

```bash
# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Configure AWS CLI
aws configure

# Create key pair
aws ec2 create-key-pair \
  --key-name django-server-key \
  --query 'KeyMaterial' \
  --output text > django-server-key.pem

chmod 400 django-server-key.pem

# Create security group
aws ec2 create-security-group \
  --group-name django-web-sg \
  --description "Security group for Django web server"

# Get security group ID
SG_ID=$(aws ec2 describe-security-groups \
  --group-names django-web-sg \
  --query 'SecurityGroups[0].GroupId' \
  --output text)

# Allow SSH (port 22)
aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 22 \
  --cidr 0.0.0.0/0

# Allow HTTP (port 80)
aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0

# Allow HTTPS (port 443)
aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 443 \
  --cidr 0.0.0.0/0

# Launch Ubuntu 22.04 instance
aws ec2 run-instances \
  --image-id ami-0c7217cdde317cfec \
  --instance-type t2.small \
  --key-name django-server-key \
  --security-group-ids $SG_ID \
  --block-device-mappings '[{"DeviceName":"/dev/sda1","Ebs":{"VolumeSize":30,"VolumeType":"gp3"}}]' \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=django-production}]'

# Get instance public IP
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=django-production" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text
```

### Connect to EC2 Instance

```bash
# SSH into instance
ssh -i django-server-key.pem ubuntu@<PUBLIC-IP>
```

## DigitalOcean Droplet Setup

```bash
# Install doctl (DigitalOcean CLI)
cd ~
wget https://github.com/digitalocean/doctl/releases/download/v1.94.0/doctl-1.94.0-linux-amd64.tar.gz
tar xf doctl-1.94.0-linux-amd64.tar.gz
sudo mv doctl /usr/local/bin

# Authenticate
doctl auth init

# Create SSH key
ssh-keygen -t rsa -b 4096 -C "your-email@example.com" -f ~/.ssh/django-do

# Add SSH key to DigitalOcean
doctl compute ssh-key create django-key --public-key "$(cat ~/.ssh/django-do.pub)"

# List available images
doctl compute image list --public | grep -i ubuntu

# Create droplet
doctl compute droplet create django-production \
  --size s-2vcpu-4gb \
  --image ubuntu-22-04-x64 \
  --region nyc3 \
  --ssh-keys $(doctl compute ssh-key list --format ID --no-header) \
  --enable-monitoring

# Get droplet IP
doctl compute droplet list --format Name,PublicIPv4

# SSH into droplet
ssh -i ~/.ssh/django-do root@<DROPLET-IP>
```

## Linode Setup

```bash
# Install Linode CLI
pip install linode-cli

# Configure
linode-cli configure

# Create SSH key
ssh-keygen -t rsa -b 4096 -f ~/.ssh/django-linode

# Add SSH key
linode-cli sshkeys create --label "django-key" --ssh_key "$(cat ~/.ssh/django-linode.pub)"

# List regions
linode-cli regions list

# List instance types
linode-cli linodes types

# Create Linode instance
linode-cli linodes create \
  --type g6-standard-2 \
  --region us-east \
  --image linode/ubuntu22.04 \
  --label django-production \
  --root_pass '<STRONG_PASSWORD>' \
  --authorized_keys "$(cat ~/.ssh/django-linode.pub)"

# Get IP address
linode-cli linodes list

# SSH into instance
ssh -i ~/.ssh/django-linode root@<LINODE-IP>
```

## Initial Server Setup

### Create Non-Root User

```bash
# Create user
sudo adduser django

# Add to sudo group
sudo usermod -aG sudo django

# Setup SSH for new user
sudo mkdir -p /home/django/.ssh
sudo cp ~/.ssh/authorized_keys /home/django/.ssh/
sudo chown -R django:django /home/django/.ssh
sudo chmod 700 /home/django/.ssh
sudo chmod 600 /home/django/.ssh/authorized_keys

# Test SSH with new user
# From local machine:
ssh django@<SERVER-IP>
```

### Update and Secure Server

```bash
# Update system packages
sudo apt update
sudo apt upgrade -y

# Install fail2ban for SSH protection
sudo apt install -y fail2ban

# Configure fail2ban
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# Configure firewall (UFW)
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw enable
sudo ufw status

# Disable password authentication (SSH key only)
sudo nano /etc/ssh/sshd_config
# Set: PasswordAuthentication no
# Set: PubkeyAuthentication yes
sudo systemctl restart sshd
```

## Install Required Software

### Install Python and Dependencies

```bash
# Install Python 3.11
sudo apt install -y software-properties-common
sudo add-apt-repository ppa:deadsnakes/ppa -y
sudo apt update
sudo apt install -y python3.11 python3.11-venv python3.11-dev

# Set Python 3.11 as default
sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1

# Install pip
sudo apt install -y python3-pip

# Install build dependencies
sudo apt install -y build-essential libpq-dev libssl-dev libffi-dev
```

### Install PostgreSQL

```bash
# Install PostgreSQL
sudo apt install -y postgresql postgresql-contrib

# Start PostgreSQL
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Create database and user
sudo -u postgres psql << EOF
CREATE DATABASE mydjango_db;
CREATE USER django_user WITH PASSWORD 'secure_password_here';
ALTER ROLE django_user SET client_encoding TO 'utf8';
ALTER ROLE django_user SET default_transaction_isolation TO 'read committed';
ALTER ROLE django_user SET timezone TO 'UTC';
GRANT ALL PRIVILEGES ON DATABASE mydjango_db TO django_user;
\q
EOF

# Test connection
psql -U django_user -h localhost -d mydjango_db
```

### Configure PostgreSQL for Remote Access (Optional)

```bash
# Edit postgresql.conf
sudo nano /etc/postgresql/14/main/postgresql.conf
# Change: listen_addresses = 'localhost' to listen_addresses = '*'

# Edit pg_hba.conf
sudo nano /etc/postgresql/14/main/pg_hba.conf
# Add: host all all 0.0.0.0/0 md5

# Restart PostgreSQL
sudo systemctl restart postgresql

# Allow PostgreSQL through firewall
sudo ufw allow 5432/tcp
```

### Install Nginx

```bash
# Install Nginx
sudo apt install -y nginx

# Start Nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# Test Nginx
curl http://localhost
```

### Install Redis (Optional - for caching/sessions)

```bash
# Install Redis
sudo apt install -y redis-server

# Configure Redis
sudo nano /etc/redis/redis.conf
# Change: supervised no to supervised systemd

# Restart Redis
sudo systemctl restart redis
sudo systemctl enable redis

# Test Redis
redis-cli ping  # Should return PONG
```

## Deploy Django Application

### Setup Application Directory

```bash
# Create application directory
sudo mkdir -p /var/www/django
sudo chown -R django:django /var/www/django

# Navigate to directory
cd /var/www/django
```

### Clone Repository

```bash
# Using HTTPS
git clone https://github.com/username/mydjango-app.git .

# Or using SSH (setup SSH key first)
ssh-keygen -t ed25519 -C "server@example.com"
cat ~/.ssh/id_ed25519.pub  # Add to GitHub
git clone git@github.com:username/mydjango-app.git .
```

### Setup Virtual Environment

```bash
# Create virtual environment
python3.11 -m venv venv

# Activate virtual environment
source venv/bin/activate

# Upgrade pip
pip install --upgrade pip

# Install dependencies
pip install -r requirements.txt
```

### Configure Environment Variables

```bash
# Create .env file
nano .env
```

```env
# .env
SECRET_KEY=your-long-random-secret-key-here
DEBUG=False
ALLOWED_HOSTS=your-domain.com,www.your-domain.com,<SERVER-IP>

# Database
DB_ENGINE=django.db.backends.postgresql
DB_NAME=mydjango_db
DB_USER=django_user
DB_PASSWORD=secure_password_here
DB_HOST=localhost
DB_PORT=5432

# Email (if using)
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_HOST_USER=your-email@gmail.com
EMAIL_HOST_PASSWORD=your-app-password
EMAIL_USE_TLS=True

# Redis (if using)
REDIS_URL=redis://localhost:6379/0

# Django settings
DJANGO_SETTINGS_MODULE=myproject.settings.prod
```

```bash
# Secure .env file
chmod 600 .env
```

### Run Migrations and Collect Static Files

```bash
# Run migrations
python manage.py migrate

# Create superuser
python manage.py createsuperuser

# Collect static files
python manage.py collectstatic --noinput

# Test application
python manage.py runserver 0.0.0.0:8000
# Visit http://<SERVER-IP>:8000
```

## Setup Gunicorn

### Install and Configure Gunicorn

```bash
# Gunicorn should be in requirements.txt
pip install gunicorn

# Test Gunicorn
gunicorn myproject.wsgi:application --bind 0.0.0.0:8000
```

### Create Gunicorn Socket

```bash
sudo nano /etc/systemd/system/gunicorn.socket
```

```ini
[Unit]
Description=gunicorn socket

[Socket]
ListenStream=/run/gunicorn.sock

[Install]
WantedBy=sockets.target
```

### Create Gunicorn Service

```bash
sudo nano /etc/systemd/system/gunicorn.service
```

```ini
[Unit]
Description=gunicorn daemon for Django project
Requires=gunicorn.socket
After=network.target

[Service]
Type=notify
User=django
Group=www-data
WorkingDirectory=/var/www/django
EnvironmentFile=/var/www/django/.env
ExecStart=/var/www/django/venv/bin/gunicorn \
  --workers 3 \
  --worker-class sync \
  --timeout 120 \
  --bind unix:/run/gunicorn.sock \
  --access-logfile /var/log/gunicorn/access.log \
  --error-logfile /var/log/gunicorn/error.log \
  --log-level info \
  myproject.wsgi:application

[Install]
WantedBy=multi-user.target
```

### Setup Gunicorn Logs

```bash
# Create log directory
sudo mkdir -p /var/log/gunicorn
sudo chown -R django:www-data /var/log/gunicorn
```

### Start Gunicorn

```bash
# Start and enable Gunicorn socket
sudo systemctl start gunicorn.socket
sudo systemctl enable gunicorn.socket

# Check socket status
sudo systemctl status gunicorn.socket

# Check socket file
sudo ls -l /run/gunicorn.sock

# Test socket activation
curl --unix-socket /run/gunicorn.sock localhost

# Check Gunicorn service status
sudo systemctl status gunicorn

# View logs
sudo journalctl -u gunicorn -f
```

### Restart Gunicorn After Changes

```bash
# After code changes
sudo systemctl daemon-reload
sudo systemctl restart gunicorn

# Or reload without dropping connections
sudo systemctl reload gunicorn
```

## Configure Nginx

### Create Nginx Configuration

```bash
sudo nano /etc/nginx/sites-available/django
```

```nginx
# /etc/nginx/sites-available/django

upstream django {
    server unix:/run/gunicorn.sock fail_timeout=0;
}

server {
    listen 80;
    server_name your-domain.com www.your-domain.com;

    client_max_body_size 100M;

    access_log /var/log/nginx/django_access.log;
    error_log /var/log/nginx/django_error.log;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    location = /favicon.ico {
        access_log off;
        log_not_found off;
    }

    location /static/ {
        alias /var/www/django/staticfiles/;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    location /media/ {
        alias /var/www/django/media/;
        expires 30d;
    }

    location / {
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Host $http_host;
        proxy_redirect off;
        proxy_buffering off;

        proxy_pass http://django;
    }
}
```

### Enable Nginx Site

```bash
# Create symbolic link
sudo ln -s /etc/nginx/sites-available/django /etc/nginx/sites-enabled/

# Remove default site
sudo rm /etc/nginx/sites-enabled/default

# Test Nginx configuration
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx

# Check status
sudo systemctl status nginx
```

## SSL/TLS with Let's Encrypt

### Install Certbot

```bash
# Install Certbot
sudo apt install -y certbot python3-certbot-nginx

# Obtain SSL certificate
sudo certbot --nginx -d your-domain.com -d www.your-domain.com

# Certificate will auto-renew, test renewal:
sudo certbot renew --dry-run
```

### Nginx Configuration After SSL

Certbot automatically updates Nginx config, but here's what it looks like:

```nginx
server {
    listen 80;
    server_name your-domain.com www.your-domain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name your-domain.com www.your-domain.com;

    ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    # Rest of configuration...
    location / {
        proxy_pass http://django;
        # ... proxy headers
    }
}
```

## Monitoring and Maintenance

### Setup Monitoring with Netdata

```bash
# Install Netdata
bash <(curl -Ss https://my-netdata.io/kickstart.sh)

# Access at http://<SERVER-IP>:19999
```

### System Resource Monitoring

```bash
# Check disk usage
df -h

# Check memory usage
free -h

# Check CPU usage
top
# or
htop  # Install: sudo apt install htop

# Check running services
sudo systemctl list-units --type=service --state=running
```

### Application Logs

```bash
# Django/Gunicorn logs
sudo journalctl -u gunicorn -f

# Nginx access logs
sudo tail -f /var/log/nginx/django_access.log

# Nginx error logs
sudo tail -f /var/log/nginx/django_error.log

# PostgreSQL logs
sudo tail -f /var/log/postgresql/postgresql-14-main.log
```

### Database Backup

```bash
# Create backup script
sudo nano /usr/local/bin/backup-django-db.sh
```

```bash
#!/bin/bash

# Database credentials
DB_NAME="mydjango_db"
DB_USER="django_user"
BACKUP_DIR="/var/backups/postgresql"
DATE=$(date +%Y%m%d_%H%M%S)

# Create backup directory
mkdir -p $BACKUP_DIR

# Create backup
pg_dump -U $DB_USER $DB_NAME | gzip > $BACKUP_DIR/backup_$DATE.sql.gz

# Delete backups older than 30 days
find $BACKUP_DIR -name "backup_*.sql.gz" -mtime +30 -delete

echo "Backup completed: backup_$DATE.sql.gz"
```

```bash
# Make executable
sudo chmod +x /usr/local/bin/backup-django-db.sh

# Setup cron job for daily backups
sudo crontab -e
# Add: 0 2 * * * /usr/local/bin/backup-django-db.sh
```

### Restore Database

```bash
# Restore from backup
gunzip -c /var/backups/postgresql/backup_20240101_020000.sql.gz | \
  psql -U django_user -d mydjango_db
```

## Automated Deployment

### Create Deployment Script

```bash
nano /var/www/django/deploy.sh
```

```bash
#!/bin/bash

set -e  # Exit on error

echo "Starting deployment..."

# Navigate to project directory
cd /var/www/django

# Store current commit
CURRENT_COMMIT=$(git rev-parse HEAD)

# Pull latest changes
echo "Pulling latest changes from Git..."
git pull origin main

# Check if there are changes
NEW_COMMIT=$(git rev-parse HEAD)

if [ "$CURRENT_COMMIT" = "$NEW_COMMIT" ]; then
    echo "No changes detected. Deployment skipped."
    exit 0
fi

# Activate virtual environment
source venv/bin/activate

# Install/update dependencies
echo "Installing dependencies..."
pip install -r requirements.txt

# Run migrations
echo "Running migrations..."
python manage.py migrate --noinput

# Collect static files
echo "Collecting static files..."
python manage.py collectstatic --noinput --clear

# Restart Gunicorn
echo "Restarting Gunicorn..."
sudo systemctl restart gunicorn

# Restart Nginx
echo "Restarting Nginx..."
sudo systemctl reload nginx

echo "Deployment completed successfully!"
echo "Previous commit: $CURRENT_COMMIT"
echo "New commit: $NEW_COMMIT"
```

```bash
# Make executable
chmod +x deploy.sh

# Run deployment
./deploy.sh
```

### Setup Deployment Webhook (Optional)

```bash
# Install webhook
sudo apt install -y webhook

# Create webhook configuration
sudo nano /etc/webhook.conf
```

```json
[
  {
    "id": "deploy-django",
    "execute-command": "/var/www/django/deploy.sh",
    "command-working-directory": "/var/www/django",
    "response-message": "Deployment triggered",
    "trigger-rule": {
      "match": {
        "type": "payload-hash-sha1",
        "secret": "your-webhook-secret",
        "parameter": {
          "source": "header",
          "name": "X-Hub-Signature"
        }
      }
    }
  }
]
```

```bash
# Create systemd service for webhook
sudo nano /etc/systemd/system/webhook.service
```

```ini
[Unit]
Description=Webhook service
After=network.target

[Service]
Type=simple
User=django
ExecStart=/usr/bin/webhook -hooks /etc/webhook.conf -verbose -port 9000

[Install]
WantedBy=multi-user.target
```

```bash
# Start webhook service
sudo systemctl start webhook
sudo systemctl enable webhook

# Allow webhook port
sudo ufw allow 9000/tcp
```

## Performance Optimization

### Gunicorn Workers Optimization

```bash
# Calculate optimal workers: (2 x CPU cores) + 1
nproc  # Show CPU cores

# Update gunicorn.service
sudo nano /etc/systemd/system/gunicorn.service
# Change --workers based on calculation

sudo systemctl daemon-reload
sudo systemctl restart gunicorn
```

### Enable Gzip Compression

```bash
sudo nano /etc/nginx/nginx.conf
```

```nginx
http {
    # ... other settings

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript
               application/json application/javascript application/xml+rss
               application/rss+xml font/truetype font/opentype
               application/vnd.ms-fontobject image/svg+xml;
}
```

### Enable Browser Caching

```nginx
# In /etc/nginx/sites-available/django

location /static/ {
    alias /var/www/django/staticfiles/;
    expires 1y;
    add_header Cache-Control "public, immutable";
}

location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}
```

### PostgreSQL Tuning

```bash
sudo nano /etc/postgresql/14/main/postgresql.conf
```

```conf
# Adjust based on available RAM
shared_buffers = 256MB              # 25% of RAM
effective_cache_size = 1GB          # 50-75% of RAM
maintenance_work_mem = 64MB
work_mem = 16MB
max_connections = 100

# Write-ahead log
wal_buffers = 16MB
checkpoint_completion_target = 0.9
```

```bash
sudo systemctl restart postgresql
```

## Troubleshooting

### Gunicorn Not Starting

```bash
# Check service status
sudo systemctl status gunicorn

# View detailed logs
sudo journalctl -u gunicorn -n 50 --no-pager

# Check socket file
sudo ls -l /run/gunicorn.sock

# Check file permissions
sudo chown -R django:www-data /var/www/django

# Test Gunicorn manually
cd /var/www/django
source venv/bin/activate
gunicorn myproject.wsgi:application --bind 0.0.0.0:8000
```

### Nginx 502 Bad Gateway

```bash
# Check if Gunicorn is running
sudo systemctl status gunicorn

# Check Nginx error log
sudo tail -f /var/log/nginx/django_error.log

# Check socket connection
sudo ls -l /run/gunicorn.sock

# Test upstream
curl --unix-socket /run/gunicorn.sock localhost
```

### Database Connection Issues

```bash
# Test PostgreSQL connection
psql -U django_user -h localhost -d mydjango_db

# Check PostgreSQL is running
sudo systemctl status postgresql

# View PostgreSQL logs
sudo tail -f /var/log/postgresql/postgresql-14-main.log

# Check pg_hba.conf
sudo nano /etc/postgresql/14/main/pg_hba.conf
```

### Permission Issues

```bash
# Fix ownership
sudo chown -R django:django /var/www/django

# Fix Gunicorn socket permissions
sudo chown django:www-data /run/gunicorn.sock

# Fix static files permissions
sudo chown -R django:www-data /var/www/django/staticfiles
sudo chmod -R 755 /var/www/django/staticfiles
```

### High Memory Usage

```bash
# Check memory usage
free -h

# Check which process uses most memory
ps aux --sort=-%mem | head

# Reduce Gunicorn workers if needed
sudo nano /etc/systemd/system/gunicorn.service
# Reduce --workers value

sudo systemctl daemon-reload
sudo systemctl restart gunicorn
```

## Security Hardening

### Disable Root Login

```bash
sudo nano /etc/ssh/sshd_config
# Set: PermitRootLogin no
sudo systemctl restart sshd
```

### Configure Automatic Security Updates

```bash
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure --priority=low unattended-upgrades
```

### Setup Intrusion Detection

```bash
# Install AIDE
sudo apt install -y aide
sudo aideinit
sudo cp /var/lib/aide/aide.db.new /var/lib/aide/aide.db

# Check system integrity
sudo aide --check
```

### Limit Login Attempts

```bash
# fail2ban is already installed, configure it
sudo nano /etc/fail2ban/jail.local
```

```ini
[sshd]
enabled = true
port = ssh
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600

[nginx-limit-req]
enabled = true
port = http,https
logpath = /var/log/nginx/django_error.log
maxretry = 5
```

```bash
sudo systemctl restart fail2ban
```

## Additional Resources

- [Django Deployment Checklist](https://docs.djangoproject.com/en/stable/howto/deployment/checklist/)
- [Gunicorn Documentation](https://docs.gunicorn.org/)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Let's Encrypt Documentation](https://letsencrypt.org/docs/)
- [Ubuntu Server Guide](https://ubuntu.com/server/docs)
