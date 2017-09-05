#!/bin/bash

FILE=$(dirname $0)/check_domains_output
LASTCHECK=$(head -1 $FILE)
RETCODE=$(tail -1 $FILE)

NBDOMAINS=$(head -2 $FILE | tail -1)


#RETCODE=$(head -2 $FILE | tail -1)
#NBDOMAINS=$(head -3 $FILE | tail -1)

case $RETCODE in
        #0 | 2) echo "Last check: $LASTCHECK, $NBDOMAINS"; (tail -n +3 $FILE | head -4 | awk '{print $1}' | tr -d ':' | paste -sd ' ' - ); exit $RETCODE;;
        0 | 2) echo "Last check: $LASTCHECK, $NBDOMAINS"; (tail -n +3 $FILE | sed '$d' | awk '{print "(",$0,")"}' | tr -d ':' | paste -sd ' ' -  | tr '|' "\n"); exit $RETCODE;;
        *) echo "Last check: $LASTCHECK, status unknown"; exit 3 ;;
esac
