# _defaults_inc.sh
TYPE="custom"
PUBIP=""
PRIVIP=""
PORTS=""


# Para TYPE="www"
WWW_HTTP="1"     # HTTP
WWW_HTTPS="1"   # HTTPS


# Para TYPE="mail"
# Servidor de correo (Postfix + Dovecot) - contenedor <ID> (<IP privada>)
#
# Cada puerto se abre explícitamente con 1. Por defecto: 25, 587 y 993.
# Cambia a 1 los que necesites y deja a 0 los que no.

# --- Envío (SMTP) ---
MAIL_SMTP="1"      # SMTP MTA a MTA (recepción de correo de otros servidores)
MAIL_SMTPAUTH="1"     # Submission con STARTTLS y autenticación
MAIL_SMTPS=""    # SMTPS (SSL implícito)

# --- Recepción (IMAP) ---
MAIL_IMAP=""     # IMAP con STARTTLS
MAIL_IMAPS="1"    # IMAPS (SSL implícito)

# --- Recepción (POP3, opcional) ---
MAIL_POP3=""     # POP3 con STARTTLS
MAIL_POP3S=""    # POP3S (SSL implícito)
