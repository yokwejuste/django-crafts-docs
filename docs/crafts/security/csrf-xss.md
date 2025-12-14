---
icon: lucide/shield-alert
---

# CSRF and XSS Protection

Learn how to protect your Django application from Cross-Site Request Forgery (CSRF) and Cross-Site Scripting (XSS) attacks.

## Cross-Site Request Forgery (CSRF)

CSRF attacks trick users into executing unwanted actions on a web application where they're authenticated.

### Django's CSRF Protection

Django provides built-in CSRF protection that's enabled by default.

```python
# settings.py
MIDDLEWARE = [
    ...
    'django.middleware.csrf.CsrfViewMiddleware',
    ...
]
```

### Using CSRF Tokens in Templates

```html
<!-- forms.html -->
<form method="post">
    {% csrf_token %}
    <input type="text" name="username">
    <input type="password" name="password">
    <button type="submit">Login</button>
</form>
```

### AJAX Requests with CSRF

```javascript
// Get CSRF token from cookie
function getCookie(name) {
    let cookieValue = null;
    if (document.cookie && document.cookie !== '') {
        const cookies = document.cookie.split(';');
        for (let i = 0; i < cookies.length; i++) {
            const cookie = cookies[i].trim();
            if (cookie.substring(0, name.length + 1) === (name + '=')) {
                cookieValue = decodeURIComponent(cookie.substring(name.length + 1));
                break;
            }
        }
    }
    return cookieValue;
}

const csrftoken = getCookie('csrftoken');

// Using fetch API
fetch('/api/endpoint/', {
    method: 'POST',
    headers: {
        'Content-Type': 'application/json',
        'X-CSRFToken': csrftoken
    },
    body: JSON.stringify(data)
});
```

### Exempting Views from CSRF (Use with Caution)

```python
from django.views.decorators.csrf import csrf_exempt
from django.http import JsonResponse

@csrf_exempt
def api_endpoint(request):
    # Only use for external APIs with other authentication
    return JsonResponse({'status': 'ok'})
```

### CSRF Settings

```python
# settings.py

# CSRF cookie settings
CSRF_COOKIE_SECURE = True  # HTTPS only
CSRF_COOKIE_HTTPONLY = True  # Prevent JavaScript access
CSRF_COOKIE_SAMESITE = 'Strict'

# Trusted origins for CSRF
CSRF_TRUSTED_ORIGINS = [
    'https://yourdomain.com',
    'https://www.yourdomain.com',
]

# CSRF failure view
CSRF_FAILURE_VIEW = 'myapp.views.csrf_failure'
```

## Cross-Site Scripting (XSS)

XSS attacks inject malicious scripts into web pages viewed by other users.

### Django's Auto-Escaping

Django automatically escapes HTML in templates:

```html
<!-- This is safe - Django auto-escapes -->
<p>{{ user_input }}</p>

<!-- Output: &lt;script&gt;alert('XSS')&lt;/script&gt; -->
```

### Marking Safe Content

```python
from django.utils.safestring import mark_safe

def my_view(request):
    # Use with extreme caution!
    html_content = mark_safe('<strong>Bold text</strong>')
    return render(request, 'template.html', {'content': html_content})
```

```html
<!-- In template -->
{{ content }}  <!-- Renders as bold text -->

<!-- Or use the safe filter -->
{{ user_content|safe }}  <!-- DANGEROUS if user_content is not sanitized! -->
```

### Sanitizing User Input

```python
import bleach

def sanitize_html(dirty_html):
    # Allow only specific tags and attributes
    allowed_tags = ['p', 'strong', 'em', 'u', 'a', 'ul', 'ol', 'li']
    allowed_attributes = {'a': ['href', 'title']}

    clean_html = bleach.clean(
        dirty_html,
        tags=allowed_tags,
        attributes=allowed_attributes,
        strip=True
    )
    return clean_html

# In views
cleaned_content = sanitize_html(request.POST.get('content'))
```

### Content Security Policy (CSP)

Add CSP headers to prevent XSS attacks:

```python
# Using django-csp
# pip install django-csp

# settings.py
MIDDLEWARE = [
    ...
    'csp.middleware.CSPMiddleware',
]

CSP_DEFAULT_SRC = ("'self'",)
CSP_SCRIPT_SRC = ("'self'", "'unsafe-inline'", "https://cdn.example.com")
CSP_STYLE_SRC = ("'self'", "'unsafe-inline'")
CSP_IMG_SRC = ("'self'", "data:", "https:")
CSP_FONT_SRC = ("'self'", "https://fonts.gstatic.com")
```

### JSON Responses

```python
from django.http import JsonResponse

def api_view(request):
    data = {
        'message': 'Hello',
        'user_input': request.GET.get('query', '')
    }
    # JsonResponse automatically escapes
    return JsonResponse(data)
```

## Protection Patterns

### 1. Input Validation

```python
from django import forms
from django.core.validators import URLValidator

class CommentForm(forms.Form):
    name = forms.CharField(max_length=100)
    email = forms.EmailField()
    website = forms.CharField(
        validators=[URLValidator()],
        required=False
    )
    comment = forms.CharField(widget=forms.Textarea)

    def clean_comment(self):
        comment = self.cleaned_data['comment']
        # Additional validation
        if '<script' in comment.lower():
            raise forms.ValidationError('Invalid content detected')
        return comment
```

### 2. Output Encoding

```html
<!-- Always escape user input -->
<div>{{ user.bio|escape }}</div>

<!-- For URLs -->
<a href="{{ user.website|urlencode }}">Website</a>

<!-- For JavaScript -->
<script>
    var userName = "{{ user.name|escapejs }}";
</script>
```

### 3. Rich Text Editors

```python
# Using django-ckeditor with sanitization
# pip install django-ckeditor

# settings.py
INSTALLED_APPS = [
    ...
    'ckeditor',
]

CKEDITOR_CONFIGS = {
    'default': {
        'toolbar': 'Custom',
        'toolbar_Custom': [
            ['Bold', 'Italic', 'Underline'],
            ['NumberedList', 'BulletedList'],
            ['Link', 'Unlink'],
        ],
        'removePlugins': 'iframe,flash,embed',
    },
}
```

## Security Headers

```python
# settings.py

# X-Frame-Options
X_FRAME_OPTIONS = 'DENY'

# X-Content-Type-Options
SECURE_CONTENT_TYPE_NOSNIFF = True

# X-XSS-Protection
SECURE_BROWSER_XSS_FILTER = True

# Referrer Policy
SECURE_REFERRER_POLICY = 'same-origin'
```

## Common Attack Vectors

### 1. Stored XSS

```python
# Vulnerable code
def save_comment(request):
    Comment.objects.create(
        text=request.POST['comment']  # Dangerous!
    )

# Safe code
def save_comment(request):
    form = CommentForm(request.POST)
    if form.is_valid():
        Comment.objects.create(
            text=form.cleaned_data['comment']
        )
```

### 2. Reflected XSS

```python
# Vulnerable code
def search(request):
    query = request.GET.get('q', '')
    return HttpResponse(f'Results for: {query}')  # Dangerous!

# Safe code
def search(request):
    query = request.GET.get('q', '')
    return render(request, 'search.html', {'query': query})
```

```html
<!-- In template - automatically escaped -->
<p>Results for: {{ query }}</p>
```

### 3. DOM-based XSS

```html
<!-- Vulnerable JavaScript -->
<script>
    // DON'T
    document.getElementById('output').innerHTML = location.hash.substring(1);
</script>

<!-- Safe JavaScript -->
<script>
    // DO
    document.getElementById('output').textContent = location.hash.substring(1);
</script>
```

## Testing for Vulnerabilities

```python
# tests.py
from django.test import TestCase, Client

class SecurityTestCase(TestCase):
    def test_csrf_protection(self):
        client = Client(enforce_csrf_checks=True)
        response = client.post('/form/', {'data': 'test'})
        self.assertEqual(response.status_code, 403)

    def test_xss_protection(self):
        response = self.client.post('/comment/', {
            'text': '<script>alert("XSS")</script>'
        })
        self.assertNotContains(response, '<script>')
```

## Best Practices

1. **Always use Django's auto-escaping**
2. **Never use `mark_safe()` on user input**
3. **Validate and sanitize all user input**
4. **Use CSP headers**
5. **Keep Django and dependencies updated**
6. **Enable HTTPS and secure cookies**
7. **Use HttpOnly and Secure flags**
8. **Implement proper error handling**
9. **Regular security audits**
10. **Educate your team about security**

## Additional Resources

- [OWASP CSRF Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.html)
- [OWASP XSS Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Cross_Site_Scripting_Prevention_Cheat_Sheet.html)
- [Django Security Documentation](https://docs.djangoproject.com/en/stable/topics/security/)
