# Build Caddy with plugins
# - Cloudflare DNS-01 ACME validation
# - Fetch Cloudflare IP ranges for trusted proxies
# - CrowdSec HTTP Bouncer to block malicious traffic
# - Caddy Security module for more authentication methods

ARG CADDY_VERSION=2.10.2

FROM caddy:${CADDY_VERSION}-builder AS builder

RUN xcaddy build \
    --with github.com/caddy-dns/cloudflare \
    --with github.com/WeidiDeng/caddy-cloudflare-ip \
    --with github.com/hslatman/caddy-crowdsec-bouncer/http \
    --with github.com/greenpau/caddy-security

FROM caddy:${CADDY_VERSION}

COPY --from=builder /usr/bin/caddy /usr/bin/caddy