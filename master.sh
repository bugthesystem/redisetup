#!/bin/bash

REDIS_VER=2.8.19
UPDATE_LINUX_PACKAGES=false
REDIS_INSTANCE_NAME=redis-server
REDIS_INSTANCE_PORT=6379

if [ ! -f member-setup.sh ]
then
	wget https://github.com/ziyasal/redisetup/raw/master/member-setup.sh
fi

sudo sh member-setup.sh master $REDIS_VER $UPDATE_LINUX_PACKAGES $REDIS_INSTANCE_NAME $REDIS_INSTANCE_PORT
