#############################################################
#                                                           #
# This file is an essential part of collector's execution!  #
# And is responsible to get the functions:                  #
#                                                           #
#   * infra_recon                                           #
#   * shodan_recon                                          #
#                                                           #
############################################################# 

infra_recon(){
    if [ -s "${report_dir}/domains_external_ipv4.txt" ]; then
        echo -ne "${yellow}$(date +"%d/%m/%Y %H:%M")${reset} ${red}>>${reset} Getting subdomains IP to use with nmap... "
        if awk '{print $2}' "${report_dir}/domains_external_ipv4.txt" | sort -u >> "${report_dir}/infra_ips.txt"; then
            echo "Done!"
        else
            echo "Fail!"
        fi

        # To avoid the warning message: "Warning: RIPE flags used with a traditional server."
        # The -- option is needed.
        echo -ne "${yellow}$(date +"%d/%m/%Y %H:%M")${reset} ${red}>>${reset} Getting information about IP... "
        echo "AS      | IP               | BGP Prefix          | CC | Registry | Allocated  | AS Name" > "${report_dir}/infra_whois.txt"
        while IFS= read -r IP; do
            whois -h whois.cymru.com -- "-v ${IP}" | tail -n +2 >> "${report_dir}/infra_whois.txt"
        done < "${report_dir}/infra_ips.txt"
        echo "Done!"

        echo -ne "${yellow}$(date +"%d/%m/%Y %H:%M")${reset} ${red}>>${reset} Getting target IP blocks to use with nmap... "
        if [ -s "${report_dir}/infra_whois.txt" ]; then
            awk '{print $5}' "${report_dir}/infra_whois.txt" | tail -n +2 >> "${tmp_dir}/tmp_infra_blocks.txt"
        fi

        #if [ -s "${report_dir}/domains_alive.txt" ]; then
        #    while IFS= read -r subdomain; do
        #        if whois "${subdomain}" 2> /dev/null | grep -q "${domain}"; then
        #            sleep 2
        #            whois "${subdomain}" 2> /dev/null | grep -E "^inetnum:|^inetrev:|^CIDR:|^inetnum-up:" | \
        #                awk '{for (i=2; i<=NF; i++){printf("%s",$i)}; printf "\n"}'
        #            sleep 2
        #        fi
        #    done < "${report_dir}/domains_alive.txt" | sort -u >> "${tmp_dir}/tmp_infra_blocks.txt"
        #    unset subdomain
        #fi

        #if [ -s "${tmp_dir}/tmp_infra_blocks.txt" ]; then
        #    while IFS= read -r block; do
        #        for asn in $(whois "${block}" 2> /dev/null | grep -E "^aut-num:" | awk '{print $2}'); do
        #            sleep 2
        #            [[ -n "${asn}" ]] && \
        #                curl -A "${curl_agent}" -s https://api.hackertarget.com/aslookup/?q="${asn}" 2> /dev/null | \
        #                grep -E "^${IPv4_regex}$|^${IPv6_regex}$"
        #            sleep 2
        #        done
        #    done < "${tmp_dir}/tmp_infra_blocks.txt" | sort -u >> "${tmp_dir}/tmp_asn_blocks.txt"
        #    unset asn
        #fi

        #[[ -s "${tmp_dir}/tmp_asn_blocks.txt" ]] && sort -u "${tmp_dir}/tmp_asn_blocks.txt" >> "${tmp_dir}/tmp_infra_blocks.txt"

        if [ -s "${tmp_dir}/tmp_infra_blocks.txt" ]; then        
            sed -i 's/,/\n/g' "${tmp_dir}/tmp_infra_blocks.txt"
            sort -u -o "${tmp_dir}/tmp_infra_blocks_sorted.txt" "${tmp_dir}/tmp_infra_blocks.txt"
        fi

        if [ -s "${tmp_dir}/tmp_infra_blocks_sorted.txt" ]; then        
            for block in $(cat "${tmp_dir}/tmp_infra_blocks_sorted.txt"); do
                owner="$(whois "${block}" 2> /dev/null | grep -E "^OrgName:|^CustName:|^owner:" | awk '{print $2,$3,$4,$5,$6,$7,$8}')"
                echo -e "${block}\t${owner}" >> "${report_dir}/infra_ipv4_blocks.txt"
                unset owner
                unset block
            done
        fi

        ownerid=$(whois "${domain}" 2> /dev/null | grep -E "^ownerid:" | awk '{print $2}')
        if [[ -n "${ownerid}" ]] && [[ -s "${report_dir}/infra_ipv4_blocks.txt" ]]; then
            for block in $(cat "${report_dir}/infra_ipv4_blocks.txt" | awk '{print $1}'); do
                if whois "${block}" 2> /dev/null | grep -q "${ownerid}"; then
                    sleep 3
                    echo -e "${block}\t$(whois "${block}" 2> /dev/null | grep -E "^OrgName:|^CustName:|^owner:" | sed 's/^.*:[[:blank:]]*//')"
                    sed -i "/${block::-3}/d" "${report_dir}/infra_ipv4_blocks.txt"
                fi
                unset block
            done | sort -u >> "${tmp_dir}/tmp_infra_owner_blocks.txt"
        fi
        unset ownerid

        [[ -s "${tmp_dir}/tmp_infra_owner_blocks.txt" ]] && sort -u -o "${report_dir}/infra_owner_blocks.txt" "${tmp_dir}/tmp_infra_owner_blocks.txt"
        echo "Done!"

        if [ -s "${report_dir}/infra_owner_blocks.txt" ]; then
            echo -ne "${yellow}$(date +"%d/%m/%Y %H:%M")${reset} ${red}>>${reset} Getting IPs from blocks with nmap -sn \"block\"... "
            count=0
            while IFS= read -r block; do
                block=$(echo "${block}" | awk '{print $1}')
                block_file=infra_nmap_$(echo "${block}" | sed -e 's/\//_/').txt
                cidr=$(echo "${block}" | awk -F'/' '{print $2}')
                if [[ ${cidr} -ge 24 ]]; then
                    nmap -sn "${block}" --exclude 10.0.0.0/8,172.16.0.0/12,192.168.0.0/16 --max-retries 3 --host-timeout 3 2> /dev/null \
                        | grep -E "Nmap.*for" | awk '{print $6}' | sed -e 's/(//' -e 's/)//' > "${report_dir}/${block_file}"
                    sed -i '/^$/d' "${report_dir}/${block_file}"
                    (( count+=1 ))
                else
                    continue
                fi
                unset block
                unset block_file
                unset cidr
            done < "${report_dir}/infra_owner_blocks.txt"
            echo "Done!"

            echo -e "${yellow}$(date +"%d/%m/%Y %H:%M")${reset} ${red}>>${reset} Got owner IP blocks!"
            if [[ ${count} -lt $(wc -l "${report_dir}/infra_owner_blocks.txt" | awk '{print $1}') ]]; then
                echo -e "${red}Warning:${reset} Just ${count} block(s) were scanned, please look at ${report_dir}/infra_owner_blocks.txt"
                echo -e "\t and nmap blocks files to know what were excluded blocks."
            fi
            unset count
        fi
        #echo -ne "${yellow}$(date +"%d/%m/%Y %H:%M")${reset} ${red}>>${reset} Getting open ports from IPs... "
        #if [ -s "${report_dir}/infra_ips.txt" ]; then
        #    for IP in $(cat ${report_dir}/infra_ips.txt); do
        #        "${nmap_bin}" "${nmap_default_options}" "${nmap_furtive_options}" -oA "${nmap_dir}/$(echo ${IP} | sed 's/\./-/g')" "${IP}" > /dev/null 2>&1 &
        #    done
        #fi
        #echo "Done!"
    else
        echo -e "${yellow}$(date +"%d/%m/%Y %H:%M")${reset} ${red}>> File ${report_dir}/domains_external_ipv4.txt does not exist or is empty!${reset}"
    fi
}

shodan_recon(){
    if [ "${shodan_use}" == "yes" ] && [ -s "${report_dir}/infra_owner_blocks.txt" ]; then
        echo -ne "${yellow}$(date +"%d/%m/%Y %H:%M")${reset} ${red}>>${reset} Executing shodan network scan... " 
        for block in $(cat "${report_dir}/infra_owner_blocks.txt" | awk '{print $1}'); do
            network=$(echo ${block} | awk -F'/' '{print $1}')
            cidr=$(echo ${block} | awk -F'/' '{print $2}')
            rm_network=$(echo ${network} | awk -F'.' '{print $1"."$2"."$3"."}')
            ip_range=$(curl -A "${curl_agent}" -s "http://jodies.de/ipcalc" -d "host=${network}&mask1=${cidr}" 2> /dev/null | sed 's/<font color="#000000">/\\\n/g ; s/\\//g' | grep -E "HostMin:|HostMax:" | awk '{print $3}' | sed 's/.*>//' | tr '\n' ' ' | sed "s/${rm_network}//g ; s/.$//")
            total_ip=$(curl -A "${curl_agent}" -s "http://jodies.de/ipcalc" -d "host=${network}&mask1=${cidr}" 2> /dev/null | sed 's/<font color="#000000">/\\\n/g ; s/\\//g' | grep -E "Hosts/Net:" | awk '{print $3}' | sed 's/.*>//' | tr '\n' ' ')
            shodan_recons=$(${shodan_bin} info 2> /dev/null | grep "Scan.*:" | awk '{print $4}')
            shodan_count=0
            if [ "${shodan_recons}" -gt "${total_ip}" ]; then
                for ip in $(seq ${ip_range}); do
                    [[ "${shodan_count}" -eq "${shodan_recon_total}" ]] && break
                    "${shodan_bin}" scan submit "${rm_network}${ip}" > "${shodan_dir}/shodan_${rm_network}${ip}" 2> "${log_file}" &
                    (( shodan_count+=1 ))
                done
            fi
        done
        echo "Done!"

        shodan_recons=$(${shodan_bin} info | grep "Scan.*:" | awk '{print $4}')
        if [ "${shodan_recon_main_domain}" == "yes" ] && [ "${shodan_recons}" -gt 1 ]; then
            echo -e "${yellow}$(date +"%d/%m/%Y %H:%M")${reset} ${red}>>${reset} Executing shodan domain scan... " 
            main_domain_ip=$(timeout 5s host -W 3 -t A ${domain} 2> /dev/null | awk '{print $4}' | head -n1)
            [[ -n "${main_domain_ip}" ]] && \
                "${shodan_bin}" scan submit "${main_domain_ip}" > "${shodan_dir}/shodan_${domain}" 2> "${log_file}" &
            echo "Done!"
        fi
    fi
        
}
