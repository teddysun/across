#!/usr/bin/env bash
#
# Description: Auto test download & I/O speed & network speed script
#
# Copyright (C) 2015 - 2026 Teddysun <i@teddysun.com>
# Thanks: LookBack <admin@dwhd.org>
# URL: https://teddysun.com/444.html
# https://github.com/teddysun/across/blob/master/bench.sh

trap _exit INT QUIT TERM

_red() {
    printf '\033[0;31;31m%b\033[0m' "${1}"
}

_green() {
    printf '\033[0;31;32m%b\033[0m' "${1}"
}

_yellow() {
    printf '\033[0;31;33m%b\033[0m' "${1}"
}

_blue() {
    printf '\033[0;31;36m%b\033[0m' "${1}"
}

_exists() {
    local cmd="${1}"
    if command -v "${cmd}" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

_exit() {
    _red "\nThe script has been terminated. Cleaning up files...\n"
    cleanup
    exit 1
}

next() {
    printf "%-70s\n" "-" | sed 's/\s/-/g'
}

cleanup() {
    rm -fr speedtest.tgz speedtest-cli benchtest_* 2>/dev/null
}

get_opsy() {
    if [[ -f /etc/os-release ]]; then
        awk -F= '/^PRETTY_NAME=/{gsub(/^"|"$/, "", $2); print $2}' /etc/os-release
    elif [[ -f /etc/lsb-release ]]; then
        awk -F= '/^DISTRIB_DESCRIPTION=/{gsub(/^"|"$/, "", $2); print $2}' /etc/lsb-release
    elif [[ -f /etc/redhat-release ]]; then
        cat /etc/redhat-release
    fi
}

get_arch() {
    local arch
    arch="$(uname -m)"
    case "${arch}" in
        x86_64|amd64)
            echo "x64"
            ;;
        i?86)
            echo "x86"
            ;;
        aarch64|arm64)
            echo "aarch64"
            ;;
        armv7*|armv8l)
            echo "arm"
            ;;
        armv6*)
            echo "arm"
            ;;
        *)
            echo "${arch}"
            ;;
    esac
}

speed_test() {
    local server_id="${1}"
    local nodeName="${2}"
    local logfile="./speedtest-cli/speedtest.log"

    if [ -z "${server_id}" ]; then
        ./speedtest-cli/speedtest --progress=no --accept-license --accept-gdpr >"${logfile}" 2>&1
    else
        ./speedtest-cli/speedtest --progress=no --server-id="${server_id}" --accept-license --accept-gdpr >"${logfile}" 2>&1
    fi
    # shellcheck disable=SC2181
    if [[ $? -ne 0 ]]; then
        printf "\033[0;33m%-18s\033[0;31m%-18s\033[0m\n" " ${nodeName}" "Test failed"
        return 1
    fi

    local dl_speed up_speed latency
    dl_speed=$(awk '/Download/{print $3" "$4}' "${logfile}")
    up_speed=$(awk '/Upload/{print $3" "$4}' "${logfile}")
    latency=$(awk '/Latency/{print $3" "$4}' "${logfile}")

    if [[ -n "${dl_speed}" && -n "${up_speed}" && -n "${latency}" ]]; then
        printf "\033[0;33m%-18s\033[0;32m%-18s\033[0;31m%-20s\033[0;36m%-12s\033[0m\n" " ${nodeName}" "${up_speed}" "${dl_speed}" "${latency}"
    else
        printf "\033[0;33m%-18s\033[0;31m%-18s\033[0m\n" " ${nodeName}" "Failed to parse results"
        return 1
    fi
}

speed() {
    speed_test '' 'Speedtest.net'
    speed_test '7190'  'Los Angeles, US'
    speed_test '22288' 'Dallas, US'
    speed_test '64420' 'Montreal, CA'
    speed_test '61933' 'Paris, FR'
    speed_test '41423' 'Amsterdam, NL'
    speed_test '5396'  'Suzhou, CN'
    speed_test '59387' 'Ningbo, CN'
    speed_test '32155' 'Hong Kong, CN'
    speed_test '13623' 'Singapore, SG'
    speed_test '65092' 'Taipei, CN'
    speed_test '48463' 'Tokyo, JP'
}

io_test() {
    local count="${1}"
    local result
    result=$( (LANG=C dd if=/dev/zero of=benchtest_$$ bs=512k count="${count}" conv=fdatasync 2>&1 && rm -f benchtest_$$) 2>&1 | awk -F '[,，]' '{io=$NF} END { print io}' | sed 's/^[ \t]*//;s/[ \t]*$//')
    echo "${result}"
}

calc_size() {
    local raw="${1}"
    local total_size=0
    local num=1
    local unit="KB"

    # Validate input is a number
    if ! [[ ${raw} =~ ^[0-9]+$ ]]; then
        echo ""
        return
    fi

    if [[ "${raw}" -eq 0 ]]; then
        echo "0 KB"
        return
    elif [[ "${raw}" -ge 1073741824 ]]; then
        num=1073741824
        unit="TB"
    elif [[ "${raw}" -ge 1048576 ]]; then
        num=1048576
        unit="GB"
    elif [[ "${raw}" -ge 1024 ]]; then
        num=1024
        unit="MB"
    fi

    total_size=$(awk 'BEGIN{printf "%.1f", '"${raw}"' / '"${num}"'}')
    echo "${total_size} ${unit}"
}

# Convert bytes to kibibytes (KiB)
to_kibyte() {
    local raw="${1}"
    if ! [[ ${raw} =~ ^[0-9]+$ ]]; then
        echo "0"
        return
    fi
    awk 'BEGIN{printf "%.0f", '"${raw}"' / 1024}'
}

calc_sum() {
    local arr=("$@")
    local s=0
    for i in "${arr[@]}"; do
        if [[ ${i} =~ ^[0-9]+$ ]]; then
            s=$((s + i))
        fi
    done
    echo ${s}
}

check_writable() {
    local testfile="bench_writable_test_$"
    if ! touch "${testfile}" 2>/dev/null; then
        _red "Error: No write permission in current directory.\n"
        _red "Please run this script in a directory with write permission.\n"
        exit 1
    fi
    rm -f "${testfile}"
}

check_virt() {

    # Prefer systemd-detect-virt if available
    if _exists "systemd-detect-virt"; then
        local sdvirt
        sdvirt=$(systemd-detect-virt 2>/dev/null)
        if [[ -n "${sdvirt}" ]] && [[ "${sdvirt}" != "none" ]]; then
            virt="${sdvirt^^}"
            return
        fi
    fi

    local virtualx=""
    local sys_manu=""
    local sys_product=""
    local sys_ver=""

    if _exists "dmidecode"; then
        sys_manu="$(dmidecode -s system-manufacturer 2>/dev/null)"
        sys_product="$(dmidecode -s system-product-name 2>/dev/null)"
        sys_ver="$(dmidecode -s system-version 2>/dev/null)"
    fi
    _exists "dmesg" && virtualx="$(dmesg 2>/dev/null)"

    if grep -qa docker /proc/1/cgroup 2>/dev/null; then
        virt="Docker"
    elif grep -qa lxc /proc/1/cgroup 2>/dev/null; then
        virt="LXC"
    elif grep -qa container=lxc /proc/1/environ 2>/dev/null; then
        virt="LXC"
    elif [[ -f /proc/user_beancounters ]]; then
        virt="OpenVZ"
    elif [[ "${virtualx}" == *kvm-clock* ]]; then
        virt="KVM"
    elif [[ "${sys_product}" == *KVM* ]]; then
        virt="KVM"
    elif [[ "${sys_manu}" == *QEMU* ]]; then
        virt="KVM"
    elif [[ "${cname}" == *KVM* ]]; then
        virt="KVM"
    elif [[ "${cname}" == *QEMU* ]]; then
        virt="KVM"
    elif [[ "${virtualx}" == *"VMware Virtual Platform"* ]]; then
        virt="VMware"
    elif [[ "${sys_product}" == *"VMware Virtual Platform"* ]]; then
        virt="VMware"
    elif [[ "${virtualx}" == *"Parallels Software International"* ]]; then
        virt="Parallels"
    elif [[ "${virtualx}" == *VirtualBox* ]]; then
        virt="VirtualBox"
    elif [[ -e /proc/xen ]]; then
        if grep -q "control_d" "/proc/xen/capabilities" 2>/dev/null; then
            virt="Xen-Dom0"
        else
            virt="Xen-DomU"
        fi
    elif [[ -f "/sys/hypervisor/type" ]] && grep -q "xen" "/sys/hypervisor/type" 2>/dev/null; then
        virt="Xen"
    elif [[ "${sys_manu}" == *"Microsoft Corporation"* ]]; then
        if [[ "${sys_product}" == *"Virtual Machine"* ]]; then
            if [[ "${sys_ver}" == *"7.0"* || "${sys_ver}" == *"Hyper-V"* ]]; then
                virt="Hyper-V"
            else
                virt="Microsoft Virtual Machine"
            fi
        fi
    fi

    # If still not detected, mark as Dedicated
    if [[ -z "${virt}" ]]; then
        virt="Dedicated"
    fi
}

ipv4_info() {
    local org city country region
    org="$(${ip_check_cmd} http://ipinfo.io/org)"
    city="$(${ip_check_cmd} http://ipinfo.io/city)"
    country="$(${ip_check_cmd} http://ipinfo.io/country)"
    region="$(${ip_check_cmd} http://ipinfo.io/region)"
    if [[ -n "${org}" ]]; then
        echo " Organization       : $(_blue "${org}")"
    fi
    if [[ -n "${city}" && -n "${country}" ]]; then
        echo " Location           : $(_blue "${city} / ${country}")"
    fi
    if [[ -n "${region}" ]]; then
        echo " Region             : $(_yellow "${region}")"
    fi
    if [[ -z "${org}" ]]; then
        echo " Region             : $(_red "No ISP detected")"
    fi
}

install_speedtest() {

    if [[ -e "./speedtest-cli/speedtest" ]]; then
        printf "%-18s%-18s%-20s%-12s\n" " Node Name" "Upload Speed" "Download Speed" "Latency"
        return 0
    fi

    sys_bit=""
    local sysarch
    sysarch="$(uname -m)"

    if [[ "${sysarch}" = "unknown" ]] || [[ -z "${sysarch}" ]]; then
        sysarch="$(arch)"
    fi

    case "${sysarch}" in
        x86_64|amd64)
            sys_bit="x86_64"
            ;;
        i386|i686)
            sys_bit="i386"
            ;;
        armv8|armv8l|aarch64|arm64)
            sys_bit="aarch64"
            ;;
        armv7|armv7l)
            sys_bit="armhf"
            ;;
        armv6|armv6l)
            sys_bit="armel"
            ;;
        *)
            _red "Error: Unsupported system architecture (${sysarch}).\n"
            exit 1
            ;;
    esac

    local url1 url2
    # https://www.speedtest.net/apps/cli
    url1="https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-${sys_bit}.tgz"
    url2="https://dl.lamp.sh/files/ookla-speedtest-1.2.0-linux-${sys_bit}.tgz"
    if ! wget --no-check-certificate -q -T10 -O speedtest.tgz "${url1}"; then
        if ! wget --no-check-certificate -q -T10 -O speedtest.tgz "${url2}"; then
            _red "Error: Failed to download speedtest-cli.\n"
            exit 1
        fi
    fi

    mkdir -p speedtest-cli && tar zxf speedtest.tgz -C ./speedtest-cli && chmod +x ./speedtest-cli/speedtest
    rm -f speedtest.tgz

    printf "%-18s%-18s%-20s%-12s\n" " Node Name" "Upload Speed" "Download Speed" "Latency"
}

print_intro() {
    echo "-------------------- A Bench.sh Script By Teddysun -------------------"
    echo " Version            : $(_green v2026-01-31)"
    echo " Usage              : $(_red "wget -qO- bench.sh | bash")"
}

# Get System information
get_system_info() {
    local arch_type
    arch_type=$(get_arch)
    
    # Use lscpu for ARM architectures if available
    if [[ "${arch_type}" == *arm* || "${arch_type}" == *aarch64* ]] && _exists "lscpu"; then
        cname=$(lscpu | grep "Model name" | sed 's/Model name:[ \t]*//g' | head -n1)
        cores=$(lscpu | grep "^CPU(s):" | sed 's/CPU(s):[ \t]*//g')
        local max_freq
        max_freq=$(lscpu | grep "CPU max MHz" | sed 's/CPU max MHz:[ \t]*//g')
        if [ -n "${max_freq}" ]; then
            freq="${max_freq}"
        else
            freq=$(awk -F'[ :]' '/cpu MHz/ {print $4;exit}' /proc/cpuinfo)
        fi
    else
        cname=$(awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//')
        cores=$(awk -F: '/^processor/ {core++} END {print core}' /proc/cpuinfo)
        freq=$(awk -F'[ :]' '/cpu MHz/ {print $4;exit}' /proc/cpuinfo)
    fi

    ccache=$(awk -F: '/cache size/ {cache=$2} END {print cache}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//')
    cpu_aes=$(grep -i 'aes' /proc/cpuinfo 2>/dev/null)
    cpu_virt=$(grep -Ei 'vmx|svm' /proc/cpuinfo 2>/dev/null)

    tram=$(LANG=C free | awk '/Mem/ {print $2}')
    tram=$(calc_size "${tram}")
    uram=$(LANG=C free | awk '/Mem/ {print $3}')
    uram=$(calc_size "${uram}")

    swap=$(LANG=C free | awk '/Swap/ {print $2}')
    swap=$(calc_size "${swap}")
    uswap=$(LANG=C free | awk '/Swap/ {print $3}')
    uswap=$(calc_size "${uswap}")

    up=$(awk '{a=$1/86400;b=($1%86400)/3600;c=($1%3600)/60} {printf("%d days, %d hour %d min\n",a,b,c)}' /proc/uptime)

    if _exists "w"; then
        load=$(LANG=C w | head -1 | awk -F'load average:' '{print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//')
    elif _exists "uptime"; then
        load=$(LANG=C uptime | head -1 | awk -F'load average:' '{print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//')
    fi

    opsy=$(get_opsy)
    arch=$(uname -m)

    if _exists "getconf"; then
        lbit=$(getconf LONG_BIT)
    else
        echo "${arch}" | grep -q "64" && lbit="64" || lbit="32"
    fi

    kern=$(uname -r)

    # Disk size calculation
    in_kernel_no_swap_total_size=$(
        LANG=C
        df -t simfs -t ext2 -t ext3 -t ext4 -t btrfs -t xfs -t vfat -t ntfs --total 2>/dev/null | grep total | awk '{ print $2 }'
    )
    swap_total_size=$(free -k | grep Swap | awk '{print $2}')
    zfs_total_size=$(to_kibyte "$(calc_sum "$(zpool list -o size -Hp 2>/dev/null)")")
    disk_total_size=$(calc_size $((swap_total_size + in_kernel_no_swap_total_size + zfs_total_size)))

    in_kernel_no_swap_used_size=$(
        LANG=C
        df -t simfs -t ext2 -t ext3 -t ext4 -t btrfs -t xfs -t vfat -t ntfs --total 2>/dev/null | grep total | awk '{ print $3 }'
    )
    swap_used_size=$(free -k | grep Swap | awk '{print $3}')
    zfs_used_size=$(to_kibyte "$(calc_sum "$(zpool list -o allocated -Hp 2>/dev/null)")")
    disk_used_size=$(calc_size $((swap_used_size + in_kernel_no_swap_used_size + zfs_used_size)))
    tcpctrl=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null)
}

# Print System information
print_system_info() {
    if [ -n "${cname}" ]; then
        echo " CPU Model          : $(_blue "${cname}")"
    else
        echo " CPU Model          : $(_blue "CPU model not detected")"
    fi
    if [ -n "${freq}" ]; then
        echo " CPU Cores          : $(_blue "${cores} @ ${freq} MHz")"
    else
        echo " CPU Cores          : $(_blue "${cores}")"
    fi
    if [ -n "${ccache}" ]; then
        echo " CPU Cache          : $(_blue "${ccache}")"
    fi
    if [ -n "${cpu_aes}" ]; then
        echo " AES-NI             : $(_green "\xe2\x9c\x93 Enabled")"
    else
        echo " AES-NI             : $(_red "\xe2\x9c\x97 Disabled")"
    fi
    if [ -n "${cpu_virt}" ]; then
        echo " VM-x/AMD-V         : $(_green "\xe2\x9c\x93 Enabled")"
    else
        echo " VM-x/AMD-V         : $(_red "\xe2\x9c\x97 Disabled")"
    fi
    echo " Total Disk         : $(_yellow "${disk_total_size}") $(_blue "(${disk_used_size} Used)")"
    echo " Total RAM          : $(_yellow "${tram}") $(_blue "(${uram} Used)")"
    if [[ "${swap}" != "0" && "${swap}" != "0 KB" && -n "${swap}" ]]; then
        echo " Total Swap         : $(_blue "${swap} (${uswap} Used)")"
    fi

    echo " System Uptime      : $(_blue "${up}")"
    echo " Load Average       : $(_blue "${load}")"
    echo " OS                 : $(_blue "${opsy}")"
    echo " Arch               : $(_blue "${arch} (${lbit} Bit)")"
    echo " Kernel             : $(_blue "${kern}")"
    echo " TCP Congestion Ctrl: $(_yellow "${tcpctrl}")"
    echo " Virtualization     : $(_blue "${virt}")"
    echo " IPv4/IPv6          : ${online}"
}

print_io_test() {
    local freespace
    freespace=$(df -m . | awk 'NR==2 {print $4}')
    if [ -z "${freespace}" ]; then
        freespace=$(df -m . | awk 'NR==3 {print $3}')
    fi

    if [ -z "${freespace}" ] || ! [[ "${freespace}" =~ ^[0-9]+$ ]]; then
        echo " $(_red "Unable to determine available space for I/O test!")"
        return 1
    fi

    if [ "${freespace}" -gt 1024 ]; then
        local writemb=2048
        io1=$(io_test ${writemb})
        echo " I/O Speed(1st run) : $(_yellow "$io1")"
        io2=$(io_test ${writemb})
        echo " I/O Speed(2nd run) : $(_yellow "$io2")"
        io3=$(io_test ${writemb})
        echo " I/O Speed(3rd run) : $(_yellow "$io3")"
        ioraw1=$(echo "$io1" | awk 'NR==1 {print $1}')
        [[ "$(echo "$io1" | awk 'NR==1 {print $2}')" == "GB/s" ]] && ioraw1=$(awk 'BEGIN{print '"$ioraw1"' * 1024}')
        ioraw2=$(echo "$io2" | awk 'NR==1 {print $1}')
        [[ "$(echo "$io2" | awk 'NR==1 {print $2}')" == "GB/s" ]] && ioraw2=$(awk 'BEGIN{print '"$ioraw2"' * 1024}')
        ioraw3=$(echo "$io3" | awk 'NR==1 {print $1}')
        [[ "$(echo "$io3" | awk 'NR==1 {print $2}')" == "GB/s" ]] && ioraw3=$(awk 'BEGIN{print '"$ioraw3"' * 1024}')
        ioall=$(awk 'BEGIN{print '"$ioraw1"' + '"$ioraw2"' + '"$ioraw3"'}')
        ioavg=$(awk 'BEGIN{printf "%.1f", '"$ioall"' / 3}')
        echo " I/O Speed(average) : $(_yellow "$ioavg MB/s")"
    else
        echo " $(_red "Not enough space for I/O Speed test!")"
    fi
}

print_end_time() {
    end_time=$(date +%s)
    time=$((end_time - start_time))
    if [ ${time} -gt 60 ]; then
        min=$((time / 60))
        sec=$((time % 60))
        echo " Finished in        : ${min} min ${sec} sec"
    else
        echo " Finished in        : ${time} sec"
    fi
    date_time=$(date '+%Y-%m-%d %H:%M:%S %Z')
    echo " Timestamp          : ${date_time}"
}

# Main execution starts here

# Check for required commands
! _exists "free" && _red "Error: free command not found.\n" && exit 1

# Check write permission
check_writable

# Set locale
export LC_ALL=C

# check for curl/wget
_exists "curl" && ip_check_cmd="curl -s -m 4"
_exists "wget" && ip_check_cmd="wget -qO- -T 4"

# Test IPv4/IPv6 connectivity
ipv4_check=$( (ping -4 -c 1 -W 4 ipv4.google.com >/dev/null 2>&1 && echo true) || ${ip_check_cmd} -4 icanhazip.com 2>/dev/null)
ipv6_check=$( (ping -6 -c 1 -W 4 ipv6.google.com >/dev/null 2>&1 && echo true) || ${ip_check_cmd} -6 icanhazip.com 2>/dev/null)

if [[ -z "${ipv4_check}" && -z "${ipv6_check}" ]]; then
    _yellow "Warning: Both IPv4 and IPv6 connectivity were not detected.\n"
fi

[[ -z "${ipv4_check}" ]] && online="$(_red "\xe2\x9c\x97 Offline")" || online="$(_green "\xe2\x9c\x93 Online")"
[[ -z "${ipv6_check}" ]] && online+=" / $(_red "\xe2\x9c\x97 Offline")" || online+=" / $(_green "\xe2\x9c\x93 Online")"

start_time=$(date +%s)
get_system_info
check_virt
clear
print_intro
next
print_system_info
ipv4_info
next
print_io_test
next
install_speedtest && speed && cleanup
next
print_end_time
next
