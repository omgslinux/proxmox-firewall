# iptables_www_inc.sh
# Servidor web estándar (nginx/apache) - contenedor <ID> (<IP privada>)
# Puertos: 80 (HTTP), 443 (HTTPS)

#PUBIP="<IP pública>"
#PRIVIP="<IP privada>"

# --- Puertos explícitos (1 = abrir, 0 = cerrar) ---
#WWW_HTTP="1"     # HTTP
#WWW_HTTPS="1"   # HTTPS

# --- Reglas ---
if [ -n "$WWW_HTTP" ]; then
    nat_ipport2ipport "$PUBIP:80" "$PRIVIP:80" tcp
fi
if [ -n "$WWW_HTTPS" ]; then
    nat_ipport2ipport "$PUBIP:443" "$PRIVIP:443" tcp
fi

unset PUBIP PRIVIP
unset WWW_HTTP WWW_HTTPS
