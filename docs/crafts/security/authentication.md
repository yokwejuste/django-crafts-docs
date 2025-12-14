---
icon: lucide/shield-check
---

# Authentication in Django

Authentication is the process of verifying the identity of users accessing your Django application.

## Built-in Authentication System

Django comes with a robust authentication system out of the box.

### User Model

```python
from django.contrib.auth.models import User

# Create a new user
user = User.objects.create_user(
    username='john',
    email='john@example.com',
    password='secure_password123'
)

# Authenticate a user
from django.contrib.auth import authenticate
user = authenticate(username='john', password='secure_password123')
```

### Login and Logout

```python
from django.contrib.auth import login, logout

def login_view(request):
    if request.method == 'POST':
        username = request.POST['username']
        password = request.POST['password']
        user = authenticate(request, username=username, password=password)

        if user is not None:
            login(request, user)
            return redirect('dashboard')
        else:
            return render(request, 'login.html', {'error': 'Invalid credentials'})

    return render(request, 'login.html')

def logout_view(request):
    logout(request)
    return redirect('home')
```

## Custom User Models

Creating a custom user model gives you flexibility for future changes.

```python
# models.py
from django.contrib.auth.models import AbstractUser
from django.db import models

class CustomUser(AbstractUser):
    email = models.EmailField(unique=True)
    phone_number = models.CharField(max_length=15, blank=True)
    date_of_birth = models.DateField(null=True, blank=True)

    def __str__(self):
        return self.email
```

```python
# settings.py
AUTH_USER_MODEL = 'accounts.CustomUser'
```

## Two-Factor Authentication (2FA)

Add an extra layer of security with 2FA.

### Using django-two-factor-auth

```bash
pip install django-two-factor-auth
```

```python
# settings.py
INSTALLED_APPS = [
    ...
    'django_otp',
    'django_otp.plugins.otp_totp',
    'django_otp.plugins.otp_static',
    'two_factor',
]

MIDDLEWARE = [
    ...
    'django_otp.middleware.OTPMiddleware',
]
```

## Social Authentication

Allow users to sign in with social accounts.

### Using django-allauth

```bash
pip install django-allauth
```

```python
# settings.py
INSTALLED_APPS = [
    ...
    'django.contrib.sites',
    'allauth',
    'allauth.account',
    'allauth.socialaccount',
    'allauth.socialaccount.providers.google',
    'allauth.socialaccount.providers.github',
]

SITE_ID = 1

AUTHENTICATION_BACKENDS = [
    'django.contrib.auth.backends.ModelBackend',
    'allauth.account.auth_backends.AuthenticationBackend',
]
```

## Password Management

### Password Validators

```python
# settings.py
AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
        'OPTIONS': {
            'min_length': 12,
        }
    },
    {
        'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',
    },
]
```

### Password Reset

```python
# urls.py
from django.contrib.auth import views as auth_views

urlpatterns = [
    path('password-reset/',
         auth_views.PasswordResetView.as_view(),
         name='password_reset'),
    path('password-reset/done/',
         auth_views.PasswordResetDoneView.as_view(),
         name='password_reset_done'),
    path('reset/<uidb64>/<token>/',
         auth_views.PasswordResetConfirmView.as_view(),
         name='password_reset_confirm'),
    path('reset/done/',
         auth_views.PasswordResetCompleteView.as_view(),
         name='password_reset_complete'),
]
```

## Session Management

### Session Settings

```python
# settings.py

# Session expiry
SESSION_COOKIE_AGE = 86400  # 24 hours
SESSION_SAVE_EVERY_REQUEST = True  # Extend session on activity

# Security settings
SESSION_COOKIE_SECURE = True  # HTTPS only
SESSION_COOKIE_HTTPONLY = True  # Prevent JavaScript access
SESSION_COOKIE_SAMESITE = 'Strict'  # CSRF protection
```

## Best Practices

1. **Always use HTTPS** in production
2. **Never store passwords in plain text**
3. **Implement rate limiting** on login attempts
4. **Use strong password requirements**
5. **Enable two-factor authentication** for sensitive accounts
6. **Regularly audit user sessions**
7. **Implement account lockout** after failed attempts
8. **Use secure session cookies**
9. **Implement proper logout** functionality
10. **Keep authentication libraries updated**

## Common Security Pitfalls

### Avoid These Mistakes

```python
# DON'T - Store passwords in plain text
user.password = 'password123'

# DO - Use set_password
user.set_password('password123')
user.save()

# DON'T - Compare passwords directly
if user.password == input_password:
    # This won't work!

# DO - Use check_password
if user.check_password(input_password):
    # Correct way
```

## Additional Resources

- [Django Authentication Documentation](https://docs.djangoproject.com/en/stable/topics/auth/)
- [OWASP Authentication Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html)
- [Django Two-Factor Auth](https://github.com/jazzband/django-two-factor-auth)
