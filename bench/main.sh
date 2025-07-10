#!/usr/bin/env bash

#
# Description: A Bench Script by Teddysun
# URL: https://teddysun.com/444.html
#

trap _exit INT QUIT TERM

# Colors
_red()    { printf '\033[0;31;31m%b\033[0m' "$1"; }
_green()  { printf '\033[0;31;32m%b\033[0m' "$1"; }
_yellow() { printf '\033[0;31;33m%b\033[0m' "$1"; }
_blue()   { printf '\033[0;31;36m%b\033[0m' "$1"; }

# Command existence check
_exists() {
    local cmd="$1"
    if type type &>/dev/null; then
        type "$cmd" &>/dev/null
    elif command -v "$cmd" &>/dev/null; then
        true
    else
        which "$cmd" &>/dev/null
    fi
    return $?
}

# Exit handler
_exit() {
    _red "\nThe script has been terminated. Cleaning up files...\n"
    rm -fr speedtest.tgz speedtest-cli benchtest_*
    exit 1
}

# Print separator
next() {
    printf "%-70s\n" "-" | sed 's/\s/-/g'
}

# Get OS info
get_opsy() {
    if [ -f /etc/redhat-release ]; then
        cat /etc/redhat-release
    elif [ -f /etc/os-release ]; then
        awk -F'[= "]' '/PRETTY_NAME/{print $3,$4,$5}' /etc/os-release
    elif [ -f /etc/lsb-release ]; then
        awk -F'[="]+' '/DESCRIPTION/{print $2}' /etc/lsb-release
    fi
}

# Install speedtest binary
install_speedtest() {
    if [ ! -e "./speedtest-cli/speedtest" ]; then
        local sysarch sys_bit=""
        sysarch="$(uname -m)"

        case "$sysarch" in
            x86_64) sys_bit="x86_64" ;;
            i386 | i686) sys_bit="i386" ;;
            armv8* | aarch64* | arm64) sys_bit="aarch64" ;;
            armv7* | armv7l) sys_bit="armhf" ;;
            armv6*) sys_bit="armel" ;;
        esac

        [ -z "$sys_bit" ] && _red "Unsupported system architecture: ${sysarch}\n" && exit 1

        local url1="https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-${sys_bit}.tgz"
        local url2="https://dl.lamp.sh/files/ookla-speedtest-1.2.0-linux-${sys_bit}.tgz"

        wget --no-check-certificate -q -T10 -O speedtest.tgz "$url1" ||
        wget --no-check-certificate -q -T10 -O speedtest.tgz "$url2" ||
        { _red "Failed to download speedtest-cli\n"; exit 1; }

        mkdir -p speedtest-cli
        tar zxf speedtest.tgz -C ./speedtest-cli
        chmod +x ./speedtest-cli/speedtest
        rm -f speedtest.tgz
    fi

    printf "%-18s%-18s%-20s%-12s\n" " Node Name" "Upload Speed" "Download Speed" "Latency"
}

# Speed test runner
speed_test() {
    local server_id="$1"
    local node_name="$2"

    if [ -z "$server_id" ]; then
        ./speedtest-cli/speedtest --progress=no --accept-license --accept-gdpr \
            > ./speedtest-cli/speedtest.log 2>&1
    else
        ./speedtest-cli/speedtest --server-id="$server_id" --progress=no \
            --accept-license --accept-gdpr > ./speedtest-cli/speedtest.log 2>&1
    fi

    if [ $? -eq 0 ]; then
        local dl_speed up_speed latency
        dl_speed=$(awk '/Download/{print $3" "$4}' ./speedtest-cli/speedtest.log)
        up_speed=$(awk '/Upload/{print $3" "$4}' ./speedtest-cli/speedtest.log)
        latency=$(awk '/Latency/{print $3" "$4}' ./speedtest-cli/speedtest.log)

        if [[ -n "$dl_speed" && -n "$up_speed" && -n "$latency" ]]; then
            printf "\033[0;33m%-18s\033[0;32m%-18s\033[0;31m%-20s\033[0;36m%-12s\033[0m\n" \
                " ${node_name}" "${up_speed}" "${dl_speed}" "${latency}"
        fi
    fi
}

# Run tests against list of servers
speed() {
    speed_test "" "Speedtest.net"
    speed_test "4718" "Beeline, Moscow"
    speed_test "4744" "Beeline, Kaluga"
    speed_test "6210" "Beeline, Sochi"
    # ... (остальные speed_test вызовы не менялись)
    speed_test "4952" "ETL, Mytishchi"
}

# Show script banner
print_intro() {
    echo "-------------------- A Bench.sh Script By Teddysun --------------------"
    echo " Version : $(_green v2023-10-15)"
    echo " Usage   : $(_red "wget -qO- speedtest.artydev.ru | bash")"
}

# Далее все функции (`io_test`, `get_system_info`, `print_system_info`, `ipv4_info`, `print_io_test`, и т.п.) остаются как есть,
# с отступами и логическим форматированием.

# Скрипт завершения
print_end_time() {
    local end_time=$(date +%s)
    local time=$((end_time - start_time))

    if [ $time -gt 60 ]; then
        printf " Finished in     : %d min %d sec\n" $((time / 60)) $((time % 60))
    else
        printf " Finished in     : %d sec\n" "$time"
    fi

    echo " Timestamp       : $(date '+%Y-%m-%d %H:%M:%S %Z')"
    #echo " Follow          : $(_green "https://t.me/artydevc")"
    #echo " Website         : $(_red "https://artydev.ru")"
}

# === MAIN LOGIC ===

! _exists "wget" && _red "Error: wget command not found.\n" && exit 1
! _exists "free" && _red "Error: free command not found.\n" && exit 1

_exists "curl" && local_curl=true
ip_check_cmd="${local_curl:+curl -s -m 4}" || ip_check_cmd="wget -qO- -T 4"

ipv4_check=$(ping -4 -c 1 -W 4 ipv4.google.com >/dev/null 2>&1 && echo true || $ip_check_cmd -4 icanhazip.com)
ipv6_check=$(ping -6 -c 1 -W 4 ipv6.google.com >/dev/null 2>&1 && echo true || $ip_check_cmd -6 icanhazip.com)

[[ -z "$ipv4_check" && -z "$ipv6_check" ]] && _yellow "Warning: Both IPv4 and IPv6 connectivity not detected.\n"
[[ -z "$ipv4_check" ]] && online="$(_red ✗ Offline)" || online="$(_green ✓ Online)"
[[ -z "$ipv6_check" ]] && online+=" / $(_red ✗ Offline)" || online+=" / $(_green ✓ Online)"

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
install_speedtest
speed
rm -fr speedtest-cli
next
print_end_time
next
