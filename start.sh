#!/bin/bash

/usr/bin/supervisord -c /etc/supervisord.conf

if [ ! -f /home/moodle/readme.txt ]; then
    # /usr/bin/mysqld_safe &
    sleep 10s
    # Here we generate random passwords (thank you pwgen!). The first two are for mysql users, the last batch for random keys in wp-config.php
    ROOT_PASSWORD="root" # `pwgen -c -n -1 12`
    MYSQL_ROOT_PASSWORD="root"
    MYSQL_MOODLE_PASSWORD="moodle"
    MOODLE_PASSWORD="moodle"
    echo "moodle:$MOODLE_PASSWORD" | chpasswd
    echo "root:$ROOT_PASSWORD" | chpasswd

    mysql -uroot < /usr/share/phpmyadmin/sql/create_tables.sql
    mysql -uroot -e "GRANT ALL PRIVILEGES ON phpmyadmin.* TO 'pma'@'%' IDENTIFIED BY 'pmapass' WITH GRANT OPTION;"
    mysql -uroot -e "CREATE DATABASE moodle; GRANT ALL PRIVILEGES ON moodle.* TO 'moodle'@'%' IDENTIFIED BY '$MYSQL_MOODLE_PASSWORD'"
    mysql -uroot -e "UPDATE mysql.user SET plugin='mysql_native_password' WHERE User='root';GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD' WITH GRANT OPTION;FLUSH PRIVILEGES;"
    mysqladmin -u root password $MYSQL_ROOT_PASSWORD
fi

if [ ! -f /home/moodle/readme.txt ]; then
    CONTAINER_IP=`networkctl status | awk '/Address/ {print $2}'`
    echo -e "Services Addr\t: http://$CONTAINER_IP:9011" >> /home/moodle/readme.txt
    echo -e "Web Address\t: https://$CONTAINER_IP" >> /home/moodle/readme.txt
    echo -e "Web Directory\t: /home/moodle/files/html" >> /home/moodle/readme.txt
    echo -e "SSH/SFTP\t: moodle/moodle" >> /home/moodle/readme.txt
    echo -e "ROOT User\t: root/root" >> /home/moodle/readme.txt
    echo -e "Database Name\t: moodle" >> /home/moodle/readme.txt
    echo -e "Database User\t: moodle/moodle" >> /home/moodle/readme.txt
    echo -e "DB ROOT User\t: root/root" >> /home/moodle/readme.txt
    echo -e "phpMyAdmin\t: http://$CONTAINER_IP/phpmyadmin" >> /home/moodle/readme.txt
fi

cat /home/moodle/readme.txt
/usr/sbin/sshd -De