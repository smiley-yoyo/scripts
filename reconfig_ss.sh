#!/bin/bash
# Install Shadowsocks on CentOS 7

echo "Changing Shadowsocks..."

random-string()
{
    cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w ${1:-32} | head -n 1
}

CONFIG_FILE=/etc/shadowsocks.json
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
SS_FAST_OPEN=true
SS_IP=`ip route get 1 | awk '{print $NF;exit}'`

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
  "fast_open": ${SS_FAST_OPEN},
  "workers": 5
}
EOF

# start service
systemctl restart shadowsocks

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