---
icon: lucide/key
---

# Environment Variables in Production

Managing environment variables properly is critical for secure Django deployments across different environments.

## Why Environment Variables?

Environment variables keep sensitive data out of your codebase:

- Database credentials
- API keys and secrets
- Django SECRET_KEY
- Third-party service credentials
- Environment-specific configurations

## Environment Types

### Development
Local machine, debug mode enabled, fake data acceptable.

### Staging
Production-like environment for testing, real-like data, no debug mode.

### Production
Live environment, real users, highest security, no debug mode.

## Django Settings Pattern

### Base Settings Structure

```python
# settings/
#   __init__.py
#   base.py      # Common settings
#   dev.py       # Development
#   staging.py   # Staging
#   prod.py      # Production

# settings/base.py
import os
from pathlib import Path
from dotenv import load_dotenv

BASE_DIR = Path(__file__).resolve().parent.parent

# Load .env file
load_dotenv(BASE_DIR / '.env')

SECRET_KEY = os.getenv('SECRET_KEY')
DEBUG = os.getenv('DEBUG', 'False').lower() in ('true', '1', 't')
ALLOWED_HOSTS = [h.strip() for h in os.getenv('ALLOWED_HOSTS', '').split(',') if h.strip()]

# Common settings for all environments
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    # ... your apps
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    # ... middleware
]
```

### Development Settings

```python
# settings/dev.py
from .base import *

DEBUG = True
ALLOWED_HOSTS = ['localhost', '127.0.0.1']

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    }
}

# Development-only apps
INSTALLED_APPS += [
    'debug_toolbar',
]

MIDDLEWARE += [
    'debug_toolbar.middleware.DebugToolbarMiddleware',
]

# Email to console
EMAIL_BACKEND = 'django.core.mail.backends.console.EmailBackend'
```

### Production Settings

```python
# settings/prod.py
import os
from .base import *

DEBUG = False
ALLOWED_HOSTS = [h.strip() for h in os.getenv('ALLOWED_HOSTS', '').split(',') if h.strip()]

# Security settings
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

# Database
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.getenv('DB_NAME'),
        'USER': os.getenv('DB_USER'),
        'PASSWORD': os.getenv('DB_PASSWORD'),
        'HOST': os.getenv('DB_HOST'),
        'PORT': os.getenv('DB_PORT', '5432'),
    }
}

# Static files
STATIC_ROOT = os.path.join(BASE_DIR, 'staticfiles')
STATICFILES_STORAGE = 'whitenoise.storage.CompressedManifestStaticFilesStorage'

# Logging
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'handlers': {
        'file': {
            'level': 'ERROR',
            'class': 'logging.FileHandler',
            'filename': '/var/log/django/error.log',
        },
    },
    'loggers': {
        'django': {
            'handlers': ['file'],
            'level': 'ERROR',
            'propagate': True,
        },
    },
}
```

### Using Different Settings

```python
# manage.py
import os
import sys

if __name__ == '__main__':
    # Default to development
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'myproject.settings.dev')
    # ... rest of manage.py

# Run with specific settings
python manage.py runserver --settings=myproject.settings.dev
python manage.py migrate --settings=myproject.settings.prod

# Or set environment variable
export DJANGO_SETTINGS_MODULE=myproject.settings.prod
python manage.py runserver
```

## AWS-Specific Solutions

### AWS Systems Manager Parameter Store

Store secrets in AWS Parameter Store:

```bash
# Store parameters
aws ssm put-parameter \
    --name "/myapp/prod/SECRET_KEY" \
    --value "your-secret-key" \
    --type "SecureString"

aws ssm put-parameter \
    --name "/myapp/prod/DB_PASSWORD" \
    --value "your-db-password" \
    --type "SecureString"
```

```python
# settings/prod.py
import boto3

def get_parameter(param_name):
    """Fetch parameter from AWS Parameter Store"""
    ssm = boto3.client('ssm', region_name='us-east-1')
    response = ssm.get_parameter(
        Name=param_name,
        WithDecryption=True
    )
    return response['Parameter']['Value']

# Use in settings
SECRET_KEY = get_parameter('/myapp/prod/SECRET_KEY')
DB_PASSWORD = get_parameter('/myapp/prod/DB_PASSWORD')
```

### AWS Secrets Manager

More advanced secret management:

```python
import boto3
import json
from botocore.exceptions import ClientError

def get_secret(secret_name, region_name='us-east-1'):
    """Retrieve secret from AWS Secrets Manager"""
    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name=region_name
    )

    try:
        response = client.get_secret_value(SecretId=secret_name)
        if 'SecretString' in response:
            return json.loads(response['SecretString'])
        else:
            return response['SecretBinary']
    except ClientError as e:
        raise e

# In settings
secrets = get_secret('myapp/prod/database')
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': secrets['dbname'],
        'USER': secrets['username'],
        'PASSWORD': secrets['password'],
        'HOST': secrets['host'],
        'PORT': secrets['port'],
    }
}
```

### AWS Elastic Beanstalk

Set environment variables in EB configuration:

```bash
# Using EB CLI
eb setenv SECRET_KEY="your-secret-key" \
         DEBUG=False \
         DB_NAME=mydb \
         DB_USER=myuser \
         DB_PASSWORD=mypassword

# Or in .ebextensions/environment.config
option_settings:
  aws:elasticbeanstalk:application:environment:
    DJANGO_SETTINGS_MODULE: myproject.settings.prod
    PYTHONPATH: /opt/python/current/app
```

### AWS EC2 with User Data

Pass environment variables on instance launch:

```bash
#!/bin/bash
# User data script
export SECRET_KEY="your-secret-key"
export DB_PASSWORD="your-db-password"

# Or write to file
cat > /etc/environment << EOF
SECRET_KEY="your-secret-key"
DB_PASSWORD="your-db-password"
DJANGO_SETTINGS_MODULE="myproject.settings.prod"
EOF
```

### AWS Lambda

Environment variables in Lambda configuration:

```python
# serverless.yml (Serverless Framework)
provider:
  name: aws
  runtime: python3.11
  environment:
    SECRET_KEY: ${env:SECRET_KEY}
    DB_HOST: ${env:DB_HOST}
    DEBUG: false

# Or in AWS Console:
# Configuration > Environment variables
```

## Using python-dotenv

Best practice for reading environment variables:

```bash
pip install python-dotenv
```

```python
# settings.py
import os
from pathlib import Path
from dotenv import load_dotenv

# Build paths
BASE_DIR = Path(__file__).resolve().parent.parent

# Load environment variables from .env file
load_dotenv(BASE_DIR / '.env')

# String values
SECRET_KEY = os.getenv('SECRET_KEY')
DB_NAME = os.getenv('DB_NAME', 'mydb')  # with default

# Boolean values
DEBUG = os.getenv('DEBUG', 'False').lower() in ('true', '1', 't')

# Integer values
MAX_CONNECTIONS = int(os.getenv('MAX_CONNECTIONS', '10'))

# Lists (comma-separated)
ALLOWED_HOSTS = os.getenv('ALLOWED_HOSTS', '').split(',')

# Custom parsing
def parse_redis_url(url):
    # Custom parsing logic
    return parsed_config

REDIS_URL = parse_redis_url(os.getenv('REDIS_URL', ''))
```

```.env
# .env file (never commit this!)
SECRET_KEY=your-development-secret-key
DEBUG=True
DB_NAME=dev_database
ALLOWED_HOSTS=localhost,127.0.0.1
MAX_CONNECTIONS=5
```

## Helper Functions for Type Conversion

Create utility functions for common conversions:

```python
# settings/utils.py
import os

def get_bool(key, default='False'):
    """Convert environment variable to boolean"""
    value = os.getenv(key, default)
    return value.lower() in ('true', '1', 't', 'yes')

def get_int(key, default=0):
    """Convert environment variable to integer"""
    try:
        return int(os.getenv(key, str(default)))
    except ValueError:
        return default

def get_list(key, default='', separator=','):
    """Convert environment variable to list"""
    value = os.getenv(key, default)
    return [item.strip() for item in value.split(separator) if item.strip()]

def get_db_config():
    """Parse DATABASE_URL or individual database settings"""
    database_url = os.getenv('DATABASE_URL')

    if database_url:
        # Parse DATABASE_URL format: postgresql://user:pass@host:port/dbname
        import re
        pattern = r'(?P<engine>\w+)://(?P<user>[^:]+):(?P<password>[^@]+)@(?P<host>[^:]+):(?P<port>\d+)/(?P<name>.+)'
        match = re.match(pattern, database_url)

        if match:
            engine_map = {
                'postgresql': 'django.db.backends.postgresql',
                'mysql': 'django.db.backends.mysql',
                'sqlite': 'django.db.backends.sqlite3',
            }
            return {
                'ENGINE': engine_map.get(match.group('engine')),
                'NAME': match.group('name'),
                'USER': match.group('user'),
                'PASSWORD': match.group('password'),
                'HOST': match.group('host'),
                'PORT': match.group('port'),
            }

    # Fallback to individual settings
    return {
        'ENGINE': os.getenv('DB_ENGINE', 'django.db.backends.postgresql'),
        'NAME': os.getenv('DB_NAME'),
        'USER': os.getenv('DB_USER'),
        'PASSWORD': os.getenv('DB_PASSWORD'),
        'HOST': os.getenv('DB_HOST', 'localhost'),
        'PORT': os.getenv('DB_PORT', '5432'),
    }

# settings.py
from pathlib import Path
from dotenv import load_dotenv
from .utils import get_bool, get_int, get_list, get_db_config

BASE_DIR = Path(__file__).resolve().parent.parent
load_dotenv(BASE_DIR / '.env')

# Use helper functions
DEBUG = get_bool('DEBUG', 'False')
ALLOWED_HOSTS = get_list('ALLOWED_HOSTS')
MAX_CONNECTIONS = get_int('MAX_CONNECTIONS', 10)

# Database
DATABASES = {
    'default': get_db_config()
}
```

```.env
DEBUG=False
SECRET_KEY=your-secret-key
ALLOWED_HOSTS=yourdomain.com,www.yourdomain.com
DATABASE_URL=postgresql://user:password@localhost:5432/dbname
# Or individual settings:
# DB_NAME=mydb
# DB_USER=myuser
# DB_PASSWORD=mypassword
# DB_HOST=localhost
# DB_PORT=5432
```

## Environment File Templates

### .env.example

```bash
# .env.example - Commit this to version control
# Copy to .env and fill in real values

# Django
SECRET_KEY=generate-a-random-secret-key
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1

# Database
DB_ENGINE=django.db.backends.postgresql
DB_NAME=mydb
DB_USER=myuser
DB_PASSWORD=changeme
DB_HOST=localhost
DB_PORT=5432

# Email
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_HOST_USER=your-email@gmail.com
EMAIL_HOST_PASSWORD=your-app-password
EMAIL_USE_TLS=True

# AWS
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
AWS_STORAGE_BUCKET_NAME=your-bucket
AWS_S3_REGION_NAME=us-east-1

# External APIs
STRIPE_PUBLIC_KEY=pk_test_xxx
STRIPE_SECRET_KEY=sk_test_xxx
SENTRY_DSN=https://xxx@sentry.io/xxx
```

## Docker Environment Variables

### Docker Compose

```yaml
# docker-compose.yml
version: '3.8'

services:
  web:
    build: .
    environment:
      - SECRET_KEY=${SECRET_KEY}
      - DEBUG=False
      - DB_HOST=db
    env_file:
      - .env
    depends_on:
      - db

  db:
    image: postgres:15
    environment:
      POSTGRES_DB: ${DB_NAME}
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
```

### Dockerfile

```dockerfile
# Dockerfile
FROM python:3.11-slim

# Accept build arguments
ARG DJANGO_SETTINGS_MODULE=myproject.settings.prod
ENV DJANGO_SETTINGS_MODULE=${DJANGO_SETTINGS_MODULE}

# Environment variables set at runtime
ENV PYTHONUNBUFFERED=1

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Build-time secrets (not recommended for sensitive data)
ARG SECRET_KEY
ENV SECRET_KEY=${SECRET_KEY}

EXPOSE 8000
CMD ["gunicorn", "myproject.wsgi:application", "--bind", "0.0.0.0:8000"]
```

## Best Practices

### 1. Never Commit Secrets

```bash
# .gitignore
.env
.env.local
.env.*.local
*.pem
*.key
secrets/
```

### 2. Different Keys per Environment

```python
# Each environment should have unique keys
# Development: dev-secret-key-xxx
# Staging: staging-secret-key-xxx
# Production: prod-secret-key-xxx
```

### 3. Rotate Secrets Regularly

```python
# Implement secret rotation
from datetime import datetime, timedelta

def should_rotate_secret(last_rotation_date):
    """Check if secret should be rotated (every 90 days)"""
    rotation_period = timedelta(days=90)
    return datetime.now() - last_rotation_date > rotation_period
```

### 4. Use Secret Management Services

- AWS Secrets Manager
- AWS Parameter Store
- HashiCorp Vault
- Azure Key Vault
- Google Secret Manager

### 5. Least Privilege Principle

```python
# IAM Policy for accessing secrets
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Resource": [
        "arn:aws:secretsmanager:us-east-1:account-id:secret:myapp/*"
      ]
    }
  ]
}
```

### 6. Validate Environment Variables

```python
# settings.py
import sys

REQUIRED_ENV_VARS = [
    'SECRET_KEY',
    'DB_NAME',
    'DB_USER',
    'DB_PASSWORD',
]

missing_vars = [var for var in REQUIRED_ENV_VARS if not config(var, default=None)]

if missing_vars:
    print(f"Error: Missing required environment variables: {', '.join(missing_vars)}")
    sys.exit(1)
```

### 7. Audit Access to Secrets

```python
import logging

logger = logging.getLogger(__name__)

def get_secret_with_audit(secret_name):
    """Get secret and log access"""
    logger.info(f"Accessing secret: {secret_name}")
    secret = get_secret(secret_name)
    logger.info(f"Secret {secret_name} accessed successfully")
    return secret
```

## Security Checklist

- [ ] All secrets in environment variables, not code
- [ ] `.env` file in `.gitignore`
- [ ] `.env.example` committed for reference
- [ ] Different secrets per environment
- [ ] Secrets encrypted at rest (AWS Secrets Manager, etc.)
- [ ] Minimal permissions for accessing secrets
- [ ] Regular secret rotation schedule
- [ ] Audit logging for secret access
- [ ] No secrets in Docker images
- [ ] Secrets removed from logs
- [ ] Backup strategy for secrets

## Common Pitfalls to Avoid

### 1. Hardcoding Secrets

```python
# DON'T
SECRET_KEY = 'hardcoded-secret-key-123'

# DO
SECRET_KEY = config('SECRET_KEY')
```

### 2. Committing .env Files

```bash
# Make sure .env is in .gitignore
echo ".env" >> .gitignore
```

### 3. Exposing Secrets in Logs

```python
# DON'T
logger.info(f"Database password: {DB_PASSWORD}")

# DO
logger.info("Database connection established")
```

### 4. Using Weak Default Values

```python
# DON'T
SECRET_KEY = config('SECRET_KEY', default='weak-default')

# DO
SECRET_KEY = config('SECRET_KEY')  # Fail if not set
```

## Additional Resources

- [AWS Secrets Manager Documentation](https://docs.aws.amazon.com/secretsmanager/)
- [AWS Systems Manager Parameter Store](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html)
- [python-decouple Documentation](https://github.com/henriquebastos/python-decouple)
- [django-environ Documentation](https://django-environ.readthedocs.io/)
- [12 Factor App - Config](https://12factor.net/config)
