#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#
# This is a Shell script for configure and start L2TP/IPSec VPN server with Docker image
# 
# Copyright (C) 2018 Teddysun <i@teddysun.com>
#
# Reference URL:
# https://github.com/libreswan/libreswan
# https://github.com/xelerance/xl2tpd

rand(){
    index=0
    str=""
    for i in {a..z}; do arr[index]=${i}; index=$(expr ${index} + 1); done
    for i in {A..Z}; do arr[index]=${i}; index=$(expr ${index} + 1); done
    for i in {0..9}; do arr[index]=${i}; index=$(expr ${index} + 1); done
    for i in {1..10}; do str="$str${arr[$RANDOM%$index]}"; done
    echo ${str}
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
        read -p "Please enter Username:" user
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
    pass="$(rand)"
    echo "Please enter ${user}'s password:"
    read -p "(Default Password: ${pass}):" tmppass
    [ ! -z ${tmppass} ] && pass=${tmppass}
    pass_enc=$(openssl passwd -1 "${pass}")
    echo "${user} l2tpd ${pass} *" >> /etc/ppp/chap-secrets
    echo "${user}:${pass_enc}:xauth-psk" >> /etc/ipsec.d/passwd
    echo "Username (${user}) add completed."
}

del_user(){
    while :
    do
        read -p "Please enter Username you want to delete it:" user
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
    sed -i "/^\<${user}\>/d" /etc/ipsec.d/passwd
    echo "Username (${user}) delete completed."
}

mod_user(){
    while :
    do
        read -p "Please enter Username you want to change password:" user
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
    pass="$(rand)"
    echo "Please enter ${user}'s new password:"
    read -p "(Default Password: ${pass}):" tmppass
    [ ! -z ${tmppass} ] && pass=${tmppass}
    pass_enc=$(openssl passwd -1 "${pass}")
    sed -i "/^\<${user}\>/d" /etc/ppp/chap-secrets
    sed -i "/^\<${user}\>/d" /etc/ipsec.d/passwd
    echo "${user} l2tpd ${pass} *" >> /etc/ppp/chap-secrets
    echo "${user}:${pass_enc}:xauth-psk" >> /etc/ipsec.d/passwd
    echo "Username ${user}'s password has been changed."
}

action=$1
case ${action} in
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
