FROM ubuntu:20.04
LABEL maintainer="thongminh@msn.com" description="Docker image with latest ubuntu softwares and wordpress multiple sites supported" version="20.01"

# Keep upstart from complaining
RUN dpkg-divert --local --rename --add /sbin/initctl
RUN ln -sf /bin/true /sbin/initctl
RUN mkdir /var/run/sshd 
RUN mkdir /run/php

ENV container docker
ENV LC_ALL C.UTF-8
# Let the conatiner know that there is no tty
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update
RUN apt-get -y upgrade

# Basic Requirements
RUN apt-get -y install pwgen curl git nano sudo unzip openssh-server openssl cron
RUN apt-get -y install mysql-server mysql-client apache2 php-fpm php-mysql
RUN mkdir /var/run/mysqld && chown mysql: /var/run/mysqld

# PHP Requirements
RUN apt-get -y install php-xml php-mbstring php-bcmath php-zip php-pdo-mysql php-curl \
    php-gd php-intl php-pear php-imagick php-imap php-memcache php-apcu php-pspell php-tidy php-xmlrpc

# mysql config
RUN sed -i -e"s/^bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf

# apache config
COPY conf/serve-web-dir.conf /tmp/
RUN sed -i 's/<\/VirtualHost>/\tAlias \/phpmyadmin "\/usr\/share\/phpmyadmin\/"\n\t<FilesMatch \\.php$>\n\t\tSetHandler "proxy:unix:\/var\/run\/php\/php7.4-fpm.sock|fcgi:\/\/localhost\/"\n\t<\/FilesMatch>\n<\/VirtualHost>/g' /etc/apache2/sites-available/000-default.conf
RUN sed -i 's/<\/VirtualHost>/\tAlias \/phpmyadmin "\/usr\/share\/phpmyadmin\/"\n\t\t<FilesMatch \\.php$>\n\t\t\tSetHandler "proxy:unix:\/var\/run\/php\/php7.4-fpm.sock|fcgi:\/\/localhost\/"\n\t\t<\/FilesMatch>\n\t<\/VirtualHost>/g' /etc/apache2/sites-available/default-ssl.conf && \
    sed -i 's/\/var\/www\/html/\/home\/webuser\/files\/html/g' /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/default-ssl.conf && \
    cat /tmp/serve-web-dir.conf >> /etc/apache2/apache2.conf && rm -f /tmp/serve-web-dir.conf  && \
    a2enmod actions proxy_fcgi alias setenvif && \
    a2enmod rewrite expires headers && \
    echo "ServerName localhost" | sudo tee /etc/apache2/conf-available/fqdn.conf && \
    a2enconf fqdn php7.4-fpm && \
    a2enmod ssl && \
    a2ensite default-ssl

# php-fpm config
RUN sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" /etc/php/7.4/fpm/php.ini
RUN sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" /etc/php/7.4/fpm/php.ini
RUN sed -i -e "s/memory_limit\s*=\s*128M/memory_limit = 2048M/g" /etc/php/7.4/fpm/php.ini
RUN sed -i -e "s/max_execution_time\s*=\s*30/max_execution_time = 3600/g" /etc/php/7.4/fpm/php.ini /etc/php/7.4/cli/php.ini
RUN sed -i -e "s/;\s*max_input_vars\s*=\s*1000/max_input_vars = 36000/g" /etc/php/7.4/fpm/php.ini /etc/php/7.4/cli/php.ini
RUN sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/7.4/fpm/php-fpm.conf
RUN sed -i -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" /etc/php/7.4/fpm/pool.d/www.conf
RUN sed -i -e "s/user\s*=\s*www-data/user = webuser/g" /etc/php/7.4/fpm/pool.d/www.conf

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Supervisor Config
RUN apt-get install -y supervisor && \
    rm -rf /var/lib/apt/lists/* && \
    apt clean
ADD ./conf/supervisord.conf /etc/supervisord.conf

ARG USER_ID
ARG GROUP_ID

# ENV settings
ENV DB_NAME="maindb"
# `pwgen -c -n -1 12`
ENV DB_USER="dbuser"
ENV DB_PASSWORD="DBsecret" 
ENV WEB_USER="webuser"
ENV WEB_PASSWORD="WEBsecret"

# Add system user for webuser
RUN addgroup --gid $GROUP_ID $WEB_USER || true

RUN useradd -m -d /home/$WEB_USER -p $WEB_PASSWORD --uid $USER_ID --gid $GROUP_ID -s /bin/bash $WEB_USER \
    && usermod -a -G www-data $WEB_USER \
    && usermod -a -G sudo $WEB_USER \
    && mkdir /home/webuser/.cache \
    && chown $WEB_USER: /home/webuser/.cache \
    && ln -s /opt/shared /home/$WEB_USER/files
RUN mkdir -p /opt/shared/html \
    && chown -R $WEB_USER: /opt/shared  \
    && chmod -R 775 /opt/shared 

# Generate private/public key for "webuser" user
RUN sudo -H -u $WEB_USER bash -c 'echo -e "\n\n\n" | ssh-keygen -t rsa'



# phpMyAdmin
RUN curl --location https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.tar.gz | tar xzf - && \
    mv phpMyAdmin* /usr/share/phpmyadmin
ADD ./conf/config.inc.php /usr/share/phpmyadmin/config.inc.php
ADD ./conf/config.inc.php /usr/share/phpmyadmin/config.inc.php
RUN chown -R $WEB_USER: /usr/share/phpmyadmin

# webuser cron and startup Script
COPY ./conf/default.cron /tmp/
# Initialization and Startup Script
ADD ./start.sh /start.sh

RUN crontab -u $WEB_USER /tmp/default.cron && \
    chmod 755 /start.sh && \
    chown mysql:mysql /var/run/mysqld

#NETWORK PORTS
# private expose
EXPOSE 9011
EXPOSE 3306
EXPOSE 80
EXPOSE 443
EXPOSE 22

# volume for mysql database and webuser install
VOLUME ["/var/lib/mysql", "/var/run/sshd", "/opt/shared"]
CMD ["/bin/bash", "/start.sh"]
