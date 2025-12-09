# Build Caddy with Porkbun DNS provider
FROM caddy:latest-builder AS builder

RUN xcaddy build \
    --with github.com/caddy-dns/porkbun

FROM caddy:latest 

COPY --from=builder /usr/bin/caddy /usr/bin/caddy