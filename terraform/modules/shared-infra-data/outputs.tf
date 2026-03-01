output "resource_group_name" {
  description = "Name of the shared resource group"
  value       = data.azurerm_resource_group.shared.name
}

output "resource_group_id" {
  description = "ID of the shared resource group"
  value       = data.azurerm_resource_group.shared.id
}

output "resource_group_location" {
  description = "Location of the shared resource group"
  value       = data.azurerm_resource_group.shared.location
}

output "key_vault_name" {
  description = "Name of the shared Key Vault"
  value       = data.azurerm_key_vault.shared.name
}

output "key_vault_id" {
  description = "ID of the shared Key Vault"
  value       = data.azurerm_key_vault.shared.id
}

output "key_vault_uri" {
  description = "URI of the shared Key Vault"
  value       = data.azurerm_key_vault.shared.vault_uri
}
