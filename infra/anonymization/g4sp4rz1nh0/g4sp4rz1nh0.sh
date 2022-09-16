#!/bin/bash

clear 
echo $0 $@

# Colours
red="\e[31m"
green="\e[32m"
yellow="\e[33m"
reset="\e[0m"

# Banner
echo -e "\t                                                       "
echo -e "\t                      .-.                              "
echo -e "\t         heehee      /aa \_                            "
echo -e "\t                   __\-  / )                 .-.       "
echo -e "\t         .-.      (__/    /        haha    _/oo \      "
echo -e "\t       _/ ..\       /     \               ( \U  /__    "
echo -e "\t      ( \  u/__    /       \__             \/   ___)   "
echo -e "\t       \    \__)   \_.-._._   )  .-.       /     \     "
echo -e "\t       /     \             \`-\`  / ee\_    /       \_ "
echo -e "\t    __/       \               __\  o/ )   \_.-.__   )  " 
echo -e "\t   (   _._.-._/     hoho     (___   \/           '-'   "
echo -e "\t    '-'                        /     \                 "
echo -e "\t    BOOOOOOO                 _/       \    teehee      "
echo -e "\t                            (_____.-._/                "
echo -e "\t                                                       "

if [ -s "${PWD}/configs/startup.cfg" ]; then
    source "${PWD}/configs/startup.cfg"
else
    echo "The ${PWD}/configs/startup.cfg is an important file needed for g4sp4rz1nh0!"
    exit 1
fi 

if [ -s "${PWD}/functions/000_startup.sh" ]; then
    source "${PWD}/functions/000_startup.sh"
else
    echo "The ${PWD}/functions/000_startup.sh is an important file needed for g4sp4rz1nh0!"
    exit 1
fi 

# Check binaries
#for bin in haproxy tor expect privoxy ansible haproxy iptables openvpn terraform; do
for bin in haproxy tor expect privoxy; do
    if [ -z $(command -v "${bin}") ]; then
        echo -e "Please install ${bin}!\n"
        dependency
    fi
done

check_argument(){
    options+=(-c --countries -i --instances -k --kill -l --local -p --paranoid -r --remote -re --relay-enforcing)

    if [[ "${options[@]}" =~ "$1" ]]; then
        echo -e "The argument of ${yellow}\"$1\"${reset} it can not be ${red}\"$2\"${reset}, please, ${yellow} specify a valid one${reset}.\n"
        usage
    fi
}

# Menu
while [[ $# -ne 0 ]]; do
    case $1 in
        -c|--countries)
            COUNTRIES="$2"
            check_argument "${COUNTRIES}"
            if [[ -z "${COUNTRIES}" ]] || [[ ! $2 =~ [0-9] ]]; then \
                echo -e "You need to specify a number to \"-c\" option!\n" ; usage; fi
            shift 2 ;;
        -i|--instances)
            TOR_INSTANCES="$2"
            check_argument "${TOR_INSTANCES}"
            if [[ -z "${TOR_INSTANCES}" ]] || [[ ! "${TOR_INSTANCES}" =~ [0-9] ]]; then \
                echo -e "You need to specify a number to \"-i\" options!\n"; usage; fi
            shift 2 ;;
        -k|--kill)
            shift
            echo "Ignoring all other options."
            kill_g4sp4rz1nh0_execution
            exit 0
            ;;
        -l|--local)
            if [[ "${INFRA}" == "remote" ]]; then
                echo "You can't use -r|--remote with -l|--local to define the infrastructure."
                echo "Choice only one and rerun the $0."
                usage
            else
                unset INFRA
                INFRA=local
                shift
            fi
            ;;
        -p|--paranoid)
            unset CHANGE_COUNTRY_ONTHEFLY
            CHANGE_COUNTRY_ONTHEFLY="yes"
            shift
            ;;
        -r|--remote)
            if [[ "${INFRA}" == "local" ]]; then
                echo "You can't use -l|--local with -r|--remote to define the infrastructure."
                echo "Choice only one and rerun the $0."
                usage
            else
                unset INFRA
                INFRA=remote
                shift
            fi
            ;;
        -re|--relay-enforcing)
            COUNTRY_LIST_CONTROLS="$2"
            check_argument "${COUNTRY_LIST_CONTROLS}"
            RELAY_ENFORCING_OPTIONS=("entry" "exit" "speed")
            if [[ ! "${RELAY_ENFORCING_OPTIONS[*]}" =~ "${COUNTRY_LIST_CONTROLS}" ]]; then
                echo -e "You need to specify a string to \"-re|--relay-enforcing\" option!\n"
                usage
            else
                # Define the load-balance algoritm 
                if [ "${COUNTRY_LIST_CONTROLS}" != "speed" ]; then
	                LOAD_BALANCE_ALGORITHM="roundrobin"
	                HAPROXY_HTTP_REUSE="never"
                else 
	                LOAD_BALANCE_ALGORITHM="leastconn"
	                HAPROXY_HTTP_REUSE="safe"
                fi
                shift 2
            fi
            ;;
        -?*|*)
            usage
    esac
done

if [[ -z "${TOR_INSTANCES}" || -z "${COUNTRIES}" || -z "${COUNTRY_LIST_CONTROLS}" || "${INFRA}" == "none" ]]; then
    echo -e "Please inform the quantitative of parameters necessary to execute the $0!\n" 
    usage
fi

if [ "${infra}" == "none" ] ; then
    echo -e "You need to specify what type of infrastructure you will use, -l|--local or -r|--remote.\n"
    usage
fi

# Checking of configurations files
if [ -d "${PWD}/configs/" ]; then
    # This is the correct sequence to load the g4sp4rz1nh0 configuration
    configs+=(g4sp4rz1nh0.cfg tor.cfg hidden_services.cfg privoxy.cfg haproxy.cfg)
    for cfg in "${configs[@]}"; do
        if [ -s "${PWD}/configs/${cfg}" ]; then
            if [[ "${cfg}" == "tor.cfg" && "${COUNTRY_LIST_CONTROLS}" == "speed" ]]; then
                sed -i "s/^StrictNodes=\".\"/StrictNodes=\"0\"/" "${PWD}/configs/tor.cfg"
            else
                sed -i "s/^StrictNodes=\".\"/StrictNodes=\"1\"/" "${PWD}/configs/tor.cfg"
            fi
            source "${PWD}/configs/${cfg}"
        else
            echo "The configuration file \"${cfg}\" is missing, please check for its absence."
            exit 1
        fi
    done
else
    echo "Directory \"configs\" does not exist, please check directory."
    exit 1
fi

# Checking of function files
if [ -d "${PWD}/functions/" ]; then
    functions+=(001_haproxy.sh 002_tor.sh 003_privoxy.sh 099_utils.sh 999_let_the_fun_begin.sh)
    for function in "${functions[@]}"; do
        if [ -s "${PWD}/functions/${function}" ]; then
            source "${PWD}/functions/${function}"  
        else
            echo "The function file \"${function}\" is missing, please check for its absence."
            exit 1
        fi
    done
else
    echo "Directory \"functions\" does not exist, please check directory."
    exit 1
fi

exit 0
