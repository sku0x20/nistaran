resource "vultr_instance" "tarani" {
  label       = var.label
  hostname    = var.hostname
  region      = var.region
  plan        = var.plan
  os_id       = var.os_id
  ssh_key_ids = var.ssh_key_ids
  tags        = var.tags
  enable_ipv6 = var.enable_ipv6
  backups     = var.backups_enabled ? "enabled" : "disabled"
}
