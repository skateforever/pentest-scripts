#!/bin/bash

create_initial_directory_structure_files(){
# Create directory and checking if the required structure is ready
directories+=("${g4sp4rz1nh0_DIR_TEMP_FILES}" "${TOR_DIR_TEMP_FILES}" "${HIDDEN_SERVICES_DIR_TEMP_FILES}" "${PRIVOXY_DIR_TEMP_FILES}" "${HAPROXY_DIR_TEMP_FILES}")

if [[ -z "${directories[@]}" ]]; then
    echo "Look at the configuration files, as there is no structure configured to be created!"
    exit 1
fi

for dir in "${directories[@]}"; do
    if [ ! -d "${dir}" ]; then
        if ! mkdir -p "${dir}"; then
            [[ "${dir}" == "${g4sp4rz1nh0_DIR_TEMP_FILES}" ]] && touch "${g4sp4rz1nh0_startup_log}"
            echo "The directory ${dir} is necessary and has not been created, check what is happening that $0 is failing to create the directory."
            rm -rf "${g4sp4rz1nh0_DIR_TEMP_FILES}"
            exit 1
        fi
    fi
done

# Adjusting the permissions of the speed tor temp folder.
chown -R "${USER_ID}" "${g4sp4rz1nh0_DIR_TEMP_FILES}"
chmod 700 -R "${g4sp4rz1nh0_DIR_TEMP_FILES}"
}

dependency(){
echo "This script has some dependencies and without it can't be executed.
Please install all dependencies and configure the appropriate configuration
file with the path for the binaries. 

  DEPENDENCIES:

  Setup for local infrastructure
    1) haproxy     --> https://www.haproxy.org/
    2) tor         --> https://www.torproject.org/
    3) privoxy     --> https://www.privoxy.org/
    4) expect      --> https://core.tcl-lang.org/expect/index

  Only for setup remote infrastructure
    5) terraform   --> https://www.terraform.io/
    6) ansible     --> https://www.ansible.com/
    7) openvpn     --> https://openvpn.net/
    8) iptables    --> https://www.netfilter.org/
"
exit 1
}

increasing_anonymization(){
    echo "Install the follow extension on your browser:"
    echo "\t* FoxyProxy (https://getfoxyproxy.org/);"
    echo "\t* HTTPS Everywhere (https://www.eff.org/https-everywhere);"
}

kill_g4sp4rz1nh0_execution(){
    for cmd in "${g4sp4rz1nh0_PATH}/functions/999_let_the_g4sp4rz1nh0_play.sh" "${TOR_DIR_TEMP_FILES}/force_new_circuit.sh" "$(command -v haproxy)" "$(command -v privoxy)" "$(command -v tor)"; do
        for pid in $(pgrep -f "${cmd}"); do
            kill -9 "${pid}" > /dev/null 2>&1
        done
    done
    rm -rf "${g4sp4rz1nh0_DIR_TEMP_FILES}" > /dev/null 2>&1
}

usage(){
echo -e "Usage:
Sintax sample: bash g4sp4rz1nh0.sh -i 2 -c 15 -re exit -l
       
 -c |--countries         : Defines the number of (C)OUNTRIES. [NEEDED]
 -i |--instances         : Defines the number of (I)NSTANCES per country. [NEEDED]
 -k |--kill              : Will terminate previous execution of $0, ignoring all other options.
 -l |--local             : Configure a local infrastructure for g4sp4r1nh0 [NEEDED if your infra is local]
                           the local infrastructure containing HAproxy and TOR.
 -p |--paranoid          : Force change country from time to time to make identification more difficult.
 -r |--remote            : Configure a remote infrastructure for g4sp4rz1nh0 [NEEDED if your infra is remote]
                           the local infrastructure containing HAproxy and TOR through VPS running a VPN.
 -re|--relay-enforcing   : Defines the (R)ELAY (E)NFORCING approach. [NEEDED]

                           Ps: To setup the list of countries you must edit the configuration
                           file. This options will control how the script will manipulate the
                           TOR ENTRY NODE and the TOR EXIT NODE.
       
                           The options for the (R)elay (E)nforcing are:
                           1) entry: Sets a specific country as ENTRY relay
                                     and will use a different country as EXIT relay.
                                     The load balancing algorithm is: Round Robin.

                           2) exit:  Sets a specific country as EXIT relay
                                     and will use a different country as ENTRY relay.
                                     This option give you the control of the EXIT relays and
                                     could be used to bypass GeoIP protections.
                                     Whoever reduces the number of EXIT realys available.
                                     The load balancing algorithm is: Round Robin.

                           3) speed: This option is the fastest option because reduces the
                                     delay between the hops of relays inside TOR network by
                                     setting the same country as ENTRY and EXIT node.
                                     All other countries will be set as EXCLUDE NODES, so the
                                     middle relay will hopefully also be selected inside the
                                     same country.

                                     The load balancing algorithm for this option is:
                                     Least Connections Round Robin.

                                     This algorithm sends the next request for the instances
                                     with least number of request in the queue but still
                                     performing the load balancing between all other instances.

                                     Do not use this option for sensitive activities because
                                     it could reduce the security if you consider that your
                                     adversary could easily compromise a TOR ENTRY-NODE and
                                     a TOR EXIT-NODE in the same country.
                                   
                                     Some countries doesn't have ENTRY GUARDS and EXIT NODES
                                     enough to create a valid circuits.

                                     Keep your eyes on the health check URL to identify
                                     countries with this issue. By default the health check is:
                                     http://127.0.0.1:63537/g4sp4rz1nh0_status"
exit 1
}
