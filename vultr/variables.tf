variable "vultr_api_key" {
  description = "Vultr API key"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "Vultr region id (e.g. ewr, sea, ams)"
  type        = string
  default     = "ewr"
}

variable "plan" {
  description = "Vultr plan id — shared 1 vCPU / 1 GiB"
  type        = string
  default     = "vc2-1c-1gb"
}

variable "os_id" {
  description = "Vultr OS id (default: Ubuntu 24.04 LTS)"
  type        = number
  default     = 2284
}

variable "label" {
  description = "Instance label"
  type        = string
  default     = "nistaran"
}

variable "hostname" {
  description = "Instance hostname"
  type        = string
  default     = "nistaran"
}

variable "ssh_key_ids" {
  description = "Vultr SSH key IDs to install on the instance"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to the instance"
  type        = list(string)
  default     = ["nistaran"]
}

variable "enable_ipv6" {
  description = "Enable IPv6 on the instance"
  type        = bool
  default     = true
}

variable "backups_enabled" {
  description = "Enable automatic backups (extra cost)"
  type        = bool
  default     = false
}
