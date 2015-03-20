#!/bin/bash

REDIS_INSTANCE_NAME=redis-server

if [ -z $REDIS_INSTANCE_NAME ]
then
	echo "ERROR: redis instance name wasn't specified."
fi


sudo /etc/init.d/$REDIS_INSTANCE_NAME stop
sudo update-rc.d -f $REDIS_INSTANCE_NAME remove
sudo rm /etc/init.d/$REDIS_INSTANCE_NAME

sudo rm /var/lib/$REDIS_INSTANCE_NAME -r
sudo rm /var/log/$REDIS_INSTANCE_NAME -r
sudo rm /usr/local/bin/$REDIS_INSTANCE_NAME
sudo rm /etc/$REDIS_INSTANCE_NAME -r
