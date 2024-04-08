ARG DISTVER=latest
FROM alpine:$DISTVER
LABEL maintainer="Peter Bacsai"

RUN apk update && \
    apk add rspamd rspamd-proxy rspamd-utils rspamd-controller supervisor nginx openssl redis stunnel && \
    rm -rf /var/cache/apk/*

RUN \
    echo "" > /etc/apk/repositories && \
    echo "https://dl-cdn.alpinelinux.org/alpine/v3.18/main" >> /etc/apk/repositories && \
    echo "https://dl-cdn.alpinelinux.org/alpine/v3.18/community" >> /etc/apk/repositories && \
    apk update && \
    apk add --update --no-cache \
    openssl \
    gettext \
    postfix \
    tzdata \
    postfix-pcre \
    ca-certificates \
    cyrus-sasl \
    cyrus-sasl-login && cp /usr/bin/envsubst /usr/local/bin/

COPY supervisord/supervisord.conf /etc/supervisord/supervisord.conf
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY rspamd/local.d/* /etc/rspamd/local.d/
COPY --chmod=644 redis.conf /etc/redis.conf
COPY --chmod=644 stunnel.conf /etc/stunnel/stunnel.conf

WORKDIR /usr/local/bin
COPY --chmod=755 container-scripts/set-timezone.sh entrypoint.sh ./

COPY conf/ /root/conf
COPY files/ /scripts

EXPOSE 11332/tcp
EXPOSE 80/tcp
EXPOSE 6379 6379
EXPOSE 25 587

CMD [ "entrypoint.sh" ]

HEALTHCHECK --start-period=60s CMD redis-cli PING || exit 1

