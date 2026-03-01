output "resource_group_name" {
  description = "Name of the shared resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_id" {
  description = "ID of the shared resource group"
  value       = azurerm_resource_group.main.id
}

output "resource_group_location" {
  description = "Location of the shared resource group"
  value       = azurerm_resource_group.main.location
}

output "key_vault_name" {
  description = "Name of the shared Key Vault"
  value       = module.key_vault.name
}

output "key_vault_id" {
  description = "ID of the shared Key Vault"
  value       = module.key_vault.id
}

output "key_vault_uri" {
  description = "URI of the shared Key Vault"
  value       = module.key_vault.vault_uri
}

output "key_vault_tenant_id" {
  description = "Tenant ID of the shared Key Vault"
  value       = module.key_vault.tenant_id
}

output "acr_name" {
  description = "Name of the Azure Container Registry"
  value       = module.acr.name
}

output "acr_login_server" {
  description = "Login server URL for the Azure Container Registry"
  value       = module.acr.login_server
}

output "acr_id" {
  description = "ID of the Azure Container Registry"
  value       = module.acr.id
}

output "aks_cluster_name" {
  description = "Name of the AKS cluster"
  value       = module.aks.name
}

output "aks_cluster_id" {
  description = "ID of the AKS cluster"
  value       = module.aks.id
}

output "aks_fqdn" {
  description = "FQDN of the AKS cluster"
  value       = module.aks.fqdn
}

output "aks_oidc_issuer_url" {
  description = "OIDC issuer URL for Workload Identity federation"
  value       = module.aks.oidc_issuer_url
}

output "aks_kubelet_identity_object_id" {
  description = "Object ID of the AKS kubelet managed identity"
  value       = module.aks.kubelet_identity_object_id
}

output "github_oidc_application_id" {
  description = "Azure AD Application (Client) ID for AZURE_CLIENT_ID"
  value       = module.github_oidc.application_id
}

output "github_oidc_tenant_id" {
  description = "Azure AD Tenant ID for AZURE_TENANT_ID"
  value       = module.github_oidc.tenant_id
}

output "github_oidc_subscription_id" {
  description = "Azure Subscription ID for AZURE_SUBSCRIPTION_ID"
  value       = module.github_oidc.subscription_id
}

output "workload_identity_client_id" {
  description = "Client ID for External Secrets Workload Identity"
  value       = azurerm_user_assigned_identity.external_secrets.client_id
}
