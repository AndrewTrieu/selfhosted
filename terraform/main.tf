locals {
  # name => proxied
  records = merge(
    { for n in var.proxied_names : n => true },
    { for n in var.dns_only_names : n => false },
  )
}

# Terraform owns each record's existence, name, type and proxy setting.
# The IP (content) belongs to cloudflare_ddns.sh, so Terraform ignores changes to it.
resource "cloudflare_dns_record" "ddns" {
  for_each = local.records

  zone_id = var.zone_id
  name    = each.key == "@" ? var.domain : "${each.key}.${var.domain}"
  type    = "A"
  content = var.placeholder_ip
  proxied = each.value
  ttl     = each.value ? 1 : var.ttl

  lifecycle {
    ignore_changes = [content]
  }
}
