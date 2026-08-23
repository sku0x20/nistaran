output "instance_id" {
  value = vultr_instance.tarani.id
}

output "main_ip" {
  value = vultr_instance.tarani.main_ip
}

output "v6_main_ip" {
  value = vultr_instance.tarani.v6_main_ip
}

# See commented-out vultr_reserved_ip resources in main.tf.
#
# output "reserved_ip" {
#   value = vultr_reserved_ip.tarani.subnet
# }
#
# output "reserved_ip_v6" {
#   value = vultr_reserved_ip.tarani_v6.subnet
# }
