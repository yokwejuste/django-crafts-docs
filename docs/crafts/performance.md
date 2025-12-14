---
icon: lucide/zap
---

# Performance Optimization

Optimize your Django application for speed and scalability.

## Database Optimization

### Query Optimization

```python
# Bad: N+1 queries problem
articles = Article.objects.all()
for article in articles:
    print(article.author.name)  # Extra query per article!

# Good: Use select_related for ForeignKey
articles = Article.objects.select_related('author').all()
for article in articles:
    print(article.author.name)  # No extra queries

# Good: Use prefetch_related for ManyToMany
articles = Article.objects.prefetch_related('tags').all()
for article in articles:
    print(article.tags.all())  # No extra queries
```

### Database Indexes

```python
from django.db import models

class Article(models.Model):
    title = models.CharField(max_length=200, db_index=True)
    slug = models.SlugField(unique=True)  # Automatically indexed
    published_date = models.DateTimeField(db_index=True)

    class Meta:
        indexes = [
            models.Index(fields=['published_date', 'title']),
            models.Index(fields=['-created_at']),
        ]
```

### Query Analysis

```python
# Use explain() to analyze queries
print(Article.objects.filter(published=True).explain())

# Count queries
from django.db import connection
from django.test.utils import override_settings

with override_settings(DEBUG=True):
    # Your code here
    print(len(connection.queries))
    for query in connection.queries:
        print(query)
```

## Caching

### View Caching

```python
from django.views.decorators.cache import cache_page

# Cache for 15 minutes
@cache_page(60 * 15)
def article_list(request):
    articles = Article.objects.all()
    return render(request, 'articles/list.html', {'articles': articles})
```

### Template Fragment Caching

```html
{% load cache %}

{% cache 500 sidebar %}
    <!-- Expensive sidebar rendering -->
    {% for item in items %}
        {{ item.name }}
    {% endfor %}
{% endcache %}
```

### Low-Level Caching

```python
from django.core.cache import cache

def get_articles():
    articles = cache.get('all_articles')
    if articles is None:
        articles = list(Article.objects.all())
        cache.set('all_articles', articles, 300)  # 5 minutes
    return articles

# Delete cache
cache.delete('all_articles')

# Clear all cache
cache.clear()
```

### Cache Configuration

```python
# settings.py

# Redis cache
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.redis.RedisCache',
        'LOCATION': 'redis://127.0.0.1:6379/1',
        'OPTIONS': {
            'CLIENT_CLASS': 'django_redis.client.DefaultClient',
        },
        'KEY_PREFIX': 'myapp',
        'TIMEOUT': 300,
    }
}

# Memcached
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.memcached.PyMemcacheCache',
        'LOCATION': '127.0.0.1:11211',
    }
}
```

## Static Files Optimization

### Compression and Minification

```bash
# Install django-compressor
pip install django-compressor
```

```python
# settings.py
INSTALLED_APPS = [
    ...
    'compressor',
]

COMPRESS_ENABLED = True
COMPRESS_CSS_FILTERS = ['compressor.filters.css_default.CssAbsoluteFilter', 'compressor.filters.cssmin.CSSMinFilter']
COMPRESS_JS_FILTERS = ['compressor.filters.jsmin.JSMinFilter']
```

```html
{% load compress %}

{% compress css %}
<link rel="stylesheet" href="{% static 'css/style1.css' %}">
<link rel="stylesheet" href="{% static 'css/style2.css' %}">
{% endcompress %}

{% compress js %}
<script src="{% static 'js/script1.js' %}"></script>
<script src="{% static 'js/script2.js' %}"></script>
{% endcompress %}
```

### CDN Integration

```python
# settings.py
STATIC_URL = 'https://cdn.yourdomain.com/static/'
MEDIA_URL = 'https://cdn.yourdomain.com/media/'
```

## Async Views

```python
# For I/O-bound operations
from django.http import JsonResponse
import httpx

async def async_view(request):
    async with httpx.AsyncClient() as client:
        response = await client.get('https://api.example.com/data')
        data = response.json()
    return JsonResponse(data)
```

## Database Connection Pooling

```bash
pip install django-db-pool
```

```python
DATABASES = {
    'default': {
        'ENGINE': 'django_db_pool.backends.postgresql',
        'POOL_OPTIONS': {
            'POOL_SIZE': 10,
            'MAX_OVERFLOW': 10,
            'RECYCLE': 3600,
        }
    }
}
```

## Lazy Loading

```python
from django.utils.functional import lazy

# Lazy translation
from django.utils.translation import gettext_lazy as _

# Lazy querysets
articles = Article.objects.all()  # Not executed yet
articles = articles.filter(published=True)  # Still not executed
list(articles)  # Now executed
```

## Pagination

```python
from django.core.paginator import Paginator

def article_list(request):
    articles = Article.objects.all()
    paginator = Paginator(articles, 25)  # 25 per page

    page_number = request.GET.get('page')
    page_obj = paginator.get_page(page_number)

    return render(request, 'list.html', {'page_obj': page_obj})
```

## Monitoring Performance

### Django Debug Toolbar

```bash
pip install django-debug-toolbar
```

```python
# settings.py
INSTALLED_APPS = [
    ...
    'debug_toolbar',
]

MIDDLEWARE = [
    ...
    'debug_toolbar.middleware.DebugToolbarMiddleware',
]

INTERNAL_IPS = ['127.0.0.1']
```

### Query Logging

```python
# settings.py
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

## Image Optimization

```python
from PIL import Image
from io import BytesIO
from django.core.files.uploadedfile import InMemoryUploadedFile

def optimize_image(image_field, max_size=(800, 600)):
    img = Image.open(image_field)

    # Resize
    img.thumbnail(max_size, Image.LANCZOS)

    # Convert to RGB if necessary
    if img.mode in ('RGBA', 'LA', 'P'):
        img = img.convert('RGB')

    # Save to BytesIO
    output = BytesIO()
    img.save(output, format='JPEG', quality=85, optimize=True)
    output.seek(0)

    return InMemoryUploadedFile(
        output,
        'ImageField',
        f'{image_field.name.split(".")[0]}.jpg',
        'image/jpeg',
        output.getbuffer().nbytes,
        None
    )
```

## Best Practices

1. **Use select_related and prefetch_related**
2. **Add database indexes** on frequently queried fields
3. **Implement caching** at multiple levels
4. **Optimize static files** delivery
5. **Use pagination** for large datasets
6. **Monitor database queries**
7. **Compress and minify** assets
8. **Use CDN** for static files
9. **Enable gzip compression**
10. **Regular performance testing**

## Performance Checklist

- [ ] Database queries optimized
- [ ] Proper indexes added
- [ ] Caching implemented
- [ ] Static files compressed
- [ ] CDN configured
- [ ] Images optimized
- [ ] Pagination in place
- [ ] Connection pooling enabled
- [ ] Monitoring tools installed
- [ ] Load testing completed

## Additional Resources

- [Django Performance Tips](https://docs.djangoproject.com/en/stable/topics/performance/)
- [Database Access Optimization](https://docs.djangoproject.com/en/stable/topics/db/optimization/)
- [Caching Framework](https://docs.djangoproject.com/en/stable/topics/cache/)
