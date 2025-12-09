#!/bin/bash

API_KEY="pk1_someapikeyvalue1234567890abcdef"
API_SECRET="sk1_somesecretapikeyvalueabcdef1234567890"
DOMAIN="example.com"
SUBDOMAINS=(
  "vault"
  "auth"
  "cloud"
  "vpn"
)

TTL="600"
# =================

IP="$(curl -fs https://api.ipify.org)"

for SUBDOMAIN in "${SUBDOMAINS[@]}"; do
  curl -fs "https://api.porkbun.com/api/json/v3/dns/editByNameType/${DOMAIN}/A/${SUBDOMAIN}" \
    -H "Content-Type: application/json" \
    -d "{
      \"apikey\": \"${API_KEY}\",
      \"secretapikey\": \"${API_SECRET}\",
      \"content\": \"${IP}\",
      \"ttl\": \"${TTL}\"
    }"
done
