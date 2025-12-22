# Build Caddy with plugins
# - Cloudflare DNS-01 ACME validation
# - Fetch Cloudflare IP ranges for trusted proxies
# - CrowdSec HTTP Bouncer to block malicious traffic
# - MaxMind GeoIP2 for geolocation-based rules
# - Caddy Security module for more authentication methods
# - Dynamic DNS to update DNS records automatically

FROM caddy:2.10.2-builder AS builder

RUN xcaddy build \
    --with github.com/caddy-dns/cloudflare \ 
    --with github.com/WeidiDeng/caddy-cloudflare-ip \
    --with github.com/hslatman/caddy-crowdsec-bouncer/http \
    --with github.com/porech/caddy-maxmind-geolocation \
    --with github.com/greenpau/caddy-security \
    --with github.com/mholt/caddy-dynamicdns

FROM caddy:2.10.2 

COPY --from=builder /usr/bin/caddy /usr/bin/caddy