---
icon: lucide/rocket
---

# Django Deployment Guide

Comprehensive guide to deploying Django applications to Azure App Service, AWS App Runner, and VPS/EC2 instances.

## Pre-Deployment Checklist

Before deploying to any platform, ensure your Django app is production-ready.

### Security Settings

```python
# settings/prod.py
import os
from dotenv import load_dotenv

load_dotenv()

# Security
DEBUG = False
SECRET_KEY = os.getenv('SECRET_KEY')
ALLOWED_HOSTS = [h.strip() for h in os.getenv('ALLOWED_HOSTS', '').split(',') if h.strip()]

# HTTPS
SECURE_SSL_REDIRECT = True
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
SECURE_BROWSER_XSS_FILTER = True
SECURE_CONTENT_TYPE_NOSNIFF = True
X_FRAME_OPTIONS = 'DENY'

# HSTS
SECURE_HSTS_SECONDS = 31536000
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True
```

### Static Files Configuration

```python
# settings/prod.py
import os

STATIC_URL = '/static/'
STATIC_ROOT = os.path.join(BASE_DIR, 'staticfiles')

MEDIA_URL = '/media/'
MEDIA_ROOT = os.path.join(BASE_DIR, 'media')

# WhiteNoise for static files
MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'whitenoise.middleware.WhiteNoiseMiddleware',  # Add this
    # ... other middleware
]

STATICFILES_STORAGE = 'whitenoise.storage.CompressedManifestStaticFilesStorage'
```

### Requirements File

```txt
# requirements.txt
Django==4.2.0
gunicorn==21.2.0
whitenoise==6.5.0
python-dotenv==1.0.0
psycopg2-binary==2.9.9
django-cors-headers==4.3.0
```

## Azure App Service Deployment

Deploy Django to Azure App Service (PaaS).

### Prerequisites

```bash
# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Login to Azure
az login

# Create resource group
az group create \
  --name myResourceGroup \
  --location eastus
```

### Create PostgreSQL Database

```bash
# Create PostgreSQL server
az postgres flexible-server create \
  --resource-group myResourceGroup \
  --name mypostgresserver \
  --location eastus \
  --admin-user myadmin \
  --admin-password <YourPassword> \
  --sku-name Standard_B1ms \
  --tier Burstable \
  --version 14 \
  --storage-size 32

# Create database
az postgres flexible-server db create \
  --resource-group myResourceGroup \
  --server-name mypostgresserver \
  --database-name mydatabase

# Configure firewall to allow Azure services
az postgres flexible-server firewall-rule create \
  --resource-group myResourceGroup \
  --name mypostgresserver \
  --rule-name AllowAzureServices \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0
```

### Create App Service

```bash
# Create App Service plan
az appservice plan create \
  --name myAppServicePlan \
  --resource-group myResourceGroup \
  --sku B1 \
  --is-linux

# Create web app
az webapp create \
  --resource-group myResourceGroup \
  --plan myAppServicePlan \
  --name mydjango-app \
  --runtime "PYTHON:3.11"
```

### Configure App Service

```bash
# Set environment variables
az webapp config appsettings set \
  --resource-group myResourceGroup \
  --name mydjango-app \
  --settings \
    SECRET_KEY="your-secret-key" \
    DEBUG="False" \
    ALLOWED_HOSTS="mydjango-app.azurewebsites.net" \
    DB_NAME="mydatabase" \
    DB_USER="myadmin" \
    DB_PASSWORD="<YourPassword>" \
    DB_HOST="mypostgresserver.postgres.database.azure.com" \
    DB_PORT="5432" \
    DJANGO_SETTINGS_MODULE="myproject.settings.prod"
```

### Deployment Files

```bash
# startup.sh
#!/bin/bash

# Collect static files
python manage.py collectstatic --noinput

# Run migrations
python manage.py migrate --noinput

# Start Gunicorn
gunicorn myproject.wsgi:application \
  --bind=0.0.0.0:8000 \
  --workers=4 \
  --timeout=600 \
  --access-logfile=- \
  --error-logfile=-
```

```bash
# Make startup script executable
chmod +x startup.sh
```

### Configure Startup Command

```bash
# Set startup command
az webapp config set \
  --resource-group myResourceGroup \
  --name mydjango-app \
  --startup-file "startup.sh"
```

### Deploy with Git

```bash
# Get deployment credentials
az webapp deployment user set \
  --user-name <username> \
  --password <password>

# Get Git URL
az webapp deployment source config-local-git \
  --name mydjango-app \
  --resource-group myResourceGroup

# Add Azure remote
git remote add azure <git-url>

# Deploy
git add .
git commit -m "Initial deployment"
git push azure main
```

### Deploy with ZIP

```bash
# Create deployment package
zip -r deploy.zip . -x "*.git*" "venv/*" "*.pyc" "__pycache__/*"

# Deploy
az webapp deployment source config-zip \
  --resource-group myResourceGroup \
  --name mydjango-app \
  --src deploy.zip
```

### Custom Domain and SSL

```bash
# Add custom domain
az webapp config hostname add \
  --webapp-name mydjango-app \
  --resource-group myResourceGroup \
  --hostname www.example.com

# Enable HTTPS
az webapp update \
  --name mydjango-app \
  --resource-group myResourceGroup \
  --https-only true
```

## AWS App Runner Deployment

Deploy Django to AWS App Runner (Container-based PaaS).

### Prerequisites

```bash
# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Configure AWS CLI
aws configure
```

### Create RDS Database

```bash
# Create RDS PostgreSQL database
aws rds create-db-instance \
  --db-instance-identifier mydjango-db \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --engine-version 14.7 \
  --master-username myadmin \
  --master-user-password <YourPassword> \
  --allocated-storage 20 \
  --db-name mydatabase \
  --backup-retention-period 7 \
  --publicly-accessible

# Get database endpoint
aws rds describe-db-instances \
  --db-instance-identifier mydjango-db \
  --query 'DBInstances[0].Endpoint.Address'
```

### Create ECR Repository

```bash
# Create ECR repository
aws ecr create-repository \
  --repository-name mydjango-app \
  --region us-east-1

# Get login credentials
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  <account-id>.dkr.ecr.us-east-1.amazonaws.com
```

### Build and Push Docker Image

```dockerfile
# Dockerfile (see Docker section below for complete file)
FROM python:3.11-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

RUN python manage.py collectstatic --noinput

EXPOSE 8000

CMD ["gunicorn", "myproject.wsgi:application", "--bind", "0.0.0.0:8000"]
```

```bash
# Build image
docker build -t mydjango-app .

# Tag image
docker tag mydjango-app:latest \
  <account-id>.dkr.ecr.us-east-1.amazonaws.com/mydjango-app:latest

# Push to ECR
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/mydjango-app:latest
```

### Create App Runner Service

```bash
# Create apprunner.yaml
cat > apprunner.yaml << 'EOF'
version: 1.0
runtime: python3
build:
  commands:
    build:
      - pip install -r requirements.txt
      - python manage.py collectstatic --noinput
run:
  runtime-version: 3.11
  command: gunicorn myproject.wsgi:application --bind 0.0.0.0:8000
  network:
    port: 8000
  env:
    - name: DJANGO_SETTINGS_MODULE
      value: myproject.settings.prod
EOF
```

```bash
# Create App Runner service using AWS Console or CLI
aws apprunner create-service \
  --service-name mydjango-app \
  --source-configuration '{
    "ImageRepository": {
      "ImageIdentifier": "<account-id>.dkr.ecr.us-east-1.amazonaws.com/mydjango-app:latest",
      "ImageRepositoryType": "ECR",
      "ImageConfiguration": {
        "Port": "8000",
        "RuntimeEnvironmentVariables": {
          "SECRET_KEY": "your-secret-key",
          "DEBUG": "False",
          "ALLOWED_HOSTS": "*",
          "DB_NAME": "mydatabase",
          "DB_USER": "myadmin",
          "DB_PASSWORD": "<YourPassword>",
          "DB_HOST": "<rds-endpoint>",
          "DB_PORT": "5432"
        }
      }
    },
    "AutoDeploymentsEnabled": true
  }' \
  --instance-configuration '{
    "Cpu": "1 vCPU",
    "Memory": "2 GB"
  }'
```

### Auto-Deploy from GitHub

```bash
# Create service with GitHub source
aws apprunner create-service \
  --service-name mydjango-app \
  --source-configuration '{
    "CodeRepository": {
      "RepositoryUrl": "https://github.com/username/mydjango-app",
      "SourceCodeVersion": {
        "Type": "BRANCH",
        "Value": "main"
      },
      "CodeConfiguration": {
        "ConfigurationSource": "API",
        "CodeConfigurationValues": {
          "Runtime": "PYTHON_3",
          "BuildCommand": "pip install -r requirements.txt && python manage.py collectstatic --noinput",
          "StartCommand": "gunicorn myproject.wsgi:application --bind 0.0.0.0:8000",
          "Port": "8000",
          "RuntimeEnvironmentVariables": {
            "SECRET_KEY": "your-secret-key"
          }
        }
      }
    },
    "AutoDeploymentsEnabled": true
  }'
```

## VPS/EC2 Deployment

Deploy Django to a Virtual Private Server or AWS EC2 instance.

### Launch EC2 Instance

```bash
# Create key pair
aws ec2 create-key-pair \
  --key-name mydjango-key \
  --query 'KeyMaterial' \
  --output text > mydjango-key.pem

chmod 400 mydjango-key.pem

# Create security group
aws ec2 create-security-group \
  --group-name mydjango-sg \
  --description "Django app security group"

# Allow SSH (port 22)
aws ec2 authorize-security-group-ingress \
  --group-name mydjango-sg \
  --protocol tcp \
  --port 22 \
  --cidr 0.0.0.0/0

# Allow HTTP (port 80)
aws ec2 authorize-security-group-ingress \
  --group-name mydjango-sg \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0

# Allow HTTPS (port 443)
aws ec2 authorize-security-group-ingress \
  --group-name mydjango-sg \
  --protocol tcp \
  --port 443 \
  --cidr 0.0.0.0/0

# Launch instance (Ubuntu 22.04)
aws ec2 run-instances \
  --image-id ami-0c7217cdde317cfec \
  --instance-type t2.micro \
  --key-name mydjango-key \
  --security-groups mydjango-sg \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=mydjango-server}]'
```

### Connect to Server

```bash
# Get instance public IP
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=mydjango-server" \
  --query 'Reservations[0].Instances[0].PublicIpAddress'

# SSH into server
ssh -i mydjango-key.pem ubuntu@<public-ip>
```

### Server Setup

```bash
# Update system
sudo apt update
sudo apt upgrade -y

# Install Python and dependencies
sudo apt install -y python3.11 python3.11-venv python3-pip
sudo apt install -y postgresql postgresql-contrib
sudo apt install -y nginx
sudo apt install -y git

# Install system dependencies for Python packages
sudo apt install -y build-essential libpq-dev
```

### Setup PostgreSQL

```bash
# Switch to postgres user
sudo -u postgres psql

# In PostgreSQL shell
CREATE DATABASE mydatabase;
CREATE USER myuser WITH PASSWORD 'mypassword';
ALTER ROLE myuser SET client_encoding TO 'utf8';
ALTER ROLE myuser SET default_transaction_isolation TO 'read committed';
ALTER ROLE myuser SET timezone TO 'UTC';
GRANT ALL PRIVILEGES ON DATABASE mydatabase TO myuser;
\q
```

### Deploy Application

```bash
# Create app directory
sudo mkdir -p /var/www/mydjango
sudo chown -R $USER:$USER /var/www/mydjango

# Clone repository
cd /var/www/mydjango
git clone https://github.com/username/mydjango-app.git .

# Create virtual environment
python3.11 -m venv venv
source venv/bin/activate

# Install dependencies
pip install --upgrade pip
pip install -r requirements.txt

# Create .env file
cat > .env << 'EOF'
SECRET_KEY=your-secret-key-here
DEBUG=False
ALLOWED_HOSTS=your-domain.com,www.your-domain.com
DB_NAME=mydatabase
DB_USER=myuser
DB_PASSWORD=mypassword
DB_HOST=localhost
DB_PORT=5432
EOF

# Run migrations
python manage.py migrate

# Collect static files
python manage.py collectstatic --noinput

# Create superuser
python manage.py createsuperuser
```

### Setup Gunicorn

```bash
# Test Gunicorn
gunicorn myproject.wsgi:application --bind 0.0.0.0:8000

# Create Gunicorn systemd service
sudo nano /etc/systemd/system/gunicorn.service
```

```ini
[Unit]
Description=Gunicorn daemon for Django project
After=network.target

[Service]
User=ubuntu
Group=www-data
WorkingDirectory=/var/www/mydjango
Environment="PATH=/var/www/mydjango/venv/bin"
EnvironmentFile=/var/www/mydjango/.env
ExecStart=/var/www/mydjango/venv/bin/gunicorn \
  --workers 3 \
  --bind unix:/var/www/mydjango/gunicorn.sock \
  myproject.wsgi:application

[Install]
WantedBy=multi-user.target
```

```bash
# Start and enable Gunicorn
sudo systemctl start gunicorn
sudo systemctl enable gunicorn
sudo systemctl status gunicorn
```

### Setup Nginx

```bash
# Create Nginx configuration
sudo nano /etc/nginx/sites-available/mydjango
```

```nginx
server {
    listen 80;
    server_name your-domain.com www.your-domain.com;

    location = /favicon.ico { access_log off; log_not_found off; }

    location /static/ {
        alias /var/www/mydjango/staticfiles/;
    }

    location /media/ {
        alias /var/www/mydjango/media/;
    }

    location / {
        include proxy_params;
        proxy_pass http://unix:/var/www/mydjango/gunicorn.sock;
    }
}
```

```bash
# Enable site
sudo ln -s /etc/nginx/sites-available/mydjango /etc/nginx/sites-enabled/

# Test Nginx configuration
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx
```

### SSL with Let's Encrypt

```bash
# Install Certbot
sudo apt install -y certbot python3-certbot-nginx

# Get SSL certificate
sudo certbot --nginx -d your-domain.com -d www.your-domain.com

# Auto-renewal test
sudo certbot renew --dry-run
```

### Automated Deployment Script

```bash
# deploy.sh
#!/bin/bash

echo "Starting deployment..."

# Navigate to project directory
cd /var/www/mydjango

# Pull latest changes
git pull origin main

# Activate virtual environment
source venv/bin/activate

# Install/update dependencies
pip install -r requirements.txt

# Run migrations
python manage.py migrate --noinput

# Collect static files
python manage.py collectstatic --noinput

# Restart Gunicorn
sudo systemctl restart gunicorn

# Restart Nginx
sudo systemctl restart nginx

echo "Deployment complete!"
```

```bash
# Make script executable
chmod +x deploy.sh

# Run deployment
./deploy.sh
```

## Dockerizing Django Application

Complete guide to containerizing your Django application.

### Production Dockerfile

```dockerfile
# Dockerfile
FROM python:3.11-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Set work directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    postgresql-client \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy project
COPY . .

# Collect static files
RUN python manage.py collectstatic --noinput

# Create non-root user
RUN useradd -m -u 1000 django && \
    chown -R django:django /app
USER django

# Expose port
EXPOSE 8000

# Run gunicorn
CMD ["gunicorn", "myproject.wsgi:application", \
     "--bind", "0.0.0.0:8000", \
     "--workers", "4", \
     "--timeout", "120"]
```

### Multi-Stage Dockerfile

```dockerfile
# Dockerfile.multistage
# Build stage
FROM python:3.11-slim as builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

# Runtime stage
FROM python:3.11-slim

WORKDIR /app

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    postgresql-client \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy Python dependencies from builder
COPY --from=builder /root/.local /root/.local
ENV PATH=/root/.local/bin:$PATH

# Copy project
COPY . .

# Collect static files
RUN python manage.py collectstatic --noinput

# Create non-root user
RUN useradd -m -u 1000 django && \
    chown -R django:django /app
USER django

EXPOSE 8000

CMD ["gunicorn", "myproject.wsgi:application", \
     "--bind", "0.0.0.0:8000"]
```

### Docker Compose

```yaml
# docker-compose.yml
version: '3.8'

services:
  db:
    image: postgres:15-alpine
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      - POSTGRES_DB=mydatabase
      - POSTGRES_USER=myuser
      - POSTGRES_PASSWORD=mypassword
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U myuser -d mydatabase"]
      interval: 10s
      timeout: 5s
      retries: 5

  web:
    build: .
    command: gunicorn myproject.wsgi:application --bind 0.0.0.0:8000
    volumes:
      - .:/app
      - static_volume:/app/staticfiles
      - media_volume:/app/media
    ports:
      - "8000:8000"
    env_file:
      - .env
    depends_on:
      db:
        condition: service_healthy

  nginx:
    image: nginx:alpine
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - static_volume:/app/staticfiles
      - media_volume:/app/media
    ports:
      - "80:80"
      - "443:443"
    depends_on:
      - web

volumes:
  postgres_data:
  static_volume:
  media_volume:
```

### Production Docker Compose

```yaml
# docker-compose.prod.yml
version: '3.8'

services:
  db:
    image: postgres:15-alpine
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      - POSTGRES_DB=${DB_NAME}
      - POSTGRES_USER=${DB_USER}
      - POSTGRES_PASSWORD=${DB_PASSWORD}
    restart: unless-stopped
    networks:
      - django-network

  web:
    build:
      context: .
      dockerfile: Dockerfile
    command: >
      sh -c "python manage.py migrate --noinput &&
             python manage.py collectstatic --noinput &&
             gunicorn myproject.wsgi:application
             --bind 0.0.0.0:8000
             --workers 4
             --timeout 120
             --access-logfile -
             --error-logfile -"
    volumes:
      - static_volume:/app/staticfiles
      - media_volume:/app/media
    env_file:
      - .env.prod
    depends_on:
      - db
    restart: unless-stopped
    networks:
      - django-network

  nginx:
    image: nginx:alpine
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf
      - ./nginx/ssl:/etc/nginx/ssl
      - static_volume:/app/staticfiles
      - media_volume:/app/media
    ports:
      - "80:80"
      - "443:443"
    depends_on:
      - web
    restart: unless-stopped
    networks:
      - django-network

volumes:
  postgres_data:
  static_volume:
  media_volume:

networks:
  django-network:
    driver: bridge
```

### Nginx Configuration for Docker

```nginx
# nginx/nginx.conf
upstream django {
    server web:8000;
}

server {
    listen 80;
    server_name your-domain.com www.your-domain.com;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 301 https://$host$request_uri;
    }
}

server {
    listen 443 ssl http2;
    server_name your-domain.com www.your-domain.com;

    ssl_certificate /etc/nginx/ssl/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/privkey.pem;

    client_max_body_size 100M;

    location /static/ {
        alias /app/staticfiles/;
    }

    location /media/ {
        alias /app/media/;
    }

    location / {
        proxy_pass http://django;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Host $host;
        proxy_redirect off;
    }
}
```

### Docker Commands

```bash
# Build image
docker build -t mydjango-app .

# Run container
docker run -p 8000:8000 --env-file .env mydjango-app

# Docker Compose commands
docker-compose up -d                    # Start services
docker-compose down                     # Stop services
docker-compose logs -f web              # View logs
docker-compose exec web python manage.py migrate
docker-compose exec web python manage.py createsuperuser
docker-compose restart web              # Restart service

# Production
docker-compose -f docker-compose.prod.yml up -d --build
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml exec web python manage.py migrate
```

### .dockerignore

```
# .dockerignore
*.pyc
__pycache__
db.sqlite3
.env
.git
.gitignore
.vscode
venv/
.pytest_cache
.coverage
htmlcov/
*.log
media/
staticfiles/
```

### Environment Variables for Docker

```.env
# .env.prod
SECRET_KEY=your-production-secret-key
DEBUG=False
ALLOWED_HOSTS=your-domain.com,www.your-domain.com

DB_ENGINE=django.db.backends.postgresql
DB_NAME=mydatabase
DB_USER=myuser
DB_PASSWORD=mypassword
DB_HOST=db
DB_PORT=5432

DJANGO_SETTINGS_MODULE=myproject.settings.prod
```

## CI/CD Pipeline

### GitHub Actions for Azure

```yaml
# .github/workflows/azure-deploy.yml
name: Deploy to Azure App Service

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v3

    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.11'

    - name: Install dependencies
      run: |
        pip install -r requirements.txt

    - name: Run tests
      run: |
        python manage.py test

    - name: Deploy to Azure
      uses: azure/webapps-deploy@v2
      with:
        app-name: mydjango-app
        publish-profile: ${{ secrets.AZURE_WEBAPP_PUBLISH_PROFILE }}
```

### GitHub Actions for AWS

```yaml
# .github/workflows/aws-deploy.yml
name: Deploy to AWS App Runner

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v3

    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v2
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: us-east-1

    - name: Login to Amazon ECR
      id: login-ecr
      uses: aws-actions/amazon-ecr-login@v1

    - name: Build and push Docker image
      env:
        ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
        ECR_REPOSITORY: mydjango-app
        IMAGE_TAG: ${{ github.sha }}
      run: |
        docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
        docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG

    - name: Deploy to App Runner
      run: |
        aws apprunner update-service \
          --service-arn ${{ secrets.APP_RUNNER_SERVICE_ARN }} \
          --source-configuration ImageRepository={ImageIdentifier=${{ steps.login-ecr.outputs.registry }}/mydjango-app:${{ github.sha }}}
```

## Monitoring and Maintenance

### Health Check Endpoint

```python
# views.py
from django.http import JsonResponse
from django.db import connection

def health_check(request):
    try:
        # Check database connection
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
        return JsonResponse({'status': 'healthy', 'database': 'connected'})
    except Exception as e:
        return JsonResponse(
            {'status': 'unhealthy', 'error': str(e)},
            status=500
        )

# urls.py
urlpatterns = [
    path('health/', health_check),
]
```

### Logging

```python
# settings/prod.py
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'verbose': {
            'format': '{levelname} {asctime} {module} {message}',
            'style': '{',
        },
    },
    'handlers': {
        'file': {
            'level': 'ERROR',
            'class': 'logging.handlers.RotatingFileHandler',
            'filename': '/var/log/django/error.log',
            'maxBytes': 1024 * 1024 * 15,  # 15MB
            'backupCount': 10,
            'formatter': 'verbose',
        },
        'console': {
            'level': 'INFO',
            'class': 'logging.StreamHandler',
            'formatter': 'verbose',
        },
    },
    'root': {
        'handlers': ['console', 'file'],
        'level': 'INFO',
    },
    'loggers': {
        'django': {
            'handlers': ['console', 'file'],
            'level': 'INFO',
            'propagate': False,
        },
    },
}
```

## Additional Resources

- [Azure App Service Documentation](https://docs.microsoft.com/en-us/azure/app-service/)
- [AWS App Runner Documentation](https://docs.aws.amazon.com/apprunner/)
- [Docker Documentation](https://docs.docker.com/)
- [Gunicorn Documentation](https://docs.gunicorn.org/)
- [Nginx Documentation](https://nginx.org/en/docs/)
