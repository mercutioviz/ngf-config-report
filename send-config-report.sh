#!/bin/bash
#
# send-config-report.sh
#
# Place this file in /etc/cron.daily
# Edit the mailclt command below to use your target email addresses and SMTP server
#  -f = from email address
#  -r = target email address (use multiple -r args for more than one address)
#  -m = IP address of SMTP server 

yest=`date --date='yesterday'`
subject="NGF Config Change Report: $yest"
/usr/local/bin/format-rcs-report.pl > /tmp/config-report.txt
/opt/phion/bin/mailclt -f sender@email -r recipient@email -m x.x.x.x -s "$subject" -a /tmp/config-report.txt

