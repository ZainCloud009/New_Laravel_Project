#!/bin/sh
set -e

# Clear stale caches and rebuild fresh caches on container startup
if [ -f /var/www/html/.env ] || [ -n "$APP_KEY" ]; then
    php /var/www/html/artisan config:clear || true
    php /var/www/html/artisan route:clear || true
    php /var/www/html/artisan view:clear || true
    php /var/www/html/artisan cache:clear || true
    php /var/www/html/artisan config:cache || true
    php /var/www/html/artisan route:cache || true
    php /var/www/html/artisan view:cache || true
fi

exec "$@"
