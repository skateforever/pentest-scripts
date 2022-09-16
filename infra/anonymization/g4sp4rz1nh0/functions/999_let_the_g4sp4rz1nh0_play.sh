#!/bin/bash

# Importing the PATHs defined by the user.
g4sp4rz1nh0_PATH="$(pwd | sed 's/\/functions//')"
HIDDEN_SERVICE_PATH="$(grep -E "^HIDDEN_SERVICE_PATH=" "${g4sp4rz1nh0_PATH}/configs/hidden_services.cfg" | awk -F'=' '{print $2}' | sed 's/"//g')"
TOR_DIR_TEMP_FILES="$(grep -E "^TOR_DIR_TEMP_FILES=" "${g4sp4rz1nh0_PATH}/configs/startup.cfg" | cut -d "=" -f 2 | sed 's|"||g')"

# Importing the settings defined by the user.
ACCEPTED_COUNTRIES="$(grep -E "^ACCEPTED_COUNTRIES=" "${g4sp4rz1nh0_PATH}/configs/tor.cfg" | cut -d "=" -f 2 | sed 's|"||g')"
BLACKLIST_COUNTRIES="$(grep -E "^BLACKLIST_COUNTRIES=" "${g4sp4rz1nh0_PATH}/configs/tor.cfg" | cut -d "=" -f 2 | sed 's|"||g')"
COUNTRY_LIST_CONTROLS="$(grep -E "^COUNTRY_LIST_CONTROLS=" "${TOR_DIR_TEMP_FILES}/initial_user_settings.txt" | cut -d "=" -f 2 | sed 's|"||g')"
CHANGE_COUNTRY_INTERVAL="$(grep -E "^CHANGE_COUNTRY_INTERVAL=" "${g4sp4rz1nh0_PATH}/configs/tor.cfg" | cut -d "=" -f 2 | sed 's|"||g')"
TOTAL_COUNTRIES_TO_CHANGE="$(grep -E "^TOTAL_COUNTRIES_TO_CHANGE=" "${g4sp4rz1nh0_PATH}/configs/tor.cfg" | cut -d "=" -f 2 | sed 's|"||g')"
TOR_PATH="$(command -v tor)"
USER_ID=$(id -un)

# checking the existence of the current_country_list.txt file responsible for the country change
if [ -s "${TOR_DIR_TEMP_FILES}/current_country_list.txt" ]; then
    cp "${TOR_DIR_TEMP_FILES}/current_country_list.txt" "${TOR_DIR_TEMP_FILES}/used_country_list.txt"
else
    echo "It will not be possible to change countries as the ${TOR_DIR_TEMP_FILES}/current_country_list.txt was not created."
    echo "Run \"bash ${g4sp4rz1nh0_PATH}/g4sp4rz1nh0 --kill\" to kill this execution."
    exit 1
fi

# This function will select a random contry from the list of available countries, 
# but will not repeat one of those current countries ${TOR_DIR_TEMP_FILES}/current_country_list.txt
select_next_country(){
    if [ -n "${AVAILABLE_COUNTRIES}" ]; then
    	NEXT_COUNTRY="$(echo "${AVAILABLE_COUNTRIES}" | sort -R | head -n 1)"
        # If the NEXT_COUNTRY was not found in the current list of countries
	    if ! grep -q -i "${NEXT_COUNTRY}" "${TOR_DIR_TEMP_FILES}/current_country_list.txt" 2> /dev/null; then
		    CURRENT_COUNTRIES="$(sed "s|${COUNTRY_TARGET}|${NEXT_COUNTRY}|g" "${TOR_DIR_TEMP_FILES}/current_country_list.txt")"
    		echo "${CURRENT_COUNTRIES}" > "${TOR_DIR_TEMP_FILES}/current_country_list.txt"
	    else
            # Call this same function again
    	    select_next_country
	    fi
    else
        echo "The variable AVAILABLE_COUNTRIES is empty."
        echo "Please check what happened!"
        exit 1
    fi
}

change_country_on_the_fly(){
	
	# _PID,INSTANCE,COUNTRY,CFG_FILE
	COUNTRY_TARGET="$1"
    INSTANCES_PER_COUNTRY=($(grep -v "^#" "${TOR_DIR_TEMP_FILES}/instances_running_list.txt" | grep "${COUNTRY_TARGET}" | awk -F',' '{print $2}' | sort -R))
	# Generate the list of countries available based on the list of accepted countries
	# but removing from this list the countries that has been used.
    AVAILABLE_COUNTRIES_TMP="$(sed "s/,/\n/g" <<< ${ACCEPTED_COUNTRIES})"

	while read -r country_line; do
		AVAILABLE_COUNTRIES="$(grep -iv "${country_line}" <<< "${AVAILABLE_COUNTRIES_TMP}")"
	done < "${TOR_DIR_TEMP_FILES}/used_country_list.txt"
	unset AVAILABLE_COUNTRIES_TMP
	
	echo "${AVAILABLE_COUNTRIES}" > "${TOR_DIR_TEMP_FILES}/available_countries.txt"

	# Check if the list of AVAILABLE COUNTRIES is not EMPTY. It means that all countries
	# has been used and we need to restart the listed based on the ACCEPTED COUNTRIES.
	if [ -n "${AVAILABLE_COUNTRIES}" ]; then
        # Call the function
		select_next_country
		# Updating the file ${TOR_DIR_TEMP_FILES}/current_country_list.txt
		# This file holds the current list of countries running.
		# The script checks this file to avoid select same country in this list for the next country.
		CURRENT_COUNTRIES="$(sed "s|${COUNTRY_TARGET}|${NEXT_COUNTRY}|g" "${TOR_DIR_TEMP_FILES}/current_country_list.txt")"
		echo "${CURRENT_COUNTRIES}" > "${TOR_DIR_TEMP_FILES}/current_country_list.txt"
		# Updating the file ${TOR_DIR_TEMP_FILES}/instances_running_list.txt
		# This file holds the current status of the instances.
		INSTANCES_RUNNING_LIST_TMP="$(sed "s|${COUNTRY_TARGET}|${NEXT_COUNTRY}|g" "${TOR_DIR_TEMP_FILES}/instances_running_list.txt")"
		echo "${INSTANCES_RUNNING_LIST_TMP}" > "${TOR_DIR_TEMP_FILES}/instances_running_list.txt"
	else 
        # If all countries available has been used. Update the list removing the current countries.
		cp "${TOR_DIR_TEMP_FILES}/current_country_list.txt" "${TOR_DIR_TEMP_FILES}/used_country_list.txt"
		# Updating the list of AVAILABLE_COUNTRIES, but removing form this list the current countries.
        AVAILABLE_COUNTRIES="$(sed "s/,/\n/g" <<< ${ACCEPTED_COUNTRIES})"
		while read -r country_line; do
			AVAILABLE_COUNTRIES_TMP="$(grep -iv "${country_line}" <<< "${AVAILABLE_COUNTRIES}")"
			AVAILABLE_COUNTRIES="${AVAILABLE_COUNTRIES_TMP}"
		done < "${TOR_DIR_TEMP_FILES}/used_country_list.txt"
		unset AVAILABLE_COUNTRIES_TMP
        # Call the function
		select_next_country
		# Updating the file ${TOR_DIR_TEMP_FILES}/current_country_list.txt
		# This file holds the current list of countries running.
		# The script checks this file to avoid select same country in this list for the next country.
		CURRENT_COUNTRIES="$(sed "s|${COUNTRY_TARGET}|${NEXT_COUNTRY}|g" "${TOR_DIR_TEMP_FILES}/current_country_list.txt")"
		echo "${CURRENT_COUNTRIES}" > "${TOR_DIR_TEMP_FILES}/current_country_list.txt"
		# Updating the file ${TOR_DIR_TEMP_FILES}/instances_running_list.txt
		# This file holds the current status of the instances.
		INSTANCES_RUNNING_LIST_TMP="$(sed "s|${COUNTRY_TARGET}|${NEXT_COUNTRY}|g" "${TOR_DIR_TEMP_FILES}/instances_running_list.txt")"
		echo "${INSTANCES_RUNNING_LIST_TMP}" > "${TOR_DIR_TEMP_FILES}/instances_running_list.txt"
	fi
	
	if [ -n "${NEXT_COUNTRY}" ]; then
		# Including the next country to the list of used_countries
		echo "${NEXT_COUNTRY}" >> "${TOR_DIR_TEMP_FILES}/used_country_list.txt"
		# Rewriting the config file of the target instances.
		# After rewrite the script will restart this instances forcing it to read and apply the new configuration.
        if [[ ${#INSTANCES_PER_COUNTRY[@]} -gt 0  ]]; then
            for TOR_CURRENT_INSTANCE in ${INSTANCES_PER_COUNTRY[@]}; do
			    # _PID,INSTANCE,COUNTRY,CFG_FILE_
                PID_TARGET="$(grep ",${TOR_CURRENT_INSTANCE}," "${TOR_DIR_TEMP_FILES}/instances_running_list.txt" | awk -F',' '{print $1}' | sed 's/_//')"
                CONFIG_TARGET="$(grep ",${TOR_CURRENT_INSTANCE}," "${TOR_DIR_TEMP_FILES}/instances_running_list.txt" | awk -F',' '{print $4}')"
                CONFIG_TARGET_TMP="${TOR_DIR_TEMP_FILES}/temp_config_tor_${TOR_CURRENT_INSTANCE}.tmp"

                if [ -z "${PID_TARGET}" ]; then
                    TOR_CURRENT_SOCKS_PORT=$(grep "127.0.0.1:" "${CONFIG_TARGET}") 
                    TOR_CURRENT_CONTROL_PORT=
                    PRIVOXY_CURRENT_PORT=
                    HIDDEN_SERVICE_CURRENT_PORT=
                    echo "Fodeu!"
                    exit 1
                else
			        # Generating the new Tor Configuration file
            		if grep -Evi "EntryNodes|ExitNodes|ExcludeNodes" "${CONFIG_TARGET}" > "${CONFIG_TARGET_TMP}"; then
                	    # entry
	                	if [ "${COUNTRY_LIST_CONTROLS}" = "entry" ]; then
		                	echo "EntryNodes ${NEXT_COUNTRY}" >> "${CONFIG_TARGET_TMP}"
                            echo "ExitNodes $(sed "s/${NEXT_COUNTRY},//" <<< ${ACCEPTED_COUNTRIES})" >> "${CONFIG_TARGET_TMP}"
				            echo "ExcludeNodes ${BLACKLIST_COUNTRIES}" >> "${CONFIG_TARGET_TMP}"
                		fi
	                	# exit
		                if [ "${COUNTRY_LIST_CONTROLS}" = "exit" ]; then
                            echo "EntryNodes $(sed "s/${NEXT_COUNTRY},//" <<< ${ACCEPTED_COUNTRIES})" >> "${CONFIG_TARGET_TMP}"
				            echo "ExitNodes ${NEXT_COUNTRY}" >> "${CONFIG_TARGET_TMP}"
    				        echo "ExcludeNodes ${BLACKLIST_COUNTRIES}" >> "${CONFIG_TARGET_TMP}"
            	    	fi
	            	    # speed
		            	if [ "${COUNTRY_LIST_CONTROLS}" = "speed" ]; then
			                echo "EntryNodes ${NEXT_COUNTRY}" >> "${CONFIG_TARGET_TMP}"
    			          	echo "ExitNodes ${NEXT_COUNTRY}" >> "${CONFIG_TARGET_TMP}"
                            echo "ExcludeNodes ${BLACKLIST_COUNTRIES},$(sed "s/${NEXT_COUNTRY},//" <<< ${ACCEPTED_COUNTRIES})" >> "${CONFIG_TARGET_TMP}"
            		    fi
                    else
                        echo "Did not possible create a new TOR configuration file!"
                        exit 1
                    fi
            		# Kill the target instance process.
	            	if kill -9 "${PID_TARGET}"; then
    	            	mv "${TOR_DIR_TEMP_FILES}/tor${TOR_CURRENT_INSTANCE}/tor_expect.exp" "${TOR_DIR_TEMP_FILES}/tor_expect.exp" > /dev/null 2>&1
	    	            if [ -d "${TOR_DIR_TEMP_FILES}/tor${TOR_CURRENT_INSTANCE}" ]; then
		    	            rm -rf "${TOR_DIR_TEMP_FILES}/tor${TOR_CURRENT_INSTANCE}/" > /dev/null 2>&1
                            if mkdir -p "${TOR_DIR_TEMP_FILES}/tor${TOR_CURRENT_INSTANCE}/" > /dev/null 2>&1; then
                                # Get new config for new instance
                				mv "${CONFIG_TARGET_TMP}" "${CONFIG_TARGET}" > /dev/null 2>&1
        	      	        	mv "${TOR_DIR_TEMP_FILES}/tor_expect.exp" \
                                    "${TOR_DIR_TEMP_FILES}/tor${TOR_CURRENT_INSTANCE}/tor_expect.exp" > /dev/null 2>&1
		            	        chown -R "${USER_ID}" "${TOR_DIR_TEMP_FILES}/tor${TOR_CURRENT_INSTANCE}" > /dev/null 2>&1
			        	        chmod 700 -R "${TOR_DIR_TEMP_FILES}/tor${TOR_CURRENT_INSTANCE}" > /dev/null 2>&1
                            else
                                echo "Did not possible create the directory ${TOR_DIR_TEMP_FILES}/tor${TOR_CURRENT_INSTANCE}!"
                                exit 1
                            fi
	    		        fi

            			if [ -d "${HIDDEN_SERVICE_PATH}${TOR_CURRENT_INSTANCE}" ]; then
	            		    rm -rf "${HIDDEN_SERVICE_PATH}${TOR_CURRENT_INSTANCE}/" > /dev/null 2>&1
                            if mkdir -p "${HIDDEN_SERVICE_PATH}${TOR_CURRENT_INSTANCE}" > /dev/null 2>&1; then
	    	            	    chown -R "${USER_ID}" "${HIDDEN_SERVICE_PATH}${TOR_CURRENT_INSTANCE}"
		    	            	chmod 700 -R "${HIDDEN_SERVICE_PATH}${TOR_CURRENT_INSTANCE}"
                            fi
        			    fi
                    else
                        echo "Did not possible to kill the instance ${TOR_CURRENT_INSTANCE} process ${PID_TARGET}!"
                        exit 1
                    fi
		
               		# There is a chain of dependencies here:
                	# 1) Execute the tor instance with the new configuration and put it in the background
               		# 2) Remove the current from the file instances_running_list.txt
	                # 3) Update the instances_running_list.txt with the new information about the TOR Instance. 
                    if "${TOR_PATH}" -f "${CONFIG_TARGET}" > /dev/null 2>&1 ; then
                        # If the RANDOM_NUMBER was not found in the current list of instances running
    	    	        if sed -i "\|${CONFIG_TARGET}|d" "${TOR_DIR_TEMP_FILES}/instances_running_list.txt"; then
                            sleep 2
                            echo "_$(cat "${TOR_DIR_TEMP_FILES}/tor${TOR_CURRENT_INSTANCE}/tor${TOR_CURRENT_INSTANCE}.pid"),${TOR_CURRENT_INSTANCE},${NEXT_COUNTRY},${CONFIG_TARGET}" \
                                >> "${TOR_DIR_TEMP_FILES}/instances_running_list.txt"
                        fi
                        if ! grep -q -i -E "^${TOR_CURRENT_INSTANCE}$" "${TOR_DIR_TEMP_FILES}/changed_instances.txt" 2> /dev/null; then
                            # If the RANDOM_NUMBER is not the same number of the previous instance changed.
    	        	        if [ -n "${TOR_CURRENT_INSTANCE}" ]; then 
	    	         	        echo "${TOR_CURRENT_INSTANCE}" >> "${TOR_DIR_TEMP_FILES}/changed_instances.txt"
                                sed -i "/^${TOR_CURRENT_INSTANCE}$/d" "${TOR_DIR_TEMP_FILES}/pending_instances.txt"
        	                fi
	        	        fi
                    else
                        echo "Did not possible to start the TOR instance of number ${TOR_CURRENT_INSTANCE}!"
                        echo "Look what the problem and execute the ${PWD}/functions/999_let_the_g4sp4rz1nh0_play.sh again!"
                        exit 1
                    fi
                fi
            done
        else
            echo "Did not possible to get the instance numbers!"
            exit 1
        fi
    else
        echo "Empty Next Country variable!!"
        exit 1
    fi
}

if ! touch "${TOR_DIR_TEMP_FILES}/changed_instances.txt"; then
    echo "Didn't possible create ${TOR_DIR_TEMP_FILES}/changed_instances.txt file."
    echo "Run \"bash g4sp4rz1nh0 --kill\" to kill this execution."
    exit 1
else
    ALL_INSTANCES="$(grep -v "^#" "${TOR_DIR_TEMP_FILES}/instances_running_list.txt" | awk -F',' '{print $2}' | sort -R)"
    TOTAL_INSTANCES=$(grep -v "^#" "${TOR_DIR_TEMP_FILES}/instances_running_list.txt" | awk -F',' '{print $2}' | wc -l)
    echo "${ALL_INSTANCES}" > "${TOR_DIR_TEMP_FILES}/pending_instances.txt" 
    while :; do
	    seq 1 "${TOTAL_COUNTRIES_TO_CHANGE}" > "${TOR_DIR_TEMP_FILES}/loop_instances_to_change.txt"
    	while read -r count; do
            TOTAL_CHANGED=$(wc -l "${TOR_DIR_TEMP_FILES}/changed_instances.txt" | awk '{print $1}')
            if [ ${TOTAL_CHANGED} -eq ${TOTAL_INSTANCES} ] ; then
                > "${TOR_DIR_TEMP_FILES}/changed_instances.txt"
                echo "${ALL_INSTANCES}" > "${TOR_DIR_TEMP_FILES}/pending_instances.txt"
            fi
            RANDOM_COUNTRY=$(grep -v "^#" "${TOR_DIR_TEMP_FILES}/instances_running_list.txt" | awk -F',' '{print $3}' | sort -R | head -n1)
            if [ -n "${RANDOM_COUNTRY}" ]; then
                change_country_on_the_fly "${RANDOM_COUNTRY}"
            fi
            sleep 5
	    done < "${TOR_DIR_TEMP_FILES}/loop_instances_to_change.txt"
    	sleep "$(shuf -i1-"${CHANGE_COUNTRY_INTERVAL}" -n1)"
    done
fi
