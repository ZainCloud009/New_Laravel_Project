#!/bin/sh
set -e

# Clear stale caches, run migrations, and rebuild fresh caches on container startup
if [ -f /var/www/html/.env ] || [ -n "$APP_KEY" ]; then
    echo "⚡ Running database migrations..."
    php /var/www/html/artisan migrate --force || true

    echo "⚡ Optimizing configuration and route cache..."
    php /var/www/html/artisan config:clear || true
    php /var/www/html/artisan route:clear || true
    php /var/www/html/artisan view:clear || true
    php /var/www/html/artisan cache:clear || true
    php /var/www/html/artisan config:cache || true
    php /var/www/html/artisan route:cache || true
    php /var/www/html/artisan view:cache || true
fi

exec "$@"
