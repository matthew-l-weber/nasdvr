#!/bin/sh
while true
do 
	cd /var/www/nasdvr/bin
	./scheduler.pl     &
	sleep 10
done
