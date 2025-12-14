---
icon: lucide/cloud
---

# Azure App Service Deployment

Complete guide to deploying Django applications to Azure App Service, a fully managed platform for building, deploying, and scaling web apps.

## Overview

Azure App Service is a Platform as a Service (PaaS) offering that supports multiple programming languages including Python. It handles infrastructure management, scaling, and security, allowing you to focus on your application.

## Prerequisites

### Install Azure CLI

```bash
# Windows (using MSI installer)
# Download from: https://aka.ms/installazurecliwindows

# macOS
brew install azure-cli

# Linux (Ubuntu/Debian)
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Linux (using pip)
pip install azure-cli

# Verify installation
az --version
```

### Login to Azure

```bash
# Login interactively
az login

# Login with service principal (for CI/CD)
az login --service-principal \
  --username <app-id> \
  --password <password-or-cert> \
  --tenant <tenant-id>

# Set default subscription
az account set --subscription <subscription-id>

# List subscriptions
az account list --output table
```

## Prepare Django Application

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

### Production Settings

```python
# settings/prod.py
import os
from dotenv import load_dotenv
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent
load_dotenv(BASE_DIR / '.env')

# Azure App Service sets this automatically
WEBSITE_HOSTNAME = os.environ.get('WEBSITE_HOSTNAME')

DEBUG = False
SECRET_KEY = os.getenv('SECRET_KEY')
ALLOWED_HOSTS = [WEBSITE_HOSTNAME] if WEBSITE_HOSTNAME else []

# Database
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.getenv('DB_NAME'),
        'USER': os.getenv('DB_USER'),
        'PASSWORD': os.getenv('DB_PASSWORD'),
        'HOST': os.getenv('DB_HOST'),
        'PORT': os.getenv('DB_PORT', '5432'),
        'OPTIONS': {
            'sslmode': 'require',
        },
    }
}

# Static files with WhiteNoise
MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'whitenoise.middleware.WhiteNoiseMiddleware',  # Add this
    # ... other middleware
]

STATIC_URL = '/static/'
STATIC_ROOT = os.path.join(BASE_DIR, 'staticfiles')
STATICFILES_STORAGE = 'whitenoise.storage.CompressedManifestStaticFilesStorage'

# Security settings
SECURE_SSL_REDIRECT = True
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
SECURE_BROWSER_XSS_FILTER = True
SECURE_CONTENT_TYPE_NOSNIFF = True
X_FRAME_OPTIONS = 'DENY'

SECURE_HSTS_SECONDS = 31536000
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True

# Logging
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
        'console': {
            'class': 'logging.StreamHandler',
            'formatter': 'verbose',
        },
    },
    'root': {
        'handlers': ['console'],
        'level': 'INFO',
    },
}
```

### Startup Script

Create a startup script for App Service:

```bash
# startup.sh
#!/bin/bash

echo "Starting Django application..."

# Collect static files
echo "Collecting static files..."
python manage.py collectstatic --noinput

# Run migrations
echo "Running database migrations..."
python manage.py migrate --noinput

# Start Gunicorn
echo "Starting Gunicorn..."
gunicorn myproject.wsgi:application \
  --bind=0.0.0.0:8000 \
  --workers=4 \
  --timeout=600 \
  --access-logfile=- \
  --error-logfile=- \
  --log-level=info
```

```bash
# Make it executable
chmod +x startup.sh
```

## Create Azure Resources

### Create Resource Group

```bash
# Create resource group
az group create \
  --name myDjangoResourceGroup \
  --location eastus

# List available locations
az account list-locations --output table
```

### Create PostgreSQL Database

```bash
# Create PostgreSQL Flexible Server
az postgres flexible-server create \
  --resource-group myDjangoResourceGroup \
  --name mydjango-db-server \
  --location eastus \
  --admin-user myadmin \
  --admin-password '<YourStrongPassword123!>' \
  --sku-name Standard_B1ms \
  --tier Burstable \
  --version 14 \
  --storage-size 32 \
  --public-access 0.0.0.0

# Create database
az postgres flexible-server db create \
  --resource-group myDjangoResourceGroup \
  --server-name mydjango-db-server \
  --database-name mydatabase

# Get connection details
az postgres flexible-server show \
  --resource-group myDjangoResourceGroup \
  --name mydjango-db-server \
  --query "{fqdn:fullyQualifiedDomainName}" \
  --output tsv
```

### Configure Firewall Rules

```bash
# Allow Azure services
az postgres flexible-server firewall-rule create \
  --resource-group myDjangoResourceGroup \
  --name mydjango-db-server \
  --rule-name AllowAzureServices \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0

# Allow specific IP (for local development)
az postgres flexible-server firewall-rule create \
  --resource-group myDjangoResourceGroup \
  --name mydjango-db-server \
  --rule-name AllowMyIP \
  --start-ip-address <your-ip> \
  --end-ip-address <your-ip>
```

## Create App Service

### Create App Service Plan

```bash
# Create Linux App Service Plan
az appservice plan create \
  --name myDjangoAppPlan \
  --resource-group myDjangoResourceGroup \
  --sku B1 \
  --is-linux

# Available SKUs: F1 (Free), B1 (Basic), S1 (Standard), P1V2 (Premium)
```

### Create Web App

```bash
# Create web app with Python 3.11
az webapp create \
  --resource-group myDjangoResourceGroup \
  --plan myDjangoAppPlan \
  --name mydjango-app \
  --runtime "PYTHON:3.11"

# List available runtimes
az webapp list-runtimes --os linux --output table
```

## Configure App Service

### Set Environment Variables

```bash
# Configure application settings (environment variables)
az webapp config appsettings set \
  --resource-group myDjangoResourceGroup \
  --name mydjango-app \
  --settings \
    SECRET_KEY="your-secret-key-here" \
    DEBUG="False" \
    ALLOWED_HOSTS="mydjango-app.azurewebsites.net" \
    DB_NAME="mydatabase" \
    DB_USER="myadmin" \
    DB_PASSWORD="<YourStrongPassword123!>" \
    DB_HOST="mydjango-db-server.postgres.database.azure.com" \
    DB_PORT="5432" \
    DJANGO_SETTINGS_MODULE="myproject.settings.prod" \
    WEBSITE_HTTPLOGGING_RETENTION_DAYS="7"
```

### Configure Startup Command

```bash
# Set startup command
az webapp config set \
  --resource-group myDjangoResourceGroup \
  --name mydjango-app \
  --startup-file "startup.sh"
```

### Configure Web Server

```bash
# Enable HTTP logging
az webapp log config \
  --resource-group myDjangoResourceGroup \
  --name mydjango-app \
  --application-logging filesystem \
  --detailed-error-messages true \
  --failed-request-tracing true \
  --web-server-logging filesystem

# Configure connection strings (alternative to app settings)
az webapp config connection-string set \
  --resource-group myDjangoResourceGroup \
  --name mydjango-app \
  --connection-string-type PostgreSQL \
  --settings DefaultConnection="Server=mydjango-db-server.postgres.database.azure.com;Database=mydatabase;User Id=myadmin;Password=<password>;SSL Mode=Require;"
```

## Deploy Application

### Option 1: Local Git Deployment

```bash
# Configure deployment user (one time only)
az webapp deployment user set \
  --user-name <username> \
  --password <password>

# Get Git URL
az webapp deployment source config-local-git \
  --name mydjango-app \
  --resource-group myDjangoResourceGroup \
  --query url \
  --output tsv

# Add Azure remote
git remote add azure <git-url>

# Deploy
git add .
git commit -m "Deploy to Azure"
git push azure main
```

### Option 2: GitHub Actions Deployment

Create GitHub Actions workflow:

```yaml
# .github/workflows/azure-deploy.yml
name: Deploy to Azure App Service

on:
  push:
    branches: [ main ]

env:
  AZURE_WEBAPP_NAME: mydjango-app
  PYTHON_VERSION: '3.11'

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v3

    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: ${{ env.PYTHON_VERSION }}

    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install -r requirements.txt

    - name: Run tests
      run: |
        python manage.py test

    - name: Collect static files
      run: |
        python manage.py collectstatic --noinput

    - name: Deploy to Azure Web App
      uses: azure/webapps-deploy@v2
      with:
        app-name: ${{ env.AZURE_WEBAPP_NAME }}
        publish-profile: ${{ secrets.AZURE_WEBAPP_PUBLISH_PROFILE }}
```

Get publish profile:

```bash
# Download publish profile
az webapp deployment list-publishing-profiles \
  --name mydjango-app \
  --resource-group myDjangoResourceGroup \
  --xml

# Add to GitHub Secrets as AZURE_WEBAPP_PUBLISH_PROFILE
```

### Option 3: ZIP Deployment

```bash
# Create deployment package
zip -r deploy.zip . -x "*.git*" "venv/*" "*.pyc" "__pycache__/*"

# Deploy via ZIP
az webapp deployment source config-zip \
  --resource-group myDjangoResourceGroup \
  --name mydjango-app \
  --src deploy.zip
```

### Option 4: Azure DevOps Pipeline

```yaml
# azure-pipelines.yml
trigger:
- main

pool:
  vmImage: 'ubuntu-latest'

variables:
  pythonVersion: '3.11'
  azureSubscription: 'MyAzureSubscription'
  webAppName: 'mydjango-app'

stages:
- stage: Build
  jobs:
  - job: BuildJob
    steps:
    - task: UsePythonVersion@0
      inputs:
        versionSpec: '$(pythonVersion)'

    - script: |
        python -m pip install --upgrade pip
        pip install -r requirements.txt
      displayName: 'Install dependencies'

    - script: |
        python manage.py test
      displayName: 'Run tests'

    - task: ArchiveFiles@2
      inputs:
        rootFolderOrFile: '$(Build.SourcesDirectory)'
        includeRootFolder: false
        archiveType: 'zip'
        archiveFile: '$(Build.ArtifactStagingDirectory)/$(Build.BuildId).zip'

    - publish: $(Build.ArtifactStagingDirectory)/$(Build.BuildId).zip
      artifact: drop

- stage: Deploy
  dependsOn: Build
  jobs:
  - deployment: DeployWeb
    environment: 'production'
    strategy:
      runOnce:
        deploy:
          steps:
          - task: AzureWebApp@1
            inputs:
              azureSubscription: '$(azureSubscription)'
              appName: '$(webAppName)'
              package: '$(Pipeline.Workspace)/drop/$(Build.BuildId).zip'
```

## Post-Deployment Tasks

### Run Migrations

```bash
# SSH into App Service
az webapp ssh \
  --name mydjango-app \
  --resource-group myDjangoResourceGroup

# Inside SSH session
python manage.py migrate
python manage.py createsuperuser
exit
```

### Configure Custom Domain

```bash
# Map custom domain
az webapp config hostname add \
  --webapp-name mydjango-app \
  --resource-group myDjangoResourceGroup \
  --hostname www.example.com

# Update ALLOWED_HOSTS
az webapp config appsettings set \
  --resource-group myDjangoResourceGroup \
  --name mydjango-app \
  --settings ALLOWED_HOSTS="mydjango-app.azurewebsites.net,www.example.com"
```

### Enable HTTPS/SSL

```bash
# Enable HTTPS only
az webapp update \
  --resource-group myDjangoResourceGroup \
  --name mydjango-app \
  --https-only true

# Create managed certificate (free)
az webapp config ssl create \
  --resource-group myDjangoResourceGroup \
  --name mydjango-app \
  --hostname www.example.com

# Bind certificate
az webapp config ssl bind \
  --resource-group myDjangoResourceGroup \
  --name mydjango-app \
  --certificate-thumbprint <thumbprint> \
  --ssl-type SNI
```

## Monitoring and Logging

### View Logs

```bash
# Stream logs
az webapp log tail \
  --resource-group myDjangoResourceGroup \
  --name mydjango-app

# Download logs
az webapp log download \
  --resource-group myDjangoResourceGroup \
  --name mydjango-app \
  --log-file logs.zip
```

### Application Insights

```bash
# Create Application Insights
az monitor app-insights component create \
  --app mydjango-insights \
  --location eastus \
  --resource-group myDjangoResourceGroup \
  --application-type web

# Get instrumentation key
az monitor app-insights component show \
  --app mydjango-insights \
  --resource-group myDjangoResourceGroup \
  --query instrumentationKey \
  --output tsv

# Configure in Django
az webapp config appsettings set \
  --resource-group myDjangoResourceGroup \
  --name mydjango-app \
  --settings APPINSIGHTS_INSTRUMENTATIONKEY="<key>"
```

```python
# Install Application Insights SDK
pip install applicationinsights

# settings.py
INSTALLED_APPS += ['applicationinsights.django']

MIDDLEWARE += ['applicationinsights.django.ApplicationInsightsMiddleware']

APPLICATIONINSIGHTS_CONNECTION_STRING = os.getenv('APPINSIGHTS_CONNECTION_STRING')
```

## Scaling

### Manual Scaling

```bash
# Scale up (change pricing tier)
az appservice plan update \
  --name myDjangoAppPlan \
  --resource-group myDjangoResourceGroup \
  --sku S1

# Scale out (add instances)
az appservice plan update \
  --name myDjangoAppPlan \
  --resource-group myDjangoResourceGroup \
  --number-of-workers 3
```

### Auto-Scaling

```bash
# Enable autoscale
az monitor autoscale create \
  --resource-group myDjangoResourceGroup \
  --resource myDjangoAppPlan \
  --resource-type Microsoft.Web/serverfarms \
  --name myDjangoAutoscale \
  --min-count 1 \
  --max-count 5 \
  --count 2

# Add CPU-based rule
az monitor autoscale rule create \
  --resource-group myDjangoResourceGroup \
  --autoscale-name myDjangoAutoscale \
  --condition "Percentage CPU > 70 avg 5m" \
  --scale out 1

az monitor autoscale rule create \
  --resource-group myDjangoResourceGroup \
  --autoscale-name myDjangoAutoscale \
  --condition "Percentage CPU < 30 avg 5m" \
  --scale in 1
```

## Deployment Slots

Use deployment slots for staging and production environments.

```bash
# Create staging slot
az webapp deployment slot create \
  --name mydjango-app \
  --resource-group myDjangoResourceGroup \
  --slot staging

# Configure staging slot
az webapp config appsettings set \
  --resource-group myDjangoResourceGroup \
  --name mydjango-app \
  --slot staging \
  --settings DEBUG="True" \
             DB_NAME="staging_db"

# Deploy to staging
git push azure-staging main

# Test staging
# https://mydjango-app-staging.azurewebsites.net

# Swap staging to production
az webapp deployment slot swap \
  --resource-group myDjangoResourceGroup \
  --name mydjango-app \
  --slot staging \
  --target-slot production
```

## Continuous Deployment

### Configure from GitHub

```bash
# Enable GitHub deployment
az webapp deployment source config \
  --name mydjango-app \
  --resource-group myDjangoResourceGroup \
  --repo-url https://github.com/username/mydjango-app \
  --branch main \
  --manual-integration

# With GitHub Actions (recommended)
# Use the GitHub Actions workflow shown earlier
```

## Azure Key Vault Integration

Store secrets securely in Azure Key Vault.

```bash
# Create Key Vault
az keyvault create \
  --name mydjango-keyvault \
  --resource-group myDjangoResourceGroup \
  --location eastus

# Add secrets
az keyvault secret set \
  --vault-name mydjango-keyvault \
  --name SECRET-KEY \
  --value "your-secret-key"

az keyvault secret set \
  --vault-name mydjango-keyvault \
  --name DB-PASSWORD \
  --value "your-db-password"

# Enable managed identity for App Service
az webapp identity assign \
  --name mydjango-app \
  --resource-group myDjangoResourceGroup

# Grant access to Key Vault
az keyvault set-policy \
  --name mydjango-keyvault \
  --object-id <app-service-identity-id> \
  --secret-permissions get list

# Reference in App Settings
az webapp config appsettings set \
  --resource-group myDjangoResourceGroup \
  --name mydjango-app \
  --settings SECRET_KEY="@Microsoft.KeyVault(SecretUri=https://mydjango-keyvault.vault.azure.net/secrets/SECRET-KEY/)"
```

```python
# Or use Azure SDK in Django
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

KEY_VAULT_URL = os.getenv('KEY_VAULT_URL')
credential = DefaultAzureCredential()
client = SecretClient(vault_url=KEY_VAULT_URL, credential=credential)

SECRET_KEY = client.get_secret('SECRET-KEY').value
DB_PASSWORD = client.get_secret('DB-PASSWORD').value
```

## Static Files with Azure Blob Storage

```bash
# Create storage account
az storage account create \
  --name mydjangostore \
  --resource-group myDjangoResourceGroup \
  --location eastus \
  --sku Standard_LRS

# Create container
az storage container create \
  --name static \
  --account-name mydjangostore \
  --public-access blob

# Get connection string
az storage account show-connection-string \
  --name mydjangostore \
  --resource-group myDjangoResourceGroup \
  --output tsv
```

```python
# Install django-storages
pip install django-storages[azure]

# settings.py
INSTALLED_APPS += ['storages']

AZURE_ACCOUNT_NAME = os.getenv('AZURE_ACCOUNT_NAME')
AZURE_ACCOUNT_KEY = os.getenv('AZURE_ACCOUNT_KEY')
AZURE_CONTAINER = 'static'

DEFAULT_FILE_STORAGE = 'storages.backends.azure_storage.AzureStorage'
STATICFILES_STORAGE = 'storages.backends.azure_storage.AzureStorage'

AZURE_CUSTOM_DOMAIN = f'{AZURE_ACCOUNT_NAME}.blob.core.windows.net'
STATIC_URL = f'https://{AZURE_CUSTOM_DOMAIN}/{AZURE_CONTAINER}/'
MEDIA_URL = f'https://{AZURE_CUSTOM_DOMAIN}/media/'
```

## Troubleshooting

### View Application Logs

```bash
# Enable detailed error messages
az webapp config set \
  --resource-group myDjangoResourceGroup \
  --name mydjango-app \
  --detailed-error-logging-enabled true

# View logs
az webapp log tail \
  --resource-group myDjangoResourceGroup \
  --name mydjango-app
```

### SSH into App Service

```bash
# SSH into the container
az webapp ssh \
  --name mydjango-app \
  --resource-group myDjangoResourceGroup

# Check Python version
python --version

# Check installed packages
pip list

# View environment variables
env | grep DJANGO

# Test database connection
python manage.py dbshell
```

### Common Issues

**Issue: Application won't start**
```bash
# Check startup logs
az webapp log tail -n mydjango-app -g myDjangoResourceGroup

# Verify startup command
az webapp config show \
  --name mydjango-app \
  --resource-group myDjangoResourceGroup \
  --query linuxFxVersion
```

**Issue: Static files not loading**
```python
# Verify WhiteNoise is configured
# Make sure collectstatic runs during deployment
python manage.py collectstatic --noinput
```

**Issue: Database connection errors**
```bash
# Check firewall rules
az postgres flexible-server firewall-rule list \
  --resource-group myDjangoResourceGroup \
  --name mydjango-db-server

# Test connection
psql "host=mydjango-db-server.postgres.database.azure.com \
      port=5432 \
      dbname=mydatabase \
      user=myadmin \
      sslmode=require"
```

## Cost Optimization

```bash
# Use Free tier for development
az appservice plan create \
  --name myDevAppPlan \
  --resource-group myDjangoResourceGroup \
  --sku F1 \
  --is-linux

# Stop app when not in use
az webapp stop \
  --name mydjango-app \
  --resource-group myDjangoResourceGroup

# Start app
az webapp start \
  --name mydjango-app \
  --resource-group myDjangoResourceGroup

# Delete resources when done
az group delete \
  --name myDjangoResourceGroup \
  --yes --no-wait
```

## Best Practices

1. **Use deployment slots** for zero-downtime deployments
2. **Enable Application Insights** for monitoring
3. **Use Azure Key Vault** for secrets
4. **Enable auto-scaling** for production workloads
5. **Use Azure CDN** for static files
6. **Configure custom domains** with SSL
7. **Enable diagnostic logging**
8. **Set up automated backups**
9. **Use managed identities** instead of credentials
10. **Implement CI/CD** with GitHub Actions or Azure DevOps

## Additional Resources

- [Azure App Service Documentation](https://docs.microsoft.com/azure/app-service/)
- [Python on Azure App Service](https://docs.microsoft.com/azure/app-service/quickstart-python)
- [Azure Database for PostgreSQL](https://docs.microsoft.com/azure/postgresql/)
- [Azure Key Vault](https://docs.microsoft.com/azure/key-vault/)
- [Application Insights](https://docs.microsoft.com/azure/azure-monitor/app/app-insights-overview)
