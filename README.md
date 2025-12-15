# Homelab Setup

This repository contains the configuration for my personal homelab stack, including:

| Service | Description | Access URL |
|---------|-------------|------------|
| **Vaultwarden** | Self-hosted password manager (Bitwarden-compatible) | `https://vault.example.com` |
| **2FAuth** | Self-hosted two-factor authentication manager | `https://auth.example.com` |
| **Filebrowser** | Self-hosted file hosting service | `https://storage.example.com` |
| **Adguard Home** | Block ads and trackers on your network | `https://dns.example.com` |
| **Wg-easy** | Wireguard VPN with management console  | `https://vpn.example.com` |
| **Gitea** | Git with a cup of tea!| `https://git.example.com` |
| **Caddy** | Reverse proxy with automatic HTTPS | *No direct UI* |
| **Portainer** | Makes Docker life 100x easier (visual container manager) | `https://<SERVER_IP>:9443` |
| **Uptime Kuma** | Monitors homelab/domain uptime | `http://<SERVER_IP>:3001` |
| **Dozzle** | Displays logs super easily (real-time Docker logs) | `http://<SERVER_IP>:9999` |
| **Netdata** | Beautiful system and container monitoring | `http://<SERVER_IP>:19999` |

The setup is built with Docker Compose and is designed to be simple, secure, and easy to maintain.

## Directory Structure

```bash
.
├── porkbun
│   └── porkbun_ddns.sh   # Porkbun DDNS update script (runs via cron)
└── homelab
    ├── Caddyfile         # Reverse proxy configuration for Caddy
    └── compose.yml       # Docker Compose stack for all services
```

## Port Forwarding on Your Router

| Service / Purpose            | External Port | Internal Port | Protocol | Required?                | Notes                                                |
| ---------------------------- | ------------- | ------------- | -------- | ------------------------ | ---------------------------------------------------- |
| **HTTPS (Caddy)**            | **443**       | 443           | TCP/UDP  | ✅ Yes                    | Needed for all domains + HTTP/3/QUIC                 |
| **HTTP (Caddy, ACME)**       | **80**        | 80            | TCP      | ✅ Yes                    | Required for certificate issuance + redirect         |
| **WireGuard VPN**            | **51820**     | 51820         | UDP      | ✅ Yes                    | Main WireGuard tunnel port                           |
| **WG-Easy Web UI**           | 51821         | 51821         | TCP      | Optional                 | Only forward if you want to access admin UI remotely |
| **Gitea SSH (Git over SSH)** | 222           | 222           | TCP      | Optional but recommended | Required for `git clone ssh://...`                   |

## Secrets and Environment Variables

Before deploying, you **must** replace all placeholder values in the config files. See `.env.example`.

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

The **homelab/** folder contains:

- `compose.yml` – spins up Docker containers
- `Caddyfile` – defines routing for:
  - `https://<vault-domain>` → Vaultwarden
  - `https://<auth-domain>` → 2FAuth
  - `https://<storage-domain>` → Filebrowser
  - `https://<dns-domain>` → Adguard Home
  - `https://<vpn-domain>` → Wireguard
  - `https://<git-domain>` → Gitea

### Start the stack

```bash
cd homelab
mkdir -p services/vaultwarden \
         services/2fauth \
         services/uptimekuma \
         services/portainer \
         services/caddy/config \
         services/caddy/data \
         services/netdata/config \
         services/netdata/lib \
         services/netdata/cache \
         services/filebrowser/srv \
         services/filebrowser/database \
         services/filebrowser/config \
         services/wg-easy/data \
         services/gitea/data \
         services/gitea/postgres \
         services/adguard/work \
         services/adguard/conf
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
docker compose restart caddy vaultwarden 2fauth adguard wg-easy gitea filebrowser portainer dozzle uptime-kuma netdata
```

## Updating

To update to the latest versions:

```bash
cd homelab
docker compose pull
docker compose up -d
```

This will refresh all Docker images with zero downtime.
