# ==========================================
# Stage 1: Build Frontend Assets with Node 22
# ==========================================
FROM node:22-alpine AS frontend
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm install
COPY resources ./resources
COPY public ./public
COPY vite.config.js ./
RUN npm run build

# ==========================================
# Stage 2: Install Composer Dependencies
# ==========================================
FROM composer:2 AS composer-builder
WORKDIR /app
COPY composer.json composer.lock ./
RUN composer install --no-dev --no-interaction --prefer-dist --no-scripts --no-autoloader
COPY . .
RUN composer dump-autoload --optimize --no-dev

# ==========================================
# Stage 3: Production Runtime
# ==========================================
FROM php:8.2-fpm-alpine AS production

# Install System Packages & PHP Extension Build Dependencies
RUN apk add --no-cache \
    nginx \
    supervisor \
    curl \
    bash \
    ca-certificates \
    tzdata \
    libpng-dev \
    libxml2-dev \
    oniguruma-dev \
    libzip-dev \
    curl-dev \
    && docker-php-ext-install -j$(nproc) \
    pdo_mysql \
    mbstring \
    exif \
    pcntl \
    bcmath \
    xml \
    zip \
    && rm -rf /var/cache/apk/*

# Setup AWS RDS CA Certificate Bundle for secure database transport
RUN mkdir -p /var/www/html/storage/certs \
    && curl -sS https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem -o /var/www/html/storage/certs/rds-ca-bundle.pem

WORKDIR /var/www/html

# Copy application and production vendor dependencies
COPY --from=composer-builder /app /var/www/html

# Copy compiled frontend assets from Stage 1
COPY --from=frontend /app/public/build /var/www/html/public/build

# Copy Nginx and Supervisor configuration
COPY docker/nginx.conf /etc/nginx/http.d/default.conf
COPY docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh \
    && chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache \
    && chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
