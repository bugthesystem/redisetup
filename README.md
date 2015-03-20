# redis + monit setup
Redis + Monit setup scripts

_**Edited Version**_

##How To

```sh
echo 65535 > /proc/sys/net/core/somaxconn
```

**redis.conf**
```sh
tcp-backlog 65535
```

**sysctl.conf**
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

**/etc/security/limits.conf**
```sh
redis soft nofile 65535
redis hard nofile 65535
```
add following line to
```sh
session required pam_limits.so
```
/etc/pam.d/common-session
/etc/pam.d/common-session-noninteractive

**/etc/init.d/redis-server**
```sh
sudo sh -c "echo never > /sys/kernel/mm/transparent_hugepage/enabled"
ulimit -n 65535
ulimit -n >> /var/log/ulimit.log #Not required!
```
