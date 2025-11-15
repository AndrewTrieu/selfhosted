#!/bin/bash

# === CONFIGURATION ===
TOKEN="TOKEN"
DOMAINS=("auth" "vault")
LOG_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_FILE="$LOG_DIR/duck.log"

# === SETUP ===
mkdir -p "$LOG_DIR"

# === UPDATE ALL DOMAINS ===
for domain in "${DOMAINS[@]}"; do
    echo "Updating DuckDNS domain $domain:" >> "$LOG_FILE"
    curl -ks "https://www.duckdns.org/update?domains=${domain}&token=${TOKEN}&ip=" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
done

echo "DuckDNS update completed at $(date)" >> "$LOG_FILE"
