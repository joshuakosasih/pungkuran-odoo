## Odoo 18 Community Fork on Docker (All-in-One Repo)

### 1. Directory Structure (Simple)
Place everything in the **root of your fork**:
```plaintext
odoo18-fork/                # your Git repo root
├── docker-compose.yml       # Compose and build definitions
├── Dockerfile               # Custom Odoo 18 ARM build
├── addons/                  # Your custom modules live here
├── config/
│   ├── odoo.conf            # Odoo settings
│   └── nginx.conf           # Nginx reverse proxy
├── .env                     # Credentials & secrets (gitignored)
└── (all other Odoo source files, including core addons)
```

### 2. `.env` Template (gitignore this file)
```ini
POSTGRES_USER=odoo
POSTGRES_PASSWORD=odoo_pass
POSTGRES_DB=odoo
ODOO_ADMIN_PASS=admin_pass
```  

### 3. `Dockerfile` (root)
```dockerfile
FROM python:3.11-slim
# System deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential libpq-dev git wget xfonts-75dpi xfonts-base \
  && rm -rf /var/lib/apt/lists/*
# wkhtmltopdf for PDFs
RUN wget https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox_0.12.6-1.arm64.deb && \
    dpkg -i wkhtmltox_0.12.6-1.arm64.deb && rm wkhtmltox_0.12.6-1.arm64.deb
# App setup
WORKDIR /opt/odoo
COPY . .
RUN python3 -m venv venv && . venv/bin/activate && \
    pip install --upgrade pip wheel && pip install -r requirements.txt
ENV PATH="/opt/odoo/venv/bin:$PATH"
CMD ["odoo", "-c", "/etc/odoo/odoo.conf"]
```  

### 4. `docker-compose.yml` (root)
```yaml
version: "3.9"
services:
  db:
    image: postgres:15-alpine
    platform: linux/arm64
    env_file: .env
    volumes:
      - db_data:/var/lib/postgresql/data
    restart: unless-stopped

  web:
    build:
      context: .
      dockerfile: Dockerfile
      platform: linux/arm64
    depends_on:
      - db
    ports:
      - "8069:8069"
    env_file: .env
    volumes:
      - ./addons:/opt/odoo/addons
      - ./config/odoo.conf:/etc/odoo/odoo.conf:ro
    restart: unless-stopped

  nginx:
    image: nginx:alpine
    platform: linux/arm64
    depends_on:
      - web
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./config/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./certs:/etc/letsencrypt:ro
    restart: unless-stopped

  cadvisor:
    image: gcr.io/cadvisor/cadvisor:latest
    platform: linux/arm64
    ports:
      - "8080:8080"
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
    restart: unless-stopped

volumes:
  db_data:
```

### 5. `config/odoo.conf` Example
```ini
[options]
; Database connection
db_host = db
db_port = 5432
db_user = ${POSTGRES_USER}
db_password = ${POSTGRES_PASSWORD}
db_name = ${POSTGRES_DB}

; HTTP server
xmlrpc_interface = 0.0.0.0
xmlrpc_port = 8069

; Addons paths
addons_path = /opt/odoo/addons,/opt/odoo/odoo/addons

; Admin password
admin_passwd = ${ODOO_ADMIN_PASS}

dbfilter = .*

; Logging
log_level = info
log_handler = :INFO
; logfile = /var/log/odoo/odoo.log

; Resource limits
limit_memory_hard = 2684354560
limit_time_cpu = 60
limit_time_real = 120
```  

### 6. `config/nginx.conf` Example
```nginx
worker_processes auto;
events { worker_connections 1024; }
http {
    include mime.types;
    default_type application/octet-stream;
    sendfile on;
    keepalive_timeout 65;

    upstream odoo_upstream {
        server web:8069;
    }

    server {
        listen 80;
        server_name localhost;

        location / {
            proxy_pass http://odoo_upstream;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        location /longpolling {
            proxy_pass http://odoo_upstream;
        }

        location ~* /web/static/ {
            proxy_cache_valid 200 60m;
            proxy_buffering on;
            expires 864000;
            proxy_pass http://odoo_upstream;
        }

        client_max_body_size 100m;
    }
}
```  

### 7. Quick Start Commands
```bash
cd odoo18-fork
docker compose up -d --build
docker compose logs -f web
# Access Odoo: http://localhost:8069
```  

> **Updated:** Added **cAdvisor** service under `services:` in `docker-compose.yml` for lightweight container metrics (exposes UI at port 8080).
