#!/bin/bash

systemctl start clamd.service 
 

clamscan -r /home --move=/virus

systemctl stop clamd.service 


sh /root/ROCKY/restart.sh