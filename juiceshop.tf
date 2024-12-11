resource "random_pet" "rg_name" {
  prefix = var.resource_group_name_prefix
}


resource "azurerm_resource_group" "rg1" {
  name = "random_pet.rg1_name.id"
  location = var.resource_group_location
}


#Virtual Network and Subnet with Delegation
resource "azurerm_virtual_network" "vnet198" {
  name                = "vnet-${random_pet.rg_name.id}"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet-aci1" {
  name                 = "subnet-${random_pet.rg_name.id}"
  resource_group_name  = azurerm_resource_group.rg1.name
  virtual_network_name = azurerm_virtual_network.vnet198.name
  address_prefixes       = ["10.0.1.0/24"]

  delegation {
    name = "aci-delegation"
    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

# Container Group
resource "random_string" "container_name" {
  length  = 25
  lower   = true
  upper   = false
  special = false
}

#resource "azurerm_subnet" "subnet-nginx2" {
#  name                 = "juiceshop-nginx"
#  resource_group_name  = azurerm_resource_group.rg1.name
#  virtual_network_name = azurerm_virtual_network.vnet198.name
#  address_prefixes       = ["10.0.2.0/24"]
#}

# Container Instance for JuiceShop
resource "azurerm_container_group" "juiceshop1" {
  name                = "juiceshop1"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  os_type             = "Linux"

  container {
    name   = "juiceshop"
    image  = "bkimminich/juice-shop:v15.0.0"
    cpu    = "1"
    memory = "1.5"
    ports {
      port     = 3000
      protocol = "TCP"
    }
  }

  ip_address_type = "Private"  # Ensures no external IP
  subnet_ids = [azurerm_subnet.subnet-aci1.id]
# network_profile_id = azurerm_subnet.subnet-aci1.id
#  subnet_ids  = [var.subnet_id1]
}


# Nginx Reverse Proxy Container
resource "azurerm_container_group" "nginx2" {
  name                = "nginx-proxy2"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  os_type             = "Linux"

  container {
    name   = "nginx"
    image  = "nginx"
    cpu    = "1"
    memory = "1.5"
    ports {
      port     = 80
      protocol = "TCP"
    }

    ports {
      port	= 443
      protocol  = "TCP"
    }
 }
  ip_address_type = "Private"
   subnet_ids = [azurerm_subnet.subnet-nginx2.id]
#  network_profile_id = azurerm_subnet.subnet-nginx2.id
#   subnet_ids = [var.subnet_id2]
}


resource "azurerm_public_ip" "public_ip" {
  name                = "lb-public-ip"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  allocation_method   = "Static"
}

resource "azurerm_lb" "lb" {
  name                = "juice-shop-lb"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  frontend_ip_configuration {
    name                 = "frontend"
    public_ip_address_id = azurerm_public_ip.public_ip.id
  }
}

resource "azurerm_lb_backend_address_pool" "backend" {
  name                = "backend-pool"
  loadbalancer_id     = azurerm_lb.lb.id
}



# Network Profile for both container groups
#resource "azurerm_network_profile" "juiceshop_network_profile" {
#  name                = "juiceshop-network-profile"
#  location            = azurerm_resource_group.rg1.location
#  resource_group_name = azurerm_resource_group.rg1.name
#
#  container_network_interface {
#    name = "examplecnic"
#
#    ip_configuration {
#      name      = "exampleipconfig"
#      subnet_id = "${azurerm_subnet.subnet-aci1.id}"
#    }
#  }
#}



output "juiceshop_internal_ip" {
  value = azurerm_container_group.juiceshop1.ip_address
}

#output "lb_ip" {
#  value = azurerm_public_ip.juiceshop_lb_pip.ip_address
#}
