# check\_domain\_sync

A bunch of Bash scripts used to analyze some discrepancies between domains definitions and to check reachability across all configured nameservers for these domains.

Uses Bash and dig.

## NRPE probe

Just run `check_domains` in crontab and use `nrpe_read.sh` to get a NRPE formatted response.

Add domains in the `domains/domains.txt` file, one per line.

`nrpe_read.sh` output example:
~~~
Critical:  check_domains (09/05 15:40:26: 195.221.20.53) : Last check: 2017-09-05 15:40:01, #domains: 256( nxdomain[0]  ) ( silent[0]  ) ( master[0]  ) ( conn[0]  ) ( soa[2] domain1.tld 5.168.192.in-addr-arpa.) (external[0])
~~~


* `nxdomain`: the domain is not registered (anymore?)
* `silent`: none of the nameservers registered for this domain give a response for this domain
* `master`: the master nameserver for this domain is unreachable
* `conn`: at least one of the slave nameservers is unreachable
* `soa`: there is a difference of SOA responses across all nameservers configured for this domain
* `external`: the domain is not handle with our nameserver (anymore?)

## tools/folder

### diag\_domain\_ns.sh

~~~bash
$ ./diag_domain_ns.sh +tcp free.fr
===============
 NS de free.fr
===============
freens1-g20.free.fr.:  212.27.60.19  2a01:e0c:1:1599::22
freens2-g20.free.fr.:  212.27.60.20  2a01:e0c:1:1599::23

---------
 free.fr
---------
nameserver_address   master                hostmaster              serial      refresh  retry  expire  minimum
==================   ======                ==========              ======      =======  =====  ======  =======
212.27.60.20         freens1-g20.free.fr.  hostmaster.proxad.net.  2017090401  10800    3600   604800  86400
2a01:e0c:1:1599::23  freens1-g20.free.fr.  hostmaster.proxad.net.  2017090401  10800    3600   604800  86400
212.27.60.19         freens1-g20.free.fr.  hostmaster.proxad.net.  2017090401  10800    3600   604800  86400
2a01:e0c:1:1599::22  freens1-g20.free.fr.  hostmaster.proxad.net.  2017090401  10800    3600   604800  86400
~~~