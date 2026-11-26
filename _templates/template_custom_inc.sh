# template_custom_inc.sh
# Procesa $PORTS como lista de puertos.
# Sin sufijo o con /tcp -> TCP; con /udp -> UDP.
# Ejemplo: PORTS="53 53/udp 587 1194/udp"

#PUBIP="<IP pública>"
#PRIVIP="<IP privada>"


for entry in $PORTS; do
    port="${entry%%/*}"
    proto="${entry#*/}"
    [ "$proto" = "$entry" ] && proto="tcp"   # sin "/" -> TCP
    nat_ipport2ipport "$PUBIP:$port" "$PRIVIP:$port" "$proto"
done

unset PUBIP PRIVIP
unset entry port proto
