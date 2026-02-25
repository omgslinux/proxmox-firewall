#!/bin/bash

PARAMS_FILE="/etc/network/iptables_params_inc.sh"

if [[ ! -s $PARAMS_FILE ]];then
    echo "NO EXISTE ${PARAMS_FILE}"
    exit 1
fi

. ${PARAMS_FILE}

function blacklist()
{
    for ipblack in $@; do
	if [[ $INPUT != "DROP" ]];then
	    /sbin/iptables -A INPUT -s $ipblack -j DROP
	fi
	if [[ $OUTPUT != "DROP" ]];then
	    /sbin/iptables -A OUTPUT -d $ipblack -j DROP
	fi
    done
}

function whitelist()
{
    for ipwhite in $@; do
	/sbin/iptables -A INPUT -s $ipwhite -j ACCEPT
	/sbin/iptables -A OUTPUT -d $ipwhite -j ACCEPT
	permitir_icmp_byip $ipwhite
    done
}

function parar()
{
    iptables -t nat -F
    iptables -t mangle -F
    iptables -t filter -F
    iptables -P FORWARD ACCEPT
    iptables -P INPUT ACCEPT
    iptables -P OUTPUT ACCEPT
}

function permitir_icmp_byif()
{
    for ifping in $@;do
	iptables -A INPUT -i $ifping -p icmp --icmp-type echo-request -j ACCEPT
	iptables -A OUTPUT -o $ifping -p icmp --icmp-type echo-reply -j ACCEPT
    done
}

function permitir_icmp_byip()
{
    for ipping in $@;do
	iptables -A INPUT -s $ipping -p icmp --icmp-type echo-request -j ACCEPT
	iptables -A OUTPUT -d $ipping -p icmp --icmp-type echo-reply -j ACCEPT
    done
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
	    iptables -t nat -A POSTROUTING -s $(get_net $iflocal) -d $(get_net $iflocal2) -j ACCEPT
	    #iptables -A FORWARD -o $iflocal -j ACCEPT
	    fi
        done
    	iptables -A INPUT -i $iflocal -j ACCEPT
	iptables -A OUTPUT -o $iflocal -j ACCEPT
	permitir_icmp_byif $iflocal
    done
}

function permitir_puertos()
{
    for i in $@; do
	/sbin/iptables -A INPUT -i $DEV_PUB -p tcp --dport $i $IEXTRA -j ACCEPT
	/sbin/iptables -A INPUT -i $DEV_PUB -p udp --dport $i $IEXTRA -j ACCEPT
	/sbin/iptables -A OUTPUT -p tcp --dport $i $OEXTRA -j ACCEPT
	/sbin/iptables -A OUTPUT -p udp --dport $i $OEXTRA -j ACCEPT
    done
}

function nat_ip2ip()
{
   # Hace nat desde fuera hacia adentro de todo lo que llega a una ip pública, y sale al exterior con esa misma IP
    __PUBIP=$1
    __PRIVIP=$2
    iptables -t nat -A PREROUTING --dst $__PUBIP -j DNAT --to-destination $__PRIVIP
    iptables -t nat -A POSTROUTING --src $__PRIVIP -o $DEV_PUB -j SNAT --to-source $__PUBIP

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
    iptables -t nat -D PREROUTING --dst $_SRCHOST -p $_PROTO --dport $_SRCPORT_FILTER -j DNAT --to-destination $_DSTHOST:$_DSTPORT_TARGET 2>/dev/null
    iptables -t nat -A PREROUTING --dst $_SRCHOST -p $_PROTO --dport $_SRCPORT_FILTER -j DNAT --to-destination $_DSTHOST:$_DSTPORT_TARGET

    # --- REGLA SNAT (SALIDA) ---
    # Filtro usa ":" | Destino usa "-"
    iptables -t nat -D POSTROUTING --source $_DSTHOST -p $_PROTO --sport $_DSTPORT_FILTER -j SNAT --to-source $_SRCHOST:$_SRCPORT_TARGET 2>/dev/null
    iptables -t nat -A POSTROUTING --source $_DSTHOST -p $_PROTO --sport $_DSTPORT_FILTER -j SNAT --to-source $_SRCHOST:$_SRCPORT_TARGET
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
    iptables -t nat -F
    iptables -t mangle -F
    iptables -t filter -F
    iptables -t filter -P INPUT $INPUT
    iptables -t filter -P FORWARD ACCEPT
    iptables -t filter -P OUTPUT $OUTPUT

    permitir_local lo $LOCAL_DEVS

    whitelist $WHITELIST

    blacklist $BLACKLIST

    permitir_puertos $PUERTOS

    if [[ $PING_PUB ]];then
        permitir_icmp_byif $DEV_PUB
	if [[ $OUTPUT == "DROP" ]];then
	    iptables -A OUTPUT -o $DEV_PUB -j ACCEPT
	fi
    fi

    # Denegamos el resto
    if [[ $INPUT != "DROP" ]];then
        iptables -A INPUT -i $DEV_PUB -p tcp --dport 21:65535 -j DROP
        iptables -A INPUT -i $DEV_PUB -p udp --dport 21:65535 -j DROP
    else
        iptables -A INPUT -i $DEV_PUB -m state --state ESTABLISHED -j ACCEPT
    fi

    for f in $(ls /etc/network/iptables_extra_*_inc.sh);do
        . $f
    done

    if [[ $DEV_NAT ]];then
        # Para internet
	iptables -t nat -A POSTROUTING -d 0/0 -j MASQUERADE
    fi


}

if [[ $1 == "start" ]];then
   arrancar
else
   parar
fi
