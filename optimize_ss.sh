#!/bin/bash
# Enable security on CentOS 7

echo "Optimizing CentOS..."

LIMITS_CONF=/etc/security/limits.conf
SYSCTL_CONF=/etc/sysctl.conf
MODPROBE=/sbin/modprobe

cat <<EOF | sudo tee -a ${LIMITS_CONF}
* soft nofile 51200
* hard nofile 51200
EOF

ulimit -n 51200

${MODPROBE} tcp_hybla

cat <<EOF | sudo tee -a ${SYSCTL_CONF}
fs.file-max = 51200

net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.core.netdev_max_backlog = 250000
net.core.somaxconn = 4096

net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 0
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.ip_local_port_range = 10000 65000
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_congestion_control = hybla
EOF

sysctl -p

systemctl restart shadowsocks

systemctl status shadowsocks

echo "================================"
echo ""
echo "Congratulations! Shadowsocks has been Optimized on your system."
echo "--------------------------------"