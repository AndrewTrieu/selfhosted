terraform {
  required_version = ">= 1.6.0"

  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
      # Pinned at scaffold time. Check the Terraform Registry for a newer release before upgrading.
      version = "5.22.0"
    }
  }

  # Cloudflare R2 is S3-compatible. Settings come from backend.hcl (see backend.hcl.example).
  backend "s3" {}
}
