variable "vultr_api_key" {
  description = "Vultr API key"
  type        = string
  sensitive   = true
}

variable "ssh_key_ids" {
  description = "Vultr SSH key IDs to install on the instance"
  type        = list(string)
  default     = []
}
