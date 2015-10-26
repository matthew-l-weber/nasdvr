#!/bin/bash

if ps aux | grep "[s]chedule.sh" > /dev/null
then
    echo "Running, do nothing"
else
    echo "Stopped"
    echo "++++++++++Starting++++++++++++++" >> /var/www/nasdvr/log/process.log
    date >> /var/www/nasdvr/log/process.log
    /var/www/nasdvr/bin/schedule.sh >> /var/www/nasdvr/log/process.log  2>&1
fi
