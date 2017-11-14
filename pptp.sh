#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#===================================================================
#   SYSTEM REQUIRED:  CentOS 6 (32bit/64bit)
#   DESCRIPTION:  Auto install pptpd for CentOS 6
#   Author: Teddysun <i@teddysun.com>
#===================================================================

if [[ $EUID -ne 0 ]]; then
    echo "Error:This script must be run as root!"
    exit 1
fi

if [[ ! -e /dev/net/tun ]]; then
    echo "TUN/TAP is not available!"
    exit 1
fi

cur_dir=`pwd`
clear
echo ""
echo "#############################################################"
echo "# Auto Install PPTP for CentOS 6                            #"
echo "# System Required: CentOS 6(32bit/64bit)                    #"
echo "# Intro: http://teddysun.com/134.html                       #"
echo "# Author: Teddysun <i@teddysun.com>                         #"
echo "#############################################################"
echo ""

# Remove installed pptpd & ppp
yum remove -y pptpd ppp
iptables --flush POSTROUTING --table nat
iptables --flush FORWARD
rm -f /etc/pptpd.conf
rm -rf /etc/ppp
arch=`uname -m`
IP=`ip addr | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | egrep -v "^192\.168|^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-2]\.|^10\.|^127\.|^255\." | head -n 1`

# Download pptpd
if [ -s pptpd-1.4.0-3.el6.$arch.rpm ]; then
  echo "pptpd-1.4.0-3.el6.$arch.rpm [found]"
else
  echo "pptpd-1.4.0-3.el6.$arch.rpm not found! download now......"
  if ! wget http://lamp.teddysun.com/files/pptpd-1.4.0-3.el6.$arch.rpm; then
    echo "Failed to download pptpd-1.4.0-3.el6.$arch.rpm, please download it to $cur_dir directory manually and retry."
    exit 1
  fi
fi

# Install some necessary tools
yum -y install net-tools make libpcap iptables gcc-c++ logrotate tar cpio perl pam tcp_wrappers dkms ppp
rpm -ivh pptpd-1.4.0-3.el6.$arch.rpm

rm -f /dev/ppp
mknod /dev/ppp c 108 0
echo 1 > /proc/sys/net/ipv4/ip_forward
echo "mknod /dev/ppp c 108 0" >> /etc/rc.local
echo "echo 1 > /proc/sys/net/ipv4/ip_forward" >> /etc/rc.local
echo "localip 192.168.8.1" >> /etc/pptpd.conf
echo "remoteip 192.168.8.2-254" >> /etc/pptpd.conf
echo "ms-dns 8.8.8.8" >> /etc/ppp/options.pptpd
echo "ms-dns 8.8.4.4" >> /etc/ppp/options.pptpd

pass=`openssl rand 6 -base64`
if [ "$1" != "" ]
  then pass=$1
fi

echo "vpn pptpd ${pass} *" >> /etc/ppp/chap-secrets

iptables -t nat -A POSTROUTING -s 192.168.8.0/24 -j SNAT --to-source ${IP}
iptables -A FORWARD -p tcp --syn -s 192.168.8.0/24 -j TCPMSS --set-mss 1356
service iptables save
chkconfig --add pptpd
chkconfig pptpd on
service iptables restart
service pptpd start

echo
echo "PPTP VPN service is installed."
echo "ServerIP:${IP}"
echo "Username:vpn"
echo "Password:${pass}"
echo "Welcome to visit: https://teddysun.com/134.html"
echo

exit 0
