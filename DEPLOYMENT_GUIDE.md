# Odoo Docker Deployment Guide

Quick deployment guide for Odoo 18.0 using Docker Compose.

## 1. Check Prerequisites

```bash
# Check if Docker is installed
docker --version

# Check if Docker Compose is installed
docker compose version

# Check if Git is installed
git --version

# Check system resources
free -h
df -h
```

**Required:**
- Docker and Docker Compose
- Git
- 4GB RAM minimum
- 20GB disk space minimum

## 2. Install Prerequisites (Skip if already installed)

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install essential packages
sudo apt install -y curl wget git unzip

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
newgrp docker

# Install Docker Compose (if needed)
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify installations
docker --version && docker compose version && git --version
```

## 3. Quick Start

```bash
# Clone repository
git clone <your-repo-url>
cd pungkuran-odoo

# Configure environment (update passwords)
nano .env
nano config/odoo.conf

# Build and start
docker compose up -d --build

# Initialize database (one-time)
docker compose exec web odoo -c /etc/odoo/odoo.conf -i base -d odoo --stop-after-init
```

**Access Odoo:**
- URL: `http://your-server-ip:8069`
- Credentials: `admin` / `admin_pass`

## 4. Management Commands

```bash
# Check status
docker compose ps

# View logs
docker compose logs web

# Restart services
docker compose restart

# Stop services
docker compose down

# Update application
git pull && docker compose down && docker compose up -d --build
```

## 5. Backup

```bash
# Database backup
docker compose exec db pg_dump -U odoo odoo > backup_$(date +%Y%m%d_%H%M%S).sql

# Restore backup
docker compose exec -T db psql -U odoo odoo < backup_file.sql
```

## 6. Optional: Production Setup

### Update Passwords
```bash
# Edit these files with strong passwords
nano .env
nano config/odoo.conf
```

### Configure Domain
```bash
# Edit nginx configuration
nano config/nginx.conf
```

### SSL Certificate
```bash
sudo apt install certbot python3-certbot-nginx -y
sudo certbot --nginx -d your-domain.com
```

### Firewall
```bash
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 443
sudo ufw enable
```

---

**Note**: This setup works on both ARM64 and x86_64 VPS instances. 