#!/bin/sh
export SMTP_SENDER_NAME=${SMTP_SENDER_NAME:-""}
export SMTP_RELAY_HOST=${SMTP_RELAY_HOST:-""}
export SMTP_RELAY_PORT=${SMTP_RELAY_PORT:-""}
export SMTP_RELAY_LOGIN=${SMTP_RELAY_LOGIN:-""}
export SMTP_RELAY_PASSWORD=${SMTP_RELAY_PASSWORD:-""}
export RECIPIENT_RESTRICTIONS=${RECIPIENT_RESTRICTIONS:-""}
export ACCEPTED_NETWORKS=${ACCEPTED_NETWORKS:-"192.168.0.0/16 172.17.0.0/16 172.16.0.0/12 10.0.0.0/8"}
export SMTP_USE_TLS=${SMTP_USE_TLS:-"no"}
export SMTP_TLS_SECURITY_LEVEL=${SMTP_TLS_SECURITY_LEVEL:-"may"}
export SMTP_TLS_WRAPPERMODE=no
export SMTPD_TLS_SECURITY_LEVEL=${SMTPD_TLS_SECURITY_LEVEL:-"none"}
export SMTP_DEBUG_PEER_LIST=${SMTP_DEBUG_PEER_LIST:-"0.0.0.0"}
export SMTP_DEBUG_PEER_LEVEL=${SMTP_DEBUG_PEER_LEVEL:-"3"}
export DEBUG=${DEBUG:-"0"}

# source /scripts/init-alpine.sh

if [ "$DEBUG" == 1 ]; then
    export
fi

# generate cerficate
openssl req -newkey rsa:4096 -x509 -sha256 -days 3650 -nodes -out "/etc/ssl/certs/$HOSTNAME.pem" -keyout "/etc/ssl/certs/$HOSTNAME.key" -subj "/CN=$HOSTNAME"

# setup dns resolver
mkdir -p /var/spool/postfix/etc/
echo 'nameserver 8.8.8.8' >> /var/spool/postfix/etc/resolv.conf

# set timezone
mkdir -p /var/spool/postfix/etc
cp /etc/localtime /var/spool/postfix/etc/

# Variables
[ -z "${SMTP_RELAY_LOGIN}" -o -z "${SMTP_RELAY_PASSWORD}" ] && {
    echo "SMTP_RELAY_LOGIN and SMTP_RELAY_PASSWORD _must_ be defined" >&2
    exit 1
}

if [ -n "${RECIPIENT_RESTRICTIONS}" ]; then
    RECIPIENT_RESTRICTIONS="inline:{$(echo ${RECIPIENT_RESTRICTIONS} | sed 's/\s\+/=OK, /g')=OK}"
else
    RECIPIENT_RESTRICTIONS=static:OK
fi

SMTP_TLS_WRAPPERMODE=no

if [ "${SMTP_RELAY_PORT}" == "465" ]; then
    SMTP_TLS_WRAPPERMODE=yes
    SMTP_TLS_SECURITY_LEVEL=encrypt
fi

# Template
export DOLLAR='$'
envsubst < /root/conf/postfix-main.cf > /etc/postfix/main.cf
envsubst < /root/conf/postfix-master.cf > /etc/postfix/master.cf
envsubst < /root/conf/header_check > /etc/postfix/header_check

if [ "$DEBUG" == 1 ]; then
    echo "Display content of /etc/postfix/main"
    cat /etc/postfix/main.cf

    echo "Display content of /etc/postfix/master"
    cat /etc/postfix/master.cf

    echo "Display content of /etc/postfix/header_check"
    cat /etc/postfix/header_check
fi

# Generate default alias DB
newaliases

echo "\$PERCENT= $PERCENT"
echo "\$SIZE= $SIZE"
echo "\$STUNNEL= $STUNNEL"
NME=redis
set-timezone.sh "$NME"

[ -z "$PERCENT" ] && PERCENT=50
[ -z "$SIZE" ] && SIZE="16mb"

sed -r -e "s/(.*rewrite-percentage).*/\1 $PERCENT/" -e "s/(.*rewrite-min-size).*/\1 $SIZE/" -i /etc/redis.conf

if [ -n "$STUNNEL" ]; then
  openssl req -x509 -newkey rsa:4096 -keyout /etc/stunnel/key.pem -out /etc/stunnel/cert.pem -days 365 -nodes -subj '/CN=localhost'
  [ ! -f /etc/stunnel/psk.txt ] && echo "/etc/stunnel/psk.txt needed for stunnel" && exit 1
  chmod 600 /etc/stunnel/psk.txt
  stunnel /etc/stunnel/stunnel.conf
  sed -r "s/(protected-mode).*/\1 yes/" -i /etc/redis.conf
fi

/usr/bin/supervisord -c /etc/supervisord/supervisord.conf