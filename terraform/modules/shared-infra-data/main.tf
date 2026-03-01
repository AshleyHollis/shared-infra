terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
    }
  }
}

data "azurerm_resource_group" "shared" {
  name = var.resource_group_name
}

data "azurerm_key_vault" "shared" {
  name                = var.key_vault_name
  resource_group_name = var.resource_group_name
}
