terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "${var.name}-${var.environment}-rg"
  location = var.location

  tags = {
    Name        = var.name
    Environment = var.environment
    Owner       = var.owner
    CostCenter  = var.cost_center
    Application = var.application
  }
}

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.name}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = {
    Name        = var.name
    Environment = var.environment
  }
}

# Subnet
resource "azurerm_subnet" "subnet" {
  name                 = "${var.name}-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Security Group Module
module "security-group" {
  source = "../modules/security-group"

  name                = var.name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.subnet.id
  environment         = var.environment
  owner               = var.owner
  cost_center         = var.cost_center
  application         = var.application
  inbound_rules       = var.inbound_rules
}

# VM Module
module "vm" {
  source = "../modules/vm"

  name                      = var.name
  location                  = var.location
  resource_group_name       = azurerm_resource_group.rg.name
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = module.security-group.nsg_id
  vm_size                   = var.vm_size
  admin_username            = var.admin_username
  ssh_public_key_path       = var.ssh_public_key_path
  disk_size_gb              = var.disk_size_gb
  environment               = var.environment
  owner                     = var.owner
  cost_center               = var.cost_center
  application               = var.application
}