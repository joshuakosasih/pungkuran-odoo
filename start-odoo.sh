#!/bin/bash

# Expand environment variables in the config file
envsubst < /etc/odoo/odoo.conf.template > /etc/odoo/odoo.conf

# Start Odoo
exec odoo -c /etc/odoo/odoo.conf "$@" 