#!/bin/sh
set -e

# Cache configuration if .env or APP_KEY is provided
if [ -f /var/www/html/.env ] || [ -n "$APP_KEY" ]; then
    php /var/www/html/artisan config:cache || true
    php /var/www/html/artisan route:cache || true
    php /var/www/html/artisan view:cache || true
fi

exec "$@"
