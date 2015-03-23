# Index
* [redis + sentinel + monit setup](#redis-sentinel)

# redis + sentinel + monit setup
Redis + Sentinel + Monit setup scripts
> ##It is not production ready configuration yet! Work in progress..##

_**Edited Version**_

###REDIS

**To Install Master**  
Edit ```master.sh``` file to set configurations (redis version,instance name, port);
```sh
# Defaults
REDIS_VER=2.8.19
UPDATE_LINUX_PACKAGES=false
REDIS_INSTANCE_NAME=redis-server
REDIS_INSTANCE_PORT=6379
```

```sh
mkdir redisetup
cd redisetup
wget https://raw.githubusercontent.com/ziyasal/redisetup/master/master.sh
sudo sh master.sh #Run install script
```

**To Install Slave**  
Edit ```member.sh``` file to set configurations (redis version,instance name, port, master ip, master port);
```sh
# Defaults
REDIS_VER=2.8.19
UPDATE_LINUX_PACKAGES=false      #true|false
REDIS_INSTANCE_NAME=redis-server
REDIS_INSTANCE_PORT=6379         #Set another one if master node is on the same host
REDIS_MASTER_IP=127.0.0.1
REDIS_MASTER_PORT=6379
```

```sh
mkdir redisetup
cd redisetup
wget https://raw.githubusercontent.com/ziyasal/redisetup/master/member.sh
sudo sh member.sh #Run install script
```

_**Set somaxconn**_
```sh
echo 65535 > /proc/sys/net/core/somaxconn
```
_**redis.conf**_   [for more detail](http://redis.io/topics/config)
```sh
tcp-backlog 65535
#**TODO**
#To dump the dataset every 15 minutes (900 seconds) if at least one key changed, you can say:
#save 900 1
#**TODO**
#Redis instantly writes to the log file so even if your machine crashes, it can still recover and have the latest data. #Similar to RDB, AOF log is represented as a regular file at var/lib/redis called appendonly.aof (by default).
#appendonly yes
#**TODO**
#To tell OS to really really write the data to the disk, Redis needs to call the fsync() function right after the write call, #which can be slow.
#appendfsync everysec
```
_**/etc/init.d/redis-server**_
```sh
sudo sh -c "echo never > /sys/kernel/mm/transparent_hugepage/enabled"
ulimit -n 65535
ulimit -n >> /var/log/ulimit.log #Not required!
```

##REDIS SENTINEL
_**install**_
```sh
wget https://raw.githubusercontent.com/ziyasal/redisetup/master/sentinel.sh
sudo sh sentinel.sh  #Run install script
```

##SYSTEM SIDE SETTINGS
_**sysctl.conf**_
```sh
vm.overcommit_memory=1                # Linux kernel overcommit memory setting
vm.swappiness=0                       # turn off swapping
net.ipv4.tcp_sack=1                   # enable selective acknowledgements
net.ipv4.tcp_timestamps=1             # needed for selective acknowledgements
net.ipv4.tcp_window_scaling=1         # scale the network window
net.ipv4.tcp_congestion_control=cubic # better congestion algorythm
net.ipv4.tcp_syncookies=1             # enable syn cookied
net.ipv4.tcp_tw_recycle=1             # recycle sockets quickly
net.ipv4.tcp_max_syn_backlog=65535    # backlog setting
net.core.somaxconn=65535              # up the number of connections per port
fs.file-max=65535
```

_**/etc/security/limits.conf**_
```sh
redis soft nofile 65535
redis hard nofile 65535
```
Add following line
```sh
session required pam_limits.so
```
to
```sh
/etc/pam.d/common-session
/etc/pam.d/common-session-noninteractive
```
###MONIT
_**install**_
```sh
sudo apt-get install monit
```
_**update monit config file**_
```sh
nano /etc/monit/monitrc
```
_Add or update httpd settings_
```sh
set httpd port 8081 and
    use address localhost  # only accept connection from localhost
    allow localhost        # allow localhost to connect to the server and
    allow admin:monit      # require user "admin" with password "monit"
```
###REDIS + SENTINEL + MONIT
_**Create redis.conf**_
```sh
nano /etc/monit/conf.d/redis.conf
```
Add followin settings for more options [monit documentation](https://mmonit.com/monit/documentation/)
```sh
#Default settings
#watch by pid
check process redis-server
    with pidfile "/var/run/redis.pid"
    start program = "/etc/init.d/redis-server start"
    stop program = "/etc/init.d/redis-server stop"
    if failed host 127.0.0.1 port 6379 then restart
    if 5 restarts within 5 cycles then timeout
```

_**Create sentinel.conf**_
```sh
nano /etc/monit/conf.d/redis-sentinel.conf
```
Add following lines
```sh
#watch by process name TODO: pid file
check process redis-sentinel
    matching "redis-sentinel"
    start program = "/etc/init.d/redis-sentinel start"
    stop program = "/etc/init.d/redis-sentinel stop"
    if failed host 127.0.0.1 port 26379 then restart
    if 5 restarts within 5 cycles then timeout
```

###SHORTCUTS

After executing the command shown below 

```sh
monit monitor all
```

Now you can keep track of redis server and sentinel by monit 

```sh
monit status
```

Get Master/Slave replication information

```sh
redis-cli -p 6379 info replication
```

Get Sentinel information

```sh
redis-cli -p 26379 info sentinel
```

