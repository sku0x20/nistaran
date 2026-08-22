terraform {
  # Vultr Object Storage is S3-compatible; bucket/region/endpoint/credentials
  # are supplied via -backend-config (see backend.hcl.example) since backend
  # blocks can't reference variables.
  backend "s3" {
    key                         = "vultr/terraform.tfstate"
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    use_path_style              = true
  }
}
