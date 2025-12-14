---
icon: lucide/package
---

# Python Package Managers

A comprehensive guide to Python package managers: pip, pipx, poetry, uv, and others.

## Overview

Python has multiple package managers, each designed for different use cases. Understanding when to use each tool is crucial for efficient Python development.

## pip - The Standard Package Manager

pip is Python's default package installer, included with Python 3.4+.

### Installation

```bash
# pip comes with Python, but you can upgrade it
python -m pip install --upgrade pip

# Check version
pip --version
```

### Basic Usage

```bash
# Install a package
pip install django

# Install specific version
pip install django==4.2.0

# Install with version constraints
pip install "django>=4.0,<5.0"

# Install from requirements.txt
pip install -r requirements.txt

# Install in editable mode (for development)
pip install -e .

# Uninstall package
pip uninstall django

# List installed packages
pip list

# Show package information
pip show django

# Search for packages (deprecated, use PyPI website)
# pip search django
```

### Requirements Files

```bash
# requirements.txt
django==4.2.0
djangorestframework>=3.14.0
python-dotenv==1.0.0
psycopg2-binary==2.9.9
gunicorn==21.2.0

# Install all requirements
pip install -r requirements.txt

# Generate requirements from current environment
pip freeze > requirements.txt
```

### Development vs Production Requirements

```bash
# requirements/base.txt
django==4.2.0
djangorestframework>=3.14.0
python-dotenv==1.0.0

# requirements/dev.txt
-r base.txt
pytest==7.4.0
black==23.7.0
flake8==6.0.0

# requirements/prod.txt
-r base.txt
gunicorn==21.2.0
psycopg2-binary==2.9.9

# Install for development
pip install -r requirements/dev.txt

# Install for production
pip install -r requirements/prod.txt
```

### Virtual Environments with pip

```bash
# Create virtual environment
python -m venv venv

# Activate (Linux/Mac)
source venv/bin/activate

# Activate (Windows)
venv\Scripts\activate

# Deactivate
deactivate

# Install packages in virtual environment
pip install django
```

### Pros and Cons

**Pros:**
- Built into Python
- Universal standard
- Simple and straightforward
- Huge ecosystem support

**Cons:**
- No dependency resolution (until pip 20.3)
- Manual virtual environment management
- No lock file by default
- Package conflicts can occur

## pipx - Install Python CLI Tools

pipx installs Python applications in isolated environments while making them globally available.

### Installation

```bash
# Install pipx
python -m pip install --user pipx
python -m pipx ensurepath

# Or via package manager (Ubuntu/Debian)
sudo apt install pipx
pipx ensurepath

# Or via Homebrew (Mac)
brew install pipx
pipx ensurepath
```

### Basic Usage

```bash
# Install a Python CLI tool
pipx install black

# Install specific version
pipx install black==23.7.0

# Run a tool without installing
pipx run black --check .

# List installed applications
pipx list

# Upgrade an application
pipx upgrade black

# Upgrade all applications
pipx upgrade-all

# Uninstall
pipx uninstall black

# Inject additional packages into an app's environment
pipx inject black colorama
```

### Common Use Cases

```bash
# Code formatters
pipx install black
pipx install isort

# Linters
pipx install flake8
pipx install pylint

# Type checkers
pipx install mypy

# Documentation tools
pipx install mkdocs
pipx install sphinx

# Build tools
pipx install build
pipx install twine

# Django development tools
pipx install django-extensions
```

### Pros and Cons

**Pros:**
- Isolated environments per application
- No virtual environment activation needed
- Global CLI tool access
- Prevents dependency conflicts

**Cons:**
- Only for CLI applications, not libraries
- Not suitable for project dependencies
- Adds overhead for simple scripts

## Poetry - Modern Dependency Management

Poetry handles dependency management, packaging, and publishing in one tool.

### Installation

```bash
# Install via official installer (recommended)
curl -sSL https://install.python-poetry.org | python3 -

# Or via pipx
pipx install poetry

# Check installation
poetry --version
```

### Initialize Project

```bash
# Create new project
poetry new myproject

# Initialize in existing project
cd myproject
poetry init

# This creates pyproject.toml
```

### pyproject.toml Example

```toml
[tool.poetry]
name = "myproject"
version = "0.1.0"
description = "My Django project"
authors = ["Your Name <you@example.com>"]
readme = "README.md"

[tool.poetry.dependencies]
python = "^3.11"
django = "^4.2"
djangorestframework = "^3.14"
python-dotenv = "^1.0"

[tool.poetry.group.dev.dependencies]
pytest = "^7.4"
black = "^23.7"
flake8 = "^6.0"
pytest-django = "^4.5"

[tool.poetry.group.prod.dependencies]
gunicorn = "^21.2"
psycopg2-binary = "^2.9"

[build-system]
requires = ["poetry-core"]
build-backend = "poetry.core.masonry.api"
```

### Basic Usage

```bash
# Install all dependencies
poetry install

# Install without dev dependencies
poetry install --without dev

# Install with specific groups
poetry install --with prod

# Add a dependency
poetry add django

# Add dev dependency
poetry add --group dev pytest

# Add with version constraint
poetry add "django>=4.2,<5.0"

# Remove dependency
poetry remove django

# Update dependencies
poetry update

# Update specific package
poetry update django

# Show installed packages
poetry show

# Show dependency tree
poetry show --tree

# Lock dependencies (update poetry.lock)
poetry lock

# Run command in virtual environment
poetry run python manage.py runserver

# Activate virtual environment
poetry shell

# Export to requirements.txt
poetry export -f requirements.txt --output requirements.txt
poetry export -f requirements.txt --without-hashes --output requirements.txt
```

### Virtual Environment Management

```bash
# Poetry creates virtual environments automatically

# Show virtual environment info
poetry env info

# List virtual environments
poetry env list

# Use specific Python version
poetry env use python3.11
poetry env use /usr/bin/python3.11

# Remove virtual environment
poetry env remove python3.11
```

### Build and Publish

```bash
# Build package
poetry build

# Publish to PyPI
poetry publish

# Build and publish
poetry publish --build

# Configure PyPI credentials
poetry config pypi-token.pypi your-token-here
```

### Pros and Cons

**Pros:**
- Automatic virtual environment management
- Lock file (poetry.lock) for reproducible installs
- Dependency resolution built-in
- Publishing and packaging tools included
- Clear separation of dev/prod dependencies

**Cons:**
- Learning curve
- Different from pip workflow
- Can be slow on large projects
- pyproject.toml format differs from other tools

## uv - Ultra-fast Package Installer

uv is an extremely fast Python package installer and resolver written in Rust.

### Installation

```bash
# Install via standalone installer (recommended)
curl -LsSf https://astral.sh/uv/install.sh | sh

# Or via pipx
pipx install uv

# Or via Homebrew (Mac)
brew install uv

# Check installation
uv --version
```

### Basic Usage

```bash
# Create virtual environment
uv venv

# Activate virtual environment
source .venv/bin/activate  # Linux/Mac
.venv\Scripts\activate     # Windows

# Install package
uv pip install django

# Install from requirements.txt
uv pip install -r requirements.txt

# Install with constraints
uv pip install "django>=4.2,<5.0"

# Compile requirements.txt (like pip-compile)
uv pip compile requirements.in -o requirements.txt

# Sync environment with requirements.txt
uv pip sync requirements.txt

# List installed packages
uv pip list

# Freeze installed packages
uv pip freeze

# Uninstall package
uv pip uninstall django
```

### Using with pyproject.toml

```toml
# pyproject.toml
[project]
name = "myproject"
version = "0.1.0"
requires-python = ">=3.11"
dependencies = [
    "django>=4.2,<5.0",
    "djangorestframework>=3.14",
    "python-dotenv>=1.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=7.4",
    "black>=23.7",
    "flake8>=6.0",
]
prod = [
    "gunicorn>=21.2",
    "psycopg2-binary>=2.9",
]

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"
```

```bash
# Install from pyproject.toml
uv pip install -e .

# Install with optional dependencies
uv pip install -e ".[dev]"
uv pip install -e ".[prod]"
```

### Lock Files with uv

```bash
# Generate uv.lock file
uv lock

# Install from lock file
uv sync

# Update lock file
uv lock --upgrade

# Install without dev dependencies
uv sync --no-dev
```

### Running Scripts

```bash
# Run Python script with uv
uv run python script.py

# Run with specific Python version
uv run --python 3.11 python script.py

# Run Django management command
uv run python manage.py runserver
```

### Pros and Cons

**Pros:**
- Extremely fast (10-100x faster than pip)
- Drop-in replacement for pip
- Built-in dependency resolution
- Lock file support
- Written in Rust for speed and reliability

**Cons:**
- Relatively new tool
- Smaller community compared to pip/poetry
- Some edge cases may not be handled
- Still evolving rapidly

## Other Package Managers

### pip-tools

Combines pip with dependency locking:

```bash
# Install
pip install pip-tools

# Create requirements.in
# requirements.in
django>=4.2
djangorestframework

# Compile to requirements.txt
pip-compile requirements.in

# Sync environment
pip-sync requirements.txt

# Update dependencies
pip-compile --upgrade
```

### Conda

Package manager for data science:

```bash
# Create environment
conda create -n myenv python=3.11

# Activate environment
conda activate myenv

# Install package
conda install django

# Install from conda-forge
conda install -c conda-forge django

# Export environment
conda env export > environment.yml

# Create from environment file
conda env create -f environment.yml
```

### PDM

Modern Python package manager:

```bash
# Install
pipx install pdm

# Initialize project
pdm init

# Add dependency
pdm add django

# Install dependencies
pdm install

# Run script
pdm run python manage.py runserver
```

## Comparison Table

| Feature | pip | pipx | Poetry | uv | pip-tools | Conda |
|---------|-----|------|--------|----|-----------| ------|
| **Speed** | Medium | Medium | Slow | Very Fast | Medium | Slow |
| **Lock Files** | No | N/A | Yes | Yes | Yes | Yes |
| **Dependency Resolution** | Basic | Basic | Advanced | Advanced | Advanced | Advanced |
| **Virtual Envs** | Manual | Auto | Auto | Manual | Manual | Auto |
| **Publishing** | No | No | Yes | No | No | No |
| **Use Case** | General | CLI Tools | Projects | General | Projects | Data Science |
| **Learning Curve** | Easy | Easy | Medium | Easy | Medium | Medium |

## When to Use Which Tool

### Use pip when:
- Working on simple projects
- Following tutorials
- Need maximum compatibility
- Working in legacy environments
- Quick prototyping

### Use pipx when:
- Installing CLI tools globally
- Need isolated tool environments
- Want tools available system-wide
- Installing development utilities

### Use Poetry when:
- Starting new Python projects
- Need dependency management and packaging
- Publishing to PyPI
- Want deterministic builds
- Working on libraries

### Use uv when:
- Need maximum installation speed
- Want pip compatibility with performance
- Working with large dependency trees
- Need lock file support
- CI/CD optimization

### Use pip-tools when:
- Want to stick with pip workflow
- Need lock files
- Simple projects with deterministic builds
- Gradual migration from pip

### Use Conda when:
- Data science projects
- Need non-Python dependencies
- Working with scientific libraries
- Need environment isolation with system packages

## Django Project Recommendations

### Small Django Projects

```bash
# Use pip with virtual environment
python -m venv venv
source venv/bin/activate
pip install django
pip freeze > requirements.txt
```

### Medium Django Projects

```bash
# Use Poetry
poetry init
poetry add django djangorestframework
poetry add --group dev pytest black flake8
poetry install
```

### Large Django Projects

```bash
# Use uv for speed
uv venv
source .venv/bin/activate
uv pip install -r requirements.txt
uv sync  # with pyproject.toml
```

### Team Django Projects

```toml
# Use Poetry with lock file
# pyproject.toml
[tool.poetry]
name = "myproject"
version = "0.1.0"

[tool.poetry.dependencies]
python = "^3.11"
django = "4.2.0"  # Exact versions for team consistency

[tool.poetry.group.dev.dependencies]
pytest = "^7.4"
```

```bash
# Team members run:
poetry install
# This installs exact versions from poetry.lock
```

## Migration Between Tools

### From pip to Poetry

```bash
# Create poetry project
poetry init

# Import from requirements.txt
cat requirements.txt | grep -v "^#" | xargs -n 1 poetry add

# Or manually edit pyproject.toml
poetry install
```

### From pip to uv

```bash
# uv is a drop-in replacement
# Replace 'pip' with 'uv pip'
uv pip install -r requirements.txt
```

### From Poetry to pip

```bash
# Export from poetry
poetry export -f requirements.txt --output requirements.txt

# Use with pip
pip install -r requirements.txt
```

### From Poetry to uv

```bash
# Poetry's pyproject.toml is compatible
uv pip install -e .
uv pip install -e ".[dev]"
```

## Best Practices

### 1. Always Use Virtual Environments

```bash
# Never install packages globally (except with pipx)
python -m venv venv
source venv/bin/activate
```

### 2. Pin Dependencies in Production

```bash
# requirements.txt for production
django==4.2.0  # Exact version, not >=4.2.0
gunicorn==21.2.0
psycopg2-binary==2.9.9
```

### 3. Separate Dev and Prod Dependencies

```bash
# requirements/base.txt
django==4.2.0

# requirements/dev.txt
-r base.txt
pytest==7.4.0

# requirements/prod.txt
-r base.txt
gunicorn==21.2.0
```

### 4. Use Lock Files

```bash
# Poetry
poetry lock

# uv
uv lock

# pip-tools
pip-compile requirements.in
```

### 5. Keep Dependencies Updated

```bash
# Check for outdated packages
pip list --outdated

# Update with Poetry
poetry update

# Update with uv
uv lock --upgrade
```

### 6. Document Installation Steps

```bash
# README.md
## Installation

### Using Poetry
```bash
poetry install
poetry run python manage.py runserver
```

### Using pip
```bash
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python manage.py runserver
```
```

## Troubleshooting

### Dependency Conflicts

```bash
# With pip - check conflicts
pip check

# With Poetry - resolve conflicts
poetry lock
poetry install

# With uv - fast resolution
uv pip install -r requirements.txt
```

### Corrupted Environment

```bash
# Delete and recreate

# pip
rm -rf venv
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Poetry
poetry env remove python3.11
poetry install

# uv
rm -rf .venv
uv venv
uv sync
```

### SSL Certificate Errors

```bash
# pip
pip install --trusted-host pypi.org --trusted-host files.pythonhosted.org django

# Set globally
pip config set global.trusted-host "pypi.org files.pythonhosted.org"
```

### Slow Installation

```bash
# Use uv for speed
pip install uv
uv pip install -r requirements.txt

# Or use pip cache
pip cache dir
pip cache list
pip cache remove *
```

## Additional Resources

- [pip Documentation](https://pip.pypa.io/)
- [pipx Documentation](https://pipx.pypa.io/)
- [Poetry Documentation](https://python-poetry.org/)
- [uv Documentation](https://github.com/astral-sh/uv)
- [pip-tools Documentation](https://pip-tools.readthedocs.io/)
- [Conda Documentation](https://docs.conda.io/)
- [Python Packaging Guide](https://packaging.python.org/)
