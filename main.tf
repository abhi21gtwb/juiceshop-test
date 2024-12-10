resource "azurem_resource_group" "rg" {
  name = "juiceshop-rg"
  location = "West India" 
}

#Vnet and  Subnet for private IPs
resource "azurerm_virtual_network" "vnet" {
  name                = "juiceshop-vnet1987"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet-aci" {
  name                 = "juiceshop-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefix       = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "subnet-nginx" {
  name                 = "juiceshop-nginx"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefix       = ["10.0.2.0/24"]
}

# Container Instance for JuiceShop
resource "azurerm_container_group" "juiceshop" {
  name                = "juiceshop"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
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
  network_profile_id = azurem_subnet.subnet-aci.id
}


# Nginx Reverse Proxy Container
resource "azurerm_container_group" "nginx" {
  name                = "nginx-proxy"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
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
  network_profile_id = azurem_subnet.subnet-nginx.id 
}

