#!/bin/bash

# start all the services

if [ ! -f /container-info.txt ]; then
    /usr/sbin/mysqld --basedir=/usr --datadir=/var/lib/mysql --plugin-dir=/usr/lib/mysql/plugin --user=mysql --log-error=/var/log/mysql/error.log --pid-file=/var/run/mysqld/mysqld.pid --socket=/var/run/mysqld/mysqld.sock --port=3306 &
    sleep 10s

    mysql -uroot -e "create database $DB_NAME"
    mysql -uroot -e "CREATE USER $DB_USER@localhost IDENTIFIED WITH mysql_native_password BY '$DB_PASSWORD';"
    mysql -uroot -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@localhost;"
    # 
    mysql -uroot < /usr/share/phpmyadmin/sql/create_tables.sql
    mysql -uroot -e "CREATE USER pmaS3Cret@localhost IDENTIFIED WITH mysql_native_password BY 'pmapassS3Cret';"
    mysql -uroot -e "GRANT ALL PRIVILEGES ON phpmyadmin.* TO pmaS3Cret@localhost;"
    killall mysqld

    # echo "webuser:$WEBUSER_PASSWORD" | chpasswd

    echo -e "Web Directory\t: /home/webuser/files" >> /container-info.txt
    echo -e "SSH/SFTP\t: $WEB_USER/$WEB_PASSWORD" >> /container-info.txt
    echo -e "Database Name\t: $DB_NAME" >> /container-info.txt
    echo -e "Database User\t: $DB_USER/$DB_PASSWORD" >> /container-info.txt
    echo -e "phpMyAdmin\t: /phpmyadmin" >> /container-info.txt
fi

#This is so the passwords show up in logs.
cat /container-info.txt
/usr/bin/supervisord -n -c /etc/supervisord.conf
# tail -f /dev/null