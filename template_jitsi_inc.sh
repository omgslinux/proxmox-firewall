# template_jitsi_inc.sh
# Jitsi Meet - contenedor <ID> (<IP privada>)
# Debian 12/13 -> Jitsi actual: puerto de medios UDP 10000
# TCP: 80 (HTTP), 443 (HTTPS/WebSocket), 5349 (Coturn fallback)
# UDP: 10000 (JVB media)

#PUBIP="<IP pública>"
#PRIVIP="<IP privada>"

# Puertos TCP (web y TURN fallback)
PUBPORTS_TCP="80 443 5349"
for PUBPORT in $PUBPORTS_TCP; do
    nat_ipport2ipport "$PUBIP:$PUBPORT" "$PRIVIP:$PUBPORT" tcp
done

# Puerto UDP de medios (JVB)
PUBPORTS_UDP="10000"
for PUBPORT in $PUBPORTS_UDP; do
    nat_ipport2ipport "$PUBIP:$PUBPORT" "$PRIVIP:$PUBPORT" udp
done

unset PUBIP PRIVIP PUBPORTS_TCP PUBPORTS_UDP PUBPORT
