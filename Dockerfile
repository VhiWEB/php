#
# BASE
#
FROM php:8.1-fpm as base

# ENV PATH
ENV php_conf /usr/local/etc/php-fpm.conf
ENV fpm_conf /usr/local/etc/php-fpm.d/www.conf
ENV php_vars /usr/local/etc/php/conf.d/docker-vars.ini

RUN apt-get update && apt-get install -yq gpg \
    && curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
    && curl https://packages.microsoft.com/config/ubuntu/22.04/prod.list > /etc/apt/sources.list.d/mssql-release.list

RUN apt-get update && ACCEPT_EULA=Y apt-get install -yq \
  nginx cron git-core jq gpg unixodbc-dev msodbcsql18 \
  supervisor unzip vim zip pkg-config \
  libpq-dev libsqlite3-dev libzip-dev libcurl4-openssl-dev libssl-dev libicu-dev \
  libjpeg-dev libpng-dev libwebp-dev libjpeg62-turbo-dev libfreetype6-dev \
  && rm -rf /var/lib/apt/lists/* \
  && pecl install redis \
  && pecl install mongodb \
  && pecl install sqlsrv \
  && pecl install pdo_sqlsrv \
  && docker-php-ext-configure gd --with-jpeg=/usr/include/ --with-freetype=/usr/include/ --with-webp=/usr/include/ \
  && docker-php-ext-enable redis \
  && docker-php-ext-enable mongodb \
  && docker-php-ext-enable sqlsrv pdo_sqlsrv \
  && docker-php-ext-install exif gd mysqli opcache zip pcntl fileinfo gettext iconv intl


RUN { \
  echo 'opcache.memory_consumption=512'; \
  echo 'opcache.interned_strings_buffer=8'; \
  echo 'opcache.max_accelerated_files=4000'; \
  echo 'opcache.revalidate_freq=2'; \
  echo 'opcache.fast_shutdown=1'; \
  echo 'opcache.enable_cli=1'; \
  } > /usr/local/etc/php/conf.d/docker-oc-opcache.ini

RUN { \
  echo 'log_errors=on'; \
  echo 'display_errors=off'; \
  echo 'upload_max_filesize=128M'; \
  echo 'post_max_size=128M'; \
  echo 'memory_limit=512M'; \
  echo 'expose_php=Off'; \
  echo 'max_execution_time=300'; \
  echo 'set_time_limit=60'; \
  } > /usr/local/etc/php/conf.d/docker-oc-php.ini

RUN sed -i \
  -e "s/pm.max_children = 5/pm.max_children = 50/g" \
  -e "s/pm.start_servers = 2/pm.start_servers = 5/g" \
  -e "s/pm.min_spare_servers = 1/pm.min_spare_servers = 5/g" \
  -e "s/pm.max_spare_servers = 3/pm.max_spare_servers = 50/g" \
  -e "s/;pm.max_requests = 500/pm.max_requests = 256/g" \
  -e "s/;request_terminate_timeout = 0/request_terminate_timeout = 300/g" \
  ${fpm_conf}

# COPY SERVER CONFIGURATION
COPY ./docker-config/nginx/nginx-site.conf /etc/nginx/sites-enabled/default
COPY ./docker-config/nginx/nginx.conf /etc/nginx/nginx.conf