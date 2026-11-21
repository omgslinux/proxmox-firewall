# iptables_extra_example_inc.sh
#
# Archivo de ejemplo para publicar servicios en contenedores.
# Cópialo/renómbralo como iptables_extra_<nombre>_inc.sh y rellena los valores.
#
# Variables:
#   PUBIP   -> IP pública (host) a la que llega el tráfico.
#   PRIVIP  -> IP privada (contenedor) que recibe el tráfico.
#   TYPE    -> Plantilla a usar: www | mail | jitsi | prosody | custom
#              (si se omite, se usa "custom").
#   PORTS   -> Solo para TYPE="custom": lista de puertos.
#              Sin sufijo o /tcp -> TCP; con /udp -> UDP.
#              Ejemplo: PORTS="53 53/udp 587 1194/udp"
#
# Se establecen unos valores predeterminados en _defaults_inc.
#
# Para dudas sobre qué puertos abre cada plantilla, consulta
# el archivo template_<TYPE>_inc.sh correspondiente.

# --- Ejemplo: servidor web (80/443) ---
# TYPE="www"
# PUBIP="100.100.100.100"
# PRIVIP="192.168.200.103"

# --- Ejemplo: servidor de correo (25/587/993 por defecto) ---
# TYPE="mail"
# PUBIP="100.100.100.100"
# PRIVIP="192.168.200.104"

# --- Por defecto (sin TYPE): se trata como custom ---
# PUBIP="100.100.100.100"
# PRIVIP="192.168.200.108"
# PORTS="8080 8443"
