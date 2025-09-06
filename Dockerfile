FROM python:3.11-slim
# System deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential libpq-dev git wget xfonts-75dpi xfonts-base \
    libldap2-dev libsasl2-dev gettext-base \
  && ARCH=$(dpkg --print-architecture) \
  && if [ "$ARCH" = "amd64" ]; then \
       wget -O /tmp/wkhtmltox.deb https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-2/wkhtmltox_0.12.6.1-2.bullseye_amd64.deb; \
     elif [ "$ARCH" = "arm64" ]; then \
       wget -O /tmp/wkhtmltox.deb https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-2/wkhtmltox_0.12.6.1-2.bullseye_arm64.deb; \
     else \
       echo "Unsupported architecture: $ARCH" && exit 1; \
     fi \
  && dpkg -i /tmp/wkhtmltox.deb || apt-get install -f -y \
  && rm -rf /var/lib/apt/lists/* /tmp/wkhtmltox.deb
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

