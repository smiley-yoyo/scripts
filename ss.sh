#!/bin/bash
# Install Shadowsocks on CentOS 7

echo "Installing Shadowsocks..."

random-string()
{
    cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w ${1:-32} | head -n 1
}

CONFIG_FILE=/etc/shadowsocks.json
SERVICE_FILE=/etc/systemd/system/shadowsocks.service
SS_PASSWORD_1=$(random-string 32)
SS_PORT_1=8381
SS_PASSWORD_2=$(random-string 32)
SS_PORT_2=8382
SS_PASSWORD_3=$(random-string 32)
SS_PORT_3=8383
SS_PASSWORD_4=$(random-string 32)
SS_PORT_4=8384
SS_PASSWORD_5=$(random-string 32)
SS_PORT_5=8385
SS_METHOD=aes-256-cfb
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
  "fast_open": true,
  "workers": 5
}
EOF

#set fastopen
echo 3 > /proc/sys/net/ipv4/tcp_fastopen

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

# start service
systemctl enable shadowsocks
systemctl start shadowsocks

# view service status
sleep 5
systemctl status shadowsocks -l

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