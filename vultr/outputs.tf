output "instance_id" {
  value = vultr_instance.this.id
}

output "main_ip" {
  value = vultr_instance.this.main_ip
}

output "v6_main_ip" {
  value = vultr_instance.this.v6_main_ip
}
