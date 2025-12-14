---
icon: lucide/cloud
---

# Environment Variables in Azure

Managing environment variables and secrets in Azure for Django applications across different environments.

## Azure-Specific Solutions

### Azure App Service Configuration

Set environment variables in App Service:

```bash
# Using Azure CLI
az webapp config appsettings set \
    --name myapp \
    --resource-group myResourceGroup \
    --settings \
        SECRET_KEY="your-secret-key" \
        DEBUG=False \
        DB_NAME=mydb \
        DB_USER=myuser \
        DB_PASSWORD=mypassword

# List all settings
az webapp config appsettings list \
    --name myapp \
    --resource-group myResourceGroup

# Delete a setting
az webapp config appsettings delete \
    --name myapp \
    --resource-group myResourceGroup \
    --setting-names DEBUG
```

### Azure Portal Configuration

Configure via Azure Portal:
1. Navigate to your App Service
2. Go to **Configuration** > **Application settings**
3. Click **New application setting**
4. Add name/value pairs
5. Click **Save**

### Django Settings for Azure

```python
# settings/prod.py
import os
from dotenv import load_dotenv
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent
load_dotenv(BASE_DIR / '.env')

# Azure App Service sets this automatically
WEBSITE_HOSTNAME = os.environ.get('WEBSITE_HOSTNAME')

# Use Azure-specific environment variables
DEBUG = False
ALLOWED_HOSTS = [WEBSITE_HOSTNAME] if WEBSITE_HOSTNAME else []

# Database from App Service connection string
DB_CONNECTION_STRING = os.environ.get('AZURE_POSTGRESQL_CONNECTIONSTRING')

if DB_CONNECTION_STRING:
    # Parse connection string
    import re
    pattern = r"host=(?P<host>[^\s]+)\s+port=(?P<port>\d+)\s+dbname=(?P<dbname>[^\s]+)\s+user=(?P<user>[^\s]+)\s+password=(?P<password>[^\s]+)"
    match = re.match(pattern, DB_CONNECTION_STRING)

    if match:
        DATABASES = {
            'default': {
                'ENGINE': 'django.db.backends.postgresql',
                'NAME': match.group('dbname'),
                'USER': match.group('user'),
                'PASSWORD': match.group('password'),
                'HOST': match.group('host'),
                'PORT': match.group('port'),
                'OPTIONS': {
                    'sslmode': 'require',
                },
            }
        }
```

## Azure Key Vault

### Setting Up Key Vault

```bash
# Create Key Vault
az keyvault create \
    --name myapp-keyvault \
    --resource-group myResourceGroup \
    --location eastus

# Add secrets
az keyvault secret set \
    --vault-name myapp-keyvault \
    --name SECRET-KEY \
    --value "your-secret-key"

az keyvault secret set \
    --vault-name myapp-keyvault \
    --name DB-PASSWORD \
    --value "your-db-password"

# List secrets
az keyvault secret list \
    --vault-name myapp-keyvault
```

### Accessing Key Vault from Django

```bash
# Install Azure SDK
pip install azure-keyvault-secrets azure-identity
```

```python
# settings/prod.py
from azure.keyvault.secrets import SecretClient
from azure.identity import DefaultAzureCredential

def get_keyvault_secret(secret_name, vault_url):
    """Retrieve secret from Azure Key Vault"""
    credential = DefaultAzureCredential()
    client = SecretClient(vault_url=vault_url, credential=credential)

    try:
        secret = client.get_secret(secret_name)
        return secret.value
    except Exception as e:
        print(f"Error retrieving secret {secret_name}: {e}")
        return None

# Configuration
KEY_VAULT_URL = "https://myapp-keyvault.vault.azure.net/"

# Get secrets
SECRET_KEY = get_keyvault_secret('SECRET-KEY', KEY_VAULT_URL)
DB_PASSWORD = get_keyvault_secret('DB-PASSWORD', KEY_VAULT_URL)

# Database configuration
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': config('DB_NAME'),
        'USER': config('DB_USER'),
        'PASSWORD': DB_PASSWORD,
        'HOST': config('DB_HOST'),
        'PORT': config('DB_PORT', default='5432'),
        'OPTIONS': {
            'sslmode': 'require',
        },
    }
}
```

### Managed Identity for Key Vault Access

```bash
# Enable system-assigned managed identity
az webapp identity assign \
    --name myapp \
    --resource-group myResourceGroup

# Get the principal ID
PRINCIPAL_ID=$(az webapp identity show \
    --name myapp \
    --resource-group myResourceGroup \
    --query principalId \
    --output tsv)

# Grant access to Key Vault
az keyvault set-policy \
    --name myapp-keyvault \
    --object-id $PRINCIPAL_ID \
    --secret-permissions get list
```

### Key Vault References in App Settings

```bash
# Reference Key Vault secrets directly in App Settings
az webapp config appsettings set \
    --name myapp \
    --resource-group myResourceGroup \
    --settings \
        SECRET_KEY="@Microsoft.KeyVault(SecretUri=https://myapp-keyvault.vault.azure.net/secrets/SECRET-KEY/)" \
        DB_PASSWORD="@Microsoft.KeyVault(SecretUri=https://myapp-keyvault.vault.azure.net/secrets/DB-PASSWORD/)"
```

## Azure Container Apps

### Environment Variables in Container Apps

```bash
# Create container app with environment variables
az containerapp create \
    --name myapp \
    --resource-group myResourceGroup \
    --environment myEnvironment \
    --image mydockerimage:latest \
    --env-vars \
        SECRET_KEY=secretref:secret-key \
        DEBUG=False \
        DB_HOST=mydb.postgres.database.azure.com

# Update environment variables
az containerapp update \
    --name myapp \
    --resource-group myResourceGroup \
    --set-env-vars \
        NEW_VAR=newvalue
```

### Container Apps with Secrets

```bash
# Create secrets
az containerapp secret set \
    --name myapp \
    --resource-group myResourceGroup \
    --secrets \
        secret-key="your-secret-key" \
        db-password="your-db-password"

# Use secrets in environment variables
az containerapp update \
    --name myapp \
    --resource-group myResourceGroup \
    --set-env-vars \
        SECRET_KEY=secretref:secret-key \
        DB_PASSWORD=secretref:db-password
```

## Azure DevOps Pipeline Variables

### Variable Groups

```yaml
# azure-pipelines.yml
trigger:
  - main

pool:
  vmImage: 'ubuntu-latest'

variables:
  - group: dev-variables
  - group: prod-variables

stages:
  - stage: Deploy
    jobs:
      - job: DeployToProd
        condition: eq(variables['Build.SourceBranch'], 'refs/heads/main')
        variables:
          - group: prod-variables
        steps:
          - task: AzureWebApp@1
            inputs:
              azureSubscription: 'MyAzureSubscription'
              appName: 'myapp'
              appSettings: |
                -SECRET_KEY "$(SECRET_KEY)" \
                -DEBUG "False" \
                -DB_PASSWORD "$(DB_PASSWORD)"
```

### Azure Pipeline Secrets

```yaml
# azure-pipelines.yml
variables:
  - name: SECRET_KEY
    value: $(SECRET_KEY_FROM_LIBRARY)

steps:
  - script: |
      echo "##vso[task.setvariable variable=SECRET_KEY;isSecret=true]$(SECRET_KEY)"
    displayName: 'Set secret variable'

  - task: AzureWebApp@1
    inputs:
      azureSubscription: 'MyAzureSubscription'
      appName: 'myapp'
      package: '$(System.DefaultWorkingDirectory)/**/*.zip'
      appSettings: '-SECRET_KEY $(SECRET_KEY)'
```

## Azure Functions

### Function App Settings

```python
# __init__.py (Azure Function)
import os
import logging
import azure.functions as func

def main(req: func.HttpRequest) -> func.HttpResponse:
    # Access environment variables
    secret_key = os.environ.get('SECRET_KEY')
    db_password = os.environ.get('DB_PASSWORD')

    # Your Django logic here
    return func.HttpResponse("OK", status_code=200)
```

```bash
# Set Function App settings
az functionapp config appsettings set \
    --name myfunction \
    --resource-group myResourceGroup \
    --settings \
        SECRET_KEY="your-secret-key" \
        DB_PASSWORD="@Microsoft.KeyVault(SecretUri=...)"
```

## Azure App Configuration

### Using App Configuration Service

```bash
# Create App Configuration store
az appconfig create \
    --name myapp-config \
    --resource-group myResourceGroup \
    --location eastus

# Add key-values
az appconfig kv set \
    --name myapp-config \
    --key "Django:SecretKey" \
    --value "your-secret-key"

az appconfig kv set \
    --name myapp-config \
    --key "Django:Debug" \
    --value "False"
```

```python
# settings.py
from azure.appconfiguration import AzureAppConfigurationClient
from azure.identity import DefaultAzureCredential

def load_azure_app_config():
    """Load configuration from Azure App Configuration"""
    connection_string = os.environ.get('AZURE_APPCONFIG_CONNECTION_STRING')

    if connection_string:
        client = AzureAppConfigurationClient.from_connection_string(connection_string)

        # Get configuration values
        secret_key = client.get_configuration_setting(key="Django:SecretKey").value
        debug = client.get_configuration_setting(key="Django:Debug").value

        return {
            'SECRET_KEY': secret_key,
            'DEBUG': debug.lower() == 'true',
        }
    return {}

# Load configuration
config_values = load_azure_app_config()
SECRET_KEY = config_values.get('SECRET_KEY', config('SECRET_KEY'))
DEBUG = config_values.get('DEBUG', False)
```

## Environment-Specific Settings

### Development Environment

```python
# settings/dev.py
import os

DEBUG = True
ALLOWED_HOSTS = ['localhost', '127.0.0.1']

# Local database
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    }
}

# Development-only settings
INSTALLED_APPS += ['debug_toolbar']
MIDDLEWARE += ['debug_toolbar.middleware.DebugToolbarMiddleware']

# Email to console
EMAIL_BACKEND = 'django.core.mail.backends.console.EmailBackend'
```

### Staging Environment

```python
# settings/staging.py
from .base import *

DEBUG = config('DEBUG', default=False, cast=bool)
ALLOWED_HOSTS = ['myapp-staging.azurewebsites.net']

# Azure PostgreSQL
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.getenv('STAGING_DB_NAME'),
        'USER': os.getenv('STAGING_DB_USER'),
        'PASSWORD': os.getenv('STAGING_DB_PASSWORD'),
        'HOST': os.getenv('STAGING_DB_HOST'),
        'PORT': '5432',
        'OPTIONS': {
            'sslmode': 'require',
        },
    }
}

# Staging-specific logging
LOGGING = {
    'version': 1,
    'handlers': {
        'azure': {
            'class': 'logging.StreamHandler',
        },
    },
    'loggers': {
        'django': {
            'handlers': ['azure'],
            'level': 'INFO',
        },
    },
}
```

### Production Environment

```python
# settings/prod.py
from .base import *
from azure.keyvault.secrets import SecretClient
from azure.identity import DefaultAzureCredential

# Azure Key Vault
KEY_VAULT_URL = os.getenv('KEY_VAULT_URL')
credential = DefaultAzureCredential()
secret_client = SecretClient(vault_url=KEY_VAULT_URL, credential=credential)

def get_secret(secret_name):
    return secret_client.get_secret(secret_name).value

# Production settings
DEBUG = False
SECRET_KEY = get_secret('SECRET-KEY')
ALLOWED_HOSTS = [config('WEBSITE_HOSTNAME')]

# Azure PostgreSQL
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.getenv('DB_NAME'),
        'USER': os.getenv('DB_USER'),
        'PASSWORD': get_secret('DB-PASSWORD'),
        'HOST': os.getenv('DB_HOST'),
        'PORT': '5432',
        'OPTIONS': {
            'sslmode': 'require',
        },
    }
}

# Security settings
SECURE_SSL_REDIRECT = True
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
SECURE_HSTS_SECONDS = 31536000
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True

# Azure Blob Storage for static/media files
AZURE_ACCOUNT_NAME = os.getenv('AZURE_ACCOUNT_NAME')
AZURE_ACCOUNT_KEY = get_secret('AZURE-STORAGE-KEY')
AZURE_CONTAINER = os.getenv('AZURE_CONTAINER')

DEFAULT_FILE_STORAGE = 'storages.backends.azure_storage.AzureStorage'
STATICFILES_STORAGE = 'storages.backends.azure_storage.AzureStorage'

AZURE_CUSTOM_DOMAIN = f'{AZURE_ACCOUNT_NAME}.blob.core.windows.net'
STATIC_URL = f'https://{AZURE_CUSTOM_DOMAIN}/{AZURE_CONTAINER}/static/'
MEDIA_URL = f'https://{AZURE_CUSTOM_DOMAIN}/{AZURE_CONTAINER}/media/'
```

## Docker with Azure

### Dockerfile for Azure

```dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY . .

# Environment variables from Azure
ENV PYTHONUNBUFFERED=1
ENV PORT=8000

# Collect static files
RUN python manage.py collectstatic --noinput

# Run gunicorn
CMD gunicorn myproject.wsgi:application --bind 0.0.0.0:$PORT
```

### Azure Container Registry

```bash
# Create ACR
az acr create \
    --name myappregistry \
    --resource-group myResourceGroup \
    --sku Basic

# Login to ACR
az acr login --name myappregistry

# Build and push image
docker build -t myappregistry.azurecr.io/myapp:latest .
docker push myappregistry.azurecr.io/myapp:latest

# Deploy to App Service
az webapp create \
    --name myapp \
    --resource-group myResourceGroup \
    --plan myAppServicePlan \
    --deployment-container-image-name myappregistry.azurecr.io/myapp:latest

# Set environment variables
az webapp config appsettings set \
    --name myapp \
    --resource-group myResourceGroup \
    --settings \
        DJANGO_SETTINGS_MODULE=myproject.settings.prod \
        WEBSITES_PORT=8000
```

## Infrastructure as Code

### Azure Resource Manager (ARM) Template

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "appName": {
      "type": "string"
    },
    "secretKey": {
      "type": "securestring"
    }
  },
  "resources": [
    {
      "type": "Microsoft.Web/sites",
      "apiVersion": "2021-02-01",
      "name": "[parameters('appName')]",
      "location": "[resourceGroup().location]",
      "properties": {
        "siteConfig": {
          "appSettings": [
            {
              "name": "SECRET_KEY",
              "value": "[parameters('secretKey')]"
            },
            {
              "name": "DEBUG",
              "value": "False"
            }
          ]
        }
      }
    }
  ]
}
```

### Bicep Template

```bicep
param appName string
param location string = resourceGroup().location

@secure()
param secretKey string

resource appService 'Microsoft.Web/sites@2021-02-01' = {
  name: appName
  location: location
  properties: {
    siteConfig: {
      appSettings: [
        {
          name: 'SECRET_KEY'
          value: secretKey
        }
        {
          name: 'DEBUG'
          value: 'False'
        }
        {
          name: 'DJANGO_SETTINGS_MODULE'
          value: 'myproject.settings.prod'
        }
      ]
    }
  }
}
```

### Terraform for Azure

```hcl
# main.tf
resource "azurerm_app_service" "main" {
  name                = "myapp"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  app_service_plan_id = azurerm_app_service_plan.main.id

  app_settings = {
    "SECRET_KEY"              = var.secret_key
    "DEBUG"                   = "False"
    "DJANGO_SETTINGS_MODULE"  = "myproject.settings.prod"
    "DB_NAME"                 = var.db_name
    "DB_HOST"                 = azurerm_postgresql_server.main.fqdn
    "DB_PASSWORD"             = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.db_password.id})"
  }

  connection_string {
    name  = "DefaultConnection"
    type  = "PostgreSQL"
    value = "Server=${azurerm_postgresql_server.main.fqdn};Database=${var.db_name};User Id=${var.db_user};Password=${var.db_password};SSL Mode=Require;"
  }
}

# Key Vault secret
resource "azurerm_key_vault_secret" "db_password" {
  name         = "db-password"
  value        = var.db_password
  key_vault_id = azurerm_key_vault.main.id
}
```

## Best Practices for Azure

### 1. Use Key Vault for Secrets

```bash
# Always store sensitive data in Key Vault
az keyvault secret set \
    --vault-name myapp-keyvault \
    --name SECRET-KEY \
    --value "$(openssl rand -base64 32)"
```

### 2. Enable Managed Identity

```bash
# System-assigned identity
az webapp identity assign \
    --name myapp \
    --resource-group myResourceGroup

# User-assigned identity
az identity create \
    --name myapp-identity \
    --resource-group myResourceGroup

az webapp identity assign \
    --name myapp \
    --resource-group myResourceGroup \
    --identities /subscriptions/{sub-id}/resourcegroups/{rg}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/myapp-identity
```

### 3. Use Deployment Slots

```bash
# Create staging slot
az webapp deployment slot create \
    --name myapp \
    --resource-group myResourceGroup \
    --slot staging

# Set slot-specific settings
az webapp config appsettings set \
    --name myapp \
    --resource-group myResourceGroup \
    --slot staging \
    --settings DEBUG=True \
    --slot-settings DEBUG

# Swap slots
az webapp deployment slot swap \
    --name myapp \
    --resource-group myResourceGroup \
    --slot staging
```

### 4. Monitor and Audit

```python
# Application Insights
APPLICATIONINSIGHTS_CONNECTION_STRING = os.getenv('APPINSIGHTS_CONNECTION_STRING')

LOGGING = {
    'version': 1,
    'handlers': {
        'appinsights': {
            'class': 'applicationinsights.django.LoggingHandler',
        },
    },
    'loggers': {
        'django': {
            'handlers': ['appinsights'],
            'level': 'INFO',
        },
    },
}
```

## Security Checklist for Azure

- [ ] All secrets in Key Vault
- [ ] Managed Identity enabled
- [ ] Key Vault access policies configured
- [ ] SSL/TLS enforced
- [ ] HTTPS redirect enabled
- [ ] Security headers configured
- [ ] Application Insights enabled
- [ ] Diagnostic logging enabled
- [ ] Network security groups configured
- [ ] Regular secret rotation
- [ ] Backup strategy in place
- [ ] Disaster recovery plan

## Additional Resources

- [Azure Key Vault Documentation](https://docs.microsoft.com/en-us/azure/key-vault/)
- [Azure App Service Documentation](https://docs.microsoft.com/en-us/azure/app-service/)
- [Azure App Configuration](https://docs.microsoft.com/en-us/azure/azure-app-configuration/)
- [Managed Identities](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/)
- [Azure Container Apps](https://docs.microsoft.com/en-us/azure/container-apps/)
