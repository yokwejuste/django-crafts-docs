---
icon: lucide/mail
---

# Email and SMS Integration in Django

Comprehensive guide to integrating email and SMS functionality in Django applications.

## Email in Django

Django provides a robust email backend system for sending emails.

## Email Backends

Django supports multiple email backends:

- SMTP (Production)
- Console (Development)
- File (Testing)
- In-Memory (Testing)
- Custom backends

## Basic Email Configuration

### Development - Console Backend

```python
# settings/dev.py
EMAIL_BACKEND = 'django.core.mail.backends.console.EmailBackend'
```

Emails are printed to the console instead of being sent.

### Production - SMTP Backend

```python
# settings/prod.py
import os
from dotenv import load_dotenv

load_dotenv()

EMAIL_BACKEND = 'django.core.mail.backends.smtp.EmailBackend'
EMAIL_HOST = os.getenv('EMAIL_HOST', 'smtp.gmail.com')
EMAIL_PORT = int(os.getenv('EMAIL_PORT', '587'))
EMAIL_USE_TLS = os.getenv('EMAIL_USE_TLS', 'True').lower() in ('true', '1', 't')
EMAIL_USE_SSL = os.getenv('EMAIL_USE_SSL', 'False').lower() in ('true', '1', 't')
EMAIL_HOST_USER = os.getenv('EMAIL_HOST_USER')
EMAIL_HOST_PASSWORD = os.getenv('EMAIL_HOST_PASSWORD')
DEFAULT_FROM_EMAIL = os.getenv('DEFAULT_FROM_EMAIL', 'noreply@example.com')
SERVER_EMAIL = os.getenv('SERVER_EMAIL', 'admin@example.com')
```

### Testing - File Backend

```python
# settings/test.py
EMAIL_BACKEND = 'django.core.mail.backends.filebased.EmailBackend'
EMAIL_FILE_PATH = '/tmp/app-emails'  # Directory for email files
```

## Sending Basic Emails

### Simple Email

```python
from django.core.mail import send_mail

send_mail(
    subject='Welcome to Our Site',
    message='Thank you for signing up!',
    from_email='noreply@example.com',
    recipient_list=['user@example.com'],
    fail_silently=False,
)
```

### HTML Email

```python
from django.core.mail import send_mail

send_mail(
    subject='Welcome to Our Site',
    message='Thank you for signing up!',  # Plain text fallback
    from_email='noreply@example.com',
    recipient_list=['user@example.com'],
    html_message='<h1>Welcome!</h1><p>Thank you for signing up!</p>',
    fail_silently=False,
)
```

### Multiple Recipients

```python
from django.core.mail import send_mail

send_mail(
    subject='Newsletter',
    message='Here is our latest newsletter',
    from_email='newsletter@example.com',
    recipient_list=[
        'user1@example.com',
        'user2@example.com',
        'user3@example.com',
    ],
)
```

## Advanced Email Sending

### EmailMessage Class

```python
from django.core.mail import EmailMessage

email = EmailMessage(
    subject='Order Confirmation',
    body='Your order has been confirmed.',
    from_email='orders@example.com',
    to=['customer@example.com'],
    bcc=['admin@example.com'],
    cc=['manager@example.com'],
    reply_to=['support@example.com'],
    headers={'Message-ID': 'order-12345'},
)
email.send()
```

### Email with Attachments

```python
from django.core.mail import EmailMessage

email = EmailMessage(
    subject='Invoice',
    body='Please find your invoice attached.',
    from_email='billing@example.com',
    to=['customer@example.com'],
)

# Attach file from path
email.attach_file('/path/to/invoice.pdf')

# Attach file from content
email.attach('report.pdf', pdf_content, 'application/pdf')

# Attach file from uploaded file
email.attach(uploaded_file.name, uploaded_file.read(), uploaded_file.content_type)

email.send()
```

### HTML Email with Images

```python
from django.core.mail import EmailMultiAlternatives
from django.template.loader import render_to_string
from django.utils.html import strip_tags

# Render HTML template
html_content = render_to_string('emails/welcome.html', {
    'user': user,
    'activation_link': activation_link,
})
text_content = strip_tags(html_content)

email = EmailMultiAlternatives(
    subject='Welcome to Our Site',
    body=text_content,
    from_email='noreply@example.com',
    to=[user.email],
)
email.attach_alternative(html_content, "text/html")

# Attach inline image
with open('/path/to/logo.png', 'rb') as f:
    email.attach('logo.png', f.read(), 'image/png')

email.send()
```

## Email Templates

### Create Email Template

```django
<!-- templates/emails/welcome.html -->
<!DOCTYPE html>
<html>
<head>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            color: #333;
        }
        .container {
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
        }
        .header {
            background-color: #4CAF50;
            color: white;
            padding: 20px;
            text-align: center;
        }
        .content {
            padding: 20px;
            background-color: #f9f9f9;
        }
        .button {
            display: inline-block;
            padding: 10px 20px;
            background-color: #4CAF50;
            color: white;
            text-decoration: none;
            border-radius: 5px;
        }
        .footer {
            text-align: center;
            padding: 20px;
            font-size: 12px;
            color: #666;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Welcome to {{ site_name }}</h1>
        </div>
        <div class="content">
            <p>Hi {{ user.first_name }},</p>
            <p>Thank you for signing up! We're excited to have you on board.</p>
            <p>To get started, please verify your email address:</p>
            <p style="text-align: center;">
                <a href="{{ activation_link }}" class="button">Verify Email</a>
            </p>
            <p>If the button doesn't work, copy and paste this link into your browser:</p>
            <p>{{ activation_link }}</p>
        </div>
        <div class="footer">
            <p>This email was sent to {{ user.email }}</p>
            <p>If you didn't sign up for this account, please ignore this email.</p>
        </div>
    </div>
</body>
</html>
```

### Plain Text Template

```django
<!-- templates/emails/welcome.txt -->
Hi {{ user.first_name }},

Thank you for signing up for {{ site_name }}!

To get started, please verify your email address by clicking the link below:

{{ activation_link }}

If you didn't sign up for this account, please ignore this email.

Thanks,
The {{ site_name }} Team
```

### Send Templated Email

```python
from django.core.mail import EmailMultiAlternatives
from django.template.loader import render_to_string
from django.utils.html import strip_tags

def send_welcome_email(user, activation_link):
    context = {
        'user': user,
        'site_name': 'My Site',
        'activation_link': activation_link,
    }

    html_message = render_to_string('emails/welcome.html', context)
    plain_message = render_to_string('emails/welcome.txt', context)

    email = EmailMultiAlternatives(
        subject='Welcome to My Site',
        body=plain_message,
        from_email='noreply@example.com',
        to=[user.email],
    )
    email.attach_alternative(html_message, "text/html")
    email.send()
```

## Email Service Providers

### Gmail SMTP

```python
# settings.py
EMAIL_BACKEND = 'django.core.mail.backends.smtp.EmailBackend'
EMAIL_HOST = 'smtp.gmail.com'
EMAIL_PORT = 587
EMAIL_USE_TLS = True
EMAIL_HOST_USER = os.getenv('GMAIL_USER')
EMAIL_HOST_PASSWORD = os.getenv('GMAIL_APP_PASSWORD')  # Use App Password
DEFAULT_FROM_EMAIL = os.getenv('GMAIL_USER')
```

```env
# .env
GMAIL_USER=your-email@gmail.com
GMAIL_APP_PASSWORD=your-16-char-app-password
```

**Note:** Enable 2FA and create an App Password in Google Account settings.

### SendGrid

```bash
pip install sendgrid
```

```python
# settings.py
SENDGRID_API_KEY = os.getenv('SENDGRID_API_KEY')

# Using SendGrid's API
from sendgrid import SendGridAPIClient
from sendgrid.helpers.mail import Mail

def send_email_sendgrid(to_email, subject, html_content):
    message = Mail(
        from_email='noreply@example.com',
        to_emails=to_email,
        subject=subject,
        html_content=html_content
    )

    try:
        sg = SendGridAPIClient(os.getenv('SENDGRID_API_KEY'))
        response = sg.send(message)
        return response.status_code
    except Exception as e:
        print(str(e))
```

### AWS SES (Simple Email Service)

```bash
pip install boto3
```

```python
# settings.py
EMAIL_BACKEND = 'django_ses.SESBackend'
AWS_SES_REGION_NAME = os.getenv('AWS_REGION', 'us-east-1')
AWS_SES_REGION_ENDPOINT = f'email.{AWS_SES_REGION_NAME}.amazonaws.com'
AWS_ACCESS_KEY_ID = os.getenv('AWS_ACCESS_KEY_ID')
AWS_SECRET_ACCESS_KEY = os.getenv('AWS_SECRET_ACCESS_KEY')

# Or using boto3 directly
import boto3

def send_email_ses(to_email, subject, body_html, body_text):
    client = boto3.client('ses', region_name='us-east-1')

    response = client.send_email(
        Source='noreply@example.com',
        Destination={'ToAddresses': [to_email]},
        Message={
            'Subject': {'Data': subject},
            'Body': {
                'Text': {'Data': body_text},
                'Html': {'Data': body_html}
            }
        }
    )
    return response
```

### Mailgun

```bash
pip install django-mailgun
```

```python
# settings.py
EMAIL_BACKEND = 'django_mailgun.MailgunBackend'
MAILGUN_ACCESS_KEY = os.getenv('MAILGUN_ACCESS_KEY')
MAILGUN_SERVER_NAME = os.getenv('MAILGUN_SERVER_NAME')
```

### Postmark

```bash
pip install python-postmark
```

```python
from postmark import PMMail

def send_email_postmark(to_email, subject, html_body, text_body):
    message = PMMail(
        api_key=os.getenv('POSTMARK_API_KEY'),
        subject=subject,
        sender='noreply@example.com',
        to=to_email,
        text_body=text_body,
        html_body=html_body,
    )
    message.send()
```

## Asynchronous Email Sending

### Using Celery

```bash
pip install celery redis
```

```python
# celery.py
import os
from celery import Celery

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'myproject.settings')

app = Celery('myproject')
app.config_from_object('django.conf:settings', namespace='CELERY')
app.autodiscover_tasks()

# tasks.py
from celery import shared_task
from django.core.mail import send_mail

@shared_task
def send_email_task(subject, message, from_email, recipient_list):
    send_mail(
        subject=subject,
        message=message,
        from_email=from_email,
        recipient_list=recipient_list,
    )
    return f'Email sent to {recipient_list}'

@shared_task
def send_welcome_email_task(user_id):
    from django.contrib.auth.models import User

    user = User.objects.get(pk=user_id)
    send_mail(
        subject='Welcome!',
        message=f'Welcome {user.first_name}!',
        from_email='noreply@example.com',
        recipient_list=[user.email],
    )

# views.py
from .tasks import send_email_task, send_welcome_email_task

def register_user(request):
    # ... user registration logic

    # Send email asynchronously
    send_welcome_email_task.delay(user.id)

    return redirect('success')
```

### Using Django Q

```bash
pip install django-q
```

```python
# settings.py
INSTALLED_APPS = [
    # ...
    'django_q',
]

Q_CLUSTER = {
    'name': 'myproject',
    'workers': 4,
    'timeout': 90,
    'django_redis': 'default'
}

# tasks.py
from django_q.tasks import async_task

def send_email_async(user_email, subject, message):
    async_task(
        'django.core.mail.send_mail',
        subject,
        message,
        'noreply@example.com',
        [user_email],
    )
```

## Bulk Email Sending

### Send Mass Email

```python
from django.core.mail import send_mass_mail

message1 = (
    'Subject 1',
    'Message 1',
    'from@example.com',
    ['user1@example.com']
)
message2 = (
    'Subject 2',
    'Message 2',
    'from@example.com',
    ['user2@example.com']
)

send_mass_mail((message1, message2), fail_silently=False)
```

### Batch Processing

```python
from django.core.mail import EmailMessage
from django.contrib.auth.models import User

def send_newsletter(subject, message):
    users = User.objects.filter(is_active=True)
    batch_size = 100

    for i in range(0, users.count(), batch_size):
        batch = users[i:i + batch_size]
        emails = [
            EmailMessage(
                subject=subject,
                body=message,
                from_email='newsletter@example.com',
                to=[user.email]
            )
            for user in batch
        ]

        # Send batch
        for email in emails:
            email.send()
```

## SMS Integration

Django doesn't have built-in SMS support, but you can integrate third-party services.

## Twilio SMS

Twilio is one of the most popular SMS providers.

### Installation

```bash
pip install twilio
```

### Configuration

```python
# settings.py
TWILIO_ACCOUNT_SID = os.getenv('TWILIO_ACCOUNT_SID')
TWILIO_AUTH_TOKEN = os.getenv('TWILIO_AUTH_TOKEN')
TWILIO_PHONE_NUMBER = os.getenv('TWILIO_PHONE_NUMBER')
```

```env
# .env
TWILIO_ACCOUNT_SID=your-account-sid
TWILIO_AUTH_TOKEN=your-auth-token
TWILIO_PHONE_NUMBER=+1234567890
```

### Send SMS

```python
# utils/sms.py
from twilio.rest import Client
from django.conf import settings

def send_sms(to_number, message):
    client = Client(
        settings.TWILIO_ACCOUNT_SID,
        settings.TWILIO_AUTH_TOKEN
    )

    message = client.messages.create(
        body=message,
        from_=settings.TWILIO_PHONE_NUMBER,
        to=to_number
    )

    return message.sid

# views.py
from .utils.sms import send_sms

def send_verification_code(request):
    phone_number = request.POST.get('phone_number')
    code = generate_verification_code()

    send_sms(
        to_number=phone_number,
        message=f'Your verification code is: {code}'
    )

    return JsonResponse({'status': 'sent'})
```

### SMS Verification

```python
# models.py
from django.db import models
import random
import string

class SMSVerification(models.Model):
    phone_number = models.CharField(max_length=15)
    code = models.CharField(max_length=6)
    created_at = models.DateTimeField(auto_now_add=True)
    verified = models.BooleanField(default=False)

    def generate_code(self):
        self.code = ''.join(random.choices(string.digits, k=6))
        self.save()
        return self.code

    def is_valid(self):
        from datetime import timedelta
        from django.utils import timezone

        expiry = self.created_at + timedelta(minutes=10)
        return timezone.now() < expiry and not self.verified

# views.py
from .models import SMSVerification
from .utils.sms import send_sms

def request_verification_code(request):
    phone_number = request.POST.get('phone_number')

    verification = SMSVerification.objects.create(
        phone_number=phone_number
    )
    code = verification.generate_code()

    send_sms(
        to_number=phone_number,
        message=f'Your verification code is: {code}. Valid for 10 minutes.'
    )

    return JsonResponse({'status': 'sent'})

def verify_code(request):
    phone_number = request.POST.get('phone_number')
    code = request.POST.get('code')

    try:
        verification = SMSVerification.objects.filter(
            phone_number=phone_number,
            code=code,
            verified=False
        ).latest('created_at')

        if verification.is_valid():
            verification.verified = True
            verification.save()
            return JsonResponse({'status': 'verified'})
        else:
            return JsonResponse({'error': 'Code expired'}, status=400)
    except SMSVerification.DoesNotExist:
        return JsonResponse({'error': 'Invalid code'}, status=400)
```

## AWS SNS (Simple Notification Service)

```bash
pip install boto3
```

### Configuration

```python
# settings.py
AWS_SNS_REGION = os.getenv('AWS_REGION', 'us-east-1')
AWS_ACCESS_KEY_ID = os.getenv('AWS_ACCESS_KEY_ID')
AWS_SECRET_ACCESS_KEY = os.getenv('AWS_SECRET_ACCESS_KEY')
```

### Send SMS with SNS

```python
import boto3
from django.conf import settings

def send_sms_sns(phone_number, message):
    client = boto3.client(
        'sns',
        region_name=settings.AWS_SNS_REGION,
        aws_access_key_id=settings.AWS_ACCESS_KEY_ID,
        aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY
    )

    response = client.publish(
        PhoneNumber=phone_number,
        Message=message,
        MessageAttributes={
            'AWS.SNS.SMS.SMSType': {
                'DataType': 'String',
                'StringValue': 'Transactional'  # or 'Promotional'
            }
        }
    )

    return response['MessageId']
```

## Africa's Talking SMS

Popular SMS provider for African countries.

```bash
pip install africastalking
```

### Configuration

```python
# settings.py
AFRICASTALKING_USERNAME = os.getenv('AFRICASTALKING_USERNAME')
AFRICASTALKING_API_KEY = os.getenv('AFRICASTALKING_API_KEY')
```

### Send SMS

```python
import africastalking
from django.conf import settings

africastalking.initialize(
    settings.AFRICASTALKING_USERNAME,
    settings.AFRICASTALKING_API_KEY
)

sms = africastalking.SMS

def send_sms_at(phone_numbers, message):
    """
    phone_numbers: list of phone numbers with country code e.g. ['+237123456789']
    """
    try:
        response = sms.send(message, phone_numbers)
        return response
    except Exception as e:
        print(f'Error: {e}')
        return None
```

## Vonage (Nexmo) SMS

```bash
pip install vonage
```

### Configuration

```python
# settings.py
VONAGE_API_KEY = os.getenv('VONAGE_API_KEY')
VONAGE_API_SECRET = os.getenv('VONAGE_API_SECRET')
VONAGE_PHONE_NUMBER = os.getenv('VONAGE_PHONE_NUMBER')
```

### Send SMS

```python
import vonage
from django.conf import settings

client = vonage.Client(
    key=settings.VONAGE_API_KEY,
    secret=settings.VONAGE_API_SECRET
)

sms = vonage.Sms(client)

def send_sms_vonage(to_number, message):
    response = sms.send_message({
        'from': settings.VONAGE_PHONE_NUMBER,
        'to': to_number,
        'text': message,
    })

    if response['messages'][0]['status'] == '0':
        return response['messages'][0]['message-id']
    else:
        error = response['messages'][0]['error-text']
        raise Exception(f'SMS failed: {error}')
```

## Two-Factor Authentication (2FA)

### Email-based 2FA

```python
# models.py
from django.db import models
from django.contrib.auth.models import User
import random
import string

class EmailOTP(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    otp = models.CharField(max_length=6)
    created_at = models.DateTimeField(auto_now_add=True)
    verified = models.BooleanField(default=False)

    def generate_otp(self):
        self.otp = ''.join(random.choices(string.digits, k=6))
        self.save()
        return self.otp

    def is_valid(self):
        from datetime import timedelta
        from django.utils import timezone

        expiry = self.created_at + timedelta(minutes=5)
        return timezone.now() < expiry and not self.verified

# views.py
from django.core.mail import send_mail

def login_request_otp(request):
    username = request.POST.get('username')
    password = request.POST.get('password')

    user = authenticate(username=username, password=password)

    if user:
        otp_obj = EmailOTP.objects.create(user=user)
        otp = otp_obj.generate_otp()

        send_mail(
            subject='Your Login Code',
            message=f'Your one-time password is: {otp}',
            from_email='noreply@example.com',
            recipient_list=[user.email],
        )

        request.session['user_id'] = user.id
        return JsonResponse({'status': 'otp_sent'})

    return JsonResponse({'error': 'Invalid credentials'}, status=400)

def verify_otp(request):
    user_id = request.session.get('user_id')
    otp = request.POST.get('otp')

    try:
        otp_obj = EmailOTP.objects.filter(
            user_id=user_id,
            otp=otp,
            verified=False
        ).latest('created_at')

        if otp_obj.is_valid():
            otp_obj.verified = True
            otp_obj.save()
            login(request, otp_obj.user)
            return JsonResponse({'status': 'logged_in'})
        else:
            return JsonResponse({'error': 'OTP expired'}, status=400)
    except EmailOTP.DoesNotExist:
        return JsonResponse({'error': 'Invalid OTP'}, status=400)
```

### SMS-based 2FA

```python
# Use the SMS verification code example above with authentication

def login_request_sms_otp(request):
    username = request.POST.get('username')
    password = request.POST.get('password')

    user = authenticate(username=username, password=password)

    if user and user.profile.phone_number:
        verification = SMSVerification.objects.create(
            phone_number=user.profile.phone_number
        )
        code = verification.generate_code()

        send_sms(
            to_number=user.profile.phone_number,
            message=f'Your login code is: {code}'
        )

        request.session['user_id'] = user.id
        return JsonResponse({'status': 'sms_sent'})

    return JsonResponse({'error': 'Invalid credentials'}, status=400)
```

## Best Practices

### 1. Use Environment Variables

```python
# Never hardcode credentials
EMAIL_HOST_USER = os.getenv('EMAIL_HOST_USER')
TWILIO_AUTH_TOKEN = os.getenv('TWILIO_AUTH_TOKEN')
```

### 2. Handle Failures Gracefully

```python
from django.core.mail import send_mail
import logging

logger = logging.getLogger(__name__)

def safe_send_email(subject, message, recipient):
    try:
        send_mail(
            subject=subject,
            message=message,
            from_email='noreply@example.com',
            recipient_list=[recipient],
            fail_silently=False,
        )
    except Exception as e:
        logger.error(f'Failed to send email to {recipient}: {str(e)}')
        # Optionally retry or queue for later
```

### 3. Rate Limiting

```python
from django.core.cache import cache

def send_sms_with_rate_limit(phone_number, message):
    cache_key = f'sms_rate_limit_{phone_number}'

    if cache.get(cache_key):
        raise Exception('Rate limit exceeded. Please try again later.')

    send_sms(phone_number, message)

    # Set rate limit for 1 minute
    cache.set(cache_key, True, 60)
```

### 4. Email Validation

```python
from django.core.validators import validate_email
from django.core.exceptions import ValidationError

def is_valid_email(email):
    try:
        validate_email(email)
        return True
    except ValidationError:
        return False
```

### 5. Unsubscribe Mechanism

```python
# models.py
class EmailPreference(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    marketing_emails = models.BooleanField(default=True)
    newsletter = models.BooleanField(default=True)
    notifications = models.BooleanField(default=True)

# Before sending
def send_marketing_email(user, subject, message):
    if hasattr(user, 'emailpreference') and user.emailpreference.marketing_emails:
        send_mail(subject, message, 'marketing@example.com', [user.email])
```

### 6. Email Logging

```python
# models.py
class EmailLog(models.Model):
    recipient = models.EmailField()
    subject = models.CharField(max_length=255)
    status = models.CharField(max_length=20)  # sent, failed
    sent_at = models.DateTimeField(auto_now_add=True)
    error_message = models.TextField(blank=True)

# Track emails
def tracked_send_email(recipient, subject, message):
    try:
        send_mail(subject, message, 'noreply@example.com', [recipient])
        EmailLog.objects.create(
            recipient=recipient,
            subject=subject,
            status='sent'
        )
    except Exception as e:
        EmailLog.objects.create(
            recipient=recipient,
            subject=subject,
            status='failed',
            error_message=str(e)
        )
```

## Testing

### Test Email Sending

```python
# tests.py
from django.test import TestCase
from django.core import mail

class EmailTest(TestCase):
    def test_send_email(self):
        mail.send_mail(
            'Subject',
            'Message',
            'from@example.com',
            ['to@example.com'],
        )

        self.assertEqual(len(mail.outbox), 1)
        self.assertEqual(mail.outbox[0].subject, 'Subject')
        self.assertEqual(mail.outbox[0].to, ['to@example.com'])
```

### Mock SMS for Testing

```python
from unittest.mock import patch

class SMSTest(TestCase):
    @patch('myapp.utils.sms.send_sms')
    def test_send_verification_code(self, mock_send_sms):
        mock_send_sms.return_value = 'message-id-123'

        result = send_verification_code('+1234567890')

        mock_send_sms.assert_called_once()
        self.assertEqual(result, 'message-id-123')
```

## Additional Resources

- [Django Email Documentation](https://docs.djangoproject.com/en/stable/topics/email/)
- [Twilio Python Documentation](https://www.twilio.com/docs/libraries/python)
- [SendGrid Python Documentation](https://docs.sendgrid.com/for-developers/sending-email/v3-python-code-example)
- [AWS SES Documentation](https://docs.aws.amazon.com/ses/)
- [Celery Documentation](https://docs.celeryproject.org/)
