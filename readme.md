# ⚙️ libmyserver.sh

A lightweight and modular Bash library for managing server infrastructure, Nginx configurations, and container deployments.

## ✨ Features

- 🔧 **Utility Functions** - Common helpers for colors, logging, and environment management
- 🌐 **Nginx Management** - Configure Nginx with SSL/TLS support (Cloudflare, Let's Encrypt, Lego)
- 🐳 **Container Support** - Podman integration with systemd service management
- ⏰ **Cron Jobs** - Automated certificate renewal and maintenance tasks
- 📝 **Template Rendering** - Simple variable substitution in configuration templates

## 🚀 Quick Start

### Build the Library

```bash
bash build.sh
```

This generates `_dist/libmyserver.sh` with all modules and templates bundled.

### example of usage

```bash
cat ./makefile.example.sh
```

## 🔐 SSL/TLS Support

The library supports three SSL certificate providers:

1. **Cloudflare Origin CA** - Set `USE_CLOUDFLARE=true`
2. **Lego ACME Client** - Set `USE_LEGO=true`
3. **Nginx ACME Module** - Set `USE_NGXACME=true`
