#!/bin/bash
# Install Shadowsocks on CentOS 7

echo "Installing Shadowsocks..."

random-string()
{
    cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w ${1:-32} | head -n 1
}

PORTS_USED=`netstat -antl |grep LISTEN | awk '{ print $4 }' | cut -d: -f2|sed '/^$/d'|sort`
PORTS_USED=`echo $PORTS_USED|sed 's/\s/$\|^/g'`
PORTS_USED="^${PORTS_USED}$"
PORTS_AVAILABLE=(`seq 1025 9000 | grep -v -E "$PORTS_USED" | shuf -n 5 | sort`)

CONFIG_FILE=/etc/shadowsocks.json
SERVICE_FILE=/etc/systemd/system/shadowsocks.service
SS_PASSWORD_1=$(random-string 32)
SS_PORT_1=${PORTS_AVAILABLE[0]}
SS_PASSWORD_2=$(random-string 32)
SS_PORT_2=${PORTS_AVAILABLE[1]}
SS_PASSWORD_3=$(random-string 32)
SS_PORT_3=${PORTS_AVAILABLE[2]}
SS_PASSWORD_4=$(random-string 32)
SS_PORT_4=${PORTS_AVAILABLE[3]}
SS_PASSWORD_5=$(random-string 32)
SS_PORT_5=${PORTS_AVAILABLE[4]}
SS_METHOD=aes-256-cfb
SS_FAST_OPEN=true
SS_IP=`ip route get 1 | awk '{print $NF;exit}'`
GET_PIP_FILE=/tmp/get-pip.py

# install pip
curl "https://bootstrap.pypa.io/get-pip.py" -o "${GET_PIP_FILE}"
python ${GET_PIP_FILE}

# install shadowsocks
pip install --upgrade pip
pip install shadowsocks

# create shadowsocls config
cat <<EOF | sudo tee ${CONFIG_FILE}
{
  "server": "0.0.0.0",
  "port_password": {
        "${SS_PORT_1}": "${SS_PASSWORD_1}",
        "${SS_PORT_2}": "${SS_PASSWORD_2}",
        "${SS_PORT_3}": "${SS_PASSWORD_3}",
        "${SS_PORT_4}": "${SS_PASSWORD_4}",
        "${SS_PORT_5}": "${SS_PASSWORD_5}"
        },
  "method": "${SS_METHOD}",
  "timeout": 300,
  "fast_open": ${SS_FAST_OPEN}
}
EOF

#set fastopen
#echo 3 > /proc/sys/net/ipv4/tcp_fastopen

# create service
cat <<EOF | sudo tee ${SERVICE_FILE}
[Unit]
Description=Shadowsocks

[Service]
TimeoutStartSec=0
ExecStart=/usr/bin/ssserver -c ${CONFIG_FILE}

[Install]
WantedBy=multi-user.target
EOF

echo "Optimizing..."

LIMITS_CONF=/etc/security/limits.conf
SYSCTL_CONF=/etc/sysctl.d/local.conf
MODPROBE=/sbin/modprobe

echo "Backing up ${LIMITS_CONF} to ${LIMITS_CONF}.old"
mv ${LIMITS_CONF} ${LIMITS_CONF}.old

cat <<EOF | sudo tee ${LIMITS_CONF}
* soft nofile 51200
* hard nofile 51200
EOF

ulimit -n 51200

${MODPROBE} tcp_hybla

echo "Backing up ${SYSCTL_CONF} to ${SYSCTL_CONF}.old"
mv ${SYSCTL_CONF} ${SYSCTL_CONF}.old

cat <<EOF | sudo tee ${SYSCTL_CONF}
fs.file-max = 51200

net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.core.rmem_default=65536
net.core.wmem_default=65536
net.core.netdev_max_backlog = 4096
net.core.somaxconn = 4096

net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 0
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.ip_local_port_range = 10000 65000
net.ipv4.tcp_max_syn_backlog = 4096
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_congestion_control = hybla
EOF

sysctl --system

echo "Installing denyhosts..."
yum install -y epel-release.noarch
yum install -y denyhosts

echo "Installing firewalld..."
systemctl enable firewalld
systemctl start firewalld

echo "Starting services..."
systemctl enable denyhosts
systemctl start denyhosts

# start service
systemctl enable shadowsocks
systemctl start shadowsocks

# view service status
sleep 5
systemctl status firewalld
systemctl status denyhosts
systemctl status shadowsocks

echo "Configuring firewall..."
firewall-cmd --permanent --add-port=${SS_PORT_1}/tcp
firewall-cmd --permanent --add-port=${SS_PORT_1}/udp
firewall-cmd --permanent --add-port=${SS_PORT_2}/tcp
firewall-cmd --permanent --add-port=${SS_PORT_2}/udp
firewall-cmd --permanent --add-port=${SS_PORT_3}/tcp
firewall-cmd --permanent --add-port=${SS_PORT_3}/udp
firewall-cmd --permanent --add-port=${SS_PORT_4}/tcp
firewall-cmd --permanent --add-port=${SS_PORT_4}/udp
firewall-cmd --permanent --add-port=${SS_PORT_5}/tcp
firewall-cmd --permanent --add-port=${SS_PORT_5}/udp
firewall-cmd --reload
echo "following ports are enabled:"
firewall-cmd --list-ports

echo "================================"
echo ""
echo "Congratulations! Shadowsocks has been installed on your system."
echo "You shadowsocks connection info:"
echo "--------------------------------"
echo "server:      ${SS_IP}"
echo "port_password: ${SS_PORT_1} : ${SS_PASSWORD_1}"
echo "port_password: ${SS_PORT_2} : ${SS_PASSWORD_2}"
echo "port_password: ${SS_PORT_3} : ${SS_PASSWORD_3}"
echo "port_password: ${SS_PORT_4} : ${SS_PASSWORD_4}"
echo "port_password: ${SS_PORT_5} : ${SS_PASSWORD_5}"
echo "method:      ${SS_METHOD}"
echo "--------------------------------"
