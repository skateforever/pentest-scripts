#!/bin/bash

# This function is executed after the execution of the function: random_country
# This function executes the function boot_tor_instances
boot_tor_per_country(){
    if [ -n "${MY_COUNTRY_LIST}" ]; then
	    for country_code in ${MY_COUNTRY_LIST}; do
		    if [ -n "${country_code}" ]; then
    			CURRENT_COUNTRY=${country_code}
	    		echo "Starting (${TOR_INSTANCES}) TOR instances enforcing the (${COUNTRY_LIST_CONTROLS}) in the COUNTRY: ${CURRENT_COUNTRY}"
                # Call the declared function
		    	boot_tor_instances 
    		fi
	    done
    else
	    echo "Your MY_COUNTRY_LIST is empty!"
        echo "You should define the list of country codes will be used."
        echo "Sample: {US},{IT},{FR},{CA},{CH},{SE},{RU},{CH},{JP},{BR}"
	    exit 1
    fi
}

# This function select the initial random countries.
random_country(){ 
    for c in $(seq "${COUNTRIES}"); do
        # Sub Function to generate the LIST of COUNTRIES
	    remove_duplicate_country(){
		    if [ "${MY_COUNTRY_LIST}" = "FIRST_EXECUTION" ]; then
			    MY_COUNTRY_LIST="${COUNTRY_CANDIDATE}"
    		else
                # If the country candidate was not found in the current country list
	    		if ! grep -q -i "${COUNTRY_CANDIDATE}" "${MY_COUNTRY_LIST}" 2> /dev/null; then
				    MY_COUNTRY_LIST=$(printf '%s\n%s\n' "${MY_COUNTRY_LIST}" "${COUNTRY_CANDIDATE}")
    			else
                    # If the country already exist in the list select another country
	    			sort_country
		    	fi
		    fi
    	}
        # Sub Function to select a random contry
	    sort_country(){ 
		    COUNTRY_CANDIDATE=$(echo "${ACCEPTED_COUNTRIES}" | sed "s|,|\n|g" | sort -R | head -n 1)
            # Call the declared function
    		remove_duplicate_country
	    }
        # Call the declared function
    	sort_country
    done
    # Now we have the list of random countries defined. Let's boot the tor using this random list.
    # Call the declared function
    boot_tor_per_country
}

create_new_tor_instance_file(){
# Writing the TOR CONFIG FILE
echo "SocksPort ${TOR_LISTEN_ADDR}:${TOR_CURRENT_SOCKS_PORT}
#This LOG options do not compromise your security.
Log notice file ${LOGDIR}${TOR_CURRENT_INSTANCE}/${LOGNAME}${TOR_CURRENT_INSTANCE}.log
#This options INFO and DEBUG can put in the log sensitive data.
#avoid to use it if possible, or just use for debug.
#Log info file ${LOGDIR}${TOR_CURRENT_INSTANCE}/${LOGNAME}${TOR_CURRENT_INSTANCE}.log
#Log debug file ${LOGDIR}${TOR_CURRENT_INSTANCE}/${LOGNAME}${TOR_CURRENT_INSTANCE}.log
RunAsDaemon 1
CookieAuthentication 0
ControlPort ${TOR_LISTEN_ADDR}:${TOR_CURRENT_CONTROL_PORT}
HashedControlPassword ${TOR_PASS}
PidFile ${TOR_DIR_TEMP_FILES}/tor${TOR_CURRENT_INSTANCE}/tor${TOR_CURRENT_INSTANCE}.pid
DataDirectory ${TOR_DIR_TEMP_FILES}/tor${TOR_CURRENT_INSTANCE}
HiddenServiceDir ${HIDDEN_SERVICE_PATH}${TOR_CURRENT_INSTANCE}
HiddenServicePort ${HIDDEN_SERVICE_CURRENT_PORT}
HiddenServiceMaxStreams 0
HiddenServiceMaxStreamsCloseCircuit 0
HiddenServiceDirGroupReadable 0
HiddenServiceNumIntroductionPoints 3
DirCache 1
DataDirectoryGroupReadable 0
CacheDirectory ${TOR_DIR_TEMP_FILES}/tor${TOR_CURRENT_INSTANCE}
CacheDirectoryGroupReadable 0
DisableDebuggerAttachment 1
FetchDirInfoEarly 0
FetchDirInfoExtraEarly 0
FetchHidServDescriptors 1
FetchServerDescriptors 1
FetchUselessDescriptors 0
KeepalivePeriod ${MINIMUM_TIMEOUT}
ProtocolWarnings 1
TruncateLogFile 1
SafeLogging 1
KeepBindCapabilities auto
HardwareAccel 0
AvoidDiskWrites 0
CircuitPriorityHalflife 1
ExtendByEd25519ID auto
NoExec 1
EnforceDistinctSubnets 1
TransPort 0
NATDPort 0
ConstrainedSockSize 8192
UseGuardFraction auto
UseMicrodescriptors auto
ClientUseIPv4 1
ClientUseIPv6 0
ClientPreferIPv6ORPort auto
PathsNeededToBuildCircuits -1
#ClientBootstrapConsensusAuthorityDownloadSchedule 6, 11, 3600, 10800, 25200, 54000, 111600, 262800
ClientBootstrapConsensusAuthorityDownloadInitialDelay 6, 11, 3600, 10800, 25200, 54000, 111600, 262800
ClientBootstrapConsensusFallbackDownloadSchedule 0, 1, 4, 11, 3600, 10800, 25200, 54000, 111600, 262800
ClientBootstrapConsensusAuthorityOnlyDownloadSchedule 0, 3, 7, 3600, 10800, 25200, 54000, 111600, 262800
ClientBootstrapConsensusMaxInProgressTries 3
RejectPlaintextPorts ${RejectPlaintextPorts}
WarnPlaintextPorts ${WarnPlaintextPorts}
CircuitBuildTimeout ${CircuitBuildTimeout}
LearnCircuitBuildTimeout ${LearnCircuitBuildTimeout}
CircuitsAvailableTimeout ${CircuitsAvailableTimeout}
CircuitStreamTimeout ${CircuitStreamTimeout}
ClientOnly ${ClientOnly}
ConnectionPadding ${ConnectionPadding}
ReducedConnectionPadding ${ReducedConnectionPadding}
GeoIPExcludeUnknown ${GeoIPExcludeUnknown}
StrictNodes ${StrictNodes}
FascistFirewall ${FascistFirewall}
FirewallPorts ${FirewallPorts}
LongLivedPorts ${LongLivedPorts}
NewCircuitPeriod ${NewCircuitPeriod}
MaxCircuitDirtiness $(shuf -i10-${MaxCircuitDirtiness} -n1)
MaxClientCircuitsPending ${MaxClientCircuitsPending}
SocksTimeout ${SocksTimeout}
TrackHostExitsExpire ${TrackHostExitsExpire}
UseEntryGuards ${UseEntryGuards}
NumEntryGuards ${NumEntryGuards}
NumDirectoryGuards 0
GuardLifetime 0
AutomapHostsOnResolve 0
AutomapHostsSuffixes ${AutomapHostsSuffixes}
SafeSocks ${SafeSocks}
TestSocks ${TestSocks}
AllowNonRFC953Hostnames ${AllowNonRFC953Hostnames}
ClientRejectInternalAddresses ${ClientRejectInternalAddresses}
DownloadExtraInfo ${DownloadExtraInfo}
OptimisticData ${OptimisticData}
" >> "${TOR_DIR_TEMP_FILES}/tor${TOR_CURRENT_INSTANCE}/tor_${TOR_CURRENT_INSTANCE}.cfg"

# HAPROXY Appending Config
echo "    server TOR_INSTANCE_${TOR_CURRENT_INSTANCE} ${TOR_LISTEN_ADDR}:${TOR_CURRENT_SOCKS_PORT} check inter ${HEALTH_CHECK_INTERVAL} fall ${HEALTH_CHECK_MAX_FAIL} rise ${HEALTH_CHECK_MININUM_SUCESS} observe layer4 minconn 1 maxconn ${MAX_CONCURRENT_REQUEST}" >> "${HAPROXY_MASTER_PROXY_CFG}"

echo "#!/usr/bin/expect -f
spawn telnet 127.0.0.1 ${TOR_CURRENT_CONTROL_PORT}
expect \"Escape character is '^]'.\"
send \"AUTHENTICATE \\\"${RAND_PASS}\\\"\\r\"
expect \"250 OK\"
send \"signal NEWNYM\r\"
expect \"250 OK\"
send \"quit\\r\" " > "${TOR_DIR_TEMP_FILES}/tor${TOR_CURRENT_INSTANCE}/tor_expect.exp"
		
echo "expect ${TOR_DIR_TEMP_FILES}/tor${TOR_CURRENT_INSTANCE}/tor_expect.exp > /dev/null 2>&1" >> "${TOR_DIR_TEMP_FILES}/force_new_circuit_temp.txt"
}

# Function to boot the TOR instances
boot_tor_instances(){
    for i in $(seq "${TOR_INSTANCES}"); do
        # Setting the current instance
		TOR_CURRENT_INSTANCE=$((TOR_CURRENT_INSTANCE + 1))

        # Check if the port is available and adjuste if other program is already using the current port
        TOR_CURRENT_SOCKS_PORT=$((TOR_CURRENT_SOCKS_PORT + 1))

        # Call the function to check if this port is available
        check_if_port_available "${TOR_CURRENT_SOCKS_PORT}"

        # Receive the next port available
	    TOR_CURRENT_SOCKS_PORT="${NEXT_PORT_AVAILABLE}"
		TOR_CURRENT_CONTROL_PORT=$((TOR_CURRENT_CONTROL_PORT + 1))

        # Call the function to check if this port is available
		check_if_port_available "${TOR_CURRENT_CONTROL_PORT}"

        # Receive the next port available
	    TOR_CURRENT_CONTROL_PORT="${NEXT_PORT_AVAILABLE}"

        HIDDEN_SERVICE_CURRENT_PORT=$((HIDDEN_SERVICE_CURRENT_PORT +1))
        # Call the function to check if this port is available
		check_if_port_available "${HIDDEN_SERVICE_CURRENT_PORT}"
        # Receive the next port available
	    HIDDEN_SERVICE_CURRENT_PORT="${NEXT_PORT_AVAILABLE}"

		mkdir -p "${HIDDEN_SERVICE_PATH}${TOR_CURRENT_INSTANCE}" 2>/dev/null
		chown -R "${USER_ID}" "${HIDDEN_SERVICE_PATH}${TOR_CURRENT_INSTANCE}"
        chmod 700 -R "${HIDDEN_SERVICE_PATH}${TOR_CURRENT_INSTANCE}"

		[[ ! -d "${TOR_DIR_TEMP_FILES}/tor${TOR_CURRENT_INSTANCE}" ]] && \
            mkdir "${TOR_DIR_TEMP_FILES}/tor${TOR_CURRENT_INSTANCE}" 2> /dev/null

        TOR_CURRENT_INSTANCE_CONFIG="${TOR_DIR_TEMP_FILES}/tor${TOR_CURRENT_INSTANCE}/tor_${TOR_CURRENT_INSTANCE}.cfg"

        if ! touch "${TOR_CURRENT_INSTANCE_CONFIG}"; then
            echo "Did not possible create the ${TOR_CURRENT_INSTANCE_CONFIG} file"
            exit 1
        else

            if [ -n "${CURRENT_COUNTRY}" ]; then
                CURRENT_COUNTRY_FLAG=$(echo "${CURRENT_COUNTRY}" | sed 's|{||g' | sed 's|}||g')

                ## ENTRY-NODES
			    if [ "${COUNTRY_LIST_CONTROLS}" = "entry" ]; then
                    echo "EntryNodes ${CURRENT_COUNTRY}" > "${TOR_CURRENT_INSTANCE_CONFIG}"
                    echo "ExitNodes ${ACCEPTED_COUNTRIES//${CURRENT_COUNTRY},/}" >> "${TOR_CURRENT_INSTANCE_CONFIG}"
                    echo "ExcludeNodes ${BLACKLIST_COUNTRIES}" >> "${TOR_CURRENT_INSTANCE_CONFIG}"
                fi

                ## EXIT-NODES
                if [ "${COUNTRY_LIST_CONTROLS}" = "exit" ]; then
                    echo "EntryNodes ${ACCEPTED_COUNTRIES//${CURRENT_COUNTRY},/}" > "${TOR_CURRENT_INSTANCE_CONFIG}"
                    echo "ExitNodes ${CURRENT_COUNTRY}" >> "${TOR_CURRENT_INSTANCE_CONFIG}"
                    echo "ExcludeNodes ${BLACKLIST_COUNTRIES}" >> "${TOR_CURRENT_INSTANCE_CONFIG}"
                fi

                ##FOCUS-ON-SPEED
                if [ "${COUNTRY_LIST_CONTROLS}" = "speed" ]; then
                    echo "EntryNodes ${CURRENT_COUNTRY}" > "${TOR_CURRENT_INSTANCE_CONFIG}"
                    echo "ExitNodes ${CURRENT_COUNTRY}" >> "${TOR_CURRENT_INSTANCE_CONFIG}"
                    echo "ExcludeNodes ${BLACKLIST_COUNTRIES},${ACCEPTED_COUNTRIES//${CURRENT_COUNTRY},/}" >> "${TOR_CURRENT_INSTANCE_CONFIG}"
                fi
		    fi

            create_new_tor_instance_file

            # Firing up
            # Execute the tor instance and put it in the background
		    ${TOR_PATH} -f "${TOR_CURRENT_INSTANCE_CONFIG}" > /dev/null 2>&1 &

		    # Update the instances_running_list.txt
            sleep 2
            echo "_$(cat "${TOR_DIR_TEMP_FILES}/tor${TOR_CURRENT_INSTANCE}/tor${TOR_CURRENT_INSTANCE}.pid" 2>/dev/null),"${TOR_CURRENT_INSTANCE}",""${CURRENT_COUNTRY}"",""${TOR_DIR_TEMP_FILES}"/tor"${TOR_CURRENT_INSTANCE}"/tor_"${TOR_CURRENT_INSTANCE}".cfg"" >> "${TOR_DIR_TEMP_FILES}/instances_running_list.txt" &
        fi
    done
}
