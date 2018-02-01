#!/bin/bash
#
# rcs-cleanup.sh
#
# Runs monthly to clean up rcs report files in /opt/phion/config/reports
#

if [ -z "$1" ]
then
    numdays=60
else
    numdays=$1
fi

now=`date +'%F %H:%M:%S'`
ymd=`date +%F`

echo "Starting log cleanup at ${now} for files older than ${numdays} days" >> /var/log/rcs-cleanup.log

# Log file names and then delete
find /data/reports/ -maxdepth 1 -mtime +${numdays} >> /var/log/rcs-cleanup.log
find /data/reports/ -maxdepth 1 -mtime +${numdays} | xargs rm -fr


