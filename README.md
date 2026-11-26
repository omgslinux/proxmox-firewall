# proxmox-firewall
Bash script to generate filter and nat rules for iptables

## Introduction
I wrote this simple script for an easy management of basic filter and rules for iptables, instead of any other "heavy" tools for such an, theorically, easy task.

Apart from basic filter rules (customizable via config file), there are wrappers for easy management of port forwarding and ip forwarding.

## Installation
The files can live in any custom directory, but since they're somehow bound to network interfaces, it's better to create the directory and `cd` to that directory, so you always run the script as `./iptables.sh`. The script <code>iptables.sh</code> can be run without any parameter (which resets any existing rule) or with the <code>start</code> parameter, which procesess all files and generates the ruleset. It can be run manually at any time, and set in the post-up of the last interface that comes up.

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


Then, you can have multiple `iptables_extra_*_inc.sh` files which will be included at the end of the workflow, with settings for port forwarding or ip forwarding.

There are two ways to use these files:

**1. Classic style (direct calls).** Scripts are bash scripts, so bash rules must be applied. You call `nat_ipport2ipport` and/or `nat_ip2ip` directly with the proper parameters. For example:

```bash
# iptables_extra_http_inc.sh
# Forward port 80 and 443 from public ip to a dmz host
PUBIP="100.100.100.100"
PRIVIP="192.168.52.103"
PUBPORT=80
nat_ipport2ipport $PUBIP:$PUBPORT $PRIVIP:$PUBPORT
PUBPORT=443
nat_ipport2ipport $PUBIP:$PUBPORT $PRIVIP:$PUBPORT

# Full NAT by ip (ip forwarding)
PUBIP="51.38.6.180"
PRIVIP="192.168.55.101"
nat_ip2ip $PUBIP $PRIVIP

unset PUBPORT PUBIP PRIVIP
```

**2. Template style (declarative).** Instead of calling the NAT functions yourself, you declare the public and private IPs (and optionally the service type) and the script will load the matching `template_<TYPE>_inc.sh` file, which already contains the port and protocol definitions. For example:

```bash
# iptables_extra_www_inc.sh
TYPE="www"
PUBIP="100.100.100.100"
PRIVIP="192.168.52.103"
```

If `TYPE` is omitted, it defaults to `custom`, and the `PORTS` variable is used to define the ports to forward:

```bash
# iptables_extra_custom_inc.sh
PUBIP="100.100.100.100"
PRIVIP="192.168.52.103"
PORTS="8080 8443 9000/udp"
```

In `PORTS`, an entry without a suffix (or with `/tcp`) is treated as TCP, and an entry with `/udp` is treated as UDP.

Available templates are listed in the `_templates/` directory with the pattern `template_<TYPE>_inc.sh` (for example `template_www_inc.sh`, `template_mail_inc.sh`, `template_jitsi_inc.sh`, `template_prosody_inc.sh`). Check the corresponding file to see which ports and protocols it opens.

Note that `PUBIP` and `PRIVIP` must both be defined for a template to be applied. If they are missing, the file is treated as a classic one and no template is loaded. The defaults are defined in `_defaults_inc.sh`, which is loaded before each `iptables_extra_*_inc.sh` file, so you only need to set the values you want to override.
