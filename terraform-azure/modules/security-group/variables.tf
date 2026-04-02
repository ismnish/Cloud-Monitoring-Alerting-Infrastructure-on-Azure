variable "location" {
  type        = string
  description = "Azure region where resources will be deployed"
}

variable "name" {
  type        = string
  description = "Base name for all resources"
}

variable "environment" {
  type        = string
  description = "Environment name (e.g. dev, staging, prod)"
}

variable "owner" {
  type        = string
  description = "Owner of the resources"
}

variable "cost_center" {
  type        = string
  description = "Cost center identifier"
}

variable "application" {
  type        = string
  description = "Application name"
}

variable "vm_size" {
  type        = string
  description = "Azure VM size (e.g. Standard_B2s)"
}

variable "admin_username" {
  type        = string
  description = "Admin username for SSH access"
  default     = "azureuser"
}

variable "ssh_public_key_path" {
  type        = string
  description = "Path to the SSH public key file (e.g. ~/.ssh/id_rsa.pub)"
}

variable "disk_size_gb" {
  type        = number
  description = "OS disk size in GB"
  default     = 30
}

variable "inbound_rules" {
  type = list(object({
    port        = number
    source_cidr = string
    description = string
  }))
  description = "List of inbound NSG rules"
}