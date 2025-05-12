## Getting Started

### Cloning the Specific Folder

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

Now you have the django2fa folder in your local repository.
