output "instance_id" {
  value = vultr_instance.nistaran.id
}

output "main_ip" {
  value = vultr_instance.nistaran.main_ip
}

output "v6_main_ip" {
  value = vultr_instance.nistaran.v6_main_ip
}
