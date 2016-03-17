#!/bin/bash
# Enable security on CentOS 7

echo "Securing CentOS..."

SS_PORT_START=8381
SS_PORT_END=8385

yum install -y epel-release.noarch
yum install -y denyhosts

echo "Starting denyhosts..."
systemctl enable denyhosts
systemctl start denyhosts
systemctl status denyhosts

echo "Enabling firewall..."
systemctl enable firewalld
systemctl start firewalld
firewall-cmd --permanent --add-port=${SS_PORT_START}-${SS_PORT_END}/tcp
firewall-cmd --permanent --add-port=${SS_PORT_START}-${SS_PORT_END}/udp
firewall-cmd --reload
echo "following ports are enabled:"
firewall-cmd --list-ports

echo "================================"
echo ""
echo "Congratulations! denyhosts and firewall has been installed on your system."