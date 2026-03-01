output "resource_group_name" {
  description = "Name of the shared resource group"
  value       = data.terraform_remote_state.shared_infra.outputs.resource_group_name
}

output "resource_group_id" {
  description = "ID of the shared resource group"
  value       = data.terraform_remote_state.shared_infra.outputs.resource_group_id
}

output "resource_group_location" {
  description = "Location of the shared resource group"
  value       = data.terraform_remote_state.shared_infra.outputs.resource_group_location
}

output "key_vault_name" {
  description = "Name of the shared Key Vault"
  value       = data.terraform_remote_state.shared_infra.outputs.key_vault_name
}

output "key_vault_id" {
  description = "ID of the shared Key Vault"
  value       = data.terraform_remote_state.shared_infra.outputs.key_vault_id
}

output "key_vault_uri" {
  description = "URI of the shared Key Vault"
  value       = data.terraform_remote_state.shared_infra.outputs.key_vault_uri
}

output "acr_name" {
  description = "Name of the Azure Container Registry"
  value       = data.terraform_remote_state.shared_infra.outputs.acr_name
}

output "acr_login_server" {
  description = "Login server URL for the Azure Container Registry"
  value       = data.terraform_remote_state.shared_infra.outputs.acr_login_server
}

output "acr_id" {
  description = "ID of the Azure Container Registry"
  value       = data.terraform_remote_state.shared_infra.outputs.acr_id
}

output "aks_cluster_name" {
  description = "Name of the AKS cluster"
  value       = data.terraform_remote_state.shared_infra.outputs.aks_cluster_name
}

output "workload_identity_client_id" {
  description = "Client ID for External Secrets Workload Identity"
  value       = data.terraform_remote_state.shared_infra.outputs.workload_identity_client_id
}