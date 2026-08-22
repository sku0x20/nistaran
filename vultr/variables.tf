variable "vultr_api_key" {
  description = "Vultr API key"
  type        = string
  sensitive   = true
}

variable "ssh_public_key" {
  description = "Public key (ed25519) to register with Vultr and install on the instance"
  type        = string
}
