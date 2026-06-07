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

variable "key_vault_secrets_officer_principal_id" {
  description = "Principal ID with Key Vault Secrets Officer access"
  type        = string
  default     = "eac9556a-cd81-431f-a1ec-d6940b2d92d3"
}

variable "cloudflare_account_id" {
  description = "Cloudflare account ID used when OpenClaw tunnel management is enabled"
  type        = string
  default     = null
  sensitive   = true
}

variable "cloudflare_api_token" {
  description = "Cloudflare API token with Cloudflare Tunnel and DNS edit permissions"
  type        = string
  default     = null
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID for ashleyhollis.com"
  type        = string
  default     = null
}

variable "enable_openclaw_tunnel" {
  description = "Create the OpenClaw Cloudflare Tunnel, DNS records, tunnel config, and Key Vault token secret"
  type        = bool
  default     = false
}

variable "openclaw_arc_oidc_issuer_url" {
  description = "OIDC issuer URL for the Azure Arc-enabled OpenClaw K3s cluster"
  type        = string
  default     = null
}

variable "openclaw_tunnel_ingress" {
  description = "Public hostnames and internal services routed through the OpenClaw Cloudflare Tunnel"
  type        = map(string)
  default = {
    "*.yt-summarizer.apps.ashleyhollis.com"   = "http://nginx-gateway-fabric.gateway-system.svc.cluster.local:80"
    "api.yt-summarizer.apps.ashleyhollis.com" = "http://nginx-gateway-fabric.gateway-system.svc.cluster.local:80"
  }
}

variable "openclaw_tunnel_dns_hostnames" {
  description = "Public hostnames that receive Cloudflare DNS records for the OpenClaw tunnel"
  type        = set(string)
  default = [
    "*.yt-summarizer.apps.ashleyhollis.com",
  ]
}
