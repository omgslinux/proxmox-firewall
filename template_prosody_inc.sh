# Template for prosody

# Container/host public ip
#PUBIP="192.168.11.9"

# Containter private ip
#PRIVIP="192.168.200.103"



# Leave the rest unchanged unless you know what you're doing


# Prosody XMPP server - contenedor 103 (192.168.200.103)
# TCP: 5222 (client), 5260 (components), 5280 (HTTP BOSH), 5281 (HTTPS BOSH)
# UDP: 3478 (STUN/TURN), 5349 (TURN over TLS)


# Puertos TCP
PUBPORTS_TCP="5222 5260 5280 5281"
for PUBPORT in $PUBPORTS_TCP; do
    nat_ipport2ipport "$PUBIP:$PUBPORT" "$PRIVIP:$PUBPORT" tcp
done

# Puertos UDP (STUN/TURN)
PUBPORTS_UDP="3478 5349"
for PUBPORT in $PUBPORTS_UDP; do
    nat_ipport2ipport "$PUBIP:$PUBPORT" "$PRIVIP:$PUBPORT" udp
done

unset PUBIP PRIVIP PUBPORTS_TCP PUBPORTS_UDP PUBPORT
