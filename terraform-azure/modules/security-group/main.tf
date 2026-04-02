resource "azurerm_network_security_group" "nsg" {
  name                = "${var.name}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  dynamic "security_rule" {
    for_each = { for idx, rule in var.inbound_rules : tostring(idx) => rule }
    content {
      name                       = security_rule.value.description
      priority                   = 100 + security_rule.key
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = tostring(security_rule.value.port)
      source_address_prefix      = security_rule.value.source_cidr
      destination_address_prefix = "*"
    }
  }

  security_rule {
    name                       = "AllowAllOutbound"
    priority                   = 200
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    Name        = var.name
    Environment = var.environment
    Owner       = var.owner
    CostCenter  = var.cost_center
    Application = var.application
  }
}

resource "azurerm_subnet_network_security_group_association" "subnet_nsg" {
  subnet_id                 = var.subnet_id
  network_security_group_id = azurerm_network_security_group.nsg.id
}