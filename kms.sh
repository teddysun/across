#!/usr/bin/env bash
#
# Auto install KMS Server
# System Required:  CentOS 6+, Debian7+, Ubuntu12+
# Copyright (C) 2017-2018 Teddysun <i@teddysun.com>
# URL: https://teddysun.com/530.html
#
# Thanks: https://github.com/Wind4/vlmcsd
#

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)

[[ $EUID -ne 0 ]] && echo -e "${red}Error:${plain} This script must be run as root!" && exit 1

if [ -f /etc/redhat-release ]; then
    release="centos"
elif grep -Eqi "debian" /etc/issue; then
    release="debian"
elif grep -Eqi "ubuntu" /etc/issue; then
    release="ubuntu"
elif grep -Eqi "centos|red hat|redhat" /etc/issue; then
    release="centos"
elif grep -Eqi "debian" /proc/version; then
    release="debian"
elif grep -Eqi "ubuntu" /proc/version; then
    release="ubuntu"
elif grep -Eqi "centos|red hat|redhat" /proc/version; then
    release="centos"
else
    release=""
fi

boot_start(){
    if [[ x"${release}" == x"debian" || x"${release}" == x"ubuntu" ]]; then
        update-rc.d -f "${1}" defaults
    elif [[ x"${release}" == x"centos" ]]; then
        chkconfig --add "${1}"
        chkconfig "${1}" on
    fi
}

boot_stop(){
    if [[ x"${release}" == x"debian" || x"${release}" == x"ubuntu" ]]; then
        update-rc.d -f "${1}" remove
    elif [[ x"${release}" == x"centos" ]]; then
        chkconfig "${1}" off
        chkconfig --del "${1}"
    fi
}

# Get version
getversion(){
    if [[ -s /etc/redhat-release ]]; then
        grep -oE  "[0-9.]+" /etc/redhat-release
    else
        grep -oE  "[0-9.]+" /etc/issue
    fi
}

# CentOS version
centosversion(){
    if [[ x"${release}" == x"centos" ]]; then
        local code=$1
        local version="$(getversion)"
        local main_ver=${version%%.*}
        if [ "$main_ver" == "$code" ]; then
            return 0
        else
            return 1
        fi
    else
        return 1
    fi
}

get_opsy() {
    [ -f /etc/redhat-release ] && awk '{print ($1,$3~/^[0-9]/?$3:$4)}' /etc/redhat-release && return
    [ -f /etc/os-release ] && awk -F'[= "]' '/PRETTY_NAME/{print $3,$4,$5}' /etc/os-release && return
    [ -f /etc/lsb-release ] && awk -F'[="]+' '/DESCRIPTION/{print $2}' /etc/lsb-release && return
}

get_char() {
    SAVEDSTTY=$(stty -g)
    stty -echo
    stty cbreak
    dd if=/dev/tty bs=1 count=1 2> /dev/null
    stty -raw
    stty echo
    stty "$SAVEDSTTY"
}

set_firewall() {
    if centosversion 6; then
        /etc/init.d/iptables status > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            iptables -L -n | grep -i 1688 > /dev/null 2>&1
            if [ $? -ne 0 ]; then
                iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 1688 -j ACCEPT
                /etc/init.d/iptables save
                /etc/init.d/iptables restart
            fi
        else
            echo -e "${yellow}Warning:${plain} iptables looks like shutdown or not installed, please enable port 1688 manually set if necessary."
        fi
    elif centosversion 7; then
        systemctl status firewalld > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            firewall-cmd --permanent --zone=public --add-port=1688/tcp
            firewall-cmd --reload
        else
            echo -e "${yellow}Warning:${plain} firewalld looks like shutdown or not installed, please enable port 1688 manually set if necessary."
        fi
    fi
}

install_main() {
    [ -f /usr/bin/vlmcsd ] && echo -e "${yellow}Warning:${plain} KMS Server is already installed. nothing to do..." && exit 1

    clear
    opsy=$( get_opsy )
    arch=$( uname -m )
    lbit=$( getconf LONG_BIT )
    kern=$( uname -r )
    echo "---------- System Information ----------"
    echo " OS      : $opsy"
    echo " Arch    : $arch ($lbit Bit)"
    echo " Kernel  : $kern"
    echo "----------------------------------------"
    echo " Auto install KMS Server"
    echo
    echo " URL: https://teddysun.com/530.html"
    echo "----------------------------------------"
    echo
    echo "Press any key to start...or Press Ctrl+C to cancel"
    char=$(get_char)

    if [[ x"${release}" == x"centos" ]]; then
        yum -y install gcc git make nss curl libcurl
        if ! wget --no-check-certificate -O /etc/init.d/kms https://raw.githubusercontent.com/teddysun/across/master/kms; then
            echo -e "[${red}Error:${plain}] Failed to download KMS Server script."
            exit 1
        fi
    elif [[ x"${release}" == x"debian" || x"${release}" == x"ubuntu" ]]; then
        apt-get -y update
        apt-get install -y gcc git make libnss3 curl libcurl3-nss
        if ! wget --no-check-certificate -O /etc/init.d/kms https://raw.githubusercontent.com/teddysun/across/master/kms-debian; then
            echo -e "[${red}Error:${plain}] Failed to download KMS Server script."
            exit 1
        fi
    else
        echo -e "${red}Error:${plain} OS is not be supported, please change to CentOS/Debian/Ubuntu and try again."
        exit 1
    fi

    cd "${cur_dir}" || exit
    git clone https://github.com/Wind4/vlmcsd.git > /dev/null 2>&1
    [ -d vlmcsd ] && cd vlmcsd || echo -e "[${red}Error:${plain}] Failed to git clone vlmcsd."
    make
    if [ $? -ne 0 ]; then
        echo -e "${red}Error:${plain} Install KMS Server failed, please check it and try again."
        exit 1
    fi
    cp -p bin/vlmcsd /usr/bin/
    chmod 755 /usr/bin/vlmcsd
    chmod 755 /etc/init.d/kms
    boot_start kms
    /etc/init.d/kms start
    if [ $? -ne 0 ]; then
        echo -e "${red}Error:${plain} KMS server start failed."
    fi
    if [[ x"${release}" == x"centos" ]]; then
        set_firewall
    fi
    cd "${cur_dir}" || exit
    rm -rf vlmcsd
    echo
    echo "Install KMS Server success"
    echo "Welcome to visit:https://teddysun.com/530.html"
    echo "Enjoy it!"
    echo
}


install_kms() {
    install_main 2>&1 | tee "${cur_dir}"/install_kms.log
}

# Uninstall KMS Server
uninstall_kms() {
    printf "Are you sure uninstall KMS Server? (y/n) "
    printf "\n"
    read -p "(Default: n):" answer
    [ -z "${answer}" ] && answer="n"
    if [ "${answer}" == "y" ] || [ "${answer}" == "Y" ]; then
        /etc/init.d/kms status > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            /etc/init.d/kms stop
        fi
        boot_stop kms
        # delete kms server
        rm -f /usr/bin/vlmcsd
        rm -f /etc/init.d/kms
        rm -f /var/log/vlmcsd.log
        echo "KMS Server uninstall success"
    else
        echo
        echo "Uninstall cancelled, nothing to do..."
        echo
    fi
}

# Initialization step
action=$1
[ -z "$1" ] && action=install
case "$action" in
    install|uninstall)
        ${action}_kms
        ;;
    *)
        echo "Arguments error! [${action}]"
        echo "Usage: $(basename $0) [install|uninstall]"
        ;;
esac
