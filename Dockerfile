FROM php:7.2-fpm

COPY docker-entry.sh /
RUN chmod +x /docker-entry.sh

# Set working directory
WORKDIR /var/www

RUN rm -rf /var/www/var

# Install PHP dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libpng-dev \
    libpq-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    locales \
    zip \
    jpegoptim optipng pngquant gifsicle \
    vim \
    unzip \
    git \
    git \
    curl \
    nginx


# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Install extensions
RUN docker-php-ext-install pdo_mysql pdo_pgsql mbstring zip exif pcntl
RUN docker-php-ext-configure gd --with-gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ --with-png-dir=/usr/include/
RUN docker-php-ext-install gd

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Copy composer.lock and composer.json
COPY ./composer.lock ./composer.json /var/www/
RUN if [ ${APP_ENV} = "prod" ] ; then composer install --no-dev --no-interaction -o ; else composer install --no-interaction -o ; fi

# Install JS dependencies
COPY ./package.json ./yarn.lock ./webpack.config.js /var/www/
COPY assets /var/www/assets
RUN curl -sL https://deb.nodesource.com/setup_12.x | bash -
RUN apt-get update && apt-get install -y nodejs

RUN npm install npm@latest -g
RUN npm install yarn@latest -g
RUN nodejs -v
RUN npm -v
RUN yarn install --production=false
RUN yarn encore production --verbose
# RUN npm install --verbose 
# RUN npm run build --production --verbose


# Copy Symfony application directories
COPY ./bin/ /var/www/bin/
COPY ./config/  /var/www/config/
COPY ./public/  /var/www/public/
COPY ./src/  /var/www/src/
COPY ./templates/  /var/www/templates/
COPY ./translations/ /var/www/translations/
RUN ls /var/www/

# Copy server configuration files
COPY ./nginx.conf /etc/nginx/conf.d/app.conf
RUN ls /etc/nginx/conf.d

COPY ./php.ini /usr/local/etc/php/conf.d/local.ini
RUN ls /usr/local/etc/php/conf.d
RUN cat /usr/local/etc/php/conf.d/local.ini

RUN rm -rf /etc/nginx/sites-enabled
RUN mkdir -p /etc/nginx/sites-enabled

RUN chmod -R 777 /var/www/public
#RUN php bin/console cache:clear


# Expose port 80 and start php-fpm server
EXPOSE 80
CMD ["/docker-entry.sh"]
