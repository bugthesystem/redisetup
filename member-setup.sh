#!/bin/bash

MODE=$1
REDIS_VER=$2
UPDATE_LINUX_PACKAGES=$3

REDIS_INSTANCE_NAME=$4
REDIS_INSTANCE_PORT=$5

#Slave node configuration
#leave this fields blank if you are configuring Master node
REDIS_MASTER_IP=$6
REDIS_MASTER_PORT=$7

echo "MODE: $MODE"
echo "REDIS_VER: $REDIS_VER"
echo "UPDATE_LINUX_PACKAGES: $UPDATE_LINUX_PACKAGES"
echo "REDIS_INSTANCE_NAME: $REDIS_INSTANCE_NAME"
echo "REDIS_INSTANCE_PORT: $REDIS_INSTANCE_PORT"
echo "REDIS_MASTER_IP: $REDIS_MASTER_IP"
echo "REDIS_MASTER_PORT: $REDIS_MASTER_PORT"
echo ""

if [ ! "$MODE" = "master" ] && [ ! "$MODE" = "slave" ]
then
	echo "ERROR: Mode should be either 'master' or 'slave'"
fi

if [ -z $REDIS_VER ]
then
	echo "ERROR: Redis version was not specified"
	exit 0
fi

if [ -z $REDIS_INSTANCE_PORT ]
then
	echo "ERROR: Redis port was not specified"
	exit 0
fi

if [ -n "$(netstat -an | grep LISTEN | grep :$REDIS_INSTANCE_PORT)" ]
then
        echo "ERROR: Redis port has been already taken"
	exit 0
fi

if [ -z $REDIS_INSTANCE_NAME ]
then
        echo "ERROR: Redis Instance Name was not specified"
        exit 0
fi

if [ -d /var/lib/$REDIS_INSTANCE_NAME ]
then
	echo "ERROR: Redis Instance Name=[$REDIS_INSTANCE_NAME] is already in use"
	exit 0
fi

if [ "$MODE" = "slave" ]
then

	if [ -z $REDIS_MASTER_IP ]
        then
                echo "ERROR: Redis MASTER IP was not specified"
                exit 0
        fi

	if [ -z $REDIS_MASTER_PORT ]
        then
                echo "ERROR: Redis MASTER PORT was not specified"
                exit 0
        fi

fi


echo "*******************************************"
echo " 1. Update and install build packages: $UPDATE_LINUX_PACKAGES"
echo "*******************************************"

if [ "$UPDATE_LINUX_PACKAGES" = "true" ]
then
	sudo apt-get update
	sudo apt-get upgrade
	sudo apt-get install build-essential
fi

echo "*******************************************"
echo " 2. Download, Unzip, Make Redis version: 'redis-$REDIS_VER'"
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

sudo mkdir /etc/$REDIS_INSTANCE_NAME
sudo mkdir /var/lib/$REDIS_INSTANCE_NAME
sudo mkdir /var/log/$REDIS_INSTANCE_NAME

sudo chown redis.redis /var/lib/$REDIS_INSTANCE_NAME
sudo chown redis.redis /var/log/$REDIS_INSTANCE_NAME

sudo cp redis-$REDIS_VER/src/redis-server /usr/local/bin/$REDIS_INSTANCE_NAME
sudo cp redis-$REDIS_VER/src/redis-cli /usr/local/bin/redis-cli
sudo cp redis-$REDIS_VER/redis.conf /etc/$REDIS_INSTANCE_NAME/redis.conf

echo "*******************************************"
echo " 4. Configure /etc/$REDIS_INSTANCE_NAME/redis.conf "
echo "*******************************************"
echo " Edit redis.conf as follows:"
echo " 1:  ... daemonize yes"
echo " 2:  ... pidfile /var/run/$REDIS_INSTANCE_NAME.pid"
echo " 3:  ... port $REDIS_INSTANCE_PORT"
echo " 4:  ... dir /var/lib/$REDIS_INSTANCE_NAME"
echo " 5:  ... loglevel notice"
echo " 6:  ... logfile /var/log/$REDIS_INSTANCE_NAME/redis.log"
echo " 7:  ... #save 900 1"
echo " 8:  ... #save 300 10"
echo " 9:  ... #save 60 10000"

sudo sed -e "s/^daemonize no$/daemonize yes/" -e "s/^pidfile \/var\/run\/redis\.pid$/pidfile \/var\/run\/$REDIS_INSTANCE_NAME\.pid/" -e "s/^port 6379$/port $REDIS_INSTANCE_PORT/" -e "s/^dir \.\//dir \/var\/lib\/$REDIS_INSTANCE_NAME\//" -e "s/^loglevel verbose$/loglevel notice/" -e "s/^logfile \"\"$/logfile \/var\/log\/$REDIS_INSTANCE_NAME\/redis.log/" -e "s/^save 900 1$/#save 900 1/" -e "s/^save 300 10$/#save 300 10/" -e "s/^save 60 10000$/#save 60 10000/" redis-$REDIS_VER/redis.conf > redis_tmp.conf

if [ "$MODE" = "slave" ]
then
	echo " 10: ... slaveof $REDIS_MASTER_IP $REDIS_MASTER_PORT"

        sudo sed -e "s/^# slaveof <masterip> <masterport>$/slaveof $REDIS_MASTER_IP $REDIS_MASTER_PORT/" redis_tmp.conf > redis_tmp2.conf
	sudo cp redis_tmp2.conf redis_tmp.conf
	rm redis_tmp2.conf
fi


sudo cp redis_tmp.conf /etc/$REDIS_INSTANCE_NAME/redis.conf
sudo rm redis_tmp.conf -f

echo "*****************************************"
echo " 5. Move and Configure redis-server daemon"
echo "*****************************************"
echo " Edit redis.conf as follows:"
echo " 1: ... DAEMON_ARGS=/etc/$REDIS_INSTANCE_NAME/redis.conf"
echo " 2: ... DAEMON=/usr/local/bin/$REDIS_INSTANCE_NAME"

if [ ! -f init_d_redis-server ]
then
	wget https://github.com/ziyasal/redisetup/raw/master/init_d_redis-server
fi

sudo sed -e "s/^DAEMON_ARGS=\/etc\/redis\/redis\.conf$/DAEMON_ARGS=\/etc\/$REDIS_INSTANCE_NAME\/redis\.conf/" -e "s/^DAEMON=\/usr\/local\/bin\/redis-server$/DAEMON=\/usr\/local\/bin\/$REDIS_INSTANCE_NAME/" init_d_redis-server > redis-server_tmp

sudo cp redis-server_tmp /etc/init.d/$REDIS_INSTANCE_NAME
rm redis-server_tmp -f

sudo chmod +x /etc/init.d/$REDIS_INSTANCE_NAME

echo "*****************************************"
echo " 7. Auto-Enable redis-server and redis-sentinel"
echo "*****************************************"

sudo update-rc.d $REDIS_INSTANCE_NAME defaults

rm redis-$REDIS_VER -r

echo "*****************************************"
echo " Installation Complete!"
echo ""
echo " Configure $REDIS_INSTANCE_NAME in /etc/$REDIS_INSTANCE_NAME/redis.conf"
echo ""
echo " WARNING: Service isn't started by default. "
echo " Use the following command to manipulate [$REDIS_INSTANCE_NAME] service:"
echo " sudo /etc/init.d/$REDIS_INSTANCE_NAME [start|stop|restart]"
echo ""
