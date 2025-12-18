#!/usr/bin/env bash
#
# Description: A Bench Script by Teddysun
#
# Copyright (C) 2015 - 2025 Teddysun <i@teddysun.com>
# Thanks: LookBack <admin@dwhd.org>
# URL: https://teddysun.com/444.html
# https://github.com/teddysun/across/blob/master/bench.sh
#
trap _exit INT QUIT TERM

_red() { printf '\033[0;31;31m%b\033[0m' "$1"; }
_green() { printf '\033[0;31;32m%b\033[0m' "$1"; }
_yellow() { printf '\033[0;31;33m%b\033[0m' "$1"; }
_blue() { printf '\033[0;31;36m%b\033[0m' "$1"; }
_purple() { printf '\033[0;35m%b\033[0m' "$1"; }

stop_speedtest=0
start_time=$(date +%s)

_exit() {
    printf "\nCleaning up...\n"
    rm -fr speedtest.tgz speedtest-cli benchtest_*
    exit 1
}

_exists() {
    command -v "$1" >/dev/null 2>&1
}

next() {
    printf "%-70s\n" "-" | sed 's/\s/-/g'
}

calc_size() {
    local raw=$1
    if [[ ! $raw =~ ^[0-9]+$ ]]; then echo ""; return; fi
    if [ "$raw" -ge 1073741824 ]; then
        echo "$(awk -v num=$raw 'BEGIN{printf "%.1f", num / 1073741824}') TB"
    elif [ "$raw" -ge 1048576 ]; then
        echo "$(awk -v num=$raw 'BEGIN{printf "%.1f", num / 1048576}') GB"
    elif [ "$raw" -ge 1024 ]; then
        echo "$(awk -v num=$raw 'BEGIN{printf "%.1f", num / 1024}') MB"
    else
        echo "${raw} KB"
    fi
}

get_swap_details() {
    local swap_list=""
    local zswap_status="Disabled"
    
    if [ -f /sys/module/zswap/parameters/enabled ]; then
        [ "$(cat /sys/module/zswap/parameters/enabled 2>/dev/null)" == "Y" ] && zswap_status="Enabled"
    fi

    if [ -f /proc/swaps ]; then
        while read -r filename type size used priority; do
            if [[ "$filename" == "/dev/zram"* ]]; then
                swap_list="${swap_list}ZRAM, "
            elif [[ "$type" == "file" ]]; then
                swap_list="${swap_list}File, "
            elif [[ "$type" == "partition" ]]; then
                swap_list="${swap_list}Partition, "
            fi
        done < <(tail -n +2 /proc/swaps)
    fi
    
    swap_list=$(echo "$swap_list" | sed 's/, $//')
    [ -z "$swap_list" ] && swap_list="None"
    
    echo "$swap_list (ZSwap: $zswap_status)"
}

get_system_info() {
    if _exists "lscpu"; then
        local l3_check=$(lscpu | grep -i "L3 cache" | awk -F: '{print $2}' | xargs)
        local l2_check=$(lscpu | grep -i "L2 cache" | awk -F: '{print $2}' | xargs)
        
        if [ -n "$l3_check" ]; then
            ccache="$l3_check (L3)"
        elif [ -n "$l2_check" ]; then
            ccache="$l2_check (L2)"
        else
            ccache="Unknown"
        fi
        
        cname=$(lscpu | grep "Model name" | awk -F: '{print $2}' | xargs)
        [ -z "$cname" ] && cname=$(awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo | xargs)
        
    else
        ccache=$(awk -F: '/cache size/ {cache=$2} END {print cache}' /proc/cpuinfo | xargs)
        cname=$(awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo | xargs)
    fi

    if [ -f /proc/cpuinfo ]; then
        cores=$(awk -F: '/^processor/ {core++} END {print core}' /proc/cpuinfo)
        freq=$(awk -F'[ :]' '/cpu MHz/ {print $4;exit}' /proc/cpuinfo)
        
        if grep -qE 'aes|aes-ni' /proc/cpuinfo; then
            cpu_aes="Enabled"
        elif _exists "lscpu" && lscpu | grep -qi "aes"; then
            cpu_aes="Enabled"
        else
            cpu_aes="Disabled"
        fi

        cpu_virt=$(grep -Ei 'vmx|svm' /proc/cpuinfo && echo "Enabled" || echo "Disabled")
    fi

    if _exists "free"; then
        local free_output
        free_output=$(free -k | awk '
            /Mem/ {t=$2; u=$3}
            /Swap/ {st=$2; su=$3}
            END {print t, u, st, su}
        ')
        read -r tram uram swap uswap <<< "$free_output"
        
        local swap_total_bytes=$(awk "BEGIN {print $swap * 1024}")
        local swap_used_bytes=$(awk "BEGIN {print $uswap * 1024}")
        
        tram=$(calc_size "$tram")
        uram=$(calc_size "$uram")
        swap=$(calc_size "$swap")
        uswap=$(calc_size "$uswap")
    fi
    
    swap_details=$(get_swap_details)

    up=$(awk '{a=$1/86400;b=($1%86400)/3600;c=($1%3600)/60} {printf("%d days, %d hour %d min\n",a,b,c)}' /proc/uptime)
    load=$(uptime | awk -F'load average:' '{print $2}' | xargs)

    if [ -f /etc/os-release ]; then
        opsy=$(awk -F'[= "]' '/PRETTY_NAME/{print $3,$4,$5}' /etc/os-release)
    elif [ -f /etc/redhat-release ]; then
        opsy=$(cat /etc/redhat-release)
    elif [ -f /etc/lsb-release ]; then
        opsy=$(awk -F'[="]+' '/DESCRIPTION/{print $2}' /etc/lsb-release)
    else
        opsy="Unknown"
    fi

    arch=$(uname -m)
    kern=$(uname -r)
    tcpctrl=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null)

    local disk_total_bytes=0
    local disk_used_bytes=0
    
    while read -r line; do
        local size=$(echo "$line" | awk '{print $2}')
        local used=$(echo "$line" | awk '{print $3}')
        disk_total_bytes=$(awk "BEGIN {print $disk_total_bytes + $size}")
        disk_used_bytes=$(awk "BEGIN {print $disk_used_bytes + $used}")
    done < <(df -P -B1 2>/dev/null | grep -vE 'tmpfs|devtmpfs|overlay|run|none|squashfs')

    local total_system_bytes=$(awk "BEGIN {print $disk_total_bytes + $swap_total_bytes}")
    local total_used_bytes=$(awk "BEGIN {print $disk_used_bytes + $swap_used_bytes}")
    
    disk_total_size=$(calc_size "$total_system_bytes")
    disk_used_size=$(calc_size "$total_used_bytes")
}

check_virt() {
    if [ -f /systemd-detect-virt ]; then
        virt=$(systemd-detect-virt)
    elif [ -f /usr/bin/systemd-detect-virt ]; then
        virt=$(/usr/bin/systemd-detect-virt)
    else
        virt="Unknown"
        if grep -qa docker /proc/1/cgroup; then virt="Docker"; fi
        if grep -qa lxc /proc/1/cgroup; then virt="LXC"; fi
        if [[ -f /proc/user_beancounters ]]; then virt="OpenVZ"; fi
        if [[ $(dmesg 2>/dev/null) == *kvm-clock* ]]; then virt="KVM"; fi
    fi
    [ -z "$virt" ] && virt="Dedicated"
}

print_cpu_info() {
    echo " $(_purple "[ CPU & Processor ]")"
    echo " CPU Model          : $(_blue "$cname")"
    echo " CPU Cores          : $(_blue "$cores @ $freq MHz")"
    echo " CPU Cache          : $(_blue "$ccache")"
    echo " AES-NI             : $([[ "$cpu_aes" == "Enabled" ]] && _green "\xe2\x9c\x93 Enabled" || _red "\xe2\x9c\x97 Disabled")"
    echo " VM-x/AMD-V         : $([[ "$cpu_virt" == "Enabled" ]] && _green "\xe2\x9c\x93 Enabled" || _red "\xe2\x9c\x97 Disabled")"
}

print_mem_disk_info() {
    echo " $(_purple "[ Memory & Storage ]")"
    echo " Total Disk         : $(_yellow "$disk_total_size") $(_blue "($disk_used_size Used)")"
    echo " Total Mem          : $(_yellow "$tram") $(_blue "($uram Used)")"
    echo " Total Swap         : $(_blue "$swap ($uswap Used)")"
    echo " Swap Type          : $(_blue "$swap_details")"
}

print_basic_system_info() {
    echo " $(_purple "[ System Basic Info ]")"
    echo " OS                 : $(_blue "$opsy")"
    echo " Arch               : $(_blue "$arch")"
    echo " Kernel             : $(_blue "$kern")"
    echo " System uptime      : $(_blue "$up")"
    echo " Load average       : $(_blue "$load")"
    echo " TCP CC             : $(_yellow "$tcpctrl")"
    echo " Virtualization     : $(_blue "$virt")"
}

print_network_info() {
    echo " $(_purple "[ Network & ISP ]")"
    local data
    data=$(curl -s --connect-timeout 5 http://ipinfo.io/json)
    if [ -n "$data" ]; then
        local org city country region
        org=$(echo "$data" | grep '"org":' | cut -d'"' -f4)
        city=$(echo "$data" | grep '"city":' | cut -d'"' -f4)
        country=$(echo "$data" | grep '"country":' | cut -d'"' -f4)
        region=$(echo "$data" | grep '"region":' | cut -d'"' -f4)
        
        [[ -n "$org" ]] && echo " Organization       : $(_blue "$org")"
        [[ -n "$city" && -n "$country" ]] && echo " Location           : $(_blue "$city / $country")"
        [[ -n "$region" ]] && echo " Region             : $(_yellow "$region")"
    else
        echo " Region             : $(_red "No ISP detected")"
    fi
}

io_test() {
    echo " $(_purple "[ I/O Speed Test ]")"
    
    local freespace=$(df -k . | awk 'NR==2 {print $4}')
    local count=1024
    
    if [ "$freespace" -ge 2097152 ]; then
        count=2048
    elif [ "$freespace" -ge 1048576 ]; then
        count=1024
    elif [ "$freespace" -ge 524288 ]; then
        count=512
    else
        echo " $(_red "Not enough space for I/O Test (Need > 512MB)")"
        return
    fi
    
    local speed_sum=0
    for i in {1..3}; do
        local raw_output
        raw_output=$(LANG=C dd if=/dev/zero of=benchtest_$$ bs=1M count=$count conv=fdatasync 2>&1 | grep "copied")
        rm -f benchtest_$$

        local val=$(echo "$raw_output" | awk -F, '{print $NF}' | awk '{print $1}')
        local unit=$(echo "$raw_output" | awk -F, '{print $NF}' | awk '{print $2}')
        local result=0

        if [[ "$unit" == "GB/s" ]]; then
            result=$(awk "BEGIN {print $val * 1024}")
        elif [[ "$unit" == "MB/s" ]]; then
            result=$val
        elif [[ "$unit" == "kB/s" ]]; then
            result=$(awk "BEGIN {print $val / 1024}")
        else
            result=$val
        fi
        
        [[ -z "$result" ]] && result=0
        
        echo " Run $i ($count MB)   : $(_yellow "$result MB/s")"
        speed_sum=$(awk "BEGIN {print $speed_sum + $result}")
    done
    echo " Average            : $(_yellow "$(awk "BEGIN {printf \"%.1f\", $speed_sum / 3}") MB/s")"
}

speed_test() {
    local nodeName="$2"
    local args="--progress=no --accept-license --accept-gdpr --format=json"
    [ -n "$1" ] && args="$args --server-id=$1"
    
    local json_out
    json_out=$(./speedtest-cli/speedtest $args 2>&1)
    
    if [[ "$json_out" =~ "Too many requests" ]] || [[ "$json_out" =~ "limit" ]]; then
        printf "\033[0;33m%-18s\033[0;31m%-20s\033[0m\n" " ${nodeName}" "Rate Limited (Skipping all)"
        stop_speedtest=1
        return
    elif [[ -z "$json_out" ]] || [[ "$json_out" =~ "error" ]]; then
        printf "\033[0;33m%-18s\033[0;31m%-20s\033[0m\n" " ${nodeName}" "Failed (Socket/Network Error)"
        return
    fi
    
    local dl_bytes up_bytes latency
    dl_bytes=$(echo "$json_out" | sed -n 's/.*"download":{[^}]*"bandwidth":\([0-9]*\).*/\1/p')
    up_bytes=$(echo "$json_out" | sed -n 's/.*"upload":{[^}]*"bandwidth":\([0-9]*\).*/\1/p')
    latency=$(echo "$json_out" | sed -n 's/.*"latency":{[^}]*"iqm":\([0-9.]*\).*/\1/p')
    
    if [[ -n "$dl_bytes" && -n "$up_bytes" ]]; then
        local dl_mbps=$(awk "BEGIN {printf \"%.2f\", $dl_bytes * 8 / 1000000}")
        local up_mbps=$(awk "BEGIN {printf \"%.2f\", $up_bytes * 8 / 1000000}")
        local lat_ms=$(awk "BEGIN {printf \"%.2f\", $latency}")

        printf "\033[0;33m%-18s\033[0;32m%-18s\033[0;31m%-20s\033[0;36m%-12s\033[0m\n" " ${nodeName}" "${up_mbps} Mbps" "${dl_mbps} Mbps" "${lat_ms} ms"
    else
         printf "\033[0;33m%-18s\033[0;31m%-20s\033[0m\n" " ${nodeName}" "Invalid JSON Data"
    fi
}

run_speedtest() {
    echo " $(_purple "[ Network Speedtest ]")"
    sys_bit=""
    local sysarch=$(uname -m)
    case "$sysarch" in
        x86_64) sys_bit="x86_64" ;;
        i386|i686) sys_bit="i386" ;;
        aarch64|armv8*) sys_bit="aarch64" ;;
        armv7*) sys_bit="armhf" ;;
        *) _red "Error: Unsupported architecture $sysarch\n" && exit 1 ;;
    esac

    if [ ! -e "./speedtest-cli/speedtest" ]; then
        local url="https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-${sys_bit}.tgz"
        mkdir -p speedtest-cli
        if ! curl -sL -o speedtest.tgz "$url"; then
             _red "Error downloading speedtest.\n" && exit 1
        fi
        tar zxf speedtest.tgz -C ./speedtest-cli && chmod +x ./speedtest-cli/speedtest
        rm -f speedtest.tgz
    fi

    printf "%-18s%-18s%-20s%-12s\n" " Node Name" "Upload Speed" "Download Speed" "Latency"
    
    speed_test '' 'Speedtest.net'
    
    local nodes=(
        "21541|Los Angeles, US"
        "43860|Dallas, US"
        "40879|Montreal, CA"
        "61933|Paris, FR"
        "28922|Amsterdam, NL"
        "25858|Beijing, CN"
        "24447|Shanghai, CN"
        "32155|Hong Kong, CN"
        "13623|Singapore, SG"
        "48463|Tokyo, JP"
    )

    for node in "${nodes[@]}"; do
        if [[ $stop_speedtest -eq 1 ]]; then
            echo " ... Skipping remaining tests due to errors/limits ..."
            break
        fi
        local id=${node%%|*}
        local name=${node##*|}
        speed_test "$id" "$name"
    done

    rm -rf speedtest-cli
}

main() {
    clear
    echo "-------------------- A Bench.sh Script By Teddysun -------------------"
    echo " Version            : $(_green 2025-Optimized-Rev7)"
    
    get_system_info
    check_virt
    
    next
    print_cpu_info
    next
    print_mem_disk_info
    next
    print_basic_system_info
    next
    print_network_info
    next
    io_test
    next
    run_speedtest
    next
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    if [ $duration -gt 60 ]; then
        local min=$((duration / 60))
        local sec=$((duration % 60))
        echo " Finished in        : ${min} min ${sec} sec"
    else
        echo " Finished in        : ${duration} sec"
    fi
    echo " Timestamp          : $(date '+%Y-%m-%d %H:%M:%S %Z')"
}

main
