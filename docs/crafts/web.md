---
icon: lucide/globe
---

# Web Development with Django

Complete guide to building web applications with Django, covering views, templates, URL routing, middleware, and modern web development patterns.

## Django Request-Response Cycle

Understanding how Django processes web requests is fundamental to building applications.

### The Flow

```
Browser Request
    ↓
URL Resolver (urls.py)
    ↓
Middleware (request processing)
    ↓
View (views.py)
    ↓
Model (if needed)
    ↓
Template (rendering)
    ↓
Middleware (response processing)
    ↓
HTTP Response to Browser
```

## URL Configuration

### Basic URL Patterns

```python
# urls.py
from django.urls import path
from . import views

urlpatterns = [
    # Simple path
    path('', views.home, name='home'),
    path('about/', views.about, name='about'),

    # Path with parameters
    path('posts/<int:post_id>/', views.post_detail, name='post_detail'),
    path('posts/<slug:slug>/', views.post_by_slug, name='post_by_slug'),

    # Multiple parameters
    path('blog/<int:year>/<int:month>/', views.monthly_archive, name='monthly_archive'),
]
```

### Path Converters

```python
from django.urls import path

urlpatterns = [
    # str - matches any non-empty string (default)
    path('articles/<str:section>/', views.article_section),

    # int - matches zero or any positive integer
    path('articles/<int:id>/', views.article_detail),

    # slug - matches any slug string (letters, numbers, hyphens, underscores)
    path('articles/<slug:slug>/', views.article_by_slug),

    # uuid - matches a formatted UUID
    path('users/<uuid:user_id>/', views.user_profile),

    # path - matches any non-empty string, including the path separator /
    path('pages/<path:page_path>/', views.page_view),
]
```

### Custom Path Converters

```python
# converters.py
class FourDigitYearConverter:
    regex = '[0-9]{4}'

    def to_python(self, value):
        return int(value)

    def to_url(self, value):
        return '%04d' % value

# urls.py
from django.urls import path, register_converter
from . import views, converters

register_converter(converters.FourDigitYearConverter, 'yyyy')

urlpatterns = [
    path('articles/<yyyy:year>/', views.year_archive),
]
```

### Including Other URLconfs

```python
# project/urls.py
from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('blog/', include('blog.urls')),
    path('api/', include('api.urls')),
    path('', include('pages.urls')),
]

# blog/urls.py
from django.urls import path
from . import views

app_name = 'blog'  # Namespace

urlpatterns = [
    path('', views.post_list, name='list'),
    path('<int:pk>/', views.post_detail, name='detail'),
    path('create/', views.post_create, name='create'),
]

# Usage in templates: {% url 'blog:detail' pk=post.pk %}
```

## Views

### Function-Based Views

```python
# views.py
from django.shortcuts import render, get_object_or_404, redirect
from django.http import HttpResponse, JsonResponse
from .models import Post

def post_list(request):
    posts = Post.objects.all().order_by('-created_at')
    context = {'posts': posts}
    return render(request, 'blog/post_list.html', context)

def post_detail(request, post_id):
    post = get_object_or_404(Post, pk=post_id)
    return render(request, 'blog/post_detail.html', {'post': post})

def post_create(request):
    if request.method == 'POST':
        # Process form
        title = request.POST.get('title')
        content = request.POST.get('content')
        post = Post.objects.create(title=title, content=content)
        return redirect('post_detail', post_id=post.id)
    return render(request, 'blog/post_form.html')

def api_posts(request):
    posts = Post.objects.all().values('id', 'title', 'created_at')
    return JsonResponse(list(posts), safe=False)
```

### Class-Based Views

```python
from django.views.generic import (
    ListView, DetailView, CreateView,
    UpdateView, DeleteView, TemplateView
)
from django.urls import reverse_lazy
from .models import Post

class PostListView(ListView):
    model = Post
    template_name = 'blog/post_list.html'
    context_object_name = 'posts'
    paginate_by = 10

    def get_queryset(self):
        return Post.objects.filter(published=True).order_by('-created_at')

class PostDetailView(DetailView):
    model = Post
    template_name = 'blog/post_detail.html'
    context_object_name = 'post'

class PostCreateView(CreateView):
    model = Post
    template_name = 'blog/post_form.html'
    fields = ['title', 'content', 'author']
    success_url = reverse_lazy('post_list')

    def form_valid(self, form):
        form.instance.author = self.request.user
        return super().form_valid(form)

class PostUpdateView(UpdateView):
    model = Post
    template_name = 'blog/post_form.html'
    fields = ['title', 'content']

    def get_success_url(self):
        return reverse_lazy('post_detail', kwargs={'pk': self.object.pk})

class PostDeleteView(DeleteView):
    model = Post
    template_name = 'blog/post_confirm_delete.html'
    success_url = reverse_lazy('post_list')
```

### Generic Views URL Configuration

```python
# urls.py
from django.urls import path
from .views import (
    PostListView, PostDetailView, PostCreateView,
    PostUpdateView, PostDeleteView
)

urlpatterns = [
    path('', PostListView.as_view(), name='post_list'),
    path('<int:pk>/', PostDetailView.as_view(), name='post_detail'),
    path('create/', PostCreateView.as_view(), name='post_create'),
    path('<int:pk>/edit/', PostUpdateView.as_view(), name='post_update'),
    path('<int:pk>/delete/', PostDeleteView.as_view(), name='post_delete'),
]
```

## Templates

### Template Basics

```django
<!-- templates/base.html -->
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{% block title %}My Site{% endblock %}</title>
    {% load static %}
    <link rel="stylesheet" href="{% static 'css/style.css' %}">
</head>
<body>
    <nav>
        <a href="{% url 'home' %}">Home</a>
        <a href="{% url 'blog:list' %}">Blog</a>
        {% if user.is_authenticated %}
            <a href="{% url 'profile' %}">Profile</a>
            <a href="{% url 'logout' %}">Logout</a>
        {% else %}
            <a href="{% url 'login' %}">Login</a>
        {% endif %}
    </nav>

    <main>
        {% if messages %}
            {% for message in messages %}
                <div class="alert alert-{{ message.tags }}">
                    {{ message }}
                </div>
            {% endfor %}
        {% endif %}

        {% block content %}{% endblock %}
    </main>

    <footer>
        <p>&copy; 2024 My Site</p>
    </footer>

    {% block extra_js %}{% endblock %}
</body>
</html>
```

### Template Inheritance

```django
<!-- templates/blog/post_list.html -->
{% extends 'base.html' %}
{% load static %}

{% block title %}Blog Posts - {{ block.super }}{% endblock %}

{% block content %}
<h1>Blog Posts</h1>

{% if posts %}
    <div class="posts">
        {% for post in posts %}
            <article class="post">
                <h2><a href="{% url 'blog:detail' pk=post.pk %}">{{ post.title }}</a></h2>
                <p class="meta">
                    By {{ post.author.username }} on {{ post.created_at|date:"F d, Y" }}
                </p>
                <p>{{ post.content|truncatewords:30 }}</p>
            </article>
        {% endfor %}
    </div>

    <!-- Pagination -->
    {% if is_paginated %}
        <div class="pagination">
            {% if page_obj.has_previous %}
                <a href="?page=1">First</a>
                <a href="?page={{ page_obj.previous_page_number }}">Previous</a>
            {% endif %}

            <span>Page {{ page_obj.number }} of {{ page_obj.paginator.num_pages }}</span>

            {% if page_obj.has_next %}
                <a href="?page={{ page_obj.next_page_number }}">Next</a>
                <a href="?page={{ page_obj.paginator.num_pages }}">Last</a>
            {% endif %}
        </div>
    {% endif %}
{% else %}
    <p>No posts available.</p>
{% endif %}
{% endblock %}
```

### Template Filters and Tags

```django
<!-- Built-in filters -->
{{ post.title|upper }}
{{ post.content|truncatewords:50 }}
{{ post.created_at|date:"Y-m-d H:i" }}
{{ post.price|floatformat:2 }}
{{ post.description|linebreaks }}
{{ post.html_content|safe }}
{{ post.title|default:"No title" }}

<!-- Custom filter -->
{% load blog_extras %}
{{ post.content|markdown }}

<!-- Template tags -->
{% for post in posts %}
    {{ forloop.counter }}. {{ post.title }}
    {% if forloop.first %}First!{% endif %}
    {% if forloop.last %}Last!{% endif %}
{% endfor %}

{% with total=posts.count %}
    <p>Total posts: {{ total }}</p>
{% endwith %}

{% include 'partials/post_card.html' with post=post %}
```

### Custom Template Tags and Filters

```python
# blog/templatetags/blog_extras.py
from django import template
import markdown as md

register = template.Library()

@register.filter
def markdown(value):
    return md.markdown(value, extensions=['extra'])

@register.simple_tag
def multiply(a, b):
    return a * b

@register.inclusion_tag('blog/latest_posts.html')
def show_latest_posts(count=5):
    posts = Post.objects.order_by('-created_at')[:count]
    return {'posts': posts}
```

```django
<!-- Usage -->
{% load blog_extras %}

{{ post.content|markdown }}
{% multiply 5 10 %}
{% show_latest_posts 3 %}
```

## Static Files

### Configuration

```python
# settings.py
import os

STATIC_URL = '/static/'
STATIC_ROOT = os.path.join(BASE_DIR, 'staticfiles')

STATICFILES_DIRS = [
    os.path.join(BASE_DIR, 'static'),
]

# For production
STATICFILES_STORAGE = 'django.contrib.staticfiles.storage.ManifestStaticFilesStorage'
```

### Directory Structure

```
myproject/
├── static/
│   ├── css/
│   │   └── style.css
│   ├── js/
│   │   └── main.js
│   └── images/
│       └── logo.png
└── myapp/
    └── static/
        └── myapp/
            ├── css/
            │   └── app.css
            └── js/
                └── app.js
```

### Using Static Files

```django
{% load static %}

<!-- CSS -->
<link rel="stylesheet" href="{% static 'css/style.css' %}">

<!-- JavaScript -->
<script src="{% static 'js/main.js' %}"></script>

<!-- Images -->
<img src="{% static 'images/logo.png' %}" alt="Logo">

<!-- App-specific static files -->
<link rel="stylesheet" href="{% static 'myapp/css/app.css' %}">
```

### Collecting Static Files

```bash
# Collect all static files to STATIC_ROOT
python manage.py collectstatic

# Clear existing files before collecting
python manage.py collectstatic --clear --noinput
```

## Media Files

### Configuration

```python
# settings.py
import os

MEDIA_URL = '/media/'
MEDIA_ROOT = os.path.join(BASE_DIR, 'media')
```

### URL Configuration

```python
# urls.py
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    # ... your url patterns
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
```

### File Uploads

```python
# models.py
from django.db import models

class Profile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    avatar = models.ImageField(upload_to='avatars/', blank=True)
    bio = models.TextField()

class Document(models.Model):
    title = models.CharField(max_length=200)
    file = models.FileField(upload_to='documents/%Y/%m/%d/')
    uploaded_at = models.DateTimeField(auto_now_add=True)
```

```django
<!-- Template with file upload -->
<form method="post" enctype="multipart/form-data">
    {% csrf_token %}
    {{ form.as_p }}
    <button type="submit">Upload</button>
</form>

<!-- Display uploaded file -->
{% if profile.avatar %}
    <img src="{{ profile.avatar.url }}" alt="Avatar">
{% endif %}
```

## Middleware

### Built-in Middleware

```python
# settings.py
MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]
```

### Custom Middleware

```python
# middleware.py
import time
import logging

logger = logging.getLogger(__name__)

class RequestTimingMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        start_time = time.time()

        response = self.get_response(request)

        duration = time.time() - start_time
        logger.info(f'{request.method} {request.path} took {duration:.2f}s')

        return response

class CustomHeaderMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        response = self.get_response(request)
        response['X-Custom-Header'] = 'MyValue'
        return response
```

```python
# settings.py
MIDDLEWARE = [
    # ... other middleware
    'myapp.middleware.RequestTimingMiddleware',
    'myapp.middleware.CustomHeaderMiddleware',
]
```

## Context Processors

### Built-in Context Processors

```python
# settings.py
TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]
```

### Custom Context Processor

```python
# context_processors.py
from .models import Category

def site_info(request):
    return {
        'site_name': 'My Django Site',
        'categories': Category.objects.all(),
    }
```

```python
# settings.py
TEMPLATES = [
    {
        'OPTIONS': {
            'context_processors': [
                # ... built-in processors
                'myapp.context_processors.site_info',
            ],
        },
    },
]
```

```django
<!-- Now available in all templates -->
<h1>{{ site_name }}</h1>
<ul>
    {% for category in categories %}
        <li>{{ category.name }}</li>
    {% endfor %}
</ul>
```

## Sessions

### Session Configuration

```python
# settings.py

# Database-backed sessions (default)
SESSION_ENGINE = 'django.contrib.sessions.backends.db'

# Cache-backed sessions
SESSION_ENGINE = 'django.contrib.sessions.backends.cache'

# File-based sessions
SESSION_ENGINE = 'django.contrib.sessions.backends.file'

# Session settings
SESSION_COOKIE_AGE = 1209600  # 2 weeks in seconds
SESSION_COOKIE_SECURE = True  # HTTPS only
SESSION_COOKIE_HTTPONLY = True
SESSION_SAVE_EVERY_REQUEST = False
```

### Using Sessions

```python
# views.py
def add_to_cart(request, product_id):
    cart = request.session.get('cart', {})
    cart[product_id] = cart.get(product_id, 0) + 1
    request.session['cart'] = cart
    request.session.modified = True
    return redirect('cart')

def view_cart(request):
    cart = request.session.get('cart', {})
    return render(request, 'cart.html', {'cart': cart})

def clear_cart(request):
    if 'cart' in request.session:
        del request.session['cart']
    return redirect('home')
```

## Messages Framework

```python
# views.py
from django.contrib import messages
from django.shortcuts import redirect

def create_post(request):
    if request.method == 'POST':
        # Process form
        messages.success(request, 'Post created successfully!')
        return redirect('post_list')
    return render(request, 'post_form.html')

def delete_post(request, pk):
    post = get_object_or_404(Post, pk=pk)
    post.delete()
    messages.info(request, f'Post "{post.title}" deleted.')
    return redirect('post_list')

def error_view(request):
    messages.error(request, 'Something went wrong!')
    messages.warning(request, 'Please check your input.')
    return render(request, 'form.html')
```

```django
<!-- Display messages -->
{% if messages %}
    {% for message in messages %}
        <div class="alert alert-{{ message.tags }}">
            {{ message }}
        </div>
    {% endfor %}
{% endif %}
```

## Pagination

```python
# views.py
from django.core.paginator import Paginator, EmptyPage, PageNotAnInteger

def post_list(request):
    posts = Post.objects.all().order_by('-created_at')
    paginator = Paginator(posts, 10)  # 10 posts per page

    page = request.GET.get('page')
    try:
        posts_page = paginator.page(page)
    except PageNotAnInteger:
        posts_page = paginator.page(1)
    except EmptyPage:
        posts_page = paginator.page(paginator.num_pages)

    return render(request, 'post_list.html', {'posts': posts_page})
```

```django
<!-- Pagination template -->
<div class="pagination">
    <span class="step-links">
        {% if posts.has_previous %}
            <a href="?page=1">&laquo; first</a>
            <a href="?page={{ posts.previous_page_number }}">previous</a>
        {% endif %}

        <span class="current">
            Page {{ posts.number }} of {{ posts.paginator.num_pages }}
        </span>

        {% if posts.has_next %}
            <a href="?page={{ posts.next_page_number }}">next</a>
            <a href="?page={{ posts.paginator.num_pages }}">last &raquo;</a>
        {% endif %}
    </span>
</div>
```

## Signals

```python
# signals.py
from django.db.models.signals import post_save, pre_delete
from django.dispatch import receiver
from django.contrib.auth.models import User
from .models import Profile

@receiver(post_save, sender=User)
def create_user_profile(sender, instance, created, **kwargs):
    if created:
        Profile.objects.create(user=instance)

@receiver(post_save, sender=User)
def save_user_profile(sender, instance, **kwargs):
    instance.profile.save()

@receiver(pre_delete, sender=Post)
def delete_post_files(sender, instance, **kwargs):
    # Delete associated files before deleting post
    if instance.image:
        instance.image.delete(save=False)
```

```python
# apps.py
from django.apps import AppConfig

class BlogConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'blog'

    def ready(self):
        import blog.signals
```

## Additional Resources

- [Django Views Documentation](https://docs.djangoproject.com/en/stable/topics/http/views/)
- [Django Templates Documentation](https://docs.djangoproject.com/en/stable/topics/templates/)
- [Django URL Dispatcher](https://docs.djangoproject.com/en/stable/topics/http/urls/)
- [Django Class-Based Views](https://docs.djangoproject.com/en/stable/topics/class-based-views/)
- [Django Static Files](https://docs.djangoproject.com/en/stable/howto/static-files/)
