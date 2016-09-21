#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#=======================================================================#
#   System Supported:  CentOS 6+ / Debian 7+ / Ubuntu 12+               #
#   Description: L2TP VPN Auto Installer                                #
#   Author: Teddysun <i@teddysun.com>                                   #
#   Intro:  https://teddysun.com/448.html                               #
#=======================================================================#
cur_dir=`pwd`

libevent2_src_filename="libevent-2.0.22-stable"
libreswan_filename="libreswan-3.18"

rootness(){
    if [[ $EUID -ne 0 ]]; then
       echo "Error:This script must be run as root!" 1>&2
       exit 1
    fi
}

tunavailable(){
    if [[ ! -e /dev/net/tun ]]; then
        echo "Error:TUN/TAP is not available!" 1>&2
        exit 1
    fi
}

disable_selinux(){
if [ -s /etc/selinux/config ] && grep 'SELINUX=enforcing' /etc/selinux/config; then
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    setenforce 0
fi
}

get_opsy(){
    [ -f /etc/redhat-release ] && awk '{print ($1,$3~/^[0-9]/?$3:$4)}' /etc/redhat-release && return
    [ -f /etc/os-release ] && awk -F'[= "]' '/PRETTY_NAME/{print $3,$4,$5}' /etc/os-release && return
    [ -f /etc/lsb-release ] && awk -F'[="]+' '/DESCRIPTION/{print $2}' /etc/lsb-release && return
}

get_os_info(){
    IP=$( ip addr | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | egrep -v "^192\.168|^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-2]\.|^10\.|^127\.|^255\.|^0\." | head -n 1 )
    if [ -z ${IP} ]; then
        IP=$( wget -qO- -t1 -T2 ipv4.icanhazip.com )
    fi
    local cname=$( awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//' )
    local cores=$( awk -F: '/model name/ {core++} END {print core}' /proc/cpuinfo )
    local freq=$( awk -F: '/cpu MHz/ {freq=$2} END {print freq}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//' )
    local tram=$( free -m | awk '/Mem/ {print $2}' )
    local swap=$( free -m | awk '/Swap/ {print $2}' )
    local up=$( awk '{a=$1/86400;b=($1%86400)/3600;c=($1%3600)/60;d=$1%60} {printf("%ddays, %d:%d:%d\n",a,b,c,d)}' /proc/uptime )
    local load=$( w | head -1 | awk -F'load average:' '{print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//' )
    local opsy=$( get_opsy )
    local arch=$( uname -m )
    local lbit=$( getconf LONG_BIT )
    local host=$( hostname )
    local kern=$( uname -r )

    echo "########## System Information ##########"
    echo 
    echo "CPU model            : ${cname}"
    echo "Number of cores      : ${cores}"
    echo "CPU frequency        : ${freq} MHz"
    echo "Total amount of ram  : ${tram} MB"
    echo "Total amount of swap : ${swap} MB"
    echo "System uptime        : ${up}"
    echo "Load average         : ${load}"
    echo "OS                   : ${opsy}"
    echo "Arch                 : ${arch} (${lbit} Bit)"
    echo "Kernel               : ${kern}"
    echo "Hostname             : ${host}"
    echo "IPv4 address         : ${IP}"
    echo 
    echo "########################################"
}

check_sys(){
    local checkType=$1
    local value=$2

    local release=''
    local systemPackage=''

    if [[ -f /etc/redhat-release ]];then
        release="centos"
        systemPackage="yum"
    elif cat /etc/issue | grep -q -E -i "debian";then
        release="debian"
        systemPackage="apt"
    elif cat /etc/issue | grep -q -E -i "ubuntu";then
        release="ubuntu"
        systemPackage="apt"
    elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat";then
        release="centos"
        systemPackage="yum"
    elif cat /proc/version | grep -q -E -i "debian";then
        release="debian"
        systemPackage="apt"
    elif cat /proc/version | grep -q -E -i "ubuntu";then
        release="ubuntu"
        systemPackage="apt"
    elif cat /proc/version | grep -q -E -i "centos|red hat|redhat";then
        release="centos"
        systemPackage="yum"
    fi

    if [[ ${checkType} == "sysRelease" ]]; then
        if [ "$value" == "$release" ];then
            return 0
        else
            return 1
        fi
    elif [[ ${checkType} == "packageManager" ]]; then
        if [ "$value" == "$systemPackage" ];then
            return 0
        else
            return 1
        fi
    fi
}

rand() {
    index=0
    str=""
    for i in {a..z}; do arr[index]=${i}; index=`expr ${index} + 1`; done
    for i in {A..Z}; do arr[index]=${i}; index=`expr ${index} + 1`; done
    for i in {0..9}; do arr[index]=${i}; index=`expr ${index} + 1`; done
    for i in {1..10}; do str="$str${arr[$RANDOM%$index]}"; done
    echo ${str}
}

is_64bit(){
    if [ `getconf WORD_BIT` = '32' ] && [ `getconf LONG_BIT` = '64' ] ; then
        return 0
    else
        return 1
    fi
}

download_file(){
    local download_root_url="http://dl.teddysun.com/files"

    if [ -s ${1} ]; then
        echo "$1 [found]"
    else
        echo "$1 not found!!!download now..."
        if ! wget -c -t3 -T60 ${download_root_url}/${1};then
            echo "Failed to download $1, please download it to ${cur_dir} directory manually and try again."
            exit 1
        fi
    fi
}

versionget(){
    if [[ -s /etc/redhat-release ]];then
        grep -oE  "[0-9.]+" /etc/redhat-release
    else
        grep -oE  "[0-9.]+" /etc/issue
    fi
}

centosversion(){
    if check_sys sysRelease centos;then
        local code=${1}
        local version="`versionget`"
        local main_ver=${version%%.*}
        if [ "${main_ver}" == "${code}" ];then
            return 0
        else
            return 1
        fi
    else
        return 1
    fi
}

debianversion(){
    if check_sys sysRelease debian;then
        local version=$( get_opsy )
        local code=${1}
        local main_ver=$( echo ${version} | sed 's/[^0-9]//g')
        if [ "${main_ver}" == "${code}" ];then
            return 0
        else
            return 1
        fi
    else
        return 1
    fi
}

version_check(){
    if check_sys packageManager yum; then
        if centosversion 5; then
            echo "Error: CentOS 5 is not supported, Please re-install OS and try again."
            exit 1
        fi
    fi
}

preinstall_l2tp(){

    echo
    if [ -d "/proc/vz" ]; then
        echo -e "\033[41;37m WARNING: \033[0m Your VPS is based on OpenVZ, and IPSec might not be supported by the kernel."
        echo "Continue installation? (y/n)"
        read -p "(Default: n)" agree
        [ -z ${agree} ] && agree="n"
        if [ "${agree}" == "n" ]; then
            echo
            echo "L2TP installation cancelled."
            echo
            exit 0
        fi
    fi
    echo
    echo "Please enter IP-Range:"
    read -p "(Default Range: 192.168.18):" iprange
    [ -z ${iprange} ] && iprange="192.168.18"

    echo "Please enter PSK:"
    read -p "(Default PSK: teddysun.com):" mypsk
    [ -z ${mypsk} ] && mypsk="teddysun.com"

    echo "Please enter Username:"
    read -p "(Default Username: teddysun):" username
    [ -z ${username} ] && username="teddysun"

    password=`rand`
    echo "Please enter ${username}'s password:"
    read -p "(Default Password: ${password}):" tmppassword
    [ ! -z ${tmppassword} ] && password=${tmppassword}

    get_char(){
    SAVEDSTTY=`stty -g`
    stty -echo
    stty cbreak
    dd if=/dev/tty bs=1 count=1 2> /dev/null
    stty -raw
    stty echo
    stty $SAVEDSTTY
    }
    echo
    echo "ServerIP:${IP}"
    echo "Server Local IP:${iprange}.1"
    echo "Client Remote IP Range:${iprange}.2-${iprange}.254"
    echo "PSK:${mypsk}"
    echo
    echo "Press any key to start... or press Ctrl + C to cancel."
    char=`get_char`

}

install_l2tp(){

    mknod /dev/random c 1 9

    if check_sys packageManager apt;then
        apt-get -y update

        if debianversion 7;then
            if is_64bit;then
                local libnspr4_filename1="libnspr4_4.10.7-1_amd64.deb"
                local libnspr4_filename2="libnspr4-0d_4.10.7-1_amd64.deb"
                local libnspr4_filename3="libnspr4-dev_4.10.7-1_amd64.deb"
                local libnspr4_filename4="libnspr4-dbg_4.10.7-1_amd64.deb"
                local libnss3_filename1="libnss3_3.17.2-1.1_amd64.deb"
                local libnss3_filename2="libnss3-1d_3.17.2-1.1_amd64.deb"
                local libnss3_filename3="libnss3-tools_3.17.2-1.1_amd64.deb"
                local libnss3_filename4="libnss3-dev_3.17.2-1.1_amd64.deb"
                local libnss3_filename5="libnss3-dbg_3.17.2-1.1_amd64.deb"
            else
                local libnspr4_filename1="libnspr4_4.10.7-1_i386.deb"
                local libnspr4_filename2="libnspr4-0d_4.10.7-1_i386.deb"
                local libnspr4_filename3="libnspr4-dev_4.10.7-1_i386.deb"
                local libnspr4_filename4="libnspr4-dbg_4.10.7-1_i386.deb"
                local libnss3_filename1="libnss3_3.17.2-1.1_i386.deb"
                local libnss3_filename2="libnss3-1d_3.17.2-1.1_i386.deb"
                local libnss3_filename3="libnss3-tools_3.17.2-1.1_i386.deb"
                local libnss3_filename4="libnss3-dev_3.17.2-1.1_i386.deb"
                local libnss3_filename5="libnss3-dbg_3.17.2-1.1_i386.deb"
            fi
            rm -rf ${cur_dir}/l2tp
            mkdir -p ${cur_dir}/l2tp
            cd ${cur_dir}/l2tp
            download_file "${libnspr4_filename1}"
            download_file "${libnspr4_filename2}"
            download_file "${libnspr4_filename3}"
            download_file "${libnspr4_filename4}"
            download_file "${libnss3_filename1}"
            download_file "${libnss3_filename2}"
            download_file "${libnss3_filename3}"
            download_file "${libnss3_filename4}"
            download_file "${libnss3_filename5}"
            dpkg -i ${libnspr4_filename1} ${libnspr4_filename2} ${libnspr4_filename3} ${libnspr4_filename4}
            dpkg -i ${libnss3_filename1} ${libnss3_filename2} ${libnss3_filename3} ${libnss3_filename4} ${libnss3_filename5}
            apt-get -y install wget gcc ppp flex bison make pkg-config libpam0g-dev libcap-ng-dev libcap-ng-utils libunbound-dev libevent-dev libcurl4-nss-dev libsystemd-daemon-dev
        else
            apt-get -y install wget gcc ppp flex bison make python libnss3-dev libnspr4-dev pkg-config libpam0g-dev libcap-ng-dev libcap-ng-utils libunbound-dev libnss3-tools libevent-dev libcurl4-nss-dev libsystemd-daemon-dev
        fi
        apt-get -y --no-install-recommends install xmlto
        apt-get -y install xl2tpd
        compile_install
    elif check_sys packageManager yum; then
        if centosversion 7; then
            yum -y install epel-release
            yum -y install ppp libreswan xl2tpd firewalld
            yum_install
        elif centosversion 6; then
            yum -y install epel-release
            yum -y install gcc gcc-c++ ppp iptables make gmp-devel xmlto bison flex libpcap-devel lsof
            yum -y install xl2tpd curl-devel nss-devel nspr-devel pkgconfig pam-devel unbound-devel libcap-ng-devel
            compile_install
        fi
    fi

}

compile_install(){

    rm -rf ${cur_dir}/l2tp
    mkdir -p ${cur_dir}/l2tp
    cd ${cur_dir}/l2tp
    download_file "${libreswan_filename}.tar.gz"
    tar -zxf ${libreswan_filename}.tar.gz

    if centosversion 6; then
        download_file "${libevent2_src_filename}.tar.gz"
        tar -zxf ${libevent2_src_filename}.tar.gz
        cd ${libevent2_src_filename}
        ./configure
        make && make install
        if [ $? -eq 0 ]; then
            if is_64bit;then
                ln -sf /usr/local/lib/libevent-2.0.so.5 /usr/lib64/libevent-2.0.so.5
                ln -sf /usr/local/lib/libevent_pthreads-2.0.so.5 /usr/lib64/libevent_pthreads-2.0.so.5
            else
                ln -sf /usr/local/lib/libevent-2.0.so.5 /usr/lib/libevent-2.0.so.5
                ln -sf /usr/local/lib/libevent_pthreads-2.0.so.5 /usr/lib/libevent_pthreads-2.0.so.5
            fi
            echo "/usr/local/lib" > /etc/ld.so.conf.d/local.conf
            ldconfig
        else
            echo "libevent2 install failed..."
            exit 1
        fi
    fi

    cd ${cur_dir}/l2tp/${libreswan_filename}
    echo "WERROR_CFLAGS =" > Makefile.inc.local
    make programs && make install

    /usr/local/sbin/ipsec --version >/dev/null 2>&1
    if [ $? -ne 0 ];then
        echo "${libreswan_filename} install failed."
        exit 1
    fi

    cat > /etc/ipsec.conf<<EOF
config setup
    nat_traversal=yes
    protostack=netkey
    oe=off
    interfaces="%defaultroute"
    dumpdir=/var/run/pluto/
    virtual_private=%v4:10.0.0.0/8,%v4:192.168.0.0/16,%v4:172.16.0.0/12,%v4:25.0.0.0/8,%v4:100.64.0.0/10,%v6:fd00::/8,%v6:fe80::/10

conn L2TP-PSK-NAT
    rightsubnet=vhost:%priv
    also=L2TP-PSK-noNAT

conn L2TP-PSK-noNAT
    authby=secret
    pfs=no
    auto=add
    keyingtries=3
    rekey=no
    ikelifetime=8h
    keylife=1h
    type=transport
    left=${IP}
    leftid=${IP}
    leftprotoport=17/1701
    right=%any
    rightprotoport=17/%any
    dpddelay=40
    dpdtimeout=130
    dpdaction=clear
EOF

    cat > /etc/ipsec.secrets<<EOF
${IP} %any: PSK "${mypsk}"
EOF

    cat > /etc/xl2tpd/xl2tpd.conf<<EOF
[global]
listen-addr = ${IP}
[lns default]
ip range = ${iprange}.2-${iprange}.254
local ip = ${iprange}.1
require chap = yes
refuse pap = yes
require authentication = yes
name = LinuxVPNserver
ppp debug = yes
pppoptfile = /etc/ppp/options.xl2tpd
length bit = yes
EOF

    cat > /etc/ppp/options.xl2tpd<<EOF
ipcp-accept-local
ipcp-accept-remote
require-mschap-v2
ms-dns 8.8.8.8
ms-dns 8.8.4.4
noccp
auth
crtscts
hide-password
idle 1800
mtu 1410
mru 1410
nodefaultroute
name l2tpd
debug
lock
proxyarp
connect-delay 5000
EOF

    rm -f /etc/ppp/chap-secrets
    cat > /etc/ppp/chap-secrets<<EOF
# Secrets for authentication using CHAP
# client    server    secret    IP addresses
${username}    l2tpd    ${password}       *
EOF

    cp -pf /etc/sysctl.conf /etc/sysctl.conf.bak

    sed -i 's/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/g' /etc/sysctl.conf

    for each in `ls /proc/sys/net/ipv4/conf/`
    do
        echo "net.ipv4.conf.${each}.accept_source_route=0" >> /etc/sysctl.conf
        echo "net.ipv4.conf.${each}.accept_redirects=0" >> /etc/sysctl.conf
        echo "net.ipv4.conf.${each}.send_redirects=0" >> /etc/sysctl.conf
        echo "net.ipv4.conf.${each}.rp_filter=0" >> /etc/sysctl.conf
    done
    sysctl -p

    if centosversion 6; then
        [ -f /etc/sysconfig/iptables ] && cp -pf /etc/sysconfig/iptables /etc/sysconfig/iptables.old.`date +%Y%m%d`

        if [ "`/sbin/iptables-save | grep -c '^\-'`" = "0" ]; then
            cat > /etc/sysconfig/iptables <<EOF
# Added by L2TP VPN script
*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
-A INPUT -p icmp -j ACCEPT
-A INPUT -i lo -j ACCEPT
-A INPUT -p tcp --dport 22 -j ACCEPT
-A INPUT -p udp -m multiport --dports 500,4500,1701 -j ACCEPT
-A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
-A FORWARD -s ${iprange}.0/24  -j ACCEPT
COMMIT
*nat
:PREROUTING ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
-A POSTROUTING -s ${iprange}.0/24 -j SNAT --to-source ${IP}
COMMIT
EOF
        else
            iptables -I INPUT -p udp -m multiport --dports 500,4500,1701 -j ACCEPT
            iptables -I FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
            iptables -I FORWARD -s ${iprange}.0/24  -j ACCEPT
            iptables -t nat -A POSTROUTING -s ${iprange}.0/24 -j SNAT --to-source ${IP}
            /etc/init.d/iptables save
        fi

        if [ ! -f /etc/ipsec.d/cert9.db ]; then
           echo > /var/tmp/libreswan-nss-pwd
           certutil -N -f /var/tmp/libreswan-nss-pwd -d /etc/ipsec.d
           rm -f /var/tmp/libreswan-nss-pwd
        fi

        chkconfig --add iptables
        chkconfig iptables on
        chkconfig --add ipsec
        chkconfig ipsec on
        chkconfig --add xl2tpd
        chkconfig xl2tpd on

        /etc/init.d/iptables restart
        /etc/init.d/ipsec start
        /etc/init.d/xl2tpd start

    else
        [ -f /etc/iptables.rules ] && cp -pf /etc/iptables.rules /etc/iptables.rules.old.`date +%Y%m%d`

        if [ "`/sbin/iptables-save | grep -c '^\-'`" = "0" ]; then
            cat > /etc/iptables.rules <<EOF
# Added by L2TP VPN script
*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
-A INPUT -p icmp -j ACCEPT
-A INPUT -i lo -j ACCEPT
-A INPUT -p tcp --dport 22 -j ACCEPT
-A INPUT -p udp -m multiport --dports 500,4500,1701 -j ACCEPT
-A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
-A FORWARD -s ${iprange}.0/24  -j ACCEPT
COMMIT
*nat
:PREROUTING ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
-A POSTROUTING -s ${iprange}.0/24 -j SNAT --to-source ${IP}
COMMIT
EOF
        else
            iptables -I INPUT -p udp -m multiport --dports 500,4500,1701 -j ACCEPT
            iptables -I FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
            iptables -I FORWARD -s ${iprange}.0/24  -j ACCEPT
            iptables -t nat -A POSTROUTING -s ${iprange}.0/24 -j SNAT --to-source ${IP}
            /sbin/iptables-save > /etc/iptables.rules
        fi

        cat > /etc/network/if-up.d/iptables <<EOF
#!/bin/sh
/sbin/iptables-restore < /etc/iptables.rules
EOF
        chmod +x /etc/network/if-up.d/iptables

        if [ ! -f /etc/ipsec.d/cert9.db ]; then
           echo > /var/tmp/libreswan-nss-pwd
           certutil -N -f /var/tmp/libreswan-nss-pwd -d /etc/ipsec.d
           rm -f /var/tmp/libreswan-nss-pwd
        fi

        update-rc.d -f xl2tpd defaults

        cp -f /etc/rc.local /etc/rc.local.old.`date +%Y%m%d`
        sed --follow-symlinks -i -e '/^exit 0/d' /etc/rc.local
        cat >> /etc/rc.local <<EOF

# Added by L2TP VPN script
echo 1 > /proc/sys/net/ipv4/ip_forward
/usr/sbin/service ipsec start
exit 0
EOF
        chmod +x /etc/rc.local
        echo 1 > /proc/sys/net/ipv4/ip_forward

        /sbin/iptables-restore < /etc/iptables.rules
        /usr/sbin/service ipsec start
        /usr/sbin/service xl2tpd restart

    fi

}

yum_install(){

    rm -f /etc/ipsec.conf
    cat > /etc/ipsec.conf<<EOF
config setup
    nat_traversal=yes
    protostack=netkey
    oe=off
    interfaces="%defaultroute"
    dumpdir=/var/run/pluto/
    virtual_private=%v4:10.0.0.0/8,%v4:192.168.0.0/16,%v4:172.16.0.0/12,%v4:25.0.0.0/8,%v4:100.64.0.0/10,%v6:fd00::/8,%v6:fe80::/10

conn L2TP-PSK-NAT
    rightsubnet=vhost:%priv
    also=L2TP-PSK-noNAT

conn L2TP-PSK-noNAT
    authby=secret
    pfs=no
    auto=add
    keyingtries=3
    rekey=no
    ikelifetime=8h
    keylife=1h
    type=transport
    left=${IP}
    leftid=${IP}
    leftprotoport=17/1701
    right=%any
    rightprotoport=17/%any
    dpddelay=40
    dpdtimeout=130
    dpdaction=clear
EOF
    rm -f /etc/ipsec.secrets
    cat > /etc/ipsec.secrets<<EOF
${IP} %any: PSK "${mypsk}"
EOF
    rm -f /etc/xl2tpd/xl2tpd.conf
    cat > /etc/xl2tpd/xl2tpd.conf<<EOF
[global]
listen-addr = ${IP}
[lns default]
ip range = ${iprange}.2-${iprange}.254
local ip = ${iprange}.1
require chap = yes
refuse pap = yes
require authentication = yes
name = LinuxVPNserver
ppp debug = yes
pppoptfile = /etc/ppp/options.xl2tpd
length bit = yes
EOF
    rm -f /etc/ppp/options.xl2tpd
    cat > /etc/ppp/options.xl2tpd<<EOF
ipcp-accept-local
ipcp-accept-remote
require-mschap-v2
ms-dns 8.8.8.8
ms-dns 8.8.4.4
noccp
auth
crtscts
hide-password
idle 1800
mtu 1410
mru 1410
nodefaultroute
name l2tpd
debug
lock
proxyarp
connect-delay 5000
EOF
    rm -f /etc/ppp/chap-secrets
    cat > /etc/ppp/chap-secrets<<EOF
# Secrets for authentication using CHAP
# client    server    secret    IP addresses
${username}    l2tpd    ${password}       *
EOF

    cp -pf /etc/sysctl.conf /etc/sysctl.conf.bak

    echo "# Added by L2TP VPN" >> /etc/sysctl.conf
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_syncookies=1" >> /etc/sysctl.conf
    echo "net.ipv4.icmp_echo_ignore_broadcasts=1" >> /etc/sysctl.conf
    echo "net.ipv4.icmp_ignore_bogus_error_responses=1" >> /etc/sysctl.conf

    for each in `ls /proc/sys/net/ipv4/conf/`
    do
        echo "net.ipv4.conf.${each}.accept_source_route=0" >> /etc/sysctl.conf
        echo "net.ipv4.conf.${each}.accept_redirects=0" >> /etc/sysctl.conf
        echo "net.ipv4.conf.${each}.send_redirects=0" >> /etc/sysctl.conf
        echo "net.ipv4.conf.${each}.rp_filter=0" >> /etc/sysctl.conf
    done
    sysctl -p

    cat > /usr/lib/firewalld/services/xl2tpd.xml<<EOF
<?xml version="1.0" encoding="utf-8"?>
<service>
  <short>xl2tpd</short>
  <description>L2TP IPSec</description>
  <port protocol="udp" port="4500"/>
  <port protocol="udp" port="1701"/>
</service>
EOF
    chmod 640 /usr/lib/firewalld/services/xl2tpd.xml

    systemctl enable ipsec
    systemctl enable xl2tpd
    systemctl enable firewalld

    systemctl status firewalld > /dev/null 2>&1
    if [ $? -eq 0 ];then
        echo "Checking firewalld status..."
        firewall-cmd --list-all
        echo "add firewalld rules..."
        firewall-cmd --permanent --add-service=ipsec
        firewall-cmd --permanent --add-service=xl2tpd
        firewall-cmd --permanent --add-masquerade
        firewall-cmd --reload
    else
        echo "Firewalld looks like not running, trying to start..."
        systemctl start firewalld
        if [ $? -eq 0 ];then
            echo "Firewalld start successfully..."
            echo "Checking firewalld status..."
            firewall-cmd --list-all
            echo "adding firewalld rules..."
            firewall-cmd --permanent --add-service=ipsec
            firewall-cmd --permanent --add-service=xl2tpd
            firewall-cmd --permanent --add-masquerade
            firewall-cmd --reload
        else
            echo "Failed to start firewalld. please enable port 500 4500 manually if necessary."
        fi
    fi

    systemctl restart ipsec
    systemctl restart xl2tpd
    echo "Checking ipsec status..."
    systemctl -a | grep ipsec
    echo "Checking xl2tpd status..."
    systemctl -a | grep xl2tpd
    echo "Checking firewalld status..."
    firewall-cmd --list-all
    firewall-cmd --list-all | grep xl2tpd > /dev/null 2>&1
    if [ $? -ne 0 ];then
        firewall-cmd --permanent --add-service=xl2tpd
        firewall-cmd --reload
    fi

}

finally(){

    cd ${cur_dir}
    rm -fr ${cur_dir}/l2tp
    # create l2tp command
    cp -f ${cur_dir}/`basename $0` /usr/bin/l2tp

    echo "Please wait a moment..."
    sleep 5
    ipsec verify
    echo
    echo "###############################################################"
    echo "# L2TP VPN Auto Installer                                     #"
    echo "# System Supported: CentOS 6+ / Debian 7+ / Ubuntu 12+        #"
    echo "# Intro: https://teddysun.com/448.html                        #"
    echo "# Author: Teddysun <i@teddysun.com>                           #"
    echo "###############################################################"
    echo "If there is no [FAILED] above, you can connect to your L2TP "
    echo "VPN Server with the default Username/Password is below:"
    echo
    echo "ServerIP:${IP}"
    echo "PSK:${mypsk}"
    echo "Username:${username}"
    echo "Password:${password}"
    echo
    echo "If you want to modify user settings, please use command(s):"
    echo "l2tp -a (Add a user)"
    echo "l2tp -d (Delete a user)"
    echo "l2tp -l (List all users)"
    echo "l2tp -m (Modify a user password)"
    echo
    echo "Welcome to visit https://teddysun.com/448.html"
    echo "Enjoy it!"
    echo
}


l2tp(){
    clear
    echo
    echo "###############################################################"
    echo "# L2TP VPN Auto Installer                                     #"
    echo "# System Supported: CentOS 6+ / Debian 7+ / Ubuntu 12+        #"
    echo "# Intro: https://teddysun.com/448.html                        #"
    echo "# Author: Teddysun <i@teddysun.com>                           #"
    echo "###############################################################"
    echo
    rootness
    tunavailable
    disable_selinux
    version_check
    get_os_info
    preinstall_l2tp
    install_l2tp
    finally
}

list_users(){
    if [ ! -f /etc/ppp/chap-secrets ];then
        echo "Error: /etc/ppp/chap-secrets file not found."
        exit 1
    fi
    local line="+-------------------------------------------+\n"
    local string=%20s
    printf "${line}|${string} |${string} |\n${line}" Username Password
    grep -v "^#" /etc/ppp/chap-secrets | awk '{printf "|'${string}' |'${string}' |\n", $1,$3}'
    printf ${line}
}

add_user(){
    while :
    do
        read -p "Please input your Username:" user
        if [ -z ${user} ]; then
            echo "Username can not be empty"
        else
            grep -w "${user}" /etc/ppp/chap-secrets > /dev/null 2>&1
            if [ $? -eq 0 ];then
                echo "Username (${user}) already exists. Please re-enter your username."
            else
                break
            fi
        fi
    done
    pass=`rand`
    echo "Please input ${user}'s password:"
    read -p "(Default Password: ${pass}):" tmppass
    [ ! -z ${tmppass} ] && pass=${tmppass}
    echo "${user}    l2tpd    ${pass}       *" >> /etc/ppp/chap-secrets
    echo "Username (${user}) add completed."
}

del_user(){
    while :
    do
        read -p "Please input Username you want to delete it:" user
        if [ -z ${user} ]; then
            echo "Username can not be empty"
        else
            grep -w "${user}" /etc/ppp/chap-secrets >/dev/null 2>&1
            if [ $? -eq 0 ];then
                break
            else
                echo "Username (${user}) is not exists. Please re-enter your username."
            fi
        fi
    done
    sed -i "/^\<${user}\>/d" /etc/ppp/chap-secrets
    echo "Username (${user}) delete completed."
}

mod_user(){
    while :
    do
        read -p "Please input Username you want to change password:" user
        if [ -z ${user} ]; then
            echo "Username can not be empty"
        else
            grep -w "${user}" /etc/ppp/chap-secrets >/dev/null 2>&1
            if [ $? -eq 0 ];then
                break
            else
                echo "Username (${user}) is not exists. Please re-enter your username."
            fi
        fi
    done
    pass=`rand`
    echo "Please input ${user}'s new password:"
    read -p "(Default Password: ${pass}):" tmppass
    [ ! -z ${tmppass} ] && pass=${tmppass}
    sed -i "/^\<${user}\>/d" /etc/ppp/chap-secrets
    echo "${user}    l2tpd    ${pass}       *" >> /etc/ppp/chap-secrets
    echo "Username ${user}'s password has been changed."
}

# Main process
action=$1
if [ -z ${action} ] && [ "`basename $0`" != "l2tp" ]; then
    action=install
fi

case ${action} in
    install)
        l2tp 2>&1 | tee /root/l2tp.log
        ;;
    -l|--list)
        list_users
        ;;
    -a|--add)
        add_user
        ;;
    -d|--del)
        del_user
        ;;
    -m|--mod)
        mod_user
        ;;
    -h|--help)
        echo "Usage: `basename $0` -l,--list   List all users"
        echo "       `basename $0` -a,--add    Add a user"
        echo "       `basename $0` -d,--del    Delete a user"
        echo "       `basename $0` -m,--mod    Modify a user password"
        echo "       `basename $0` -h,--help   Print this help information"
        ;;
    *)
        echo "Usage: `basename $0` [-l,--list|-a,--add|-d,--del|-m,--mod|-h,--help]" && exit
        ;;
esac
