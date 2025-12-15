# Homelab Setup

This repository contains the configuration for my personal homelab stack, built with Docker Compose and fronted by Caddy as a secure reverse proxy.

The goal of this setup is to be simple, secure, and easy to maintain, while providing essential self-hosted services for daily use.

- Automatic HTTPS (Caddy + ACME + DNS-01)
- Dynamic DNS with Porkbun
- Password management & 2FA
- WireGuard VPN with web UI
- Ad & tracker blocking
- Fully containerized (Docker Compose)
- Monitoring, logs, and uptime checks
- Zero-downtime updates
- Auto-start on boot

| Service          | Description                                         | Access                        |
| ---------------- | --------------------------------------------------- | ----------------------------- |
| **Vaultwarden**  | Self-hosted Bitwarden-compatible password manager   | `https://vault.example.com`   |
| **2FAuth**       | Self-hosted two-factor authentication manager       | `https://auth.example.com`    |
| **Filebrowser**  | Lightweight self-hosted file management             | `https://storage.example.com` |
| **AdGuard Home** | Network-wide ad & tracker blocking                  | `https://dns.example.com`     |
| **WG-Easy**      | WireGuard VPN with web management UI                | `https://vpn.example.com`     |
| **Gitea**        | Self-hosted Git service (“Git with a cup of tea ☕”) | `https://git.example.com`     |
| **Caddy**        | Reverse proxy with automatic HTTPS (ACME + DNS-01)  | *No direct UI*                |
| **Portainer**    | Visual Docker container management                  | `https://<SERVER_IP>:9443`    |
| **Uptime Kuma**  | Uptime and service monitoring                       | `http://<SERVER_IP>:3001`     |
| **Dozzle**       | Real-time Docker log viewer                         | `http://<SERVER_IP>:9999`     |
| **Netdata**      | System & container performance monitoring           | `http://<SERVER_IP>:19999`    |

## Directory Structure

```bash
.
├── porkbun
│   └── porkbun_ddns.sh    # Porkbun Dynamic DNS updater (cron-based)
└── homelab
    ├── Caddyfile          # Caddy reverse proxy configuration
    ├── compose.yml        # Docker Compose stack
    ├── Dockerfile         # Custom Caddy build (Porkbun DNS plugin)
    └── .env.example       # Environment variable template
```

## Port Forwarding on Your Router

| Purpose           | External  | Internal | Proto   | Required               | Notes                                    |
| ----------------- | --------- | -------- | ------- | ---------------------- | ---------------------------------------- |
| **HTTPS (Caddy)** | **443**   | 443      | TCP/UDP | ✅ Yes                 | Required for all domains + HTTP/3 (QUIC) |
| **HTTP (ACME)**   | **80**    | 80       | TCP     | ✅ Yes                 | Certificate issuance + redirects         |
| **WireGuard VPN** | **51820** | 51820    | UDP     | ✅ Yes                 | Main VPN tunnel                          |
| **WG-Easy UI**    | 51821     | 51821    | TCP     | Optional               | Only if remote admin UI is needed        |
| **Gitea SSH**     | 222       | 222      | TCP     | Optional (recommended) | Required for Git over SSH                |

## Secrets and Environment Variables

Before running the stack:

1. Copy environment variables:

```bash
cp homelab/.env.example homelab/.env
```

2. Replace all placeholder values
3. Add Porkbun API credentials to porkbun_ddns.sh

## Porkbun Dynamic DNS Updater

The script updates all Porkbun domains used by the homelab.

### Run manually

```bash
cd porkbun
./porkbun_ddns.sh
```

### Cron to run periodically (recommended)

```bash
cd porkbun
chmod 700 porkbun_ddns.sh
crontab -e
```

Add:

```bash
*/5 * * * * /path/to/porkbun/porkbun_ddns.sh >/dev/null 2>&1
```

This ensures your Porkbun domains always point to your current IP.

## Homelab Stack (Docker Compose)

The `homelab/` directory contains everything needed to run the stack:

- `compose.yml` – spins up Docker containers
- `Caddyfile` – defines routing for:
  - `https://<vault-domain>` → Vaultwarden
  - `https://<auth-domain>` → 2FAuth
  - `https://<storage-domain>` → Filebrowser
  - `https://<dns-domain>` → Adguard Home
  - `https://<vpn-domain>` → Wireguard
  - `https://<git-domain>` → Gitea
- `Dockerfile` – builds Caddy with Porkbun DNS provider
- `.env.example` – contains examples the necessary environment variables

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
docker logs <container> -f
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
cd homelab
sudo chown -R 1000:1000 services
sudo chmod -R 755 services
```

Then restart the containers:

```bash
cd homelab
docker compose restart
```

## Updating

To update to the latest versions:

```bash
cd homelab
docker compose pull
docker compose up -d
```

This will refresh all Docker images with zero downtime.
