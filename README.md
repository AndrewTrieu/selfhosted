# Homelab Setup (Vaultwarden + 2FAuth + Caddy + DuckDNS)

This repository contains the configuration for my personal homelab stack, including:

- **Vaultwarden** – self-hosted password manager (Bitwarden-compatible)
- **2FAuth** – self-hosted two-factor authentication manager
- **Caddy** – reverse proxy with automatic HTTPS via DuckDNS (DNS-01)
- **DuckDNS Updater** – updates my dynamic IP address automatically

The setup is built with Docker Compose and is designed to be simple, secure, and easy to maintain.

## Directory Structure

```bash
.
├── duckdns
│   ├── duck.log        # Log file for DuckDNS updates
│   └── duck.sh         # DuckDNS update script (runs via cron)
└── homelab
    ├── Caddyfile       # Reverse proxy configuration for Caddy
    └── compose.yml     # Docker Compose stack for Vaultwarden + 2FAuth + Caddy
```

## Secrets and Environment Variables

Before deploying, you **must** replace all placeholder values in the config files.

- `https://vault.example.com` and `vault.example.com` → your Vaultwarden domain
- `https://auth.example.com` and `auth.example.com` → your 2FAuth domain
- `admin@example.com` → your email address (used by Caddy / Let’s Encrypt and 2FAuth)
- `TOKEN` → your DuckDNS token
- `SomeRandomStringOf32CharsExactly` → a **32-character** random string for `APP_KEY`

## DuckDNS Dynamic DNS Updater

The `duckdns/duck.sh` script updates all DuckDNS domains used by the homelab. It always logs to `duckdns/duck.log`.

### Run manually

```bash
cd duckdns
./duck.sh
```

### Cron to run periodically (recommended)

```bash
cd duckdns
chmod 700 duck.sh
crontab -e
```

Add:

```bash
*/5 * * * * /path/to/duckdns/duck.sh >/dev/null 2>&1
```

This ensures your DuckDNS domains always point to your current IP.

## Homelab Stack (Docker Compose)

The **homelab/** folder contains:

- `compose.yml` – runs Vaultwarden, 2FAuth, and Caddy
- `Caddyfile` – defines routing for:
  - `https://<vault-domain>` → Vaultwarden
  - `https://<auth-domain>` → 2FAuth

### Start the stack

```bash
cd homelab
docker compose up -d
```

### Stop the stack

```bash
cd homelab
docker compose down
```

### View logs

```bash
docker logs caddy -f
docker logs vaultwarden -f
docker logs 2fauth -f
```

### Auto-start on system boot

The containers already use:

```yml
restart: always
```

But remember to enable Docker on startup:

```bash
sudo systemctl enable docker
```

### Set correct permissions for volumes (optional)

Run:

```bash
sudo chown -R 1000:1000 homelab/vaultwarden
sudo chmod -R 755 homelab/vaultwarden

sudo chown -R 1000:1000 homelab/2fauth
sudo chmod -R 755 homelab/2fauth
```

Then restart the containers:

```bash
cd homelab
docker compose restart vaultwarden 2fauth
```

## Updating

To update to the latest versions:

```bash
cd homelab
docker compose pull
docker compose up -d
```

This will refresh all Docker images with zero downtime.
