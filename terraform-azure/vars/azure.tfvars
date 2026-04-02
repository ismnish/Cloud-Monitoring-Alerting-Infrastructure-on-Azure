# Azure Region
location = "eastus"

# Resource Naming & Tags
name        = "prometheus-stack"
environment = "dev"
owner       = "techiescamp"
cost_center = "techiescamp-commerce"
application = "monitoring"

# VM Configuration
# Standard_B2s = 2 vCPU, 4 GB RAM
vm_size             = "Standard_B2s"
admin_username      = "azureuser"
ssh_public_key_path = "~/.ssh/id_rsa.pub"
disk_size_gb        = 30

# Inbound NSG Rules
inbound_rules = [
  { port = 22,   source_cidr = "0.0.0.0/0", description = "SSH" },
  { port = 80,   source_cidr = "0.0.0.0/0", description = "HTTP" },
  { port = 443,  source_cidr = "0.0.0.0/0", description = "HTTPS" },
  { port = 9090, source_cidr = "0.0.0.0/0", description = "Prometheus" },
  { port = 9100, source_cidr = "0.0.0.0/0", description = "NodeExporter" },
  { port = 9093, source_cidr = "0.0.0.0/0", description = "AlertManager" },
  { port = 3000, source_cidr = "0.0.0.0/0", description = "Grafana" },
]