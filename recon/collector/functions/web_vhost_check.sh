#############################################################
#                                                           #
# This file is an essential part of collector's execution!  #
# And is responsible to get the functions:                  #
#                                                           #
#   * vhost_check                                           #
#                                                           #
#############################################################            

vhost_check(){

        vhost_original="$(timeout --signal=9 1 curl -siLk -o /dev/null -w "%{response_code}","%{size_download}" "$IP" --no-keepalive)"

    echo -n "Looking for vhost with dead subdomains... "

    if [[ -s "${report_dir}/domains_without_resolution.txt" ]] && [[ -s "${report_dir}/domains_external_ipv4.txt" ]]; then
        # Getting the IPs
        for IP in $(awk '{print $2}' "${report_dir}/domains_external_ipv4.txt" | sort -u) ; do
            #Getting the ports
            for PORT in ${web_port_detect[@]}; do
                # Getting the dead subdomains
                while read DEAD_SUBDOMAIN; do
                    #vhost_hostheader_check="$(timeout --signal=9 5 curl -siLk -o /dev/null -w "%{response_code}","%{size_download}" http://"${IP}" -H Host:"${DEAD_UBDOMAIN}")"
                    vhost_dns_check="$(timeout --signal=9 8 curl -sikL "${DEAD_SUBDOMAIN}" --resolve "${DEAD_SUBDOMAIN}:${PORT}:${IP}" -o /dev/null -w "%{response_code}","%{size_download}")"
                done < "${report_dir}/domains_without_resolution.txt"
            done
        done
    fi

    echo "Done!"

}

