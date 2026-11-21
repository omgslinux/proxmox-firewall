# template_mail_inc.sh
# Servidor de correo (Postfix + Dovecot) - contenedor <ID> (<IP privada>)
#
# Cada puerto se abre explícitamente con 1. Por defecto: 25, 587 y 993.
# Cambia a 1 los que necesites y deja a 0 los que no.

# --- Envío (SMTP) ---
#MAIL_SMTP="1"      # SMTP MTA a MTA (recepción de correo de otros servidores)
#MAIL_SMTPAUTH="1"     # Submission con STARTTLS y autenticación
#MAIL_SMTPS=""    # SMTPS (SSL implícito)

# --- Recepción (IMAP) ---
#MAIL_IMAP=""     # IMAP con STARTTLS
#MAIL_IMAPS="1"    # IMAPS (SSL implícito)

# --- Recepción (POP3, opcional) ---
#MAIL_POP3=""     # POP3 con STARTTLS
#MAIL_POP3S=""    # POP3S (SSL implícito)

# --- Reglas ---
if [ -n "$MAIL_SMTP" ]; then
    nat_ipport2ipport "$PUBIP:25" "$PRIVIP:25" tcp
fi
if [ -n "$MAIL_SMTPAUTH" ]; then
    nat_ipport2ipport "$PUBIP:587" "$PRIVIP:587" tcp
fi
if [ -n "$MAIL_SMTPS" ]; then
    nat_ipport2ipport "$PUBIP:465" "$PRIVIP:465" tcp
fi
if [ -n "$MAIL_IMAP_143" ]; then
    nat_ipport2ipport "$PUBIP:143" "$PRIVIP:143" tcp
fi
if [ -n "$MAIL_IMAPS_993" ]; then
    nat_ipport2ipport "$PUBIP:993" "$PRIVIP:993" tcp
fi
if [ -n "$MAIL_POP3_110" ]; then
    nat_ipport2ipport "$PUBIP:110" "$PRIVIP:110" tcp
fi
if [ -n "$MAIL_POP3S_995" ]; then
    nat_ipport2ipport "$PUBIP:995" "$PRIVIP:995" tcp
fi

unset PUBIP PRIVIP
unset MAIL_SMTP5 MAIL_SMTPAUTH MAIL_SMTPS
unset MAIL_IMAP MAIL_IMAPS
unset MAIL_POP3 MAIL_POP3S
