#!/bin/bash

REDIS_VER=2.8.19
SENTINEL_PORT=26379 #default port: 26379
REDIS_MASTER_IP=127.0.0.1
REDIS_MASTER_PORT=6379
SENTINEL_QUORUM=1
NODE_DOWN_AFTER_MILLISECONDS=3000 # Number of milliseconds the master (or any attached slave or sentinel) should
                                  # be unreachable (as in, not acceptable reply to PING, continuously, for the
                                  # specified period) in order to consider it in S_DOWN state (Subjectively
                                  # Down).

UPDATE_LINUX_PACKAGES=false #true|false


echo "REDIS_VER: $REDIS_VER"
echo "SENTINEL_PORT: $SENTINEL_PORT"
echo "REDIS_MASTER_IP: $REDIS_MASTER_IP"
echo "REDIS_MASTER_PORT: $REDIS_MASTER_PORT"
echo "SENTINEL_QUORUM: $SENTINEL_QUORUM"
echo "UPDATE_LINUX_PACKAGES: $UPDATE_LINUX_PACKAGES"
echo ""

if [ -z $REDIS_VER ]
then
        echo "ERROR: Redis version was not specified"
        exit 0
fi

if [ -z $SENTINEL_PORT ]
then
        echo "ERROR: Sentinel port was not specified"
        exit 0
fi

if [ -n "$(netstat -an | grep LISTEN | grep :$SENTINEL_PORT)" ]
then
        echo "ERROR: Sentinel port has been already taken"
        exit 0
fi


if [ -z $REDIS_MASTER_IP ]
then
        echo "ERROR: Redis master ip was not specified"
        exit 0
fi

if [ -z $REDIS_MASTER_PORT ]
then
        echo "ERROR: Redis master port was not specified"
        exit 0
fi



echo "*******************************************"
echo " 1. Update and install build packages"
echo "*******************************************"


if [ "$UPDATE_LINUX_PACKAGES" = "true" ]
then
	sudo apt-get update
	sudo apt-get upgrade
	sudo apt-get install build-essential
fi

echo "*******************************************"
echo " 2. Download, Unzip, Make Redis version: '$1'"
echo "*******************************************"

DELETE_TAR=true
if [ -f redis-$REDIS_VER.tar.gz ]
then
        DELETE_TAR=false
else
	wget http://download.redis.io/releases/redis-$REDIS_VER.tar.gz
fi

tar xzf redis-$REDIS_VER.tar.gz
cd redis-$REDIS_VER
make
sudo make install
cd ..

if [ "$DELETE_TAR" = "true" ]
then
        rm redis-$REDIS_VER.tar.gz -f
fi

echo "*******************************************"
echo " 3. Create 'redis' user, create folders, copy redis files "
echo "*******************************************"

if [ -z $(cat /etc/passwd | grep redis) ]
then
        echo "ADDING 'redis' user"
        sudo useradd redis
fi

sudo mkdir /etc/redis-sentinel
sudo mkdir /var/lib/redis-sentinel
sudo mkdir /var/log/redis-sentinel

sudo chown redis.redis /var/lib/redis-sentinel
sudo chown redis.redis /var/log/redis-sentinel

sudo cp redis-$REDIS_VER/src/redis-sentinel /usr/local/bin/redis-sentinel

echo "*******************************************"
echo " 4. Configure /etc/redis-sentinel/sentinel.conf "
echo "*******************************************"
echo " Edit sentinel.conf as follows:"
echo " 1: ... port $SENTINEL_PORT"
echo " 2: ... sentinel monitor mymaster $REDIS_MASTER_IP $REDIS_MASTER_PORT $SENTINEL_QUORUM"
echo " 3: ... sentinel down-after-milliseconds mymaster $NODE_DOWN_AFTER_MILLISECONDS"
echo " 4: ... daemonize yes"
echo " 5: ... dir /var/lib/redis-sentinel"
echo " 6: ... loglevel notice"
echo " 7: ... logfile /var/log/redis-sentinel/redis-sentinel.log"

sudo sed -e "s/^port 26379$/port $SENTINEL_PORT/" redis-$REDIS_VER/sentinel.conf >  sentinel_tmp.conf
sudo sed -i "s/^sentinel monitor mymaster 127\.0\.0\.1 6379 2$/sentinel monitor mymaster $REDIS_MASTER_IP $REDIS_MASTER_PORT $SENTINEL_QUORUM/" sentinel_tmp.conf
sudo sed -i "s/^sentinel down-after-milliseconds mymaster 30000$/sentinel down-after-milliseconds mymaster $NODE_DOWN_AFTER_MILLISECONDS/" sentinel_tmp.conf

sudo echo "daemonize yes" >> sentinel_tmp.conf
sudo echo "dir /var/lib/redis-sentinel" >> sentinel_tmp.conf
sudo echo "loglevel notice" >> sentinel_tmp.conf
sudo echo "logfile /var/log/redis-sentinel/redis-sentinel.log" >> sentinel_tmp.conf

sudo cp sentinel_tmp.conf /etc/redis-sentinel/sentinel.conf
sudo rm sentinel_tmp.conf -f

sudo chown redis.redis /etc/redis-sentinel/sentinel.conf

echo "*****************************************"
echo " 5. Move and Configure redis-sentinel daemon"
echo "*****************************************"

if [ ! -f init_d_redis-sentinel ]
then
	wget https://github.com/ziyasal/redisetup/raw/master/init_d_redis-sentinel
fi

sudo sed -e "s/^1111$/2222/" init_d_redis-sentinel > redis-sentinel_tmp

sudo cp redis-sentinel_tmp /etc/init.d/redis-sentinel

sudo chmod +x /etc/init.d/redis-sentinel
sudo rm redis-sentinel_tmp -f

echo "*****************************************"
echo " 7. Auto-Enable redis-server and redis-sentinel"
echo "*****************************************"

sudo update-rc.d redis-sentinel defaults

echo "*****************************************"
echo " Installation Complete!"
echo ""
echo " Configure redis-sentinel in /etc/redis-sentinel/sentinel.conf"
echo ""
echo " WARNING: Service isn't started by default."
echo " User the following command to manipulate redis-sentinel instance."
echo " sudo /etc/init.d/redis-sentinel [start|stop|restart]"
echo ""
