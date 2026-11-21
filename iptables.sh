#!/bin/bash

PARAMS_FILE="/etc/network/iptables_params_inc.sh"

if [[ ! -s $PARAMS_FILE ]];then
    echo "NO EXISTE ${PARAMS_FILE}"
    exit 1
fi

. ${PARAMS_FILE}

function _ipt()
{
   iptables $@
}

function blacklist()
{
    for ipblack in $@; do
	if [[ $INPUT != "DROP" ]];then
	    _ipt -A INPUT -s $ipblack -j DROP
	fi
	if [[ $OUTPUT != "DROP" ]];then
	    _ipt -A OUTPUT -d $ipblack -j DROP
	fi
    done
}

function whitelist()
{
    for ipwhite in $@; do
	_ipt -A INPUT -s $ipwhite -j ACCEPT
	_ipt -A OUTPUT -d $ipwhite -j ACCEPT
	permitir_icmp_byip $ipwhite
    done
}

function parar()
{
    _ipt -t nat -F
    _ipt -t mangle -F
    _ipt -t filter -F
    _ipt -P FORWARD ACCEPT
    _ipt -P INPUT ACCEPT
    _ipt -P OUTPUT ACCEPT
}

function permitir_icmp_byif()
{
    for ifping in $@;do
        _ipt -A INPUT -i $ifping -p icmp --icmp-type echo-request -j ACCEPT
        _ipt -A OUTPUT -o $ifping -p icmp --icmp-type echo-reply -j ACCEPT
    done
}

function permitir_icmp_byip()
{
    for ipping in $@;do
	_ipt -A INPUT -s $ipping -p icmp --icmp-type echo-request -j ACCEPT
	_ipt -A OUTPUT -d $ipping -p icmp --icmp-type echo-reply -j ACCEPT
    done
}

function get_ip ()
{
    local _IPS
    _IPS=$(ip -4 -o addr show dev "$1" 2>/dev/null | awk '{ sub(/\/.*/,"",$4); print $4 }')
    local _N=$(echo "$_IPS" | grep -c .)

    if [[ $_N -ne 1 ]]; then
        echo "get_ip: '$1' tiene $_N IPv4 (se esperaba exactamente 1)" >&2
        return 1
    fi

    echo "$_IPS"
}

function get_net ()
{
	ip a l $1|grep -w inet|awk '{ print $2 }'
}

function permitir_local()
{
    for iflocal in $@;do
        for iflocal2 in $@;do
            if [[ $iflocal != $iflocal2 && $iflocal != "lo" && $iflocal2 != "lo" ]];then
               _ipt -t nat -A POSTROUTING -s $(get_net $iflocal) -d $(get_net $iflocal2) -j ACCEPT
	           #iptables -A FORWARD -o $iflocal -j ACCEPT
    	    fi
        done
    	_ipt -A INPUT -i $iflocal -j ACCEPT
    	_ipt -A OUTPUT -o $iflocal -j ACCEPT
    	permitir_icmp_byif $iflocal
    done
}

function permitir_puertos()
{
    for i in $@; do
	_ipt -A INPUT -i $DEV_PUB -p tcp --dport $i $IEXTRA -j ACCEPT
	_ipt -A INPUT -i $DEV_PUB -p udp --dport $i $IEXTRA -j ACCEPT
	_ipt -A OUTPUT -p tcp --dport $i $OEXTRA -j ACCEPT
	_ipt -A OUTPUT -p udp --dport $i $OEXTRA -j ACCEPT
    done
}

function nat_ip2ip()
{
   # Hace nat desde fuera hacia adentro de todo lo que llega a una ip pública, y sale al exterior con esa misma IP
    __PUBIP=$1
    __PRIVIP=$2
   _ipt -t nat -A PREROUTING --dst $__PUBIP -j DNAT --to-destination $__PRIVIP
   _ipt -t nat -A POSTROUTING --src $__PRIVIP -o $DEV_PUB -j SNAT --to-source $__PUBIP

}

function nat_ifport2ipport()
{
    local _IFACE=$(echo $1 | cut -d ":" -f1)
    local _REST=$(echo $1 | cut -d ":" -f2-)
    local _SRCIP

    _SRCIP=$(get_ip "$_IFACE") || return 1

    nat_ipport2ipport $_SRCIP:$_REST $2 ${3:-tcp}
}

function nat_ipport2ipport()
{
    # $1: IP_PUBLICA:PUERTO_INI:PUERTO_FIN (o IP:PUERTO)
    # $2: IP_PRIVADA:PUERTO_INI:PUERTO_FIN (o IP:PUERTO)
    # $3: protocolo (udp/tcp)

    local _SRC=$1
    local _DST=$2
    local _PROTO=${3:-tcp}

    # Extraer IPs y Puertos (usando ":" como delimitador único para parsear)
    local _SRCHOST=$(echo $_SRC | cut -d ":" -f1)
    local _SRCPORT_RAW=$(echo $_SRC | cut -d ":" -f2-) # Coge todo lo que sigue a la IP
    local _DSTHOST=$(echo $_DST | cut -d ":" -f1)
    local _DSTPORT_RAW=$(echo $_DST | cut -d ":" -f2-)

    # Convertir formato para filtros (IP:PUERTO_INI:PUERTO_FIN -> PUERTO_INI:PUERTO_FIN)
    # Reemplazamos cualquier "-" por ":" para el filtro
    local _SRCPORT_FILTER=$(echo $_SRCPORT_RAW | tr '-' ':')
    local _DSTPORT_FILTER=$(echo $_DSTPORT_RAW | tr '-' ':')

    # Convertir formato para TARGET (SNAT/DNAT)
    # Aquí el puerto debe ir precedido por ":" y el rango separado por "-"
    local _SRCPORT_TARGET=$(echo $_SRCPORT_RAW | tr ':' '-')
    local _DSTPORT_TARGET=$(echo $_DSTPORT_RAW | tr ':' '-')

    # --- REGLA DNAT (ENTRADA) ---
    # Filtro usa ":" | Destino usa "-"
   _ipt -t nat -D PREROUTING --dst $_SRCHOST -p $_PROTO --dport $_SRCPORT_FILTER -j DNAT --to-destination $_DSTHOST:$_DSTPORT_TARGET 2>/dev/null
   _ipt -t nat -A PREROUTING --dst $_SRCHOST -p $_PROTO --dport $_SRCPORT_FILTER -j DNAT --to-destination $_DSTHOST:$_DSTPORT_TARGET

    # --- REGLA SNAT (SALIDA) ---
    # Filtro usa ":" | Destino usa "-"
   _ipt -t nat -D POSTROUTING --source $_DSTHOST -p $_PROTO --sport $_DSTPORT_FILTER -j SNAT --to-source $_SRCHOST:$_SRCPORT_TARGET 2>/dev/null
   _ipt -t nat -A POSTROUTING --source $_DSTHOST -p $_PROTO --sport $_DSTPORT_FILTER -j SNAT --to-source $_SRCHOST:$_SRCPORT_TARGET
}

function arrancar()
{
    # Activamos el forwarding entre interfaces
    echo "1">/proc/sys/net/ipv4/ip_forward

    if [[ $DEBUG ]];then
        set -x
    fi

    if [[ -z $DEV_PUB ]];then
	DEV_PUB=$(ip r l|grep ^default|awk '{ print $5 }')
    fi

    # Reglas de enmascaramiento
    if [[ $INPUT != "DROP" ]];then
	INPUT="ACCEPT"
    else
        IEXTRA="-m state --state NEW,ESTABLISHED"
    fi

    if [[ $OUTPUT != "DROP" ]];then
	OUTPUT="ACCEPT"
    else
        OEXTRA="-m state --state ESTABLISHED"
    fi
    _ipt -t nat -F
    _ipt -t mangle -F
    _ipt -t filter -F
    _ipt -t filter -P INPUT $INPUT
    _ipt -t filter -P FORWARD ACCEPT
    _ipt -t filter -P OUTPUT $OUTPUT

    permitir_local lo $LOCAL_DEVS

    whitelist $WHITELIST

    blacklist $BLACKLIST

    permitir_puertos $PUERTOS

    if [[ $PING_PUB ]];then
        permitir_icmp_byif $DEV_PUB
	if [[ $OUTPUT == "DROP" ]];then
	   _ipt -A OUTPUT -o $DEV_PUB -j ACCEPT
	fi
    fi

    # Denegamos el resto
    if [[ $INPUT != "DROP" ]];then
       _ipt -A INPUT -i $DEV_PUB -p tcp --dport 21:65535 -j DROP
       _ipt -A INPUT -i $DEV_PUB -p udp --dport 21:65535 -j DROP
    else
       _ipt -A INPUT -i $DEV_PUB -m state --state ESTABLISHED -j ACCEPT
    fi

    for f in $(ls /etc/network/iptables_extra_*_inc.sh);do
        . $f
    done

    if [[ $DEV_NAT ]];then
        # Para internet
        _ipt -t nat -A POSTROUTING -d 0/0 -j MASQUERADE
    fi


}

if [[ $1 == "start" ]];then
    arrancar
else
    parar
fi
