### default

```bash
server {
    #proxy_cache cache;
        #proxy_cache_valid 200 1s;
    listen 8080;
    listen [::]:8080;
    root /home/site/wwwroot/public;
    index  index.php index.html index.htm;
    server_name  example.com www.example.com;
    port_in_redirect off;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }

    if ($http_x_arr_ssl = "") {
      return 301 https://$host$request_uri;
    }
    # redirect server error pages to the static page /50x.html
    #
    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /html/;
    }

    # Disable .git directory
    location ~ /\.git {
        deny all;
        access_log off;
        log_not_found off;
    }

    # Add locations of phpmyadmin here.
    location ~* [^/]\.php(/|$) {
        fastcgi_split_path_info ^(.+?\.[Pp][Hh][Pp])(|/.*)$;
        fastcgi_pass 127.0.0.1:9000;
        include fastcgi_params;
        fastcgi_param HTTP_PROXY "";
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
        fastcgi_param QUERY_STRING $query_string;
        fastcgi_intercept_errors on;
        fastcgi_connect_timeout         300;
        fastcgi_send_timeout           3600;
        fastcgi_read_timeout           3600;
        fastcgi_buffer_size 128k;
        fastcgi_buffers 4 256k;
        fastcgi_busy_buffers_size 256k;
        fastcgi_temp_file_write_size 256k;
    }
}
```

### laravel-worker.conf
```bash
process_name=%(program_name)s_%(process_num)02d
command=php /home/site/wwwroot/artisan queue:work --sleep=3 --tries=3 --max-time=3600
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
user=forge
numprocs=1
redirect_stderr=true
stdout_logfile=/home/site/wwwroot/storage/logs/worker.log
stopwaitsecs=3600
```

### php.ini
```bash
error_log=/dev/stderr
display_errors=Off
log_errors=On
display_startup_errors=Off
date.timezone=Asia/Dubai
memory_limit=256M
```

### startup.sh
```bash
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

# restart nginx
service nginx restart
service supervisor restart

# Install Composer 
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php composer-setup.php --install-dir=/usr/local/bin --filename=composer
php -r "unlink('composer-setup.php');"

COMPOSER_ALLOW_SUPERUSER=1  
composer install --prefer-dist --no-ansi --no-interaction --no-progress --no-scripts -d /home/site/wwwroot

php /home/site/wwwroot/artisan down --refresh=15 --secret="1630542a-246b-4b66-afa1-dd72a4c43515"

php /home/site/wwwroot/artisan migrate --force
php /home/site/wwwroot/artisan db:seed --force

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

# Generate API doc
php /home/site/wwwroot/artisan l5-swagger:generate

# Turn off maintenance mode
php /home/site/wwwroot/artisan up
```
