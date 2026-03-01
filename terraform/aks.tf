module "aks" {
  source = "./modules/aks"

  name                = "aks-${local.name_prefix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  dns_prefix          = local.name_prefix
  kubernetes_version  = var.kubernetes_version

  node_count      = 1
  node_vm_size    = var.aks_node_size
  node_pool_name  = "system2"
  os_disk_size_gb = var.aks_os_disk_size_gb

  enable_workload_identity = true

  tags = local.common_tags

  lifecycle {
    prevent_destroy = true
  }
}
