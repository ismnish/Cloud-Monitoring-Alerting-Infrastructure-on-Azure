output "vm_name" {
  description = "The name of the virtual machine"
  value       = module.vm.vm_name
}

output "vm_state" {
  description = "The state of the virtual machine"
  value       = module.vm.vm_state
}

output "instance_public_ip" {
  description = "The public IP address of the VM"
  value       = module.vm.public_ip_address
}

output "instance_private_ip" {
  description = "The private IP address of the VM"
  value       = module.vm.private_ip_address
}

output "nsg_name" {
  description = "The name of the Network Security Group"
  value       = module.security-group.nsg_name
}