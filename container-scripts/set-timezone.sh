#!/bin/sh

red='\e[1;31m'
grn='\e[1;32m'
yel='\e[1;33m'
#blu='\e[1;34m'
#mag='\e[1;35m'
#cyn=$'\e[1;36m'
end='\e[0m'

printf "%b" "${grn}"
echo " \$TIMEZONE= $TIMEZONE"
echo

if [ -n "$TIMEZONE" ]; then
  if [ "$1" != "unbound" ]; then
    echo " Waiting for DNS"
    for TRY in 1 2 3 4 5 6; do
      echo "  Try: $TRY"
      ping -c1 google.com && break
      sleep 10s
    done
    apk add --no-cache --no-progress -q tzdata
  fi
  if [ -f /usr/share/zoneinfo/"$TIMEZONE" ]; then
    echo " Setting timezone to $TIMEZONE"
    cp /usr/share/zoneinfo/"$TIMEZONE" /etc/localtime
    echo "$TIMEZONE" >/etc/timezone
  else
    printf "%b\n" "${red} $TIMEZONE does not exist"
  fi
  [ "$1" != "unbound" ] && apk del -q tzdata
fi
printf "%b\n" "${yel} Starting ${1-container} at $(date +'%x %X') ${end}"
