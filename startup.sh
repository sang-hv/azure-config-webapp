cp /home/default /etc/nginx/sites-enabled/default

cp /home/php.ini /usr/local/etc/php/conf.d/php.ini


# install support for webp file conversion
apt-get update --allow-releaseinfo-change && apt-get install -y libfreetype6-dev \
                libjpeg62-turbo-dev \
                libpng-dev \
                libwebp-dev \
        && docker-php-ext-configure gd --with-freetype --with-webp  --with-jpeg
docker-php-ext-install gd

# install support for queue
apt-get install -y supervisor 

cp /home/laravel-worker.conf /etc/supervisor/conf.d/laravel-worker.conf
cp /home/laravel-match_update-worker.conf /etc/supervisor/conf.d/laravel-match_update-worker.conf
# restart nginx
service nginx restart
service supervisor restart
service supervisor start

# Install Composer 
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php composer-setup.php --install-dir=/usr/local/bin --filename=composer
php -r "unlink('composer-setup.php');"

composer dump-autoload -d /home/site/wwwroot/ -n

php /home/site/wwwroot/artisan migrate --force
php /home/site/wwwroot/artisan db:seed --force

# Generate API doc
php /home/site/wwwroot/artisan l5-swagger:generate

# Clear caches
php /home/site/wwwroot/artisan cache:clear

# Clear expired password reset tokens
#php /home/site/wwwroot/artisan auth:clear-resets

# Clear and cache routes
php /home/site/wwwroot/artisan route:cache

# Clear and cache config
php /home/site/wwwroot/artisan config:cache

# Clear and cache views
php /home/site/wwwroot/artisan view:cache

# Install node modules
# npm ci --prefix /home/site/wwwroot

# npm run build --prefix /home/site/wwwroot

# Turn off maintenance mode
php /home/site/wwwroot/artisan up

# Install crontab 
apt-get update -qq && apt-get install cron -yqq
mkdir -p /home/LogFiles/cronjob
(crontab -l 2>/dev/null; echo "* * * * * . /etc/profile && /usr/local/bin/php /home/site/wwwroot/artisan schedule:run >> /home/LogFiles/cronjob/cronjobresult.log 2>&1")|crontab
service cron start
