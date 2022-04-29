#!/bin/bash

# This function just check if the selected port is available before use it.
check_if_port_available(){
    # 0(Zero) means that the port is not available and 1 means that this port is available
	PORT_FREE=0
	REQUESTED_PORT="$1"
	while [ ${PORT_FREE} -lt 1 ]; do
        # Check if this port is available
        if [[ $(netstat -ln | grep -q ":${REQUESTED_PORT}" 2> /dev/null) ]]; then
			REQUESTED_PORT="$((REQUESTED_PORT + 1))"
            # Call this function again to check if the new port is available
			check_if_port_available "${REQUESTED_PORT}"
		else
			NEXT_PORT_AVAILABLE="${REQUESTED_PORT}"
            # The port is available. Exit the loop
			PORT_FREE=1
		fi
	done
}

setting_proxy(){
# Setting proxy to the system
grep -Ev "Proxies.*TOR|no_proxy|all_proxy|http_proxy|https_proxy|ftp_proxy|rsync_proxy" "/home/${USER_ID}/.bashrc" > .bashrc_temp 
echo "# Proxies TOR" >> .bashrc_temp
echo "export no_proxy=${DO_NOT_PROXY}" >> .bashrc_temp
echo "export all_proxy=http://127.0.0.1:${HAPROXY_MASTER_PROXY_PORT}" >> .bashrc_temp
echo "export http_proxy=http://127.0.0.1:${HAPROXY_MASTER_PROXY_PORT}" >> .bashrc_temp
echo "export https_proxy=https://127.0.0.1:${HAPROXY_MASTER_PROXY_PORT}" >> .bashrc_temp
echo "export ftp_proxy=http://127.0.0.1:${HAPROXY_MASTER_PROXY_PORT}" >> .bashrc_temp
echo "export rsync_proxy=http://127.0.0.1:${HAPROXY_MASTER_PROXY_PORT}" >> .bashrc_temp
mv -f .bashrc_temp "/home/${USER_ID}/.bashrc"
}
