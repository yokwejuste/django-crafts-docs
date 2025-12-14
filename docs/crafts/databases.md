---
icon: lucide/database
---

# Database Integration in Django

Comprehensive guide to integrating SQL and NoSQL databases with Django, including PostgreSQL, MySQL, SQLite, and MongoDB.

## SQL Databases

Django's ORM (Object-Relational Mapping) natively supports multiple SQL databases.

## PostgreSQL - Recommended for Production

PostgreSQL is the recommended database for Django production deployments.

### Installation

```bash
# Install PostgreSQL
# Ubuntu/Debian
sudo apt update
sudo apt install postgresql postgresql-contrib

# macOS
brew install postgresql@15

# Start PostgreSQL
sudo systemctl start postgresql  # Linux
brew services start postgresql@15  # macOS
```

### Python Driver

```bash
# Install psycopg2 (PostgreSQL adapter)
pip install psycopg2-binary

# Or for production (compile from source)
pip install psycopg2

# With Poetry
poetry add psycopg2-binary

# With uv
uv pip install psycopg2-binary
```

### Django Configuration

```python
# settings.py
import os
from dotenv import load_dotenv

load_dotenv()

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.getenv('DB_NAME', 'mydatabase'),
        'USER': os.getenv('DB_USER', 'myuser'),
        'PASSWORD': os.getenv('DB_PASSWORD', 'mypassword'),
        'HOST': os.getenv('DB_HOST', 'localhost'),
        'PORT': os.getenv('DB_PORT', '5432'),
        'OPTIONS': {
            'connect_timeout': 10,
        },
    }
}
```

### Create Database and User

```bash
# Access PostgreSQL
sudo -u postgres psql

# In PostgreSQL shell
CREATE DATABASE mydatabase;
CREATE USER myuser WITH PASSWORD 'mypassword';
ALTER ROLE myuser SET client_encoding TO 'utf8';
ALTER ROLE myuser SET default_transaction_isolation TO 'read committed';
ALTER ROLE myuser SET timezone TO 'UTC';
GRANT ALL PRIVILEGES ON DATABASE mydatabase TO myuser;

# Exit
\q
```

### PostgreSQL-Specific Features

```python
# models.py
from django.contrib.postgres.fields import ArrayField, JSONField
from django.contrib.postgres.search import SearchVectorField
from django.db import models

class Article(models.Model):
    title = models.CharField(max_length=200)
    content = models.TextField()
    tags = ArrayField(models.CharField(max_length=50))  # Array field
    metadata = models.JSONField(default=dict)  # JSON field
    search_vector = SearchVectorField(null=True)  # Full-text search

    class Meta:
        indexes = [
            models.Index(fields=['title']),
        ]
```

### PostgreSQL Full-Text Search

```python
from django.contrib.postgres.search import SearchVector, SearchQuery, SearchRank

# Create search vector
Article.objects.update(search_vector=SearchVector('title', 'content'))

# Search
query = SearchQuery('django')
articles = Article.objects.annotate(
    rank=SearchRank(models.F('search_vector'), query)
).filter(search_vector=query).order_by('-rank')
```

## MySQL/MariaDB

MySQL and MariaDB are popular alternatives to PostgreSQL.

### Installation

```bash
# Install MySQL
# Ubuntu/Debian
sudo apt update
sudo apt install mysql-server

# macOS
brew install mysql

# Start MySQL
sudo systemctl start mysql  # Linux
brew services start mysql  # macOS
```

### Python Driver

```bash
# Install mysqlclient (recommended)
pip install mysqlclient

# Or PyMySQL (pure Python)
pip install pymysql

# With Poetry
poetry add mysqlclient

# With uv
uv pip install mysqlclient
```

### Django Configuration

```python
# settings.py
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.mysql',
        'NAME': os.getenv('DB_NAME', 'mydatabase'),
        'USER': os.getenv('DB_USER', 'myuser'),
        'PASSWORD': os.getenv('DB_PASSWORD', 'mypassword'),
        'HOST': os.getenv('DB_HOST', 'localhost'),
        'PORT': os.getenv('DB_PORT', '3306'),
        'OPTIONS': {
            'init_command': "SET sql_mode='STRICT_TRANS_TABLES'",
            'charset': 'utf8mb4',
        },
    }
}
```

### Create Database and User

```bash
# Access MySQL
sudo mysql -u root -p

# In MySQL shell
CREATE DATABASE mydatabase CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'myuser'@'localhost' IDENTIFIED BY 'mypassword';
GRANT ALL PRIVILEGES ON mydatabase.* TO 'myuser'@'localhost';
FLUSH PRIVILEGES;

# Exit
EXIT;
```

### Using PyMySQL

```python
# settings.py or __init__.py
import pymysql

pymysql.install_as_MySQLdb()

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.mysql',
        'NAME': 'mydatabase',
        # ... rest of config
    }
}
```

## SQLite - Development Database

SQLite is Django's default database, perfect for development and small projects.

### Django Configuration

```python
# settings/dev.py
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    }
}
```

### Pros and Cons

**Pros:**
- No installation required
- Zero configuration
- Perfect for development
- File-based (portable)

**Cons:**
- Not suitable for production
- Limited concurrent writes
- No user management
- Limited data types

## Multiple Database Configuration

Django supports multiple databases simultaneously.

```python
# settings.py
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'primary_db',
        'USER': 'primary_user',
        'PASSWORD': 'primary_pass',
        'HOST': 'localhost',
        'PORT': '5432',
    },
    'analytics': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'analytics_db',
        'USER': 'analytics_user',
        'PASSWORD': 'analytics_pass',
        'HOST': 'analytics.example.com',
        'PORT': '5432',
    },
    'legacy': {
        'ENGINE': 'django.db.backends.mysql',
        'NAME': 'legacy_db',
        'USER': 'legacy_user',
        'PASSWORD': 'legacy_pass',
        'HOST': 'legacy.example.com',
        'PORT': '3306',
    }
}
```

### Database Router

```python
# routers.py
class AnalyticsRouter:
    """Route analytics models to analytics database"""

    analytics_models = {'analytics'}

    def db_for_read(self, model, **hints):
        if model._meta.app_label in self.analytics_models:
            return 'analytics'
        return None

    def db_for_write(self, model, **hints):
        if model._meta.app_label in self.analytics_models:
            return 'analytics'
        return None

    def allow_relation(self, obj1, obj2, **hints):
        if (obj1._meta.app_label in self.analytics_models or
            obj2._meta.app_label in self.analytics_models):
            return True
        return None

    def allow_migrate(self, db, app_label, model_name=None, **hints):
        if app_label in self.analytics_models:
            return db == 'analytics'
        return None

# settings.py
DATABASE_ROUTERS = ['myproject.routers.AnalyticsRouter']
```

### Using Multiple Databases

```python
# Read from specific database
users = User.objects.using('analytics').all()

# Write to specific database
article = Article(title='Test')
article.save(using='analytics')

# Copy between databases
user = User.objects.using('default').get(pk=1)
user.save(using('analytics'))
```

## MongoDB - NoSQL Database

MongoDB is a popular NoSQL database that can be integrated with Django.

### Why MongoDB with Django?

- Document-oriented storage
- Flexible schema
- Horizontal scalability
- High performance for certain workloads
- Good for unstructured data

### Installation

```bash
# Install MongoDB
# Ubuntu/Debian
sudo apt-get install -y mongodb-org

# macOS
brew tap mongodb/brew
brew install mongodb-community@7.0

# Start MongoDB
sudo systemctl start mongod  # Linux
brew services start mongodb-community@7.0  # macOS
```

### Python Drivers

```bash
# Install pymongo (official MongoDB driver)
pip install pymongo

# Install djongo (Django ORM wrapper for MongoDB)
pip install djongo

# Install mongoengine (ODM for MongoDB)
pip install mongoengine

# With Poetry
poetry add pymongo djongo mongoengine

# With uv
uv pip install pymongo djongo mongoengine
```

## Option 1: Using Djongo

Djongo allows you to use Django's ORM with MongoDB.

### Configuration

```python
# settings.py
DATABASES = {
    'default': {
        'ENGINE': 'djongo',
        'NAME': 'mydatabase',
        'ENFORCE_SCHEMA': False,
        'CLIENT': {
            'host': os.getenv('MONGO_HOST', 'localhost'),
            'port': int(os.getenv('MONGO_PORT', '27017')),
            'username': os.getenv('MONGO_USER', ''),
            'password': os.getenv('MONGO_PASSWORD', ''),
            'authSource': 'admin',
            'authMechanism': 'SCRAM-SHA-1',
        }
    }
}
```

### Models with Djongo

```python
# models.py
from djongo import models

class Blog(models.Model):
    name = models.CharField(max_length=100)
    tagline = models.TextField()

    class Meta:
        db_table = 'blogs'

class Author(models.Model):
    name = models.CharField(max_length=100)
    email = models.EmailField()

    class Meta:
        db_table = 'authors'

class Entry(models.Model):
    blog = models.ForeignKey(Blog, on_delete=models.CASCADE)
    headline = models.CharField(max_length=255)
    body_text = models.TextField()
    authors = models.ManyToManyField(Author)
    published_date = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'entries'
```

### Embedded Documents

```python
from djongo import models

class BlogEntry(models.Model):
    _id = models.ObjectIdField()
    headline = models.CharField(max_length=255)
    body_text = models.TextField()

    class Meta:
        abstract = True

class MetaData(models.Model):
    views = models.IntegerField(default=0)
    likes = models.IntegerField(default=0)

    class Meta:
        abstract = True

class Blog(models.Model):
    _id = models.ObjectIdField()
    name = models.CharField(max_length=100)
    entries = models.ArrayField(
        model_container=BlogEntry,
    )
    metadata = models.EmbeddedField(
        model_container=MetaData,
    )

    objects = models.DjongoManager()

    class Meta:
        db_table = 'blogs'
```

## Option 2: Using MongoEngine

MongoEngine is an Object-Document Mapper (ODM) for MongoDB.

### Configuration

```python
# settings.py
from mongoengine import connect

# MongoDB connection
MONGODB_SETTINGS = {
    'db': os.getenv('MONGO_DB', 'mydatabase'),
    'host': os.getenv('MONGO_HOST', 'localhost'),
    'port': int(os.getenv('MONGO_PORT', 27017)),
    'username': os.getenv('MONGO_USER', ''),
    'password': os.getenv('MONGO_PASSWORD', ''),
    'authentication_source': 'admin',
}

connect(**MONGODB_SETTINGS)
```

### Models with MongoEngine

```python
# documents.py
from mongoengine import Document, EmbeddedDocument
from mongoengine.fields import (
    StringField, EmailField, DateTimeField,
    ListField, EmbeddedDocumentField, ReferenceField,
    IntField, DictField
)
from datetime import datetime

class Author(Document):
    name = StringField(required=True, max_length=100)
    email = EmailField(required=True, unique=True)
    bio = StringField()
    created_at = DateTimeField(default=datetime.utcnow)

    meta = {
        'collection': 'authors',
        'indexes': ['email']
    }

class Comment(EmbeddedDocument):
    author = StringField(required=True)
    content = StringField(required=True)
    created_at = DateTimeField(default=datetime.utcnow)
    likes = IntField(default=0)

class BlogPost(Document):
    title = StringField(required=True, max_length=200)
    slug = StringField(required=True, unique=True)
    content = StringField(required=True)
    author = ReferenceField(Author)
    tags = ListField(StringField(max_length=50))
    comments = ListField(EmbeddedDocumentField(Comment))
    metadata = DictField()
    published = DateTimeField()
    created_at = DateTimeField(default=datetime.utcnow)
    updated_at = DateTimeField(default=datetime.utcnow)
    views = IntField(default=0)

    meta = {
        'collection': 'blog_posts',
        'indexes': [
            'slug',
            'author',
            'tags',
            '-published'  # Descending index
        ]
    }
```

### CRUD Operations with MongoEngine

```python
# Create
author = Author(
    name='John Doe',
    email='john@example.com',
    bio='Software developer'
)
author.save()

# Create blog post
post = BlogPost(
    title='My First Post',
    slug='my-first-post',
    content='This is the content',
    author=author,
    tags=['django', 'mongodb', 'python']
)
post.save()

# Read
posts = BlogPost.objects(tags='django')
post = BlogPost.objects(slug='my-first-post').first()

# Update
post.update(set__views=post.views + 1)
post.reload()

# Or update and save
post.title = 'Updated Title'
post.save()

# Delete
post.delete()

# Query with filters
recent_posts = BlogPost.objects(
    published__gte=datetime(2024, 1, 1)
).order_by('-published')

# Aggregation
from mongoengine.queryset.visitor import Q

popular_posts = BlogPost.objects(
    Q(views__gte=100) | Q(comments__size__gte=10)
)
```

### Adding Comments (Embedded Documents)

```python
# Add comment to blog post
comment = Comment(
    author='Jane Doe',
    content='Great post!'
)

post = BlogPost.objects(slug='my-first-post').first()
post.comments.append(comment)
post.save()

# Update embedded document
post.update(inc__comments__0__likes=1)  # Increment first comment likes
```

## Option 3: Using PyMongo Directly

For maximum flexibility, use PyMongo directly without ORM.

### Configuration

```python
# database.py
from pymongo import MongoClient
import os

client = MongoClient(
    host=os.getenv('MONGO_HOST', 'localhost'),
    port=int(os.getenv('MONGO_PORT', 27017)),
    username=os.getenv('MONGO_USER', ''),
    password=os.getenv('MONGO_PASSWORD', ''),
)

db = client[os.getenv('MONGO_DB', 'mydatabase')]

# Collections
blogs_collection = db['blogs']
authors_collection = db['authors']
posts_collection = db['posts']
```

### CRUD Operations with PyMongo

```python
# views.py
from .database import posts_collection, authors_collection
from bson.objectid import ObjectId
from datetime import datetime

# Create
def create_post(request):
    post = {
        'title': 'My Post',
        'content': 'Post content',
        'author_id': ObjectId('...'),
        'tags': ['django', 'mongodb'],
        'created_at': datetime.utcnow(),
        'views': 0
    }
    result = posts_collection.insert_one(post)
    post_id = result.inserted_id

    return JsonResponse({'id': str(post_id)})

# Read
def get_post(request, post_id):
    post = posts_collection.find_one({'_id': ObjectId(post_id)})
    if post:
        post['_id'] = str(post['_id'])
        return JsonResponse(post)
    return JsonResponse({'error': 'Not found'}, status=404)

# List with pagination
def list_posts(request):
    page = int(request.GET.get('page', 1))
    per_page = 10
    skip = (page - 1) * per_page

    posts = list(posts_collection.find()
                 .sort('created_at', -1)
                 .skip(skip)
                 .limit(per_page))

    for post in posts:
        post['_id'] = str(post['_id'])

    return JsonResponse({'posts': posts})

# Update
def update_post(request, post_id):
    posts_collection.update_one(
        {'_id': ObjectId(post_id)},
        {'$set': {'title': 'Updated Title', 'updated_at': datetime.utcnow()}}
    )
    return JsonResponse({'status': 'updated'})

# Delete
def delete_post(request, post_id):
    posts_collection.delete_one({'_id': ObjectId(post_id)})
    return JsonResponse({'status': 'deleted'})

# Increment views
def increment_views(post_id):
    posts_collection.update_one(
        {'_id': ObjectId(post_id)},
        {'$inc': {'views': 1}}
    )
```

### Complex Queries with PyMongo

```python
# Find with multiple conditions
posts = posts_collection.find({
    'tags': {'$in': ['django', 'python']},
    'views': {'$gte': 100},
    'created_at': {'$gte': datetime(2024, 1, 1)}
})

# Aggregation pipeline
pipeline = [
    {'$match': {'published': True}},
    {'$group': {
        '_id': '$author_id',
        'post_count': {'$sum': 1},
        'total_views': {'$sum': '$views'}
    }},
    {'$sort': {'post_count': -1}},
    {'$limit': 10}
]

top_authors = list(posts_collection.aggregate(pipeline))

# Text search (requires text index)
posts_collection.create_index([('title', 'text'), ('content', 'text')])
results = posts_collection.find({'$text': {'$search': 'django mongodb'}})
```

## Hybrid Approach: SQL + MongoDB

Use both SQL and MongoDB in the same Django project.

```python
# settings.py
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'mydatabase',
        'USER': 'myuser',
        'PASSWORD': 'mypassword',
        'HOST': 'localhost',
        'PORT': '5432',
    }
}

# MongoDB connection
from mongoengine import connect

connect(
    db='mongodb_database',
    host='localhost',
    port=27017
)
```

### Use Case Example

```python
# models.py - PostgreSQL models
from django.db import models

class User(models.Model):
    username = models.CharField(max_length=150, unique=True)
    email = models.EmailField(unique=True)
    created_at = models.DateTimeField(auto_now_add=True)

class Product(models.Model):
    name = models.CharField(max_length=200)
    price = models.DecimalField(max_digits=10, decimal_places=2)
    stock = models.IntegerField()

# documents.py - MongoDB documents
from mongoengine import Document, EmbeddedDocument
from mongoengine.fields import (
    StringField, IntField, ListField,
    EmbeddedDocumentField, DateTimeField
)

class Activity(EmbeddedDocument):
    action = StringField()
    timestamp = DateTimeField()
    metadata = DictField()

class UserActivity(Document):
    user_id = IntField(required=True)  # References Django User
    activities = ListField(EmbeddedDocumentField(Activity))

    meta = {'collection': 'user_activities'}

class ProductAnalytics(Document):
    product_id = IntField(required=True)  # References Django Product
    views = IntField(default=0)
    searches = ListField(StringField())
    click_data = ListField(DictField())

    meta = {'collection': 'product_analytics'}
```

### Using Both Databases

```python
# views.py
from django.contrib.auth.models import User
from .models import Product
from .documents import UserActivity, ProductAnalytics
from datetime import datetime

def track_product_view(request, product_id):
    # Get product from PostgreSQL
    product = Product.objects.get(pk=product_id)

    # Update analytics in MongoDB
    analytics, created = ProductAnalytics.objects.get_or_create(
        product_id=product_id
    )
    analytics.update(inc__views=1)

    # Track user activity in MongoDB
    if request.user.is_authenticated:
        user_activity, created = UserActivity.objects.get_or_create(
            user_id=request.user.id
        )
        activity = Activity(
            action='view_product',
            timestamp=datetime.utcnow(),
            metadata={'product_id': product_id, 'product_name': product.name}
        )
        user_activity.activities.append(activity)
        user_activity.save()

    return render(request, 'product_detail.html', {'product': product})
```

## Database Connection Pooling

### PostgreSQL with pgBouncer

```python
# settings.py
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'mydatabase',
        'USER': 'myuser',
        'PASSWORD': 'mypassword',
        'HOST': 'localhost',
        'PORT': '6432',  # pgBouncer port
        'DISABLE_SERVER_SIDE_CURSORS': True,  # Required for pgBouncer
        'CONN_MAX_AGE': 60,  # Persistent connections
        'OPTIONS': {
            'MAX_CONNS': 20,
        }
    }
}
```

### MongoDB Connection Pooling

```python
# MongoEngine
from mongoengine import connect

connect(
    db='mydatabase',
    host='localhost',
    port=27017,
    maxPoolSize=50,
    minPoolSize=10,
    maxIdleTimeMS=45000,
    waitQueueTimeoutMS=10000
)

# PyMongo
from pymongo import MongoClient

client = MongoClient(
    'localhost',
    27017,
    maxPoolSize=50,
    minPoolSize=10,
    maxIdleTimeMS=45000
)
```

## Environment Variables

```.env
# PostgreSQL
DB_ENGINE=django.db.backends.postgresql
DB_NAME=mydatabase
DB_USER=myuser
DB_PASSWORD=mypassword
DB_HOST=localhost
DB_PORT=5432

# MySQL
MYSQL_DB_NAME=mydatabase
MYSQL_USER=myuser
MYSQL_PASSWORD=mypassword
MYSQL_HOST=localhost
MYSQL_PORT=3306

# MongoDB
MONGO_DB=mydatabase
MONGO_HOST=localhost
MONGO_PORT=27017
MONGO_USER=mongouser
MONGO_PASSWORD=mongopassword
```

## Database Migrations

### SQL Databases

```bash
# Create migrations
python manage.py makemigrations

# Apply migrations
python manage.py migrate

# Migrate specific app
python manage.py migrate myapp

# Show migrations
python manage.py showmigrations

# Rollback migration
python manage.py migrate myapp 0003  # Rollback to migration 0003
```

### MongoDB (Djongo)

```bash
# Djongo uses Django migrations
python manage.py makemigrations
python manage.py migrate
```

### MongoDB (MongoEngine)

```python
# No migrations needed - schema-less
# But you can create indexes

from mongoengine import Document
from mongoengine.fields import StringField

class MyDocument(Document):
    name = StringField()

    meta = {
        'indexes': [
            'name',
            {'fields': ['name'], 'unique': True}
        ]
    }

# Create indexes
MyDocument.ensure_indexes()
```

## Best Practices

### 1. Use Environment Variables

```python
# Never hardcode credentials
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.getenv('DB_NAME'),
        'USER': os.getenv('DB_USER'),
        'PASSWORD': os.getenv('DB_PASSWORD'),
        'HOST': os.getenv('DB_HOST'),
        'PORT': os.getenv('DB_PORT'),
    }
}
```

### 2. Use Connection Pooling

```python
# Enable persistent connections
DATABASES = {
    'default': {
        # ...
        'CONN_MAX_AGE': 60,  # 60 seconds
    }
}
```

### 3. Create Database Indexes

```python
# models.py
class Article(models.Model):
    title = models.CharField(max_length=200, db_index=True)
    slug = models.SlugField(unique=True)

    class Meta:
        indexes = [
            models.Index(fields=['title', 'created_at']),
        ]
```

### 4. Use Read Replicas

```python
# settings.py
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'primary_db',
        # ... primary database config
    },
    'replica': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'replica_db',
        # ... replica database config
    }
}

# Read from replica
users = User.objects.using('replica').all()
```

### 5. Monitor Database Performance

```python
# settings.py
if DEBUG:
    LOGGING = {
        'version': 1,
        'handlers': {
            'console': {
                'class': 'logging.StreamHandler',
            },
        },
        'loggers': {
            'django.db.backends': {
                'handlers': ['console'],
                'level': 'DEBUG',
            },
        },
    }
```

## Troubleshooting

### PostgreSQL Connection Issues

```bash
# Check if PostgreSQL is running
sudo systemctl status postgresql

# Check connection
psql -h localhost -U myuser -d mydatabase

# Check pg_hba.conf for authentication settings
sudo nano /etc/postgresql/15/main/pg_hba.conf
```

### MongoDB Connection Issues

```bash
# Check if MongoDB is running
sudo systemctl status mongod

# Check connection
mongosh mongodb://localhost:27017/mydatabase

# Check MongoDB logs
sudo tail -f /var/log/mongodb/mongod.log
```

### Migration Errors

```bash
# Fake migration (if already applied manually)
python manage.py migrate --fake myapp 0001

# Reset migrations (development only)
python manage.py migrate myapp zero
rm -rf myapp/migrations/
python manage.py makemigrations myapp
python manage.py migrate
```

## Additional Resources

- [Django Database Documentation](https://docs.djangoproject.com/en/stable/ref/databases/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [MongoDB Documentation](https://docs.mongodb.com/)
- [Djongo Documentation](https://www.djongomapper.com/)
- [MongoEngine Documentation](http://docs.mongoengine.org/)
- [PyMongo Documentation](https://pymongo.readthedocs.io/)
