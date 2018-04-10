#!/bin/bash

function check() {
	local DIG_OPT="+noall +answer +ttlid"
	local domain="$1"
	echo "== domain $domain =="
	local SPF=$((dig ${DIG_OPT} TXT $domain | awk '{$1=""; print}' | grep -i "spf1"; echo) | paste -sd "\n" -)
	[ -n "$SPF" ] && {
		echo "  SPF: "; 
		echo -ne "    "
		echo "$SPF"
	}
	local DMARC=$( (dig ${DIG_OPT} TXT _dmarc.$domain | awk '{$1=""; print}'; echo) | paste -sd "\n" -) 
	[ -n "$DMARC" ] && {
		echo "  DMARC: " 
		echo -ne "    " 
		echo "$DMARC"
		echo -ne "    " ; dig ${DIG_OPT} TXT $domain._report._dmarc.$domain | paste -sd "\n" - 
	}
	echo
}

for d in $@;
do
	check "$d"
done
