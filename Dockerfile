FROM alpine
RUN apk add supervisor curl bash wget mariadb mariadb-client sed dropbear shadow msmtp git redis memcached openssl nginx coreutils openssh-sftp-server grep
RUN ln -s /bin/true /sbin/service || true &&  mkdir /etc/php && mkdir /var/log/supervisor
RUN mkdir -p /etc/redis && ln -s /etc/redis.conf /etc/redis/
RUN touch /root/.bashrc
RUN addgroup memcache && ((echo ;echo ;echo;echo;echo;echo;echo;echo;echo;echo;echo;echo;echo) |adduser -G memcache -D -h /var/www -s /bin/bash memcache )
RUN usermod -s /bin/bash root && addgroup crontabs
RUN test -e /usr/libexec/sftp-server || (test -e /usr/lib/ssh/sftp-server && mkdir -p /usr/libexec/ && ln -s /usr/lib/ssh/sftp-server /usr/libexec/sftp-server) || true
#RUN test -e /usr/libexec/sftp-server || (test -e /usr/lib/sftp-server && mkdir -p /usr/libexec/ && ln -s /usr/lib/sftp-server /usr/libexec/sftp-server) || true
RUN mkdir /var/spool/crontabs
RUN touch /var/spool/crontabs/www-data
RUN ln -sf /etc/supervisor/supervisord.conf /etc/supervisord.conf

ENV MUSL_LOCALE_DEPS cmake make musl-dev gcc gettext-dev libintl
ENV MUSL_LOCPATH /usr/share/i18n/locales/musl
RUN apk add --no-cache \
    $MUSL_LOCALE_DEPS
RUN apk add --no-cache \
    $MUSL_LOCALE_DEPS \
    && wget https://gitlab.com/rilian-la-te/musl-locales/-/archive/master/musl-locales-master.zip \
    && unzip musl-locales-master.zip \
      && cd musl-locales-master \
      && cmake -DLOCALE_PROFILE=OFF -D CMAKE_INSTALL_PREFIX:PATH=/usr . && make && make install \
      && cd .. && rm -r musl-locales-master 

RUN apk add php8

RUN apk add $(apk list |cut -d"-" -f1-2|grep php8-[a-z]|grep -v -e pec -e dbg)
RUN apk add php8-pecl-imagick php8-pecl-uuid php8-pecl-event php8-pecl-apcu php8-pecl-redis php8-pecl-zstd php8-pecl-igbinary php8-pecl-ssh2 php8-pecl-mongodb php8-pecl-oauth php8-pecl-memcached php8-pecl-memcache 

RUN apk add --no-cache --no-progress --virtual BUILD_DEPS_PHP_GNUPG gpgme-dev \
    && apk add --no-cache --no-progress gpgme \
    && pecl install gnupg 
RUN /bin/bash -c  "echo extension=gnupg >> /etc/php8/conf.d/docker-php-ext-gnupg.ini"
RUN mkdir -p /etc/php/8.0/
RUN ln -s /etc/php8 /etc/php/8.0/fpm
RUN ln -s /etc/php8/php-fpm.d/ /etc/php/8.0/fpm/pool.d

RUN apk add nano lftp openssh-client
RUn sed 's~^\[mysqld\]~[mysqld]\ndata=/var/lib/mysql~g' -i /etc/my.cnf.d/* 

RUN (delgroup www-data || true ) && deluser xfs ||true 
RUN cat /etc/group|grep ":33:" && delgroup $(cat /etc/group|grep ":33:"|cut -d":" -f1) || true 
RUN addgroup -g 33 www-data
RUN mkdir /var/www || true 
RUN (echo ;echo ;echo;echo;echo;echo;echo;echo;echo;echo;echo;echo;echo) |adduser -G www-data -D -h /var/www -s /bin/bash -u 33  www-data

#RUN mkdir -p /etc/php/8.0/fpm/pool.d/
#RUN ln -s /etc/php8/conf.d/ /etc/php/8.0/fpm/

#RUN ln -s  /etc/php8/php-fpm.d/ /etc/php/8.0/fpm/pool.d/
COPY docker-apt-proxy.sh /root/.bin/
##COPY docker-prepare.sh /root/.bin/docker-install.sh
COPY pool-www.conf /root/www.conf
COPY msmtp-cron-sendmail/sendmail /usr/sbin/sendmail.cron
COPY supervisord.conf /etc/supervisor/supervisord.conf
#COPY docker-install.sh /root/.bin/
COPY 000-default.conf default-ssl.conf /etc/apache2/sites-available/
COPY 000-default.conf default-ssl.conf /etc/apache2/sites-enabled/
COPY 000-default.conf default-ssl.conf /etc/apache2/sites-available.default/
COPY healthcheck.sh shutdown.sh supervisor-logger run-apache.sh restart-websockets.sh run-websockets.sh run-fpm.sh run_supervised_artisan_queue.sh _0_crt-snakeoil.sh  _0_fix-composer.sh  _0_fix-dropbear.sh  _0_get-toolkit.sh  _0_sys-mailprep.sh _2_supervisor_prep.sh _1_php-initprep.sh _1_php-initfirst.sh _1_php-initfpm.sh _1_sql-initprep.sh  _1_sys-mongopre.sh  _1_www-userprep.sh _3_logfilter_web.sh /

#COPY x-finalcommands.sh /root/.x_finalcmd.sh
RUN ln -s /usr/bin/php81 /usr/bin/php || true
COPY installers /
COPY run-dropbear.sh /usr/local/bin/run.sh
RUN mv /etc/nginx/http.d /etc/nginx/conf.d && ln -s  /etc/nginx/conf.d /etc/nginx/http.d 
RUN rm -rf /etc/mysql || true && ln -sf /etc/my.cnf /etc/mysql
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 22 80 443
RUN chmod +x /supervisor-logger
RUN rm -rf /var/www/logs /var/www/run/ /var/www/modules

VOLUME /var/lib/mysql
VOLUME /var/www
VOLUME /var/lib/redis
VOLUME /var/lib/memcached

WORKDIR /var/www
HEALTHCHECK --interval=180s --timeout=25s CMD /bin/bash /healthcheck.sh

CMD ["/bin/bash","/usr/local/bin/run.sh"]
MAINTAINER commits@hideaddress.net