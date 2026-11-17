# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Infrastructure-as-config for a single-host homelab: one Docker Compose project with a custom-built Caddy reverse proxy in front and persistent data on a ZFS pool. There is no application code. "Changes" are edits to Compose YAML, the Caddyfile, a Dockerfile, a bash script, the Ansible roles, the Terraform config and `README.md`, which is the full setup runbook. The Ansible and Terraform parts are checked by `.forgejo/workflows/ci.yml`.

## Repo ↔ server mapping (paths are hardcoded)

- The contents of `homelab/` are deployed to **`/opt/homelab`** on the server. `/opt/homelab` is not a git checkout, so the repo and the server can drift apart. When asked to change "the deployment", compare against `/opt/homelab` first.
- All persistent state lives under **`/tank/services/<service>/...`**, bind-mounted by absolute path; there are no named volumes.
- `homelab/services/**` are **templates copied once** into the same paths under `/tank/services/` (README "Setup" step 4), and containers mount the `/tank` copy. That includes the Caddy `Dockerfile`: `stacks/edge.yml` builds from `/tank/services/caddy`, not from the repo. Editing a template changes nothing on the server until it is copied over.

## Compose layout

`homelab/compose.yml` is only the root. It `include:`s `stacks/*.yml` and defines the `proxy`/`vpndns` networks.
- Define networks only in the root; a duplicate definition in a stack file conflicts.
- Each include passes `env_file: .env`, so `${VARS}` resolve from the root `.env`.
- Relative paths in a stack file resolve from `stacks/` (hence `../Caddyfile` in `edge.yml`).
- Deployed stacks: `edge` (caddy, crowdsec, cloudflared), `dns-vpn`, `apps`, `admin`, `home` (Home Assistant, matter-hub).
- `auth.yml` (Authentik), `ci.yml` (Forgejo runner + docker-in-docker), `monitoring.yml` (Uptime Kuma, Netdata) and `matter.yml` (matter-server, otbr) each have a Compose profile (`auth`, `ci`, `monitoring`, `matter`). They start only when listed in `COMPOSE_PROFILES` in `.env`. Their header comment lists what they need.

## Commands

Run from `/opt/homelab` on the server, or from `homelab/` with a `.env` present (`cp .env.example .env` is enough for validating):

```bash
docker compose config -q                      # validate the merged config + .env interpolation
docker compose up -d <service>                # apply changes to one service
docker compose up -d --build caddy            # rebuild Caddy after changing /tank/services/caddy/Dockerfile
docker compose logs -f <service>

# Caddyfile: validate, then hot-reload without restarting the container
docker compose exec caddy caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile
docker compose exec caddy caddy reload   --config /etc/caddy/Caddyfile --adapter caddyfile

docker exec -it crowdsec cscli bouncers add caddy-bouncer   # generate CROWDSEC_API_KEY
bash -n homelab/cloudflare/cloudflare_ddns.sh               # syntax-check the DDNS script
```

The server's `/opt/homelab/caddy` is a standalone Caddy binary for host-side `caddy fmt`/`adapt`. It lacks the plugins, so use the container for `validate`.

## Optional automation: Ansible, Terraform and CI

The README's manual steps are the primary path. Ansible and Terraform are optional and must stay equivalent to those steps. Update the matching README note when either changes.


- **`ansible/`** bootstraps the host. The inventory uses `ansible_connection: local`, because the control node is the server itself. Run `ansible-playbook site.yml --check --diff -K` first. `zfs-pool.yml` is destructive and needs `-e zfs_pool_create=true`; never add it to `site.yml`.
- Ansible templates copy with `force: false`. Never change that, because server files hold real secrets and runtime state. Do not set `mode` on directories that already exist.
- `homelab_user`, `zfs_pool_disks` and the inventory hold placeholders in git. Keep real values in a local, uncommitted override.
- **`terraform/`** optionally manages the DDNS record set. Terraform owns each record's name and `proxied` setting, and ignores `content`, which DDNS updates. State is in R2 (`terraform/backend.hcl`, gitignored). The API token comes from `TF_VAR_cloudflare_api_token`, and `terraform.tfvars` is gitignored.
- `homelab_stacks` (Ansible) lists the stacks to prepare: datasets, Matter sysctls and runner config. It must match `COMPOSE_PROFILES` in `.env`; keep both in sync.
- Run `terraform -chdir=terraform plan` and review it before any `apply`. CI never applies. The provider version is pinned in `versions.tf`.

## Architecture

- **Ingress:** Caddy is the only service exposing 80/443. It is a custom xcaddy build with `caddy-dns/cloudflare` (DNS-01), `caddy-cloudflare-ip` (`trusted_proxies cloudflare`), `caddy-crowdsec-bouncer` and `caddy-security`. A directive from a new plugin requires a Dockerfile change and a rebuild.
- **Caddyfile conventions:** site addresses are env vars (`{env.X_DOMAIN}`), and each must also be listed in the `caddy` service's `environment:` in `stacks/edge.yml`; `.env` alone is not enough. Normal sites `import common_config` (security headers + Cloudflare DNS TLS + JSON access log + `crowdsec` + compression). Upstreams are addressed by container name on `proxy`; host-network services (3x-ui, Home Assistant) are reached via `host.docker.internal`.
- **Other ingress paths:** Forgejo SSH goes through Cloudflare Tunnel (`cloudflared`, configured in the Cloudflare dashboard) to `forgejo:22`. WireGuard (UDP 51820) and VLESS Reality (TCP 8443) are DNS-only and bypass Caddy. 3x-ui runs with `network_mode: host`; Caddy proxies only `/admin*` → 2053 and the VLESS WebSocket `/ws*` → 10000. The WG-Easy UI (51821), Portainer (9443) and Dozzle (9999) are LAN-only; there are no Caddy sites for them.
- **CrowdSec loop:** Caddy writes JSON access logs to `/data/access.log` (`/tank/services/caddy/data`). CrowdSec mounts that directory read-only, and Caddy's bouncer queries it at `http://crowdsec:8080`.
- **DNS chain:** router/WireGuard clients → AdGuard (host :53; 172.30.0.100 / 10.2.0.100) → Unbound (10.2.0.53 on `vpndns`) with a Redis cachedb (`unbound-redis`, hostname `redis`). Keep these static IPs in sync if subnets change.
- **Home:** Home Assistant uses host networking for LAN discovery. `matter-hub` (host network, web UI on 8482, Matter on UDP 5540+) bridges HA entities to Google Home through `127.0.0.1:8123` with `HAMH_HA_TOKEN`, and advertises mDNS only on the LAN NIC (`HAMH_MDNS_NETWORK_INTERFACE`). matter-hub *exports* HA entities to Matter; the optional `matter-server` is the opposite (a Matter *controller* that imports devices into HA), and `otbr` turns the Dongle-M (Thread RCP over TCP :6638) into a Thread border router. All of them use host networking, and their LAN interface settings (`enp5s0`) must agree. matter-hub already holds UDP 5540.

## Adding or renaming a public web service

Keep all of these in sync:
1. A service in the right `stacks/*.yml` (on `proxy`, with data under `/tank/services/<name>`).
2. The `X_DOMAIN` entry in the caddy `environment:` in `stacks/edge.yml`, plus an `{env.X_DOMAIN}` site in the `Caddyfile`.
3. `.env.example`.
4. `cloudflare/cloudflare_ddns.sh` `PROXIED_ON`/`PROXIED_OFF`, **and** `terraform/variables.tf` `proxied_names`/`dns_only_names`. These are the same list in two places: keep them identical. The script does not read `.env` and keeps its own `CF_API_TOKEN`/`DOMAIN`. The repo copy holds placeholders; never commit the real token from the server copy. After adding the name to Terraform, run `plan` and then `apply`, so the new record exists.
5. `README.md`: the services table, the domain lists, the ZFS dataset list (`recordsize=16K` for Postgres/Redis), the template-copy step, the mermaid diagram and the directory tree.

## Gotchas

- Templates must never contain real secrets. `services/adguard/conf/AdGuardHome.yaml` has `REPLACE_WITH_BCRYPT_HASH` in place of the login hash. When refreshing a template from the server, strip secrets the same way. The server files are root-only, so the user has to make readable copies.
- Forgejo's wizard-chosen settings (domain, root URL, registration, reverse-proxy trust) are set as `FORGEJO__section__KEY` env vars in `stacks/apps.yml`, which Forgejo writes into `app.ini` on each start. Add new Forgejo settings there, not in `app.ini`; its secrets stay generated on the server.

- Home Assistant keeps HTTP settings in `/tank/services/homeassistant/config/.storage/http`, not `configuration.yaml`; a YAML `http:` block is read once, then ignored. Reverse-proxy trust (`use_x_forwarded_for`, `trusted_proxies: 172.30.0.0/16`) must be in `data.stable`. Changes land in `data.pending` and revert after 5 minutes unless confirmed (`error: not_promoted`); to set them without the UI, stop HA and move them into `stable`. A `400` through Caddy plus a "not set-up for reverse proxies" log line means `stable` lacks them.
- A new subdomain can stay unresolvable on the LAN/VPN after its record is created: Unbound caches the empty answer for up to 30 minutes and persists it in Redis. `unbound-control` is disabled, so to clear it run `docker exec unbound-redis redis-cli FLUSHALL`, then restart `unbound` and then `adguard`.
- Most images use `:latest`, so `docker compose pull` can bring in breaking upgrades. Pinned: Forgejo `15`, Postgres `15`, Caddy `2.10.2`, matter-hub `2.0.59`.
- A ZFS dataset mounts over its directory and hides whatever was there. Create the dataset before the service's data goes in, or move the data into it. The `zfs` role refuses to create a dataset over a directory that already has files.
