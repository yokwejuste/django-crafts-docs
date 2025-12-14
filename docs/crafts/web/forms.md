---
icon: lucide/file-input
---

# Django Forms

Forms are essential for collecting and validating user input in Django applications.

## Basic Forms

### Creating a Simple Form

```python
# forms.py
from django import forms

class ContactForm(forms.Form):
    name = forms.CharField(max_length=100)
    email = forms.EmailField()
    subject = forms.CharField(max_length=200)
    message = forms.CharField(widget=forms.Textarea)
```

### Using Forms in Views

```python
# views.py
from django.shortcuts import render, redirect
from .forms import ContactForm

def contact_view(request):
    if request.method == 'POST':
        form = ContactForm(request.POST)
        if form.is_valid():
            # Process the form data
            name = form.cleaned_data['name']
            email = form.cleaned_data['email']
            # Send email, save to database, etc.
            return redirect('success')
    else:
        form = ContactForm()

    return render(request, 'contact.html', {'form': form})
```

### Rendering Forms in Templates

```html
<!-- contact.html -->
<form method="post">
    {% csrf_token %}
    {{ form.as_p }}
    <button type="submit">Submit</button>
</form>

<!-- Manual rendering for more control -->
<form method="post">
    {% csrf_token %}
    <div class="form-group">
        <label for="{{ form.name.id_for_label }}">Name:</label>
        {{ form.name }}
        {% if form.name.errors %}
            <div class="error">{{ form.name.errors }}</div>
        {% endif %}
    </div>

    <div class="form-group">
        <label for="{{ form.email.id_for_label }}">Email:</label>
        {{ form.email }}
        {% if form.email.errors %}
            <div class="error">{{ form.email.errors }}</div>
        {% endif %}
    </div>

    <button type="submit">Submit</button>
</form>
```

## Model Forms

Model Forms automatically generate forms from Django models.

### Creating Model Forms

```python
# models.py
from django.db import models

class Article(models.Model):
    title = models.CharField(max_length=200)
    slug = models.SlugField(unique=True)
    content = models.TextField()
    published = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

# forms.py
from django import forms
from .models import Article

class ArticleForm(forms.ModelForm):
    class Meta:
        model = Article
        fields = ['title', 'slug', 'content', 'published']
        # Or exclude fields
        # exclude = ['created_at']

        widgets = {
            'content': forms.Textarea(attrs={'rows': 10}),
            'slug': forms.TextInput(attrs={'placeholder': 'article-slug'}),
        }

        labels = {
            'published': 'Publish immediately',
        }

        help_texts = {
            'slug': 'URL-friendly version of the title',
        }
```

### Using Model Forms

```python
# views.py
from django.shortcuts import render, redirect, get_object_or_404
from .forms import ArticleForm
from .models import Article

def create_article(request):
    if request.method == 'POST':
        form = ArticleForm(request.POST)
        if form.is_valid():
            article = form.save()
            return redirect('article_detail', pk=article.pk)
    else:
        form = ArticleForm()

    return render(request, 'article_form.html', {'form': form})

def edit_article(request, pk):
    article = get_object_or_404(Article, pk=pk)

    if request.method == 'POST':
        form = ArticleForm(request.POST, instance=article)
        if form.is_valid():
            form.save()
            return redirect('article_detail', pk=article.pk)
    else:
        form = ArticleForm(instance=article)

    return render(request, 'article_form.html', {'form': form})
```

## Form Validation

### Field-Level Validation

```python
from django import forms
from django.core.exceptions import ValidationError

class SignupForm(forms.Form):
    username = forms.CharField(max_length=30)
    email = forms.EmailField()
    password = forms.CharField(widget=forms.PasswordInput)
    confirm_password = forms.CharField(widget=forms.PasswordInput)

    def clean_username(self):
        username = self.cleaned_data['username']
        if User.objects.filter(username=username).exists():
            raise ValidationError('Username already exists')
        return username

    def clean_email(self):
        email = self.cleaned_data['email']
        if not email.endswith('@company.com'):
            raise ValidationError('Must use company email')
        return email
```

### Form-Level Validation

```python
class SignupForm(forms.Form):
    # ... fields ...

    def clean(self):
        cleaned_data = super().clean()
        password = cleaned_data.get('password')
        confirm_password = cleaned_data.get('confirm_password')

        if password and confirm_password:
            if password != confirm_password:
                raise ValidationError('Passwords do not match')

        return cleaned_data
```

### Custom Validators

```python
from django.core.exceptions import ValidationError
import re

def validate_phone_number(value):
    pattern = r'^\+?1?\d{9,15}$'
    if not re.match(pattern, value):
        raise ValidationError('Enter a valid phone number')

class ProfileForm(forms.Form):
    phone = forms.CharField(validators=[validate_phone_number])
```

## Form Widgets

### Built-in Widgets

```python
from django import forms

class ProductForm(forms.Form):
    name = forms.CharField(
        widget=forms.TextInput(attrs={
            'class': 'form-control',
            'placeholder': 'Product name'
        })
    )

    description = forms.CharField(
        widget=forms.Textarea(attrs={
            'rows': 5,
            'cols': 40
        })
    )

    price = forms.DecimalField(
        widget=forms.NumberInput(attrs={
            'min': 0,
            'step': '0.01'
        })
    )

    category = forms.ChoiceField(
        choices=[
            ('electronics', 'Electronics'),
            ('clothing', 'Clothing'),
            ('books', 'Books'),
        ],
        widget=forms.Select(attrs={'class': 'form-select'})
    )

    tags = forms.MultipleChoiceField(
        choices=[
            ('new', 'New'),
            ('sale', 'On Sale'),
            ('featured', 'Featured'),
        ],
        widget=forms.CheckboxSelectMultiple
    )

    available = forms.BooleanField(
        required=False,
        widget=forms.CheckboxInput(attrs={'class': 'form-check-input'})
    )

    launch_date = forms.DateField(
        widget=forms.DateInput(attrs={'type': 'date'})
    )
```

### Custom Widgets

```python
from django.forms import Widget

class ColorPickerWidget(Widget):
    template_name = 'widgets/color_picker.html'

    def get_context(self, name, value, attrs):
        context = super().get_context(name, value, attrs)
        context['widget']['type'] = 'color'
        return context

class ProductForm(forms.Form):
    color = forms.CharField(widget=ColorPickerWidget)
```

## File Uploads

### Handling File Uploads

```python
# forms.py
class UploadForm(forms.Form):
    title = forms.CharField(max_length=50)
    file = forms.FileField()
    image = forms.ImageField()  # Requires Pillow

# views.py
def upload_file(request):
    if request.method == 'POST':
        form = UploadForm(request.POST, request.FILES)
        if form.is_valid():
            handle_uploaded_file(request.FILES['file'])
            return redirect('success')
    else:
        form = UploadForm()

    return render(request, 'upload.html', {'form': form})

def handle_uploaded_file(f):
    with open('uploaded_file.txt', 'wb+') as destination:
        for chunk in f.chunks():
            destination.write(chunk)
```

### File Upload with Models

```python
# models.py
class Document(models.Model):
    title = models.CharField(max_length=200)
    file = models.FileField(upload_to='documents/')
    uploaded_at = models.DateTimeField(auto_now_add=True)

# forms.py
class DocumentForm(forms.ModelForm):
    class Meta:
        model = Document
        fields = ['title', 'file']

# views.py
def upload_document(request):
    if request.method == 'POST':
        form = DocumentForm(request.POST, request.FILES)
        if form.is_valid():
            form.save()
            return redirect('document_list')
    else:
        form = DocumentForm()

    return render(request, 'upload_document.html', {'form': form})
```

## Formsets

Formsets allow you to work with multiple forms on the same page.

### Basic Formsets

```python
from django.forms import formset_factory

class BookForm(forms.Form):
    title = forms.CharField()
    author = forms.CharField()

# Create a formset
BookFormSet = formset_factory(BookForm, extra=3)

# views.py
def manage_books(request):
    if request.method == 'POST':
        formset = BookFormSet(request.POST)
        if formset.is_valid():
            for form in formset:
                if form.cleaned_data:
                    # Process each form
                    pass
    else:
        formset = BookFormSet()

    return render(request, 'manage_books.html', {'formset': formset})
```

### Model Formsets

```python
from django.forms import modelformset_factory
from .models import Book

BookFormSet = modelformset_factory(
    Book,
    fields=['title', 'author', 'published'],
    extra=1,
    can_delete=True
)

def edit_books(request):
    if request.method == 'POST':
        formset = BookFormSet(request.POST)
        if formset.is_valid():
            formset.save()
            return redirect('book_list')
    else:
        formset = BookFormSet(queryset=Book.objects.all())

    return render(request, 'edit_books.html', {'formset': formset})
```

### Inline Formsets

```python
from django.forms import inlineformset_factory
from .models import Author, Book

BookInlineFormSet = inlineformset_factory(
    Author,
    Book,
    fields=['title', 'published'],
    extra=1,
    can_delete=True
)

def edit_author_books(request, author_id):
    author = get_object_or_404(Author, pk=author_id)

    if request.method == 'POST':
        formset = BookInlineFormSet(request.POST, instance=author)
        if formset.is_valid():
            formset.save()
            return redirect('author_detail', pk=author.pk)
    else:
        formset = BookInlineFormSet(instance=author)

    return render(request, 'edit_author_books.html', {
        'author': author,
        'formset': formset
    })
```

## AJAX Forms

### Using Fetch API

```html
<!-- template.html -->
<form id="ajaxForm">
    {% csrf_token %}
    <input type="text" name="name" required>
    <input type="email" name="email" required>
    <button type="submit">Submit</button>
</form>

<div id="message"></div>

<script>
document.getElementById('ajaxForm').addEventListener('submit', async function(e) {
    e.preventDefault();

    const formData = new FormData(this);

    try {
        const response = await fetch('/api/submit/', {
            method: 'POST',
            headers: {
                'X-CSRFToken': formData.get('csrfmiddlewaretoken')
            },
            body: formData
        });

        const data = await response.json();

        if (response.ok) {
            document.getElementById('message').textContent = 'Success!';
            this.reset();
        } else {
            document.getElementById('message').textContent = 'Error: ' + data.error;
        }
    } catch (error) {
        console.error('Error:', error);
    }
});
</script>
```

```python
# views.py
from django.http import JsonResponse

def ajax_submit(request):
    if request.method == 'POST':
        form = ContactForm(request.POST)
        if form.is_valid():
            # Process form
            return JsonResponse({'status': 'success'})
        else:
            return JsonResponse({
                'status': 'error',
                'errors': form.errors
            }, status=400)

    return JsonResponse({'status': 'error'}, status=405)
```

## Best Practices

1. **Always use CSRF protection** for POST requests
2. **Validate on both client and server** side
3. **Use Model Forms** when working with models
4. **Provide clear error messages**
5. **Use proper widgets** for better UX
6. **Keep forms simple** and focused
7. **Use formsets** for multiple related forms
8. **Handle file uploads** securely
9. **Test form validation** thoroughly
10. **Use crispy-forms or similar** for consistent styling

## Additional Resources

- [Django Forms Documentation](https://docs.djangoproject.com/en/stable/topics/forms/)
- [Django Crispy Forms](https://django-crispy-forms.readthedocs.io/)
- [Django Widget Tweaks](https://github.com/jazzband/django-widget-tweaks)
