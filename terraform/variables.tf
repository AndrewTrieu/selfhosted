variable "cloudflare_api_token" {
  description = "Cloudflare API token with Zone:Read and DNS:Edit. Set via TF_VAR_cloudflare_api_token, never in a file."
  type        = string
  sensitive   = true
}

variable "zone_id" {
  description = "Cloudflare zone ID for the domain."
  type        = string
}

variable "domain" {
  description = "Apex domain. Record names are built as <name>.<domain>, which is how the API returns them."
  type        = string
}

# Must match PROXIED_ON / PROXIED_OFF in cloudflare/cloudflare_ddns.sh. Keep both in sync.
variable "proxied_names" {
  description = "Subdomains that are proxied (orange cloud). \"@\" is the apex."
  type        = list(string)
  default     = ["@", "vault", "2fa", "cloud", "git", "xui", "dns", "flights", "home"]
}

variable "dns_only_names" {
  description = "Subdomains that are DNS only. Non-HTTP traffic must not be proxied."
  type        = list(string)
  default     = ["wg", "reality"]
}

variable "placeholder_ip" {
  description = "Content for records Terraform creates. DDNS overwrites it within 5 minutes. Ignored after creation."
  type        = string
  default     = "192.0.2.1"
}

variable "ttl" {
  description = "TTL in seconds for DNS-only records. Proxied records always use automatic TTL (1)."
  type        = number
  default     = 600
}
