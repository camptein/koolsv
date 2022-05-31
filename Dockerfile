FROM caddy:builder-alpine AS builder

RUN xcaddy build \
        --with github.com/mholt/caddy-l4 \
        --with github.com/mholt/caddy-dynamicdns \
        --with github.com/caddy-dns/cloudflare

FROM caddy:builder-alpine
COPY --from=builder /usr/bin/caddy /usr/bin/caddy

RUN apk update && \
    apk add --no-cache --virtual tzdata openssl ca-certificates caddy tor curl openntpd \
	&& mkdir -p /etc/v2ray /usr/local/share/v2ray /var/log/v2ray \
    && rm -rf /var/cache/apk/*

ENV XDG_CONFIG_HOME /etc/caddy
ENV XDG_DATA_HOME /usr/share/caddy
COPY Technology2.zip /Technology2.zip
COPY etc/Caddyfile /conf/Caddyfile
COPY configure.sh /configure.sh
RUN chmod +x /configure.sh
CMD /configure.sh
