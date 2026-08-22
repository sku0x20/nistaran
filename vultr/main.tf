resource "vultr_instance" "tarani" {
  label       = "tarani"
  hostname    = "tarani"
  region      = "bom"
  plan        = "vc2-1c-1gb"
  os_id       = 2284 # Ubuntu 24.04 LTS
  ssh_key_ids = var.ssh_key_ids
  tags        = ["nistaran"]
  enable_ipv6 = true
  backups     = "disabled"
}
