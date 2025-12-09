---
icon: lucide/rocket
---

# Get started
Welcome to Django Crafts! This repository contains various Django projects and tutorials to help you learn and implement different Django features and functionalities.

## Project Structure
The repository is organized into several sections, each focusing on a specific aspect of Django development. Each section contains a dedicated folder with relevant code examples and documentation.

## Cloning a Specific Folder

If you want to clone only a specific project folder instead of the entire repository, you can use sparse checkout with git. Follow these steps:

1. Create a new directory and initialize a git repository:
   ```bash
   mkdir my-project
   cd my-project
   git init
   ```

2. Add the remote repository:
   ```bash
   git remote add origin https://github.com/YOUR_USERNAME/Django-Crafts.git
   ```

3. Enable sparse checkout:
   ```bash
   git config core.sparseCheckout true
   ```

4. Specify the folder you want to clone (e.g., django2fa):
   ```bash
   echo "django2fa/" >> .git/info/sparse-checkout
   ```

5. Pull the content:
   ```bash
   git pull origin main
   ```

Now you have only the django2fa folder in your local repository.

## Contributing
Now you have only the django2fa folder in your local repository, which makes it easier to focus on a specific project.

1. **Create a Branch**: Create a new branch for your feature or bug fix.
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make Changes**: Implement your changes, following our coding standards.

3. **Test Your Changes**: Ensure your changes work as expected and don't break existing functionality.

4. **Commit Your Changes**: Commit your changes with a clear and descriptive commit message.
   ```bash
   git commit -m "Add a descriptive message about your changes"
   ```

5. **Push to Your Fork**: Push your changes to your forked repository.
   ```bash
   git push origin feature/your-feature-name
   ```

6. **Submit a Pull Request**: Create a pull request from your branch to our main repository.

## Repo Structure

```mermaid
%% Mermaid diagram: Repository code tree & architecture (root + per-app typical layout)
graph TD
  RC["DjangoCrafts/"]

  %% Top-level directories (from repo)
  RC --> dot_github[".github/"]
  RC --> device_fp["device_fingerprinting/"]
  RC --> django2fa["django2fa/"]
  RC --> django_recaptcha["django_recaptcha/"]
  RC --> django_sso["django_sso/"]

  %% Top-level files (from repo)
  RC --> gitmodules[".gitmodules"]
  RC --> django_passkeys["django-passkeys (submodule/file)"]
  RC --> code_of_conduct["CODE_OF_CONDUCT.md"]
  RC --> contributing["CONTRIBUTING.md"]
  RC --> license["LICENSE"]
  RC --> readme["README.md"]
  RC --> security["SECURITY.md"]
  RC --> support["SUPPORT.md"]

  %% device_fingerprinting app (contents inferred as typical Django app layout)
  subgraph DF [device_fingerprinting/]
    df_apps["apps.py (inferred)"]
    df_models["models.py (inferred)"]
    df_views["views.py (inferred)"]
    df_urls["urls.py (inferred)"]
    df_admin["admin.py (inferred)"]
    df_forms["forms.py (inferred)"]
    df_serializers["serializers.py (inferred)"]
    df_migrations["migrations/ (likely)"]
    df_templates["templates/device_fingerprinting/ (likely)"]
    df_static["static/device_fingerprinting/ (likely)"]
    df_tests["tests.py (inferred)"]
    df_utils["utils/ (inferred)"]
  end
  device_fp --> DF

  %% django2fa app (typical layout - inferred)
  subgraph D2 [django2fa/]
    d2_apps["apps.py (inferred)"]
    d2_models["models.py (inferred)"]
    d2_views["views.py (inferred)"]
    d2_urls["urls.py (inferred)"]
    d2_admin["admin.py (inferred)"]
    d2_forms["forms.py (inferred)"]
    d2_templates["templates/django2fa/ (likely)"]
    d2_static["static/django2fa/ (likely)"]
    d2_tests["tests.py (inferred)"]
    d2_utils["utils/ (inferred)"]
  end
  django2fa --> D2

  %% django_recaptcha app (typical layout - inferred)
  subgraph DR [django_recaptcha/]
    dr_apps["apps.py (inferred)"]
    dr_models["models.py (inferred)"]
    dr_views["views.py (inferred)"]
    dr_urls["urls.py (inferred)"]
    dr_admin["admin.py (inferred)"]
    dr_forms["forms.py (inferred)"]
    dr_templates["templates/django_recaptcha/ (likely)"]
    dr_static["static/django_recaptcha/ (likely)"]
    dr_tests["tests.py (inferred)"]
  end
  django_recaptcha --> DR

  %% django_sso app (typical layout - inferred)
  subgraph DS [django_sso/]
    ds_apps["apps.py (inferred)"]
    ds_models["models.py (inferred)"]
    ds_views["views.py (inferred)"]
    ds_urls["urls.py (inferred)"]
    ds_admin["admin.py (inferred)"]
    ds_forms["forms.py (inferred)"]
    ds_templates["templates/django_sso/ (likely)"]
    ds_static["static/django_sso/ (likely)"]
    ds_tests["tests.py (inferred)"]
    ds_utils["utils/ (inferred)"]
  end
  django_sso --> DS

  %% Visual styles
```
