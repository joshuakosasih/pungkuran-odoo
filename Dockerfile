FROM python:3.11-slim
# System deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential libpq-dev git wget xfonts-75dpi xfonts-base \
  && rm -rf /var/lib/apt/lists/*
# wkhtmltopdf for PDFs
RUN wget https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox_0.12.6-1.arm64.deb && \
    dpkg -i wkhtmltox_0.12.6-1.arm64.deb && rm wkhtmltox_0.12.6-1.arm64.deb
# App
WORKDIR /opt/odoo
COPY . .
RUN python3 -m venv venv && . venv/bin/activate && \
    pip install --upgrade pip wheel && pip install -r requirements.txt
ENV PATH="/opt/odoo/venv/bin:$PATH"
CMD ["odoo", "-c", "/etc/odoo/odoo.conf"]

