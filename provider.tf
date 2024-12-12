provider "azurerm" {
  features {}

  client_id       = var.client_id
  client_secret   = var.client_secret
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
  use_msi         = false # Explicitly disable MSI to use the provided credentials
}

resource "azurerm_resource_group" "rg12" {
  name = "random_pet.rg1_name.id"
  location = var.resource_group_location
}

# Declare input variables for Azure authentication
variable "client_id" {
  description = "Azure Client ID"
  type        = string
}

variable "client_secret" {
  description = "Azure Client Secret"
  type        = string
}

variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "tenant_id" {
  description = "Azure Tenant ID"
  type        = string
}
