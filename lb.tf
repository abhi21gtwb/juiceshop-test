resource "azurerm_public_ip" "public_ip" {
  name                = "lb-public-ip"
  location            = azurerm_resource_group.rg12.location
  resource_group_name = azurerm_resource_group.rg12.name
  allocation_method   = "Static"
}

resource "azurerm_lb" "lb" {
  name                = "juice-shop-lb"
  location            = azurerm_resource_group.rg12.location
  resource_group_name = azurerm_resource_group.rg12.name
  frontend_ip_configuration {
    name                 = "frontend"
    public_ip_address_id = azurerm_public_ip.public_ip.id
  }
}

# Backend Pool for Load Balance
resource "azurerm_lb_backend_address_pool" "backend" {
  name                = "backend-pool"
  loadbalancer_id     = azurerm_lb.lb.id
}


# Add the container's private IP address to the backend pool
resource "azurerm_lb_backend_address_pool_address" "lb_pool" {
  name                    = "backend-address-10.0.1.4"  # Unique name for the backend address
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend.id
  ip_address              = "10.0.1.4"  # hardcode container's private IP
  virtual_network_id      = azurerm_virtual_network.vnet198.id  #Vnet mapping
}

# Health Probe for Load Balancer
resource "azurerm_lb_probe" "lb_probe" {
  name                = "http-probe"
  protocol            = "Http"
  port                = 80
  request_path        = "/"
  interval_in_seconds = 30
  number_of_probes    = 3
  loadbalancer_id     = azurerm_lb.lb.id
}

# Load Balancing Rule for Load Balancer
resource "azurerm_lb_rule" "example" {
  name                           = "HTTP-Rule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = azurerm_lb.lb.frontend_ip_configuration[0].name
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.backend.id]
  probe_id                       = azurerm_lb_probe.lb_probe.id
  loadbalancer_id                = azurerm_lb.lb.id
}

output "lb_ip" {
  value = azurerm_public_ip.public_ip.ip_address
}
