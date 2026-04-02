variable "name" {
  type        = string
  description = "Base name for VM resources"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID to deploy the VM into"
}

variable "network_security_group_id" {
  type        = string
  description = "NSG ID to associate with the VM NIC"
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
  description = "Path to the SSH public key file"
}

variable "disk_size_gb" {
  type        = number
  description = "OS disk size in GB"
  default     = 30
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "owner" {
  type        = string
  description = "Owner tag value"
}

variable "cost_center" {
  type        = string
  description = "Cost center tag value"
}

variable "application" {
  type        = string
  description = "Application tag value"
}