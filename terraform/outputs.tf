# Record IDs, useful for writing import commands.
output "record_ids" {
  description = "Cloudflare record ID for each managed subdomain."
  value       = { for k, r in cloudflare_dns_record.ddns : k => r.id }
}
