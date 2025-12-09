---
icon: lucide/lock
---

# Security

- [Django 2FA](#django-2fa)
- [Django SSO](#django-sso)
- [Django 2FA with Google Authenticator](#django-2fa-with-google-authenticator)
- [Django Passkeys](#django-passkeys)
- [Django ReCaptcha](#django-recaptcha)
- [Device Fingerprinting](#device-fingerprinting)

### Django 2FA

A Django project that demonstrates how to implement Two-Factor Authentication in your Django applications. This enhances security by requiring users to provide two forms of identification before gaining access.

### Django SSO

A [Django-based Single Sign-On (SSO) implementation](https://github.com/yokwejuste/DjangoCrafts/tree/main/django_sso/) that allows users to authenticate using Google OAuth2. This project demonstrates how to:

1. Authenticate users with Google OAuth2
2. Generate SSO tokens that can be used by other applications
3. Manage user sessions and authentication states

The implementation provides a practical example of SSO for educational purposes, making it easier to understand the concepts behind single sign-on authentication systems.

### Django 2FA with Google Authenticator

A [comprehensive Django application](https://github.com/yokwejuste/DjangoCrafts/tree/main/django2fa/) demonstrating two-factor authentication (2FA) implementation using `django-two-factor-auth`. This project showcases a secure Django implementation with multiple two-factor authentication methods including:

- TOTP (Time-based One-Time Password) for Google Authenticator
- Email verification codes
- Phone verification (SMS)

The application provides a complete authentication flow with a custom user model for enhanced security and Bootstrap UI for responsive design.

### Django Passkeys

A [Django-based web application](https://github.com/yokwejuste/django-passkeys) that implements both traditional authentication (username/password) and passkey authentication using the WebAuthn API. Passkey authentication allows users to securely log in without passwords, using biometric or hardware-based authentication methods.

Key features include:
- Traditional username/password registration and login
- Passkey-based authentication (passwordless)
- Implementation of the WebAuthn API for secure authentication
- Django's CSRF protection and HTTPS support for secure contexts

### Django ReCaptcha

A [comprehensive demonstration](https://github.com/yokwejuste/DjangoCrafts/tree/main/django_recaptcha/) of different CAPTCHA implementations in Django, including Google reCAPTCHA (v2 and v3) and Django Simple CAPTCHA. This project helps protect your forms from spam and bot submissions by showcasing multiple CAPTCHA types:

- Google reCAPTCHA v2 Checkbox - Traditional "I'm not a robot" verification
- Google reCAPTCHA v2 Invisible - Protection without user interaction
- Google reCAPTCHA v3 - Background scoring system
- Django Simple CAPTCHA - Self-hosted math challenge with audio support

The implementation uses Django, django-recaptcha, django-simple-captcha, and Tailwind CSS for styling.

### Device Fingerprinting

A [Django-based device fingerprinting system](https://github.com/yokwejuste/DjangoCrafts/tree/main/device_fingerprinting/) that demonstrates how to identify and track unique devices accessing your web application. This project showcases:

- Browser-based device fingerprinting implementation
- Secure storage of device signatures
- User session tracking and device change detection
- Analytics dashboard for device statistics
- Privacy-focused implementation with customizable tracking parameters

The implementation provides a practical example of device fingerprinting for both security and analytics purposes, helping you understand how to identify suspicious login attempts and track user devices without relying on cookies.