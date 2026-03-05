variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "centralindia"
}

variable "kubernetes_version" {
  description = "Kubernetes version for AKS"
  type        = string
  default     = "1.33"
}

variable "aks_node_size" {
  description = "VM size for AKS nodes"
  type        = string
  default     = "Standard_B4als_v2"
}

variable "aks_os_disk_size_gb" {
  description = "OS disk size for AKS nodes in GB"
  type        = number
  default     = 128
}

variable "acr_sku" {
  description = "SKU for Azure Container Registry"
  type        = string
  default     = "Basic"
}

variable "squad_teams_bot_app_id" {
  description = "App ID for the Squad Teams bot (Entra app in M365 dev tenant)"
  type        = string
}

variable "squad_teams_bot_tenant_id" {
  description = "Tenant ID where the Squad Teams bot Entra app is registered (M365 dev tenant)"
  type        = string
}

variable "key_vault_secrets_officer_principal_id" {
  description = "Principal ID with Key Vault Secrets Officer access"
  type        = string
  default     = "eac9556a-cd81-431f-a1ec-d6940b2d92d3"
}
