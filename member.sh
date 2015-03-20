#!/bin/bash

REDIS_VER=2.8.19
UPDATE_LINUX_PACKAGES=false #true|false
REDIS_INSTANCE_NAME=redis-server
REDIS_INSTANCE_PORT=6379 #default Master port is 6379
                         #so we have to use another one
                         #if master node is on the same host
REDIS_MASTER_IP=127.0.0.1
REDIS_MASTER_PORT=6379

if [ ! -f redis-node-setup.sh ]
then
        wget https://github.com/ziyasal/redisetup/raw/master/member-setup.sh
fi


sudo sh redis-node-setup.sh slave $REDIS_VER $UPDATE_LINUX_PACKAGES $REDIS_INSTANCE_NAME $REDIS_INSTANCE_PORT $REDIS_MASTER_IP $REDIS_MASTER_PORT
