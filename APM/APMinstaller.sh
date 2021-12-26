#!/bin/bash
 
#####################################################################################
#                                                                                   #
# * APMinstaller v.1 with ROCKY8                                                    #
# * ROCKY-8.5-x86_64                                                                #
# * Apache 2.4.X , MariaDB 10.6.X, PHP 7.4 setup shell script                       #
# * Created Date    : 2021/12/25                                                    #
# * Created by  : Joo Sung ( webmaster@apachezone.com )                             #
#                                                                                   #
#####################################################################################

##########################################
#                                        #
#           repositories install         #
#                                        #
########################################## 

sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
sudo dnf install -y https://rpms.remirepo.net/enterprise/remi-release-8.rpm

sudo dnf install -y epel-release mod_ssl

echo "[mariadb]" > /etc/yum.repos.d/mariadb.repo
echo "name = MariaDB" >> /etc/yum.repos.d/mariadb.repo
echo "baseurl = http://yum.mariadb.org/10.6/rhel8-amd64" >> /etc/yum.repos.d/mariadb.repo
echo "module_hotfixes=1" >> /etc/yum.repos.d/mariadb.repo
echo "gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB" >> /etc/yum.repos.d/mariadb.repo
echo "gpgcheck=1" >> /etc/yum.repos.d/mariadb.repo 

sudo dnf -y install wget openssh-clients bind-utils git nc vim-enhanced man ntsysv vim \
iotop sysstat strace lsof mc lrzsz zip unzip bzip2 glibc* net-tools bind gcc gcc-c++ cmake \
libxml2-devel libXpm-devel gmp-devel libicu-devel openssl openssl-devel gettext-devel tree \
bzip2-devel libcurl-devel libjpeg-devel libpng-devel freetype-devel readline-devel expat-devel gnupg2 \
libxslt-devel pcre-devel curl-devel ncurses-devel autoconf automake zlib-devel libuuid-devel python3 curl \
net-snmp-devel libevent-devel libtool-ltdl-devel postgresql-devel bison make pkgconfig firewalld yum-utils perl-ExtUtils-Embed

sudo dnf -y update

cd /root/ROCKY/APM

##########################################
#                                        #
#           SELINUX disabled             #
#                                        #
##########################################

sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
/usr/sbin/setenforce 0

##########################################
#                                        #
#           아파치 및 HTTP2 설치            #
#                                        #
########################################## 

# Nghttp2 설치
sudo dnf --enablerepo=epel -y install libnghttp2

# /etc/mime.types 설치 
sudo dnf -y install mailcap

# httpd 설치
sudo dnf install -y httpd httpd-devel

sudo systemctl enable --now httpd

sudo dnf install -y certbot python3-certbot-apache 

##########################################
#                                        #
#               firewalld                #
#                                        #
##########################################  

sudo systemctl start firewalld
sudo systemctl enable firewalld

sudo firewall-cmd --permanent --zone=public --add-service=http
sudo firewall-cmd --permanent --zone=public --add-service=https
sudo firewall-cmd --permanent --zone=public --add-port=3306/tcp
sudo firewall-cmd --permanent --zone=public --add-port=9090/tcp
sudo firewall-cmd --permanent --zone=public --add-port=11211/tcp
sudo firewall-cmd --reload

##########################################
#                                        #
#           httpd.conf   Setup           #
#                                        #
##########################################  

sed -i '/nameserver/i\nameserver 127.0.0.1' /etc/resolv.conf
cp -av /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf.original
sed -i 's/DirectoryIndex index.html/ DirectoryIndex index.html index.htm index.php index.php3 index.cgi index.jsp/' /etc/httpd/conf/httpd.conf
sed -i 's/Options Indexes FollowSymLinks/Options FollowSymLinks/' /etc/httpd/conf/httpd.conf
sed -i 's/#ServerName www.example.com:80/ServerName localhost:80/' /etc/httpd/conf/httpd.conf
sed -i 's/AllowOverride none/AllowOverride All/' /etc/httpd/conf/httpd.conf
sed -i 's/#AddHandler cgi-script .cgi/AddHandler cgi-script .cgi/' /etc/httpd/conf/httpd.conf
sed -i 's/UserDir disabled/#UserDir disabled/' /etc/httpd/conf.d/userdir.conf
sed -i 's/#UserDir public_html/UserDir public_html/' /etc/httpd/conf.d/userdir.conf
sed -i 's/Options MultiViews Indexes SymLinksIfOwnerMatch IncludesNoExec/Options MultiViews SymLinksIfOwnerMatch IncludesNoExec/' /etc/httpd/conf.d/userdir.conf

cp /root/ROCKY/APM/index.html /var/www/html/
#cp -f /root/ROCKY/APM/index.html /usr/share/httpd/noindex/

echo "<VirtualHost *:80>
  DocumentRoot /var/www/html
</VirtualHost> " >> /etc/httpd/conf.d/default.conf

systemctl restart httpd
systemctl restart named.service

##########################################
#                                        #
#         PHP7.4 및 라이브러리 install      #
#                                        #
########################################## 

sudo dnf module reset php -y
sudo dnf module enable php:remi-8.0 -y
sudo dnf install -y php php-cli php-fpm php-common php-pdo php-mysqlnd php-mbstring php-opcache php-gd php-zip \
php-soap php-devel php-json php-ldap php-xml php-iconv php-xmlrpc php-snmp php-pgsql php-process php-curl php-intl php-fileinfo

sudo dnf install -y GeoIP GeoIP-data GeoIP-devel

echo "#geoip setup
<IfModule mod_geoip.c>
 GeoIPEnable On
 GeoIPDBFile /usr/share/GeoIP/GeoIP.dat MemoryCache
</IfModule>" > /etc/httpd/conf.d/geoip.conf


cp -av /etc/php.ini /etc/php.ini.original
sed -i 's/short_open_tag = Off/short_open_tag = On/' /etc/php.ini
sed -i 's/expose_php = On/expose_php = Off/' /etc/php.ini
sed -i 's/display_errors = Off/display_errors = On/' /etc/php.ini
sed -i 's/;error_log = php_errors.log/error_log = php_errors.log/' /etc/php.ini
sed -i 's/error_reporting = E_ALL \& ~E_DEPRECATED/error_reporting = E_ALL \& ~E_NOTICE \& ~E_DEPRECATED \& ~E_USER_DEPRECATED/' /etc/php.ini
sed -i 's/variables_order = "GPCS"/variables_order = "EGPCS"/' /etc/php.ini
sed -i 's/post_max_size = 8M/post_max_size = 100M/' /etc/php.ini
sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 100M/' /etc/php.ini
sed -i 's/;date.timezone =/date.timezone = "Asia\/Seoul"/' /etc/php.ini
sed -i 's/session.gc_maxlifetime = 1440/session.gc_maxlifetime = 86400/' /etc/php.ini
sed -i 's/disable_functions =/disable_functions = system,exec,passthru,proc_open,popen,curl_multi_exec,parse_ini_file,show_source/' /etc/php.ini 

##########################################
#                                        #
#         ioncube_loader install         #
#                                        #
########################################## 

#cd /root/ROCKY

#wget http://downloads3.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz

#tar xfz ioncube_loaders_lin_x86-64.tar.gz

#cp /root/ROCKY/ioncube/ioncube_loader_lin_7.4_ts.so /usr/lib64/php/modules/

#chmod 755 /usr/lib64/php/modules/ioncube_loader_lin_7.4_ts.so

#echo "zend_extension = /usr/lib64/php/modules/ioncube_loader_lin_7.4.so" >> /etc/php.ini

#rm -rf ioncube*

##########################################
#                                        #
#          설정 파일 들의 퍼미션 설정         #
#                                        #
########################################## 

mkdir /etc/skel/public_html

chmod 707 /etc/skel/public_html

chmod 700 /root/ROCKY/adduser.sh

chmod 700 /root/ROCKY/deluser.sh

chmod 700 /root/ROCKY/clamav.sh

chmod 700 /root/ROCKY/restart.sh

cp /root/ROCKY/APM/skel/index.html /etc/skel/public_html/

systemctl restart httpd


curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin/ && ln -s /usr/local/bin/composer.phar /usr/local/bin/composer

sed -i 's/allow_url_fopen = On/allow_url_fopen = Off/' /etc/php.ini

systemctl restart httpd

echo '<?php
phpinfo();
?>' >> /var/www/html/phpinfo.php

##########################################
#                                        #
#          MARIADB 10.6.X install        #
#                                        #
########################################## 

# MariaDB 10.6.x 설치

sudo dnf install -y mariadb mariadb-server php-mysqli

sudo systemctl start mariadb
sudo systemctl enable mariadb

sudo mariadb-secure-installation

# S.M.A.R.T. 디스크 모니터링을 설치
dnf -y install smartmontools

systemctl enable smartd

systemctl start smartd

##########################################
#                                        #
#        운영 및 보안 관련 추가 설정           #
#                                        #
##########################################

cd /root/ROCKY/

yum -y install glibc-static

#chkrootkit 설치
tar xvfz chkrootkit.tar.gz

mv chkrootkit-* chkrootkit

cd chkrootkit

make sense

rm -rf /root/ROCKY/chkrootkit.tar.gz

#mod_security fail2ban.noarch arpwatch 설치
dnf -y install  mod_security mod_security_crs fail2ban arpwatch

sed -i 's/SecRuleEngine On/SecRuleEngine DetectionOnly/' /etc/httpd/conf.d/mod_security.conf

#fail2ban 설치
service fail2ban start
chkconfig --level 2345 fail2ban on

sed -i 's,\(#filter = sshd-aggressive\),\1\nenabled = true,g;' /etc/fail2ban/jail.conf 

#clamav 설치
yum -y install clamav-server clamav-data clamav-update clamav-filesystem clamav clamav-scanner-systemd clamav-devel clamav-lib clamav-server-systemd

cp /usr/share/doc/clamd/clamd.conf /etc/clamd.conf

sed -i '/^Example/d' /etc/clamd.conf
sed -i 's/User <USER>/User clamscan/' /etc/clamd.conf
sed -i 's/#LocalSocket /LocalSocket /' /etc/clamd.conf
sed -i 's/clamd.<SERVICE>/clamd.scan/' /etc/clamd.conf

chmod 755 /var/run/clamd.scan

sed 's/710/755/' /usr/lib/tmpfiles.d/clamd.scan.conf > /etc/tmpfiles.d/clamd.scan.conf
cp /etc/freshclam.conf /etc/freshclam.conf.bak
sed -i '/^Example/d' /etc/freshclam.conf

echo "# Run the freshclam as daemon
[Unit]
Description = freshclam scanner
After = network.target
[Service]
Type = forking
ExecStart = /usr/bin/freshclam -d -c 4
Restart = on-failure
PrivateTmp = true
[Install]
WantedBy=multi-user.target" >> /usr/lib/systemd/system/clam-freshclam.service

systemctl enable clam-freshclam.service
systemctl start clam-freshclam.service
mv /usr/lib/systemd/system/clamd\@.service /usr/lib/systemd/system/clamd.service
rm -rf /usr/lib/systemd/system/clamd.service

echo "[Unit]
Description = clamd scanner daemon
After = syslog.target nss-lookup.target network.target

[Service]
Type = simple
ExecStart = /usr/sbin/clamd -c /etc/clamd.conf --foreground=yes
Restart = on-failure
PrivateTmp = true

[Install]
WantedBy=multi-user.target" >> /usr/lib/systemd/system/clamd.service

sed -i '/^Example$/d' /etc/clamd.d/scan.conf
sed -i -e 's/#LocalSocket \/var\/run\/clamd.scan\/clamd.sock/LocalSocket \/var\/run\/clamd.scan\/clamd.sock/g' /etc/clamd.d/scan.conf

systemctl enable clamd.service

systemctl start clamd.service

systemctl stop clamd.service


mkdir /virus
mkdir /backup
mkdir /root/ROCKY/php

#memcache 설치
sudo dnf install -y memcached libmemcached

sudo systemctl enable memcached.service

sudo systemctl start memcached.service

sed -i 's/OPTIONS=""/OPTIONS="-l 127.0.0.1"/' /etc/sysconfig/memcached

systemctl restart memcached


echo "#mod_expires configuration" > /tmp/httpd.conf_tempfile
echo "<IfModule mod_expires.c>"   >> /tmp/httpd.conf_tempfile
echo "    ExpiresActive On"    >> /tmp/httpd.conf_tempfile
echo "    ExpiresDefault \"access plus 1 days\""    >> /tmp/httpd.conf_tempfile
echo "    ExpiresByType text/css \"access plus 1 days\""       >> /tmp/httpd.conf_tempfile
echo "    ExpiresByType text/javascript \"access plus 1 days\""      >> /tmp/httpd.conf_tempfile
echo "    ExpiresByType text/x-javascript \"access plus 1 days\""        >> /tmp/httpd.conf_tempfile
echo "    ExpiresByType application/x-javascript \"access plus 1 days\"" >> /tmp/httpd.conf_tempfile
echo "    ExpiresByType application/javascript \"access plus 1 days\""    >> /tmp/httpd.conf_tempfile
echo "    ExpiresByType image/jpeg \"access plus 1 days\""    >> /tmp/httpd.conf_tempfile
echo "    ExpiresByType image/gif \"access plus 1 days\""       >> /tmp/httpd.conf_tempfile
echo "    ExpiresByType image/png \"access plus 1 days\""      >> /tmp/httpd.conf_tempfile
echo "    ExpiresByType image/bmp \"access plus 1 days\""        >> /tmp/httpd.conf_tempfile
echo "    ExpiresByType image/cgm \"access plus 1 days\"" >> /tmp/httpd.conf_tempfile
echo "    ExpiresByType image/tiff \"access plus 1 days\""       >> /tmp/httpd.conf_tempfile
echo "    ExpiresByType audio/basic \"access plus 1 days\""      >> /tmp/httpd.conf_tempfile
echo "    ExpiresByType audio/midi \"access plus 1 days\""        >> /tmp/httpd.conf_tempfile
echo "    ExpiresByType audio/mpeg \"access plus 1 days\""        >> /tmp/httpd.conf_tempfile
echo "    ExpiresByType audio/x-aiff \"access plus 1 days\""  >> /tmp/httpd.conf_tempfile
echo "    ExpiresByType audio/x-mpegurl \"access plus 1 days\"" >> /tmp/httpd.conf_tempfile
echo "	  ExpiresByType audio/x-pn-realaudio \"access plus 1 days\""   >> /tmp/httpd.conf_tempfile
echo "    ExpiresByType audio/x-wav \"access plus 1 days\""   >> /tmp/httpd.conf_tempfile
echo "    ExpiresByType application/x-shockwave-flash \"access plus 1 days\""   >> /tmp/httpd.conf_tempfile
echo "</IfModule>"   >> /tmp/httpd.conf_tempfile
cat /tmp/httpd.conf_tempfile >> /etc/httpd/conf.d/mod_expires.conf
rm -f /tmp/httpd.conf_tempfile

##########################################
#                                        #
#            Local SSL 설정              #
#                                        #
##########################################

mv /root/ROCKY/APM/etc/cron.daily/backup /etc/cron.daily/
mv /root/ROCKY/APM/etc/cron.daily/check_chkrootkit /etc/cron.daily/

chmod 700 /etc/cron.daily/backup
chmod 700 /etc/cron.daily/check_chkrootkit


echo "0 0,12 * * * root python -c 'import random; import time; time.sleep(random.random() * 3600)' && /usr/local/bin/certbot-auto renew" | sudo tee -a /etc/crontab > /dev/null
echo "01 01 * * 7 /root/ROCKY/clamav.sh" >> /etc/crontab

#openssl 로 디피-헬만 파라미터(dhparam) 키 만들기 둘중 하나 선택
#openssl dhparam -out /etc/ssl/certs/dhparam.pem 4096
openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048

#중요 폴더 및 파일 링크
ln -s /etc/httpd/conf.d /root/ROCKY/conf.d
ln -s /etc/my.cnf /root/ROCKY/my.cnf
ln -s /etc/php.ini /root/ROCKY/php.ini

service httpd restart

cd /root/ROCKY

##########################################
#                                        #
#             Cockpit install            #
#                                        #
########################################## 

dnf install -y cockpit

systemctl enable --now cockpit.socket

sh restart.sh

echo ""
echo ""
echo "축하 드립니다. APMinstaller 모든 작업이 끝났습니다."

exit 0

