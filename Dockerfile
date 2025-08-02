FROM python:3.11-slim
# System deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential libpq-dev git wget xfonts-75dpi xfonts-base \
    libldap2-dev libsasl2-dev gettext-base \
  && rm -rf /var/lib/apt/lists/*
# Note: wkhtmltopdf installation skipped due to compatibility issues with ARM64/Bookworm
# PDF generation will use alternative methods or can be installed later if needed
# App
WORKDIR /opt/odoo
COPY . .
RUN python3 -m venv venv && . venv/bin/activate && \
    pip install --upgrade pip wheel && pip install -r requirements.txt && \
    pip install -e .
ENV PATH="/opt/odoo/venv/bin:$PATH"

# Copy and make startup script executable
COPY start-odoo.sh /opt/odoo/start-odoo.sh
RUN chmod +x /opt/odoo/start-odoo.sh

# Use startup script that expands environment variables
CMD ["/opt/odoo/start-odoo.sh"]

