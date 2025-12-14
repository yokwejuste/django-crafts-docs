---
icon: lucide/test-tube
---

# Testing Django Applications

Write comprehensive tests to ensure your Django application works correctly.

## Test Types

Django supports several types of tests:
- **Unit Tests**: Test individual components
- **Integration Tests**: Test component interactions
- **Functional Tests**: Test user workflows
- **Performance Tests**: Test application performance

## Basic Testing

### Creating Tests

```python
# tests.py
from django.test import TestCase
from .models import Article

class ArticleModelTest(TestCase):
    def setUp(self):
        self.article = Article.objects.create(
            title='Test Article',
            content='Test content'
        )

    def test_article_creation(self):
        self.assertEqual(self.article.title, 'Test Article')
        self.assertTrue(isinstance(self.article, Article))

    def test_article_str(self):
        self.assertEqual(str(self.article), 'Test Article')
```

### Running Tests

```bash
# Run all tests
python manage.py test

# Run specific app
python manage.py test myapp

# Run specific test
python manage.py test myapp.tests.ArticleModelTest

# Run with verbosity
python manage.py test --verbosity=2

# Keep test database
python manage.py test --keepdb
```

## Testing Views

```python
from django.test import TestCase, Client
from django.urls import reverse

class ArticleViewTest(TestCase):
    def setUp(self):
        self.client = Client()
        self.article = Article.objects.create(
            title='Test Article',
            content='Content'
        )

    def test_article_list_view(self):
        response = self.client.get(reverse('article_list'))
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, 'Test Article')
        self.assertTemplateUsed(response, 'articles/list.html')

    def test_article_detail_view(self):
        url = reverse('article_detail', args=[self.article.id])
        response = self.client.get(url)
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, self.article.title)

    def test_article_create_view(self):
        data = {
            'title': 'New Article',
            'content': 'New content'
        }
        response = self.client.post(reverse('article_create'), data)
        self.assertEqual(response.status_code, 302)
        self.assertEqual(Article.objects.count(), 2)
```

## Testing Forms

```python
from django.test import TestCase
from .forms import ArticleForm

class ArticleFormTest(TestCase):
    def test_valid_form(self):
        data = {
            'title': 'Valid Title',
            'content': 'Valid content'
        }
        form = ArticleForm(data=data)
        self.assertTrue(form.is_valid())

    def test_invalid_form(self):
        data = {'title': ''}  # Missing required field
        form = ArticleForm(data=data)
        self.assertFalse(form.is_valid())
        self.assertIn('title', form.errors)

    def test_form_validation(self):
        data = {
            'title': 'abc',  # Too short
            'content': 'Content'
        }
        form = ArticleForm(data=data)
        self.assertFalse(form.is_valid())
```

## Testing Models

```python
class ArticleModelTest(TestCase):
    def test_save_and_retrieve(self):
        article = Article()
        article.title = 'Test'
        article.save()

        saved_article = Article.objects.first()
        self.assertEqual(saved_article.title, 'Test')

    def test_default_values(self):
        article = Article.objects.create(title='Test')
        self.assertFalse(article.published)

    def test_model_methods(self):
        article = Article.objects.create(
            title='Test Article',
            slug='test-article'
        )
        self.assertEqual(article.get_absolute_url(), '/articles/test-article/')
```

## Testing Authentication

```python
from django.contrib.auth.models import User

class AuthenticationTest(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            username='testuser',
            password='testpass123'
        )

    def test_login(self):
        logged_in = self.client.login(
            username='testuser',
            password='testpass123'
        )
        self.assertTrue(logged_in)

    def test_protected_view(self):
        # Without login
        response = self.client.get(reverse('dashboard'))
        self.assertEqual(response.status_code, 302)

        # With login
        self.client.force_login(self.user)
        response = self.client.get(reverse('dashboard'))
        self.assertEqual(response.status_code, 200)
```

## Testing APIs

```python
from rest_framework.test import APITestCase
from rest_framework import status

class ArticleAPITest(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            username='testuser',
            password='testpass'
        )

    def test_create_article(self):
        self.client.force_authenticate(user=self.user)
        data = {'title': 'New Article', 'content': 'Content'}
        response = self.client.post('/api/articles/', data)
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

    def test_get_articles(self):
        response = self.client.get('/api/articles/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
```

## Test Coverage

```bash
# Install coverage
pip install coverage

# Run tests with coverage
coverage run --source='.' manage.py test

# View coverage report
coverage report

# Generate HTML report
coverage html
```

```python
# .coveragerc
[run]
omit =
    */migrations/*
    */tests/*
    */venv/*
    manage.py

[report]
exclude_lines =
    pragma: no cover
    def __repr__
    raise AssertionError
    raise NotImplementedError
```

## Fixtures

```python
# fixtures/articles.json
[
    {
        "model": "myapp.article",
        "pk": 1,
        "fields": {
            "title": "Test Article",
            "content": "Test content"
        }
    }
]

# In tests
class ArticleTest(TestCase):
    fixtures = ['articles.json']

    def test_article_from_fixture(self):
        article = Article.objects.get(pk=1)
        self.assertEqual(article.title, 'Test Article')
```

## Mocking

```python
from unittest.mock import patch, Mock

class EmailTest(TestCase):
    @patch('myapp.tasks.send_email')
    def test_send_welcome_email(self, mock_send_email):
        user = User.objects.create_user('test', 'test@example.com')
        send_welcome_email(user)
        mock_send_email.assert_called_once()

    @patch('requests.get')
    def test_api_call(self, mock_get):
        mock_get.return_value.json.return_value = {'status': 'ok'}
        result = fetch_external_data()
        self.assertEqual(result['status'], 'ok')
```

## Performance Testing

```python
from django.test.utils import override_settings
import time

class PerformanceTest(TestCase):
    def test_query_count(self):
        with self.assertNumQueries(1):
            list(Article.objects.all())

    def test_response_time(self):
        start = time.time()
        response = self.client.get('/api/articles/')
        end = time.time()
        self.assertLess(end - start, 1.0)  # Less than 1 second
```

## Best Practices

1. **Test early and often**
2. **Aim for high coverage** (80%+)
3. **Write independent tests**
4. **Use descriptive test names**
5. **Follow AAA pattern**: Arrange, Act, Assert
6. **Use factories** for test data
7. **Mock external services**
8. **Test edge cases**
9. **Keep tests fast**
10. **Run tests before committing**

## Additional Resources

- [Django Testing Documentation](https://docs.djangoproject.com/en/stable/topics/testing/)
- [pytest-django](https://pytest-django.readthedocs.io/)
- [Factory Boy](https://factoryboy.readthedocs.io/)
