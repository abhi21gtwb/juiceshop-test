provider "azurerm" {
  features {}

  client_id       = var.client_id
  client_secret   = var.client_secret
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
  use_msi         = false # Explicitly disable MSI to use the provided credentials
}

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
  backend "azurerm" {
      resource_group_name  = "juiceshop-rg"
      storage_account_name = "storageaccount191599"
      container_name       = "vhds"
      key                  = "terraform.tfstate"
      use_azuread_auth     = true
  }

}

#resource "azurerm_resource_group" "rg" {
#  name     = "juiceshop-rg"
# location = "centralus" # Replace with your preferred Azure region
#}

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
