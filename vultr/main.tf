resource "vultr_instance" "tarani" {
  label       = "tarani"
  hostname    = "tarani"
  region      = "bom"
  plan        = "vc2-1c-1gb"
  os_id       = 2625 # Debian 13 x64 (trixie)
  ssh_key_ids = var.ssh_key_ids
  tags        = ["nistaran"]
  enable_ipv6 = true
  backups     = "disabled"
}
