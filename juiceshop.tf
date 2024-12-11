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

resource "azurerm_subnet" "subnet-nginx2" {
  name                 = "subnet-${random_pet.rg_name.id}"
  resource_group_name  = azurerm_resource_group.rg1.name
  virtual_network_name = azurerm_virtual_network.vnet198.name
  address_prefixes       = ["10.0.2.0/24"]


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

# Container Instance for JuiceShop
resource "azurerm_container_group" "juiceshop1" {
  name                = "${var.container_group_name_prefix}-${random_string.container_name.result}"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  os_type             = "Linux"
  subnet_ids          = [azurerm_subnet.subnet-aci1.id]  # Subnet for private IP
  ip_address_type     = "Private"                  # Must use private IP for subnet

  container {
    name   = "${var.container_name_prefix}-${random_string.container_name.result}"
    image  = var.image
    cpu    = var.cpu_cores
    memory = var.memory_in_gb
    ports {
      port     = var.port
      protocol = "TCP"
    }
  }
}


# Nginx Reverse Proxy Container
resource "azurerm_container_group" "nginx2" {
  name                = "${var.container_group_name_prefix}-${random_string.container_name.result}"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  os_type             = "Linux"
  subnet_ids          = [azurerm_subnet.subnet-nginx2.id]  # Subnet for private IP
  ip_address_type     = "Private"                  # Must use private IP for subnet

  container {
    name   = "${var.container_name_prefix}-${random_string.container_name.result}"
    image  = var.image2
    cpu    = var.cpu_cores
    memory = var.memory_in_gb
    ports {
      port     = var.port
      protocol = "TCP"
    }

    ports {
      port	= var.port2
      protocol  = "TCP"
    }
 }
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


# Variables
variable "resource_group_location" {
  type        = string
  default     = "eastus"
  description = "Location for all resources."
}

variable "resource_group_name_prefix" {
  type        = string
  default     = "rg"
  description = "Prefix of the resource group name that's combined with a random value so name is unique in your Azure subscription."
}

variable "container_group_name_prefix" {
  type        = string
  default     = "acigroup"
  description = "Prefix of the container group name that's combined with a random value so name is unique in your Azure subscription.."
}

variable "container_name_prefix" {
  type        = string
  default     = "aci"
  description = "Prefix of the container name that's combined with a random value so name is unique in your Azure subscription."
}


variable "image" {
  type        = string
  default     = "bkimminich/juice-shop:v15.0.0"
  description = "Container image to deploy. Should be of the form repoName/imagename"
}


variable "port" {
  type        = number
  default     = 3000
  description = "Port to open on the container 1."
}

variable "cpu_cores" {
  type        = number
  default     = 1
  description = "The number of CPU cores to allocate to the container."
}

variable "memory_in_gb" {
  type        = number
  default     = 2
  description = "The amount of memory to allocate to the container in gigabytes."
}


variable "image2" {
  type        = string
  default     = "nginx.latest"
  description = "Container image to deploy. Should be of the form repoName/imagename."
}

variable "port2" {
  type        = number
  default     = 80
  description = "Port to open on the container."
}


output "juiceshop_internal_ip" {
  value = azurerm_container_group.juiceshop1.ip_address
}

#output "lb_ip" {
#  value = azurerm_public_ip.juiceshop_lb_pip.ip_address
#}
