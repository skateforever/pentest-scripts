#!/bin/bash

boot_privoxy_instances(){
    for i in $(seq $((${TOR_INSTANCES} * ${COUNTRIES}))); do
        # Setting the current instance
        PRIVOXY_CURRENT_INSTANCE=$((PRIVOXY_CURRENT_INSTANCE + 1))

        # Check if the port is available and adjuste if other program is already using the current port
        PRIVOXY_CURRENT_PORT=$((PRIVOXY_CURRENT_PORT + 1))

        #Call the function to check if this port is available
        check_if_port_available "${PRIVOXY_CURRENT_PORT}"

        TOR_CURRENT_SOCKS_PORT=$(grep ^SocksPort  "${TOR_DIR_TEMP_FILES}/tor${PRIVOXY_CURRENT_INSTANCE}/tor_${PRIVOXY_CURRENT_INSTANCE}.cfg"  | awk -F':' '{print $2}') 
        
        create_new_privoxy_instance_files
    done

}

create_new_privoxy_instance_files(){
echo "user-manual /usr/share/doc/PRIVOXY/user-manual
confdir ${PRIVOXY_DIR_TEMP_FILES}
# Disabled by default. Only enable it, if you need debug someting.
#logdir ${PRIVOXY_DIR_TEMP_FILES}
# Disabled by default. Only enable it, if you need debug someting.
#logfile privoxy_${PRIVOXY_CURRENT_INSTANCE}.log
#debug 512
#debug 16
#debug 32768			    
toggle 1
enable-remote-toggle  0
enable-remote-http-toggle  0
enable-edit-actions 0
enforce-blocks 0
buffer-limit 4096
forwarded-connect-retries ${RETRIES}
keep-alive-timeout ${PRIVOXY_TIMEOUT}
default-server-timeout ${PRIVOXY_TIMEOUT}
socket-timeout ${PRIVOXY_TIMEOUT}
connection-sharing 1
listen-address  ${PRIVOXY_LISTEN_ADDR}:${PRIVOXY_CURRENT_PORT}
forward-socks5t / ${PRIVOXY_LISTEN_ADDR}:${TOR_CURRENT_SOCKS_PORT} ." > "${PRIVOXY_FILE}_${PRIVOXY_CURRENT_INSTANCE}.cfg"

# HAPROXY Appending Config
echo "    server PRIVOXY_INSTANCE_${PRIVOXY_CURRENT_INSTANCE} ${PRIVOXY_LISTEN_ADDR}:${PRIVOXY_CURRENT_PORT} check inter ${HEALTH_CHECK_INTERVAL} fall ${HEALTH_CHECK_MAX_FAIL} rise ${HEALTH_CHECK_MININUM_SUCESS} observe layer7 minconn 1 maxconn ${MAX_CONCURRENT_REQUEST}" >> "${HAPROXY_MASTER_PROXY_CFG}"

# Execute the Privoxy Instance
${PRIVOXY_PATH} --pidfile ${PRIVOXY_DIR_TEMP_FILES}/privoxy_${PRIVOXY_CURRENT_INSTANCE}.pid "${PRIVOXY_FILE}_${PRIVOXY_CURRENT_INSTANCE}.cfg" &
}
