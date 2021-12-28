#!/bin/bash

vpn_firewall(){
    interfaces=($(ip addr | grep -E "^[0-9]" | grep -Eiv "loopback|docker" | awk '{print $2}' | sed 's/:$//'))

    if [ -n "${iptables_bin}" ]; then
        for interface in "${interfaces[@]}"; do
            "${iptables_bin}" -t filter -A INPUT -s "${VPN_GATEWAY}"/32 -i "${interface}" -j ACCEPT
            "${iptables_bin}" -t filter -A INPUT -i "${interface}" -j DROP
            "${iptables_bin}" -t filter -A OUTPUT -d "${VPN_GATEWAY}"/32 -o "${interface}" -j ACCEPT
            "${iptables_bin}" -t filter -A OUTPUT -o "${interface}" -j DROP
        done
    else
        echo "Please install the iptablles binary to continue the configuration!"
        exit 1
    fi
}
