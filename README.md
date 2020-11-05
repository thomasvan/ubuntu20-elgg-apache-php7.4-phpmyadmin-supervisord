# Run the latest MAMP on Ubuntu 20, includes

-   apache version: Apache/2.4.x
-   php-fpm 7.4.x
-   mysql version 8.x
-   phpMyAdmin latest version
-   composer latest version
-   You can also handle all services using supervisord 4. <container_ip>:9011 or commandline:

```bash
webuser@c9786d14b245:~/files/htmlsudo supervisorctl
Apache2                          RUNNING   pid 13, uptime 0:57:02
Cron                             RUNNING   pid 15, uptime 0:57:02
MySQL                            RUNNING   pid 12, uptime 0:57:02
PHP-FPM                          RUNNING   pid 11, uptime 0:57:02
System-Log                       RUNNING   pid 16, uptime 0:57:02
```

---

## Usage

Services and ports exposed

-   MySQL - <container_ip>:3306
-   phpMyAdmin - http://<container_ip>/phpmyadmin
-   Apache and php-fpm 7.4.x - http://<container_ip> and https://<container_ip> for web browsing

### Sample container initialization

```bash
docker build -t elgg:latest \
  --build-arg USER_ID=$(id -u) \
  --build-arg GROUP_ID=$(id -g) .

docker run -d \
  --mount "type=bind,src=$(pwd)/shared,dst=/opt/shared" \
  -p 9011:9011 \
  -p 8080:80 \
  elgg:latest

docker run -it --rm \
  --mount "type=bind,src=$(pwd)/shared,dst=/opt/shared" \
  --workdir /opt/shared \
  elgg:latest bash -c "su - webuser"
docker run -v <your-webapp-root-directory>:/home/webuser/files/html -p 9022:9011 -p 8080:80 -d se:latest
```

---

After starting the container ubuntu20-elgg-apache-php7.4-phpmyadmin-supervisord, please check to see if it has started and the port mapping is correct. This will also report the port mapping between the docker container and the host machine.

### Accessing containers by port mapping

```bash
docker ps

0.0.0.0:9011->9022/tcp
```

---

You can start/stop/restart and view the error logs of apache and php-fpm services: `http://127.0.0.1:9022`

### Accessing containers by internal IP

_For Windows 10, you need to [add route: route add 172.17.0.0 MASK 255.255.0.0 10.0.75.2](https://forums.docker.com/t/connecting-to-containers-ip-address/18817/13) manually before using one of the following ways to get internal IP:_

-   Looking into the output of `docker logs <container-id>`:
-   Using [docker inspect](https://docs.docker.com/engine/reference/commandline/inspect/parent-command) command

---

```bash
c9786d14b245 login: webuser
Password:
Welcome to Ubuntu 18.04.1 LTS ...

webuser@c9786d14b245:~cat ~/readme.txt
Services Addr   : http://172.17.0.2:9011
Web Address     : https://172.17.0.2
Web Directory   : /home/webuser/files/html
SSH/SFTP        : webuser/123456
ROOT SSH User   : root/root
Database Name   : default
Database User   : default/secret
DB ROOT User    : root/root
phpMyAdmin      : http://172.17.0.2/phpmyadmin
```

---

_Now as you've got all that information, you can set up webuser and access the website via IP Address or creating an [alias in hosts](https://support.rackspace.com/how-to/modify-your-hosts-file/) file_

```bash
c9786d14b245 login: webuser
Password:
Welcome to Ubuntu 18.04.1 LTS ...

webuser@c9786d14b245:~cd files/html/
webuser@c9786d14b245:~/files/htmlecho "install webuser here..."
install webuser here...
webuser@c9786d14b245:~/files/htmlecho "all set, you can browse your website now"
all set, you can browse your website now
webuser@c9786d14b245:~/files/html$
```

---

_If anyone has suggestions please leave a comment on [this GitHub issue](https://github.com/thomasvagon/ubuntu20-elgg-apache-php7.4-phpmyadmin-supervisord/issues/2)._

_Requests? Just make a comment on [this GitHub issue](https://github.com/thomasvan/ubuntu20-elgg-apache-php7.4-phpmyadmin-supervisord/issues/1) if there's anything you'd like added or changed._
