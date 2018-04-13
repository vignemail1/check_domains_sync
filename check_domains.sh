#!/bin/bash
BASE=$(dirname $0)

FILES=${@:- "$BASE/domains/domains.txt" }

function listDNSip() {
	local domain="$1"
	local dig_opts="$2"
	local local_opts="+time=1 +tries=1 +retry=1"
	for h in $(dig ${local_opts} +short NS ${dig_opts} $domain 2> /dev/null); 
	do 
		dig @0 +short $h A $h AAAA 2> /dev/null
	done
}

function check_domain() {
    local domain="$1"
    local dig_opts="$2"

    local local_opts="+time=1 +tries=1 +retry=1"

    [ -z "$domain" ] && return 0

    local out
    out=$(dig @0 ${local_opts} +nssearch ${dig_opts} $domain 2> /dev/null | tr "[:lower:]" "[:upper:]")
    local has_error=$?

	local ORG_ns_soa=$(echo "$out" | egrep -iq "(8.8.8.8|9.9.9.9|1.1.1.1)" &> /dev/null; echo $?)

    local nb
    local nbdedup
    nb_dedup=$(echo "$out" | grep "SOA " | cut -d' ' -f1-7 | sort | uniq | wc -l | awk '{print $1}')
    nb=$(echo "$out" | grep "SOA " | wc -l | awk '{print $1}')
	local nb_ns=$(dig ${local_opts} +short NS ${dig_opts} $domain 2> /dev/null| wc -l)

	local out_code=0
	if [[ ${ORG_ns_soa} -ne 0 ]];
	then
		if [[ ${nb_dedup} -ne 0 ]];
		then
			# domaine migré chez un autre hebergeur DNS
			let out_code+=10
		fi
	fi

        if [[ ${nb_dedup} -eq 0 ]];
        then
                if [[ ${nb_ns} -eq 0 ]];
                then
                        echo "$domain" #nxdomain
			let out_code+=3
                        return ${out_code}
                else
                        echo "$domain" #silent domain
			let out_code+=4
                        return ${out_code}
                fi
        fi
	local master=$(dig @0 +short $d SOA 2> /dev/null | tr "[:lower:]" "[:upper:]" | awk '{print $1}' | sed 's|\.$||')
	local master_ok=$(echo "${out}" | grep -q "FROM SERVER ${master}" &> /dev/null; echo $?)
        if [[ ${has_error} -ne 0 ]];
        then
		if [[ ${master_ok} -ne 0 ]];
        	then
        	        echo "$domain" #master
        	        let out_code+=5
        	        return ${out_code}
        	fi
                echo "$domain" #partial / conn_error
		let out_code+=1
                return ${out_code}
        fi

        if [[ ${nb} -lt ${nb_ns} ]];
        then
		if [[ ${master_ok} -ne 0 ]];
                then
                        echo "$domain" #master
                        let out_code+=5
                        return ${out_code}
                fi
                echo "$domain" # partial / conn_error: at least one nameserver doesn't respond
		let out_code+=1
                return ${out_code}
        fi

        case ${nb_dedup} in
        1) return ${out_code} ;;
        *) echo "$domain"; let out_code+=2; return ${out_code};; #soa_error
        esac
}

function check_domains_from_file() {
        local fichier="$1"
        local dig_opts="$2"
        local out

        while read d;
        do
		let nb_domains++
                #echo "testing $d..."
                out=$(check_domain $d "${dig_opts}")
                ret=$?
		if [[ $ret -gt 9 ]];
		then
			external+=("$d")
			let ret=${ret}-10
		fi
                case $ret in
                        1) conn_error+=("$d");;
                        2) soa_error+=("$d");;
                        3) nxdomain_error+=("$d");;
                        4) silent_error+=("$d");;
			5) master_error+=("$d");;
                esac
        done < <( egrep -v "^(#|$)" $fichier);
}

nb_domains=0

for file in $FILES;
do
	check_domains_from_file $file
done

nb_errors=$(( ${#silent_error[@]} + ${#soa_error[@]} + ${#conn_error[@]} + ${#master_error[@]} ))
echo "#domains: "${nb_domains}
echo "nxdomain[${#nxdomain_error[@]}]: ${nxdomain_error[@]}"
echo "silent[${#silent_error[@]}]: ${silent_error[@]}"
echo "master[${#master_error[@]}]: ${master_error[@]}"
echo "conn[${#conn_error[@]}]: ${conn_error[@]}"
echo "soa[${#soa_error[@]}]: ${soa_error[@]}"
echo "external[${#external[@]}]: ${external[@]}"
case ${nb_errors} in
        0) exit 0;;
        *) exit 2;;
esac
