#!/bin/bash
# Install shadowsocks-libev on CentOS 7

echo "Installing Shadowsocks..."

random-string()
{
    cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w ${1:-32} | head -n 1
}

PORTS_USED=`ss -antl |grep LISTEN | awk '{ print $4 }' | cut -d: -f2|sed '/^$/d'|sort`
PORTS_USED=`echo $PORTS_USED|sed 's/\s/$\|^/g'`
PORTS_USED="^${PORTS_USED}$"
PORTS_AVAILABLE=(`seq 1025 9000 | grep -v -E "$PORTS_USED" | shuf -n 5 | sort`)

CONFIG_FILE=/etc/shadowsocks-libev/config.json
SS_PASSWORD=$(random-string 16)
SS_PORT=${PORTS_AVAILABLE[0]}
SS_IP=`ip route get 1 | awk '{print $NF;exit}'`
SS_METHOD=aes-256-gcm
GET_PIP_FILE=/tmp/get-pip.py

# install shadowsocks
wget https://copr.fedorainfracloud.org/coprs/librehat/shadowsocks/repo/epel-7/librehat-shadowsocks-epel-7.repo -P /etc/yum.repos.d/
yum update -y
yum install -y shadowsocks-libev

# create shadowsocls config
cat <<EOF | sudo tee ${CONFIG_FILE}
{
    "server":["[::0]","0.0.0.0"],
    "server_port":${SS_PORT},
    "local_address":"127.0.0.1",
    "local_port":1080,
    "password":"${SS_PASSWORD}",
    "nameserver":"8.8.8.8",
    "timeout":600,
    "udp_timeout":600,
    "method":"${SS_METHOD}",
    "mode":"tcp_and_udp",
    "fast_open":true,
}
EOF

# enable shadowsocks-libev
systemctl enable shadowsocks-libev

echo "Installing GoogleBBR"
rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-2.el7.elrepo.noarch.rpm

yum --enablerepo=elrepo-kernel install kernel-ml -y
rpm -qa | grep kernel

egrep ^menuentry /etc/grub2.cfg | cut -f 2 -d \'
CORE_NUM=`egrep ^menuentry /etc/grub2.cfg | cut -f 2 -d \' | awk '/CentOS Linux \(4\./ {print NR}'`
CORE_NUM=`expr ${CORE_NUM} - 1`
echo "choose ${CORE_NUM}"
grub2-set-default ${CORE_NUM}


echo "Tuning server..."

LIMITS_CONF=/etc/security/limits.conf
SYSCTL_CONF=/etc/sysctl.d/local.conf

echo "Backing up ${LIMITS_CONF} to ${LIMITS_CONF}.old"
mv ${LIMITS_CONF} ${LIMITS_CONF}.old

cat <<EOF | sudo tee ${LIMITS_CONF}
* soft nofile 51200
* hard nofile 51200
EOF

ulimit -n 51200

echo "Backing up ${SYSCTL_CONF} to ${SYSCTL_CONF}.old"
mv ${SYSCTL_CONF} ${SYSCTL_CONF}.old

cat <<EOF | sudo tee ${SYSCTL_CONF}
net.ipv4.tcp_fastopen = 3
# 设置 IPv4 下的 TFO 默认为开启状态
net.ipv4.tcp_congestion_control=bbr
# 设置拥塞控制算法为Google BBR
net.core.default_qdisc = fq
# 将网络拥塞队列算法设置为性能和延迟最佳的 fq_codel

fs.file-max = 1024000
# 系统所有进程一共可以打开的句柄数 (bytes)
kernel.msgmnb = 65536
# 进程通讯消息队列的最大字节数 (bytes)
kernel.msgmax = 65536
# 进程通讯消息队列单条数据最大的长度 (bytes)
kernel.shmmax = 68719476736
# 内核允许的最大共享内存大小 (bytes)
kernel.shmall = 4294967296
# 任意时间内系统可以使用的共享内存总量 (bytes)

net.core.rmem_max = 12582912
# 设置内核接收 Socket 的最大长度 (bytes)
net.core.wmem_max = 12582912
# 设置内核发送 Socket 的最大长度 (bytes)
net.ipv4.tcp_rmem = 10240 87380 12582912
# 设置 TCP Socket 接收长度的最小值，预留值，最大值 (bytes)
net.ipv4.tcp_wmem = 10240 87380 12582912
# 设置 TCP Socket 发送长度的最小值，预留值，最大值 (bytes)
net.ipv4.ip_forward = 1
# 开启所有网络设备的 IPv4 流量转发，用于支持 IPv4 的正常访问
net.ipv4.tcp_syncookies = 1
# 开启 SYN Cookie，用于防范 SYN 队列溢出后可能收到的攻击
net.ipv4.tcp_tw_reuse = 1
# 允许将等待中的 Socket 重新用于新的 TCP 连接，提高 TCP 性能
net.ipv4.tcp_tw_recycle = 0
# 禁止将等待中的 Socket 快速回收，提高 TCP 的稳定性
net.ipv4.tcp_fin_timeout = 30
# 设置客户端断开 Sockets 连接后 TCP 在 FIN 等待状态的实际 (s)，保证性能
net.ipv4.tcp_keepalive_time = 1200
# 设置 TCP 发送 keepalive 数据包的频率，影响 TCP 链接保留时间 (s)，保证性能
net.ipv4.tcp_mtu_probing = 1
# 开启 TCP 层的 MTU 主动探测，提高网络速度
net.ipv4.conf.all.accept_source_route = 1
net.ipv4.conf.default.accept_source_route = 1
# 允许接收 IPv4 环境下带有路由信息的数据包，保证安全性
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
# 拒绝接收来自 IPv4 的 ICMP 重定向消息，保证安全性
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.lo.send_redirects = 0
# 禁止发送在 IPv4 下的 ICMP 重定向消息，保证安全性
net.ipv4.conf.all.rp_filter = 0
net.ipv4.conf.default.rp_filter = 0
net.ipv4.conf.lo.rp_filter = 0
# 关闭反向路径回溯进行源地址验证 (RFC1812)，提高性能
net.ipv4.icmp_echo_ignore_broadcasts = 1
# 忽略所有 ICMP ECHO 请求的广播，保证安全性
net.ipv4.icmp_ignore_bogus_error_responses = 1
# 忽略违背 RFC1122 标准的伪造广播帧，保证安全性
net.ipv6.conf.all.accept_source_route = 1
net.ipv6.conf.default.accept_source_route = 1
# 允许接收 IPv6 环境下带有路由信息的数据包，保证安全性
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
# 禁止接收来自 IPv6 下的 ICMPv6 重定向消息，保证安全性
net.ipv6.conf.all.autoconf = 1
# 开启自动设定本地连接地址，用于支持 IPv6 地址的正常分配
net.ipv6.conf.all.forwarding = 1
# 开启所有网络设备的 IPv6 流量转发，用于支持 IPv6 的正常访问
EOF

echo "================================"
echo ""
echo "Congratulations! Shadowsocks has been installed on your system."
echo "You shadowsocks connection info:"
echo "--------------------------------"
echo "server:      ${SS_IP}"
echo "port:        ${SS_PORT}"
echo "password:    ${SS_PASSWORD}"
echo "method:      ${SS_METHOD}"
echo "--------------------------------"
echo "Restart is required."
echo "Please manual restart your server after installation completed."
