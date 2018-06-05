FROM alpine:edge
RUN echo '@testing http://nl.alpinelinux.org/alpine/edge/testing' >> /etc/apk/repositories && \
    # Install common packages
    apk add --no-cache \
        bash \
        nano \
        grep \
        sed \
        curl \
        wget \
        tar \
        gzip \
        pcre \
        nginx \
        ca-certificates \
        && \
    # Add PHP actions
    # cd /tmp && \
    # git clone https://github.com/Wodby/php-actions-alpine.git && \
    # cd php-actions-alpine && \
    # git checkout $PHP_ACTIONS_VER && \
    # rsync -av rootfs/ / && \
    # Install PHP extensions
    apk add --no-cache \
        php7@testing \
        php7-fpm@testing \
        php7-opcache@testing \
        php7-xml@testing \
        php7-ctype@testing \
        php7-gd@testing \
        php7-json@testing \
        php7-posix@testing \
        php7-curl@testing \
        php7-dom@testing \
        php7-sockets@testing \
        php7-zlib@testing \
        php7.0-mcrypt@testing \
        php7-mysqli@testing \
        php7-bz2@testing \
        php7-phar@testing \
        php7-openssl@testing \
        php7-zip@testing \
        php7-soap@testing \
        php7-dev@testing \
        php7-pear@testing \
        php7-mbstring@testing \
        php7-memcached@testing \
        php7-exif@testing \
        && \
    # Create symlinks PHP -> PHP7
    ln -sf /usr/bin/php7 /usr/bin/php && \
    ln -sf /usr/sbin/php-fpm7 /usr/bin/php-fpm && \
    # Configure php log dir
    rm -rf /var/log/php7 && \
    mkdir /var/log/php && \
    touch /var/log/php/error.log && \
    touch /var/log/php/fpm-error.log && \
    touch /var/log/php/fpm-slow.log && \
    # Final cleanup
    rm -rf /var/cache/apk/* /tmp/* /usr/share/man
# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

ENV WORDPRESS_VERSION 4.5.3
ENV WORDPRESS_SHA1 835b68748dae5a9d31c059313cd0150f03a49269

# upstream tarballs include ./wordpress/ so this gives us /srv/wordpress
RUN curl -o wordpress.tar.gz -SL https://wordpress.org/wordpress-${WORDPRESS_VERSION}.tar.gz \
    && echo "$WORDPRESS_SHA1 *wordpress.tar.gz" | sha1sum -c - \
    && mkdir -p /srv/ \
    && tar -xzvf wordpress.tar.gz -C /srv/ \
    && rm wordpress.tar.gz
# download New Relic php agent
RUN curl -o newrelic-php5-6.tar.gz -SL https://download.newrelic.com/php_agent/release/newrelic-php5-6.5.0.166-linux-musl.tar.gz \
    && tar -xzvf newrelic-php5-6.tar.gz -C /tmp/ \
    && rm newrelic-php5-6.tar.gz
COPY docker-entrypoint.sh /entrypoint.sh
COPY wp-content /srv/wordpress/wp-content
COPY plugins /srv/wordpress/wp-content/plugins
COPY themes /srv/wordpress/wp-content/themes
COPY languages /srv/wordpress/wp-content/languages
COPY config/wp-config.php /srv/wordpress/wp-config.php
COPY config/memlimit.ini /etc/php7/conf.d/memlimit.ini
COPY config/opcache-recommended.ini /etc/php7/conf.d/opcache-recommended.ini
COPY pages/blog-suspended.php /srv/wordpress/wp-content/blog-suspended.php
COPY import /srv/wordpress/wp-content/import
COPY plugins/wordpress-mu-domain-mapping/sunrise.php /srv/wordpress/wp-content/sunrise.php
COPY config/php7-fpm.conf /etc/php7/php-fpm.d/www.conf
COPY config/nginx-example_realip.conf /etc/nginx/conf.d/example_realip.conf
COPY config/nginx-example_ssl.conf /etc/nginx/conf.d/example_ssl.conf
COPY config/nginx-nginx.conf /etc/nginx/nginx.conf
COPY config/nginx-wordpress.conf /etc/nginx/sites-enabled/wordpress.conf
RUN chmod -R a-w /srv/wordpress && chmod a+rx /entrypoint.sh && chmod u+w /srv/wordpress/wp-content \
    && (addgroup -g 82 -S www-data || /bin/true) \
    && (adduser -u 82 -S -D -G www-data www-data || /bin/true) \
    && mkdir -p /var/log/php7 /var/log/nginx/wordpress /run/nginx
EXPOSE 9000 80 443
VOLUME /srv/wordpress
WORKDIR /srv/wordpress
# grr, ENTRYPOINT resets CMD now
ENTRYPOINT ["/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
