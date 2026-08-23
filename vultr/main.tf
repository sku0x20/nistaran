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

# Reserved IPs keep the instance's address stable across destroy/recreate,
# but cost ~$3/mo each and main_ip is otherwise stable across reboots/resizes.
# Uncomment if something external starts depending on a fixed IP.
#
# resource "vultr_reserved_ip" "tarani" {
#   region      = "bom"
#   ip_type     = "v4"
#   label       = "tarani"
#   instance_id = vultr_instance.tarani.id
# }
#
# resource "vultr_reserved_ip" "tarani_v6" {
#   region      = "bom"
#   ip_type     = "v6"
#   label       = "tarani-v6"
#   instance_id = vultr_instance.tarani.id
# }
