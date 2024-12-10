provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg1" {
  name = "juiceshop-rg1"
  location = "West India" 
}

#Vnet and  Subnet for private IPs
resource "azurerm_virtual_network" "vnet198" {
  name                = "juiceshop-vnet198"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet-aci1" {
  name                 = "juiceshop-subnet1"
  resource_group_name  = azurerm_resource_group.rg1.name
  virtual_network_name = azurerm_virtual_network.vnet198.name
  address_prefixes       = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "subnet-nginx2" {
  name                 = "juiceshop-nginx2"
  resource_group_name  = azurerm_resource_group.rg1.name
  virtual_network_name = azurerm_virtual_network.vnet198.name
  address_prefixes       = ["10.0.2.0/24"]
}

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
  network_profile_id = azurerm_network_profile.juiceshop_network_profile.id
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
      port     = 443
      protocol = "TCP"
    }

    volume {
      name = "nginx-config"
      mount_path = "/etc/nginx/conf.d"
    }
  }

  ip_address_type = "Private"
  network_profile_id = azurerm_network_profile.juiceshop_network_profile.id
}


# Network Profile for both container groups
resource "azurerm_network_profile" "juiceshop_network_profile" {
  name                = "juiceshop-network-profile"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name

  container_network_interface {
    name = "examplecnic"

    ip_configuration {
      name      = "exampleipconfig"
      subnet_id = "${azurerm_subnet.subnet-aci1.id}"
    }
  }
}
