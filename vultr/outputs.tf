output "instance_id" {
  value = vultr_instance.tarani.id
}

output "main_ip" {
  value = vultr_instance.tarani.main_ip
}

output "v6_main_ip" {
  value = vultr_instance.tarani.v6_main_ip
}
