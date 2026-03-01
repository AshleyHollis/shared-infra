module "acr" {
  source = "./modules/container-registry"

  name                = replace("acr${local.name_prefix}", "-", "")
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = var.acr_sku

  tags = local.common_tags
}

import {
  to = module.acr.azurerm_container_registry.acr
  id = "/subscriptions/28aefbe7-e2af-4b4a-9ce1-92d6672c31bd/resourceGroups/rg-ytsumm-prd/providers/Microsoft.ContainerRegistry/registries/acrytsummprd"
}
