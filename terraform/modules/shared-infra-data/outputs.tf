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
  description = "Name of the shared key vault"
  value       = data.terraform_remote_state.shared_infra.outputs.key_vault_name
}

output "key_vault_id" {
  description = "ID of the shared key vault"
  value       = data.terraform_remote_state.shared_infra.outputs.key_vault_id
}

output "key_vault_uri" {
  description = "URI of the shared key vault"
  value       = data.terraform_remote_state.shared_infra.outputs.key_vault_uri
}

output "key_vault_tenant_id" {
  description = "Tenant ID of the shared key vault"
  value       = data.terraform_remote_state.shared_infra.outputs.key_vault_tenant_id
}

output "acr_name" {
  description = "Name of the shared container registry"
  value       = data.terraform_remote_state.shared_infra.outputs.acr_name
}

output "acr_login_server" {
  description = "Login server of the shared container registry"
  value       = data.terraform_remote_state.shared_infra.outputs.acr_login_server
}

output "acr_id" {
  description = "ID of the shared container registry"
  value       = data.terraform_remote_state.shared_infra.outputs.acr_id
}

output "aks_cluster_name" {
  description = "Name of the shared AKS cluster"
  value       = data.terraform_remote_state.shared_infra.outputs.aks_cluster_name
}

output "aks_cluster_id" {
  description = "ID of the shared AKS cluster"
  value       = data.terraform_remote_state.shared_infra.outputs.aks_cluster_id
}

output "aks_fqdn" {
  description = "FQDN of the shared AKS cluster"
  value       = data.terraform_remote_state.shared_infra.outputs.aks_fqdn
}

output "aks_oidc_issuer_url" {
  description = "OIDC issuer URL of the shared AKS cluster"
  value       = data.terraform_remote_state.shared_infra.outputs.aks_oidc_issuer_url
}

output "aks_kubelet_identity_object_id" {
  description = "Object ID of the AKS kubelet managed identity"
  value       = data.terraform_remote_state.shared_infra.outputs.aks_kubelet_identity_object_id
}

output "github_oidc_application_id" {
  description = "Application ID for GitHub OIDC authentication"
  value       = data.terraform_remote_state.shared_infra.outputs.github_oidc_application_id
}

output "github_oidc_tenant_id" {
  description = "Tenant ID for GitHub OIDC authentication"
  value       = data.terraform_remote_state.shared_infra.outputs.github_oidc_tenant_id
}

output "github_oidc_subscription_id" {
  description = "Subscription ID for GitHub OIDC authentication"
  value       = data.terraform_remote_state.shared_infra.outputs.github_oidc_subscription_id
}

output "workload_identity_client_id" {
  description = "Client ID of the workload identity for external secrets"
  value       = data.terraform_remote_state.shared_infra.outputs.workload_identity_client_id
}
