FROM alpine
RUN apk add supervisor curl bash wget php8
RUN apk add $(apk list |cut -d"-" -f1-2|grep php8-[a-z]|grep -v -e pec -e dbg)
RUN apk add mariadb mariadb-client
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
COPY installers /
COPY run-dropbear.sh /usr/local/bin/run.sh
#EXPOSE 80
EXPOSE 443
