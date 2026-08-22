resource "vultr_ssh_key" "tarani" {
  name    = "tarani"
  ssh_key = var.ssh_public_key
}

resource "vultr_instance" "tarani" {
  label       = "tarani"
  hostname    = "tarani"
  region      = "bom"
  plan        = "vc2-1c-1gb"
  os_id       = 2625 # Debian 13 x64 (trixie)
  ssh_key_ids = [vultr_ssh_key.tarani.id]
  tags        = ["nistaran"]
  enable_ipv6 = true
  backups     = "disabled"
}
