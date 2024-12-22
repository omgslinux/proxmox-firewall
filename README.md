# proxmox-firewall
Bash script to generate filter and nat rules for iptables

## Introduction
I wrote this simple script for an easy management of basic filter and rules for iptables, instead of any other "heavy" tools for such an, theorically, easy task.

Apart from basic filter rules (customizable via config file), there are wrappers for easy management of port forwarding and ip forwarding.

## Installation
The files are all in <code>/etc/network</code>. The script <code>iptables.sh</code> can be run without any parameter (which resets any existing rule) or with the <code>start</code> parameter, which procesess all files and generates the ruleset. It can be run manually at any time, and set in the post-up of the last interface that comes up.

## Files
Apart from the <code>iptables.sh</code> script, there's a config file, <code>iptables_params_inc.sh</code> which must have the proper values for your system. 

```
# Comment if you don't want any debug
DEBUG="1"

# Internet interface
DEV_PUB="eno1"

# NAT interface for local nets
DEV_NAT="eno1"

# Comment to disallow ping
PING_PUB="1"

# List of allowed ports, separated with spaces
PUERTOS="22 80 8006"

# Default INPUT policy. "ACCEPT" or "DROP"
INPUT="DROP"

# Default OUTPUT policy. "ACCEPT" or "DROP"
OUTPUT="ACCEPT"

# Local interfaces, excluding $DEV_PUB and lo
LOCAL_DEVS="vmbr0 vmbr1"

# Forbidden ips and/or networks, separated with spaces
BLACKLIST=""

# Whitelisted ips and/or networks, separated with spaces
WHITELIST=""
```

Then, you can have multiple <code>iptables_extra_*_inc.sh</code> files which will be included at the end of the workflow, with settings for port forwarding or ip forwarding. Scripts are bash scripts, so bash rules must be applied. For example:

```
# iptables_extra_http_inc.sh
# Forward port 80 and 443 from public ip to a dmz host
PUBIP="200.133.79.52"
PRIVIP="192.168.52.103"
PUBPORT=80
nat_ipport2ipport $PUBIP:$PUBPORT $PRIVIP:$PUBPORT
PUBPORT=443
nat_ipport2ipport $PUBIP:$PUBPORT $PRIVIP:$PUBPORT


# Full NAT by ip (ip forwarding)
PUBIP="51.38.6.180"
PRIVIP="192.168.55.101"

nat_ip2ip $PUBIP $PRIVIP

unset PUBPORT PUBIP

```

So, the <code>nat_ipport2ipport</code> and <code>nat_ip2ip</code> have to be called with proper parameters in order to work.
