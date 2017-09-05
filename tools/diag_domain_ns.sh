#!/bin/bash

TEMPFILE=$(mktemp)

function echo_color ()
{
    local OPT="";
    local LIGHT=1;
    local BG_BLACK=1;
    while [ 0 ]; do
        case "$1" in
            "-n")
                OPT="-n";
                shift;
                continue
            ;;
            "-l")
                LIGHT=0;
                shift;
                continue
            ;;
            "-b")
                BG_BLACK=0;
                shift;
                continue
            ;;
            *)
                break
            ;;
        esac;
    done;
    local COLOR=$1;
    shift;
    [ ${BG_BLACK} -eq 0 ] && {
        tput -T $TERM setaf 15;
        tput -T $TERM setab 0
    };
    if [ $LIGHT -eq 0 ]; then
        tput -T $TERM setaf $(( $COLOR + 8 )) 2> /dev/null;
        if [ $? -ne 0 ]; then
            tput -T $TERM setaf $COLOR;
        fi;
    else
        tput -T $TERM setaf $COLOR;
    fi;
    echo -e $OPT "$@";
    tput sgr0;
    [ ${BG_BLACK} -eq 0 ] && {
        tput -T $TERM setaf 15;
        tput -T $TERM setab 0
    }
}
function echo_red() {
        local OPT=""
        local LIGHT=""
	local BG_BLACK=""
	while [ 0 ];
        do
                case "$1" in
                        "-n") OPT="-n"; shift; continue;;
                        "-l") LIGHT="-l"; shift; continue;;
                        "-b") BG_BLACK="-b"; shift; continue;;
                        *) break;;
                esac
        done
        echo_color $OPT $LIGHT ${BG_BLACK} 1 "$@"
}
function echo_green() {
        local OPT=""
	local LIGHT=""
	local BG_BLACK=""
	while [ 0 ];
        do
                case "$1" in
                        "-n") OPT="-n"; shift; continue;;
                        "-l") LIGHT="-l"; shift; continue;;
                        "-b") BG_BLACK="-b"; shift; continue;;
                        *) break;;
                esac
        done
        echo_color $OPT $LIGHT ${BG_BLACK} 2 "$@"
}

function echo_yellow ()
{
    local OPT="";
    local LIGHT="";
    local BG_BLACK="";
    while [ 0 ]; do
        case "$1" in
            "-n")
                OPT="-n";
                shift;
                continue
            ;;
            "-l")
                LIGHT="-l";
                shift;
                continue
            ;;
            "-b")
                BG_BLACK="-b";
                shift;
                continue
            ;;
            *)
                break
            ;;
        esac;
    done;
    echo_color $OPT $LIGHT ${BG_BLACK} 3 "$@"
}
function echo_blue() {
        local OPT=""
	local LIGHT=""
	local BG_BLACK=""
	while [ 0 ];
        do
                case "$1" in
                        "-n") OPT="-n"; shift; continue;;
                        "-l") LIGHT="-l"; shift; continue;;
                        "-b") BG_BLACK="-b"; shift; continue;;
                        *) break;;
                esac
        done
        echo_color $OPT $LIGHT ${BG_BLACK} 4 "$@"
}

function header_double() {
	local TEXT="$1"
	echo "=${TEXT}=" | tr '[[:print:]]' '='
	echo " $TEXT"
	echo "=${TEXT}=" | tr '[[:print:]]' '='
}
function header_simple() {
	local TEXT="$1"
	echo "-${TEXT}-" | tr '[[:print:]]' '-'
	echo " $TEXT"
	echo "-${TEXT}-" | tr '[[:print:]]' '-'
}
trap ctrl_c INT
function ctrl_c() {
	[ -w ${TEMPFILE} ] && {
		#echo_yellow "Deleting ${TEMPFILE}" >&2
		rm ${TEMPFILE}
	}
}

function Usage() {
    local PROG="$1"
    cat <<EOT
Usage:
    $PROG [+tcp] [-h] domains

with:
    -h: show this help and exits.
    domains: a space-separated list of domains (domain1.tld domain2.tld 5.168.192.in-addr.arpa. ...)
EOT
}

DIG_OPTS="+time=1 +tries=1 +retry=1"
if [ "$1" = "+tcp" ];
then
	DIG_OPTS="${DIG_OPTS} +tcp"
	shift
fi

if [ "$1" = "-h" ];
then
    Usage "$0"
    exit 0
fi

if [ ${#@} -eq 0 ];
then
    Usage "$0"
    exit 0
fi

for d in $@;
do
	header_double "NS de $d"
	for h in $(dig +noall +short NS $d);
	do
		echo -ne "$h: "
		dig +noall +answer +short AAAA $h A $h 2> /dev/null | paste -sd ' ' - | tee -a $TEMPFILE
	done | column -t | sort -k2,2 -n
	echo
	header_simple "$d"
	
	headers="nameserver_address master hostmaster serial refresh retry expire minimum"
	(
	echo "${headers}"
	echo "${headers}" | tr '[:graph:]' '='
	while read IP;
	do
		echo -ne "${IP} "
		(dig @${IP} +noall +answer +short ${DIG_OPTS} SOA $d | grep -v "^;;") || echo "unreacheable"
	done < <(cat $TEMPFILE | tr ' ' "\n") 
	echo
	) | column -t
	ctrl_c
done


