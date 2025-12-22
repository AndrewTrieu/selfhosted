#!/usr/bin/env bash
set -euo pipefail

########################
# CONFIGURATION
########################

CF_API_TOKEN="your_cloudflare_api_token_here"
DOMAIN="example.com"

# Cloudflare PROXIED = true (orange cloud)
PROXIED_ON=(
  "@"
  "vault"
  "auth"
  "cloud"
  "git"
  "xui"
  "dns"
)

# Cloudflare PROXIED = false (DNS only)
PROXIED_OFF=(
  "vpn"
  "reality"
)

TTL=600
CF_API="https://api.cloudflare.com/client/v4"

# =================
# Resolve public IP
# =================
IP="$(curl -fs https://api.ipify.org)"
echo "INFO: Current IP: $IP"

# =================
# Resolve Zone ID
# =================
ZONE_ID="$(curl -fs \
  -H "Authorization: Bearer $CF_API_TOKEN" \
  "$CF_API/zones?name=$DOMAIN" \
  | jq -r '.result[0].id')"

if [[ -z "$ZONE_ID" || "$ZONE_ID" == "null" ]]; then
  echo "ERROR: Failed to resolve Zone ID"
  exit 1
fi

echo "SUCCESS: Zone ID resolved"

# =================
# Function to create/update record
# =================
update_record() {
  local SUB="$1"
  local PROXIED="$2"
  local NAME

  if [[ "$SUB" == "@" ]]; then
    NAME="$DOMAIN"
  else
    NAME="$SUB.$DOMAIN"
  fi

  echo "INFO: Updating $NAME (proxied=$PROXIED)"

  RECORD_ID="$(curl -fs \
    -H "Authorization: Bearer $CF_API_TOKEN" \
    "$CF_API/zones/$ZONE_ID/dns_records?type=A&name=$NAME" \
    | jq -r '.result[0].id')"

  if [[ -z "$RECORD_ID" || "$RECORD_ID" == "null" ]]; then
    # Create
    curl -fs -X POST "$CF_API/zones/$ZONE_ID/dns_records" \
      -H "Authorization: Bearer $CF_API_TOKEN" \
      -H "Content-Type: application/json" \
      -d "{
        \"type\": \"A\",
        \"name\": \"$NAME\",
        \"content\": \"$IP\",
        \"ttl\": $TTL,
        \"proxied\": $PROXIED
      }" >/dev/null
  else
    # Update
    curl -fs -X PUT "$CF_API/zones/$ZONE_ID/dns_records/$RECORD_ID" \
      -H "Authorization: Bearer $CF_API_TOKEN" \
      -H "Content-Type: application/json" \
      -d "{
        \"type\": \"A\",
        \"name\": \"$NAME\",
        \"content\": \"$IP\",
        \"ttl\": $TTL,
        \"proxied\": $PROXIED
      }" >/dev/null
  fi
}

# =================
# Update PROXIED = true records
# =================
for SUB in "${PROXIED_ON[@]}"; do
  update_record "$SUB" true
done

# =================
# Update PROXIED = false records
# =================
for SUB in "${PROXIED_OFF[@]}"; do
  update_record "$SUB" false
done

echo "SUCCESS: DNS update complete"
exit 0
