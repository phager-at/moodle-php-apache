#!/usr/bin/env bash

set -e

echo "Installing apt depdencies"

BUILD_PACKAGES="gettext libcurl4-openssl-dev libpq-dev default-libmysqlclient-dev libldap2-dev libxslt-dev \
    libxml2-dev libicu-dev libfreetype6-dev libjpeg62-turbo-dev libmemcached-dev \
    zlib1g-dev libpng12-dev unixodbc-dev"

LIBS="locales libaio1 libcurl3 libgss3 libicu52 libmysqlclient18 libpq5 libmemcached11 libmemcachedutil2 libldap-2.4-2 libxml2 libxslt1.1 unixodbc libmcrypt-dev"

apt-get update
apt-get install -y --no-install-recommends $BUILD_PACKAGES $LIBS unzip ghostscript locales apt-transport-https
echo 'Generating locales..'
echo 'en_US.UTF-8 UTF-8' > /etc/locale.gen
echo 'en_AU.UTF-8 UTF-8' >> /etc/locale.gen
locale-gen

echo "Installing php extensions"
docker-php-ext-install -j$(nproc) \
    intl \
    mysqli \
    opcache \
    pgsql \
    soap \
    xsl \
    xmlrpc \
    zip

docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/
docker-php-ext-install -j$(nproc) gd

docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/
docker-php-ext-install -j$(nproc) ldap

pecl install solr memcached redis apcu igbinary
docker-php-ext-enable solr memcached redis apcu igbinary

echo 'apc.enable_cli = On' >> /usr/local/etc/php/conf.d/docker-php-ext-apcu.ini

# Install Microsoft depdencises for sqlsrv
curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
curl https://packages.microsoft.com/config/debian/8/prod.list -o /etc/apt/sources.list.d/mssql-release.list
apt-get update
ACCEPT_EULA=Y apt-get install -y msodbcsql

pecl install sqlsrv-4.3.0
docker-php-ext-enable sqlsrv

# Keep our image size down..
pecl clear-cache
apt-get remove --purge -y $BUILD_PACKAGES
apt-get autoremove -y
apt-get clean
rm -rf /var/lib/apt/lists/*
