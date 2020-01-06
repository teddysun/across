#!/usr/bin/env bash
#
# This is a Shell script for configure and start WireGuard VPN server.
#
# Copyright (C) 2019 - 2020 Teddysun <i@teddysun.com>
#
# Reference URL:
# https://www.wireguard.com
# https://git.zx2c4.com/WireGuard
# https://teddysun.com/554.html

trap _exit INT QUIT TERM

_red() {
    printf '\033[1;31;31m%b\033[0m' "$1"
}

_green() {
    printf '\033[1;31;32m%b\033[0m' "$1"
}

_yellow() {
    printf '\033[1;31;33m%b\033[0m' "$1"
}

_printargs() {
    printf -- "%s" "[$(date)] "
    printf -- "%s" "$1"
    printf "\n"
}

_info() {
    _printargs "$@"
}

_warn() {
    printf -- "%s" "[$(date)] "
    _yellow "$1"
    printf "\n"
}

_error() {
    printf -- "%s" "[$(date)] "
    _red "$1"
    printf "\n"
    exit 2
}

_exit() {
    printf "\n"
    _red "$0 has been terminated."
    printf "\n"
    exit 1
}

_exists() {
    local cmd="$1"
    if eval type type > /dev/null 2>&1; then
        eval type "$cmd" > /dev/null 2>&1
    elif command > /dev/null 2>&1; then
        command -v "$cmd" > /dev/null 2>&1
    else
        which "$cmd" > /dev/null 2>&1
    fi
    rt="$?"
    return ${rt}
}

_ipv4() {
    local ipv4="$( ip addr | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | \
                   egrep -v "^192\.168|^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-2]\.|^10\.|^127\.|^255\.|^0\.|^169\.254\." | head -n 1 )"
    [ -z "${ipv4}" ] && ipv4="$( wget -qO- -t1 -T2 ipv4.icanhazip.com )"
    [ -z "${ipv4}" ] && ipv4="$( wget -qO- -t1 -T2 ipinfo.io/ip )"
    printf -- "%s" "${ipv4}"
}

_ipv6() {
    local ipv6=""
    ipv6="$(wget -qO- -t1 -T2 ipv6.icanhazip.com)"
    printf -- "%s" "${ipv6}"
}

_nic() {
    local nic=""
    nic="$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)"
    printf -- "%s" "${nic}"
}

_port() {
    local port="$(shuf -i 1024-20480 -n 1)"
    while true
    do
        if _exists "netstat" && netstat -tunlp | grep -w "${port}" > /dev/null 2>&1; then
            port="$(shuf -i 1024-20480 -n 1)"
        else
            break
        fi
    done
    printf -- "%s" "${port}"
}

_os() {
    local os=""
    [ -f "/etc/debian_version" ] && source /etc/os-release && os="${ID}" && printf -- "%s" "${os}" && return
    [ -f "/etc/fedora-release" ] && os="fedora" && printf -- "%s" "${os}" && return
    [ -f "/etc/redhat-release" ] && os="centos" && printf -- "%s" "${os}" && return
}

_os_full() {
    [ -f /etc/redhat-release ] && awk '{print ($1,$3~/^[0-9]/?$3:$4)}' /etc/redhat-release && return
    [ -f /etc/os-release ] && awk -F'[= "]' '/PRETTY_NAME/{print $3,$4,$5}' /etc/os-release && return
    [ -f /etc/lsb-release ] && awk -F'[="]+' '/DESCRIPTION/{print $2}' /etc/lsb-release && return
}

_os_ver() {
    local main_ver="$( echo $(_os_full) | grep -oE  "[0-9.]+")"
    printf -- "%s" "${main_ver%%.*}"
}

_error_detect() {
    local cmd="$1"
    _info "${cmd}"
    eval ${cmd} 1> /dev/null
    if [ $? -ne 0 ]; then
        _error "Execution command (${cmd}) failed, please check it and try again."
    fi
}

_version_gt(){
    test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" != "$1"
}

_is_installed() {
    if _exists "wg" && _exists "wg-quick"; then
        if [ -s "/lib/modules/$(uname -r)/extra/wireguard.ko" ] || [ -s "/lib/modules/$(uname -r)/extra/wireguard.ko.xz" ] \
           || [ -s "/lib/modules/$(uname -r)/updates/dkms/wireguard.ko" ]; then
            return 0
        else
            return 1
        fi
    else
        return 2
    fi
}

_get_latest_ver() {
    wireguard_ver="$(wget --no-check-certificate -qO- https://api.github.com/repos/WireGuard/wireguard-linux-compat/tags | grep 'name' | head -1 | cut -d\" -f4)"
    if [ -z "${wireguard_ver}" ]; then
        wireguard_ver="$(curl -Lso- https://api.github.com/repos/WireGuard/wireguard-linux-compat/tags | grep 'name' | head -1 | cut -d\" -f4)"
    fi
    wireguard_tools_ver="$(wget --no-check-certificate -qO- https://api.github.com/repos/WireGuard/wireguard-tools/tags | grep 'name' | head -1 | cut -d\" -f4)"
    if [ -z "${wireguard_tools_ver}" ]; then
        wireguard_tools_ver="$(curl -Lso- https://api.github.com/repos/WireGuard/wireguard-tools/tags | grep 'name' | head -1 | cut -d\" -f4)"
    fi
    if [ -z "${wireguard_ver}" ] || [ -z "${wireguard_tools_ver}" ]; then
        _error "Failed to get wireguard latest version from github"
    fi
}

# Check OS version
check_os() {
    _info "Check OS version"
    if _exists "virt-what"; then
        virt="$(virt-what)"
    elif _exists "systemd-detect-virt"; then
        virt="$(systemd-detect-virt)"
    fi
    if [ -n "${virt}" -a "${virt}" = "lxc" ]; then
        _error "Virtualization method is LXC, which is not supported."
    fi
    if [ -n "${virt}" -a "${virt}" = "openvz" ] || [ -d "/proc/vz" ]; then
        _error "Virtualization method is OpenVZ, which is not supported."
    fi
    [ -z "$(_os)" ] && _error "Not supported OS"
    case "$(_os)" in
        ubuntu)
            [ -n "$(_os_ver)" -a "$(_os_ver)" -lt 16 ] && _error "Not supported OS, please change to Ubuntu 16+ and try again."
            ;;
        debian|raspbian)
            [ -n "$(_os_ver)" -a "$(_os_ver)" -lt 8 ] &&  _error "Not supported OS, please change to De(Rasp)bian 8+ and try again."
            ;;
        fedora)
            [ -n "$(_os_ver)" -a "$(_os_ver)" -lt 29 ] && _error "Not supported OS, please change to Fedora 29+ and try again."
            ;;
        centos)
            [ -n "$(_os_ver)" -a "$(_os_ver)" -lt 7 ] &&  _error "Not supported OS, please change to CentOS 7+ and try again."
            ;;
        *)
            _error "Not supported OS"
            ;;
    esac
}

# Install from repository
install_wg_1() {
    _info "Install wireguard from repository"
    case "$(_os)" in
        ubuntu)
            _error_detect "add-apt-repository ppa:wireguard/wireguard"
            _error_detect "apt-get update"
            _error_detect "apt-get -y install linux-headers-$(uname -r)"
            _error_detect "apt-get -y install qrencode"
            _error_detect "apt-get -y install iptables"
            _error_detect "apt-get -y install wireguard"
            ;;
        debian)
            echo "deb http://deb.debian.org/debian/ unstable main" > /etc/apt/sources.list.d/unstable.list
            printf 'Package: *\nPin: release a=unstable\nPin-Priority: 90\n' > /etc/apt/preferences.d/limit-unstable
            _error_detect "apt-get update"
            _error_detect "apt-get -y install linux-headers-$(uname -r)"
            _error_detect "apt-get -y install qrencode"
            _error_detect "apt-get -y install iptables"
            _error_detect "apt-get -y install wireguard"
            ;;
        fedora)
            _error_detect "dnf -y copr enable jdoss/wireguard"
            _error_detect "dnf -y install kernel-devel"
            _error_detect "dnf -y install kernel-headers"
            _error_detect "dnf -y install qrencode"
            _error_detect "dnf -y install wireguard-dkms wireguard-tools"
            ;;
        centos)
            if [ -n "$(_os_ver)" -a "$(_os_ver)" -eq 7 ]; then
                _error_detect "curl -Lso /etc/yum.repos.d/wireguard.repo https://copr.fedorainfracloud.org/coprs/jdoss/wireguard/repo/epel-7/jdoss-wireguard-epel-7.repo"
            fi
            if [ -n "$(_os_ver)" -a "$(_os_ver)" -eq 8 ]; then
                _error_detect "curl -Lso /etc/yum.repos.d/wireguard.repo https://copr.fedorainfracloud.org/coprs/jdoss/wireguard/repo/epel-8/jdoss-wireguard-epel-8.repo"
            fi
            _error_detect "yum -y install epel-release"
            _error_detect "yum -y install kernel-devel"
            _error_detect "yum -y install kernel-headers"
            _error_detect "yum -y install qrencode"
            _error_detect "yum -y install wireguard-dkms wireguard-tools"
            ;;
        *)
            ;; # do nothing
    esac
    if ! _is_installed; then
        _error "Failed to install wireguard, the kernel is most likely not configured correctly"
    fi
}

# Install from source
install_wg_2() {
    _info "Install wireguard from source"
    case "$(_os)" in
        ubuntu|debian|raspbian)
            _error_detect "apt-get update"
            if [ ! -d "/usr/src/linux-headers-$(uname -r)" ]; then
                if [ "$(_os)" = "raspbian" ]; then
                    _error_detect "apt-get -y install raspberrypi-kernel-headers"
                else
                    _error_detect "apt-get -y install linux-headers-$(uname -r)"
                fi
            fi
            _error_detect "apt-get -y install qrencode"
            _error_detect "apt-get -y install iptables"
            _error_detect "apt-get -y install bc"
            _error_detect "apt-get -y install gcc"
            _error_detect "apt-get -y install make"
            _error_detect "apt-get -y install libmnl-dev"
            _error_detect "apt-get -y install libelf-dev"
            ;;
        fedora)
            [ ! -d "/usr/src/kernels/$(uname -r)" ] && _error_detect "dnf -y install kernel-headers" && _error_detect "dnf -y install kernel-devel"
            _error_detect "dnf -y install qrencode"
            _error_detect "dnf -y install bc"
            _error_detect "dnf -y install gcc"
            _error_detect "dnf -y install make"
            _error_detect "dnf -y install libmnl-devel"
            _error_detect "dnf -y install elfutils-libelf-devel"
            ;;
        centos)
            _error_detect "yum -y install epel-release"
            [ ! -d "/usr/src/kernels/$(uname -r)" ] && _error_detect "yum -y install kernel-headers" && _error_detect "yum -y install kernel-devel"
            _error_detect "yum -y install qrencode"
            _error_detect "yum -y install bc"
            _error_detect "yum -y install gcc"
            _error_detect "yum -y install make"
            _error_detect "yum -y install yum-utils"
            [ -n "$(_os_ver)" -a "$(_os_ver)" -eq 8 ] && _error_detect "yum-config-manager --enable PowerTools"
            _error_detect "yum -y install libmnl-devel"
            _error_detect "yum -y install elfutils-libelf-devel"
            ;;
        *)
            ;; # do nothing
    esac
    _get_latest_ver
    wireguard_name="wireguard-linux-compat-$(echo ${wireguard_ver} | grep -oE '[0-9.]+')"
    wireguard_url="https://github.com/WireGuard/wireguard-linux-compat/archive/${wireguard_ver}.tar.gz"
    wireguard_tools_name="wireguard-tools-$(echo ${wireguard_tools_ver} | grep -oE '[0-9.]+')"
    wireguard_tools_url="https://github.com/WireGuard/wireguard-tools/archive/${wireguard_tools_ver}.tar.gz"
    _error_detect "wget --no-check-certificate -qO ${wireguard_name}.tar.gz ${wireguard_url}"
    _error_detect "tar zxf ${wireguard_name}.tar.gz"
    _error_detect "cd ${wireguard_name}/src"
    _error_detect "make"
    _error_detect "make install"
    _error_detect "wget --no-check-certificate -qO ${wireguard_tools_name}.tar.gz ${wireguard_tools_url}"
    _error_detect "tar zxf ${wireguard_tools_name}.tar.gz"
    _error_detect "cd ${wireguard_tools_name}/src"
    _error_detect "make"
    _error_detect "make install"
    _error_detect "cd ${cur_dir} && rm -fr ${wireguard_name}.tar.gz ${wireguard_name}"
    _error_detect "rm -fr ${wireguard_tools_name}.tar.gz ${wireguard_tools_name}"
    if ! _is_installed; then
        _error "Failed to install wireguard, the kernel is most likely not configured correctly"
    fi
}

# Uninstall WireGuard
uninstall_wg() {
    if ! _is_installed; then
        _error "WireGuard is not installed"
    fi
    _info "Uninstall WireGuard start"
    # stop wireguard at first
    _error_detect "systemctl stop wg-quick@${SERVER_WG_NIC}"
    _error_detect "systemctl disable wg-quick@${SERVER_WG_NIC}"
    # if wireguard has been installed from repository
    if _exists "yum" && _exists "rpm"; then
        if rpm -qa | grep -q wireguard; then
            _error_detect "yum -y remove wireguard-dkms wireguard-tools"
        fi
    elif _exists "apt" && _exists "apt-get"; then
        if apt list --installed | grep -q wireguard; then
            _error_detect "apt-get -y remove wireguard"
        fi
    fi
    # if wireguard has been installed from source
    if _is_installed; then
        _error_detect "rm -f /usr/bin/wg"
        _error_detect "rm -f /usr/bin/wg-quick"
        _error_detect "rm -f /usr/share/man/man8/wg.8"
        _error_detect "rm -f /usr/share/man/man8/wg-quick.8"
        _exists "modprobe" && _error_detect "modprobe -r wireguard"
    fi
    [ -d "/etc/wireguard" ] && _error_detect "rm -fr /etc/wireguard"
    _info "Uninstall WireGuard completed"
}

# Create server interface
create_server_if() {
    SERVER_PRIVATE_KEY="$(wg genkey)"
    SERVER_PUBLIC_KEY="$(echo ${SERVER_PRIVATE_KEY} | wg pubkey)"
    CLIENT_PRIVATE_KEY="$(wg genkey)"
    CLIENT_PUBLIC_KEY="$(echo ${CLIENT_PRIVATE_KEY} | wg pubkey)"
    CLIENT_PRE_SHARED_KEY="$( wg genpsk )"
    _info "Create server interface: /etc/wireguard/${SERVER_WG_NIC}.conf"
    [ ! -d "/etc/wireguard" ] && mkdir -p "/etc/wireguard"
    if [ -n "${SERVER_PUB_IPV6}" ]; then
        cat > /etc/wireguard/${SERVER_WG_NIC}.conf <<EOF
[Interface]
Address = ${SERVER_WG_IPV4}/24,${SERVER_WG_IPV6}/64
ListenPort = ${SERVER_WG_PORT}
PrivateKey = ${SERVER_PRIVATE_KEY}

[Peer]
PublicKey = ${CLIENT_PUBLIC_KEY}
AllowedIPs = ${CLIENT_WG_IPV4}/32,${CLIENT_WG_IPV6}/128
PresharedKey = ${CLIENT_PRE_SHARED_KEY}
EOF
    else
        cat > /etc/wireguard/${SERVER_WG_NIC}.conf <<EOF
[Interface]
Address = ${SERVER_WG_IPV4}/24
ListenPort = ${SERVER_WG_PORT}
PrivateKey = ${SERVER_PRIVATE_KEY}

[Peer]
PublicKey = ${CLIENT_PUBLIC_KEY}
AllowedIPs = ${CLIENT_WG_IPV4}/32
PresharedKey = ${CLIENT_PRE_SHARED_KEY}
EOF
    fi
    chmod 600 /etc/wireguard/${SERVER_WG_NIC}.conf
}

# Create client interface
create_client_if() {
    _info "Create client interface: /etc/wireguard/${SERVER_WG_NIC}_client"
    if [ -n "${SERVER_PUB_IPV6}" ]; then
        cat > /etc/wireguard/${SERVER_WG_NIC}_client <<EOF
[Interface]
PrivateKey = ${CLIENT_PRIVATE_KEY}
Address = ${CLIENT_WG_IPV4}/24,${CLIENT_WG_IPV6}/64
DNS = ${CLIENT_DNS_1},${CLIENT_DNS_2}

[Peer]
PublicKey = ${SERVER_PUBLIC_KEY}
PresharedKey = ${CLIENT_PRE_SHARED_KEY}
AllowedIPs = 0.0.0.0/0,::/0
Endpoint = ${SERVER_PUB_IPV4}:${SERVER_WG_PORT}
EOF
    else
        cat > /etc/wireguard/${SERVER_WG_NIC}_client <<EOF
[Interface]
PrivateKey = ${CLIENT_PRIVATE_KEY}
Address = ${CLIENT_WG_IPV4}/24
DNS = ${CLIENT_DNS_1},${CLIENT_DNS_2}

[Peer]
PublicKey = ${SERVER_PUBLIC_KEY}
PresharedKey = ${CLIENT_PRE_SHARED_KEY}
AllowedIPs = 0.0.0.0/0
Endpoint = ${SERVER_PUB_IPV4}:${SERVER_WG_PORT}
EOF
    fi
    chmod 600 /etc/wireguard/${SERVER_WG_NIC}_client
}

# Generate a QR Code picture with default client interface
generate_qr() {
    _info "Generate a QR Code picture with client interface"
    _error_detect "qrencode -s8 -o /etc/wireguard/${SERVER_WG_NIC}_client.png < /etc/wireguard/${SERVER_WG_NIC}_client"
}

# Enable IP forwarding
enable_ip_forward() {
    _info "Enable IP forward"
    sed -i '/net.ipv4.ip_forward/d' /etc/sysctl.conf
    [ -n "${SERVER_PUB_IPV6}" ] && sed -i '/net.ipv6.conf.all.forwarding/d' /etc/sysctl.conf
    echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
    [ -n "${SERVER_PUB_IPV6}" ] && echo "net.ipv6.conf.all.forwarding = 1" >> /etc/sysctl.conf
    sysctl -p >/dev/null 2>&1
}

# Set firewall rules
set_firewall() {
    _info "Setting firewall rules"
    if _exists "firewall-cmd"; then
        if [ "$(firewall-cmd --state | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g")" = "running" ]; then
            default_zone="$(firewall-cmd --get-default-zone)"
            if [ "$(firewall-cmd --zone=${default_zone} --query-masquerade)" = "no" ]; then
                _error_detect "firewall-cmd --permanent --zone=${default_zone} --add-masquerade"
            fi
            if ! firewall-cmd --list-ports | grep -qw "${SERVER_WG_PORT}/udp"; then
                _error_detect "firewall-cmd --permanent --zone=${default_zone} --add-port=${SERVER_WG_PORT}/udp"
            fi
            _error_detect "firewall-cmd --reload"
        else
            _warn "Firewalld looks like not running, please start it and manually set"
        fi
    else
        if _exists "iptables"; then
            iptables -A INPUT -p udp --dport ${SERVER_WG_PORT} -j ACCEPT
            iptables -A FORWARD -i ${SERVER_WG_NIC} -j ACCEPT
            iptables -t nat -A POSTROUTING -o ${SERVER_PUB_NIC} -j MASQUERADE
            iptables-save > /etc/iptables.rules
            if [ -d "/etc/network/if-up.d" ]; then
                cat > /etc/network/if-up.d/iptables <<EOF
#!/bin/sh
/sbin/iptables-restore < /etc/iptables.rules
EOF
                chmod +x /etc/network/if-up.d/iptables
            fi
        fi
        if _exists "ip6tables"; then
            ip6tables -A INPUT -p udp --dport ${SERVER_WG_PORT} -j ACCEPT
            ip6tables -A FORWARD -i ${SERVER_WG_NIC} -j ACCEPT
            ip6tables -t nat -A POSTROUTING -o ${SERVER_PUB_NIC} -j MASQUERADE
            ip6tables-save > /etc/ip6tables.rules
            if [ -d "/etc/network/if-up.d" ]; then
                cat > /etc/network/if-up.d/ip6tables <<EOF
#!/bin/sh
/sbin/ip6tables-restore < /etc/ip6tables.rules
EOF
                chmod +x /etc/network/if-up.d/ip6tables
            fi
        fi
    fi
}

# WireGuard installation completed
install_completed() {
    _info "Starting WireGuard via wg-quick for ${SERVER_WG_NIC}"
    _error_detect "systemctl daemon-reload"
    _error_detect "systemctl start wg-quick@${SERVER_WG_NIC}"
    _error_detect "systemctl enable wg-quick@${SERVER_WG_NIC}"
    _info "WireGuard VPN Server installation completed"
    _info "WireGuard VPN default client file is below:"
    _info "$(_green "/etc/wireguard/${SERVER_WG_NIC}_client")"
    _info "WireGuard VPN default client QR Code is below:"
    _info "$(_green "/etc/wireguard/${SERVER_WG_NIC}_client.png")"
    _info "Download and scan this QR Code with your phone"
    _info "Welcome to visit: https://teddysun.com/554.html"
    _info "Enjoy it"
}

add_client() {
    if ! _is_installed; then
        _red "WireGuard was not installed, please install it and try again\n" && exit 1
    fi
    default_server_if="/etc/wireguard/${SERVER_WG_NIC}.conf"
    default_client_if="/etc/wireguard/${SERVER_WG_NIC}_client"
    [ ! -s "${default_server_if}" ] && echo "The default server interface ($(_red ${default_server_if})) does not exists" && exit 1
    [ ! -s "${default_client_if}" ] && echo "The default client interface ($(_red ${default_client_if})) does not exists" && exit 1
    while true
    do
        read -p "Please enter a client name (for example: wg1):" client
        if [ -z "${client}" ]; then
            _red "Client name can not be empty\n"
        else
            new_client_if="/etc/wireguard/${client}_client"
            if [ "${client}" = "${SERVER_WG_NIC}" ]; then
                echo "The default client ($(_yellow ${client})) already exists. Please re-enter it"
            elif [ -s "${new_client_if}" ]; then
                echo "The client ($(_yellow ${client})) already exists. Please re-enter it"
            else
                break
            fi
        fi
    done
    # Get information from default interface file
    client_files=($(find /etc/wireguard -name "*_client" | sort))
    client_ipv4=()
    client_ipv6=()
    for ((i=0; i<${#client_files[@]}; i++)); do
        tmp_ipv4="$(grep -w "Address" ${client_files[$i]} | awk '{print $3}' | cut -d\/ -f1 )"
        tmp_ipv6="$(grep -w "Address" ${client_files[$i]} | awk '{print $3}' | awk -F, '{print $2}' | cut -d\/ -f1 )"
        client_ipv4=(${client_ipv4[@]} ${tmp_ipv4})
        client_ipv6=(${client_ipv6[@]} ${tmp_ipv6})
    done
    # Sort array
    client_ipv4_sorted=($(printf '%s\n' "${client_ipv4[@]}" | sort))
    index=$(expr ${#client_ipv4[@]} - 1)
    last_ip=$(echo ${client_ipv4_sorted[$index]} | cut -d. -f4)
    issue_ip_last=$(expr ${last_ip} + 1)
    [ ${issue_ip_last} -gt 254 ] && _red "Too many client, IP addresses might not be enough\n" && exit 1
    ipv4_comm=$(echo ${client_ipv4[$index]} | cut -d. -f1-3)
    ipv6_comm=$(echo ${client_ipv6[$index]} | awk -F: '{print $1":"$2":"$3":"$4}')
    CLIENT_PRIVATE_KEY="$(wg genkey)"
    CLIENT_PUBLIC_KEY="$(echo ${CLIENT_PRIVATE_KEY} | wg pubkey)"
    SERVER_PUBLIC_KEY="$(grep -w "PublicKey" ${default_client_if} | awk '{print $3}')"
    CLIENT_ENDPOINT="$(grep -w "Endpoint" ${default_client_if} | awk '{print $3}')"
    CLIENT_PRE_SHARED_KEY="$(grep -w "PresharedKey" ${default_client_if} | awk '{print $3}')"
    CLIENT_WG_IPV4="${ipv4_comm}.${issue_ip_last}"
    CLIENT_WG_IPV6="${ipv6_comm}:${issue_ip_last}"
    # Create a new client interface
    if [ -n "${SERVER_PUB_IPV6}" ]; then
        cat > ${new_client_if} <<EOF
[Interface]
PrivateKey = ${CLIENT_PRIVATE_KEY}
Address = ${CLIENT_WG_IPV4}/24,${CLIENT_WG_IPV6}/64
DNS = ${CLIENT_DNS_1},${CLIENT_DNS_2}

[Peer]
PublicKey = ${SERVER_PUBLIC_KEY}
PresharedKey = ${CLIENT_PRE_SHARED_KEY}
AllowedIPs = 0.0.0.0/0,::/0
Endpoint = ${CLIENT_ENDPOINT}
EOF
        # Add a new client to default server interface
        cat >> ${default_server_if} <<EOF

[Peer]
PublicKey = ${CLIENT_PUBLIC_KEY}
AllowedIPs = ${CLIENT_WG_IPV4}/32,${CLIENT_WG_IPV6}/128
PresharedKey = ${CLIENT_PRE_SHARED_KEY}
EOF
    else
        cat > ${new_client_if} <<EOF
[Interface]
PrivateKey = ${CLIENT_PRIVATE_KEY}
Address = ${CLIENT_WG_IPV4}/24
DNS = ${CLIENT_DNS_1},${CLIENT_DNS_2}

[Peer]
PublicKey = ${SERVER_PUBLIC_KEY}
PresharedKey = ${CLIENT_PRE_SHARED_KEY}
AllowedIPs = 0.0.0.0/0
Endpoint = ${CLIENT_ENDPOINT}
EOF
        cat >> ${default_server_if} <<EOF

[Peer]
PublicKey = ${CLIENT_PUBLIC_KEY}
AllowedIPs = ${CLIENT_WG_IPV4}/32
PresharedKey = ${CLIENT_PRE_SHARED_KEY}
EOF
    fi
    chmod 600 ${new_client_if}
    echo "Add a WireGuard client ($(_green ${client})) completed"
    systemctl restart wg-quick@${SERVER_WG_NIC}
    # Generate a new QR Code picture
    qrencode -s8 -o ${new_client_if}.png < ${new_client_if}
    echo "Generate a QR Code picture with new client ($(_green ${client})) completed"
    echo
    echo "WireGuard VPN new client ($(_green ${client})) file is below:"
    _green "/etc/wireguard/${client}_client\n"
    echo
    echo "WireGuard VPN new client ($(_green ${client})) QR Code is below:"
    _green "/etc/wireguard/${client}_client.png\n"
    echo "Download and scan this QR Code with your phone, enjoy it"
}

remove_client() {
    if ! _is_installed; then
        _red "WireGuard was not installed, please install it and try again\n" && exit 1
    fi
    default_server_if="/etc/wireguard/${SERVER_WG_NIC}.conf"
    [ ! -s "${default_server_if}" ] && echo "The default server interface ($(_red ${default_server_if})) does not exists" && exit 1
    while true
    do
        read -p "Please enter a client name you want to delete it (for example: wg1):" client
        if [ -z "${client}" ]; then
            _red "Client name can not be empty\n"
        else
            if [ "${client}" = "${SERVER_WG_NIC}" ]; then
                echo "The default client ($(_yellow ${client})) can not be delete"
            else
                break
            fi
        fi
    done
    client_if="/etc/wireguard/${client}_client"
    [ ! -s "${client_if}" ] && echo "The client file ($(_red ${client_if})) does not exists" && exit 1
    tmp_tag="$(grep -w "Address" ${client_if} | awk '{print $3}' | cut -d\/ -f1 )"
    [ -n "${tmp_tag}" ] && sed -i '/'"$tmp_tag"'/,+1d;:a;1,3!{P;$!N;D};N;ba' ${default_server_if}
    # Delete client interface file
    rm -f ${client_if}
    [ -s "/etc/wireguard/${client}_client.png" ] && rm -f /etc/wireguard/${client}_client.png
    systemctl restart wg-quick@${SERVER_WG_NIC}
    echo "The client name ($(_green ${client})) has been deleted"
}

list_clients() {
    if ! _is_installed; then
        _red "WireGuard was not installed, please install it and try again\n" && exit 1
    fi
    default_server_if="/etc/wireguard/${SERVER_WG_NIC}.conf"
    [ ! -s "${default_server_if}" ] && echo "The default server interface ($(_red ${default_server_if})) does not exists" && exit 1
    local line="+-------------------------------------------------------------------------+\n"
    local string=%-35s
    printf "${line}|${string} |${string} |\n${line}" " Client Interface" " Client's IP"
    client_files=($(find /etc/wireguard -name "*_client" | sort))
    ips=($(grep -w "AllowedIPs" ${default_server_if} | awk '{print $3}'))
    [ ${#client_files[@]} -ne ${#ips[@]} ] && echo "One or more client interface file is missing in /etc/wireguard" && exit 1
    for ((i=0; i<${#ips[@]}; i++)); do
        tmp_ipv4="$(echo ${ips[$i]} | cut -d\/ -f1)"
        for ((j=0; j<${#client_files[@]}; j++)); do
            if grep -qw "${tmp_ipv4}" "${client_files[$j]}"; then
                printf "|${string} |${string} |\n" " ${client_files[$j]}" " ${ips[$i]}"
                break
            fi
        done
    done
    printf ${line}
}

check_version() {
    _is_installed
    rt=$?
    if [ ${rt} -eq 0 ]; then
        _exists "modinfo" && installed_wg_ver="$(modinfo -F version wireguard)"
        [ -n "${installed_wg_ver}" ] && echo "WireGuard version: $(_green ${installed_wg_ver})" && return 0
    elif [ ${rt} -eq 1 ]; then
        _red "WireGuard kernel module does not exists\n" && return 1
    elif [ ${rt} -eq 2 ]; then
        _red "WireGuard was not installed\n" && return 2
    fi
}

show_help() {
    printf "
Usage  : $0 [Options]
Options:
        -h, --help       Print this help text and exit
        -r, --repo       Install WireGuard from repository
        -s, --source     Install WireGuard from source
        -u, --update     Upgrade WireGuard from source
        -v, --version    Print WireGuard version if installed
        -a, --add        Add a WireGuard client
        -d, --del        Delete a WireGuard client
        -l, --list       List all WireGuard client's IP
        -n, --uninstall  Uninstall WireGuard

"
}

install_from_repo() {
    _is_installed && check_version && _red "WireGuard was already installed\n" && exit 0
    check_os
    install_wg_1
    create_server_if
    create_client_if
    generate_qr
    enable_ip_forward
    set_firewall
    install_completed
}

install_from_source() {
    _is_installed && check_version && _red "WireGuard was already installed\n" && exit 0
    check_os
    install_wg_2
    create_server_if
    create_client_if
    generate_qr
    enable_ip_forward
    set_firewall
    install_completed
}

update_from_source() {
    if check_version > /dev/null 2>&1; then
        _get_latest_ver
        wg_ver="$(echo ${wireguard_ver} | grep -oE '[0-9.]+')"
        _info "WireGuard version: $(_green ${installed_wg_ver})"
        _info "WireGuard latest version: $(_green ${wg_ver})"
        if _version_gt "${wg_ver}" "${installed_wg_ver}"; then
            _info "Starting upgrade WireGuard"
            install_wg_2
            _error_detect "systemctl daemon-reload"
            _error_detect "systemctl restart wg-quick@${SERVER_WG_NIC}"
            _info "Update WireGuard completed"
        else
            _info "There is no update available for WireGuard"
        fi
    else
        _red "WireGuard was not installed, maybe you need to install it at first\n"
    fi
}

cur_dir="$(pwd)"

[ ${EUID} -ne 0 ] && _red "This script must be run as root\n" && exit 1

SERVER_PUB_IPV4="${VPN_SERVER_PUB_IPV4:-$(_ipv4)}"
SERVER_PUB_IPV6="${VPN_SERVER_PUB_IPV6:-$(_ipv6)}"
SERVER_PUB_NIC="${VPN_SERVER_PUB_NIC:-$(_nic)}"
SERVER_WG_NIC="${VPN_SERVER_WG_NIC:-wg0}"
SERVER_WG_IPV4="${VPN_SERVER_WG_IPV4:-10.88.88.1}"
SERVER_WG_IPV6="${VPN_SERVER_WG_IPV6:-fd88:88:88::1}"
SERVER_WG_PORT="${VPN_SERVER_WG_PORT:-$(_port)}"
CLIENT_WG_IPV4="${VPN_CLIENT_WG_IPV4:-10.88.88.2}"
CLIENT_WG_IPV6="${VPN_CLIENT_WG_IPV6:-fd88:88:88::2}"
CLIENT_DNS_1="${VPN_CLIENT_DNS_1:-1.1.1.1}"
CLIENT_DNS_2="${VPN_CLIENT_DNS_2:-8.8.8.8}"

main() {
    action="$1"
    [ -z "${action}" ] && show_help && exit 0
    case "${action}" in
        -h|--help)
            show_help
            ;;
        -r|--repo)
            install_from_repo
            ;;
        -s|--source)
            install_from_source
            ;;
        -u|--update)
            update_from_source
            ;;
        -v|--version)
            check_version
            ;;
        -a|--add)
            add_client
            ;;
        -d|--del)
            remove_client
            ;;
        -l|--list)
            list_clients
            ;;
        -n|--uninstall)
            uninstall_wg
            ;;
        *)
            show_help
            ;;
    esac
}

main "$@"
