#!/usr/bin/env bash

#####################################################################################
#                                                                                   #
# * APMinstaller v.1 with Rocky8                                                   #
# * CentOS-8-x86_64-1911                                                            #
# * Apache 2.4.X , MariaDB 10.4.X, Multi-PHP(base php7.2) setup shell script        #
# * Created Date    : 2021/12/25                                                    #
# * Created by  : Joo Sung ( webmaster@apachezone.com )                             #
#                                                                                   #
#####################################################################################

echo "
 =======================================================

               < ROCKY 설치 하기>

 =======================================================
"
echo "설치 하시겠습니까? 'Y' or 'N'"
read YN
YN=`echo $YN | tr "a-z" "A-Z"`
 
if [ "$YN" != "Y" ]
then
    echo "설치 중단."
    exit
fi

echo""
echo "설치를 시작 합니다."

cd /root/ROCKY/APM

chmod 700 APMinstaller.sh

chmod 700 /root/ROCKY/adduser.sh

chmod 700 /root/ROCKY/deluser.sh

chmod 700 /root/ROCKY/restart.sh

sh APMinstaller.sh

cd /root/ROCKY

echo ""
echo ""
echo "ROCKY 설치 완료!"
echo ""
echo ""
echo ""

echo "
 =======================================================

               < phpMyAdmin 설치 하기>

 =======================================================
"
echo "phpMyAdmin 설치 하시겠습니까? 'Y' or 'N'"
read YN
YN=`echo $YN | tr "a-z" "A-Z"`
 
if [ "$YN" != "Y" ]
then
    echo "설치 중단."
    exit
fi

echo""
echo "phpMyAdmin 설치를 시작 합니다."
cd /root/ROCKY/APM

chmod 700 phpMyAdmin.sh

sh phpMyAdmin.sh

echo ""
echo ""
echo "phpMyAdmin 설치 완료!"
echo ""
echo ""
echo ""

#설치 파일 삭제
rm -rf /root/ROCKY/APM
echo ""
rm -rf /root/ROCKY/install.sh
echo ""
exit;

esac

