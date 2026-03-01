module "key_vault" {
  source = "./modules/key-vault"

  name                         = "kv-${local.name_prefix}"
  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  purge_protection_enabled     = true
  secrets_officer_principal_id = var.key_vault_secrets_officer_principal_id

  secrets = {}

  tags = local.common_tags
}

import {
  to = module.key_vault.azurerm_key_vault.vault
  id = "/subscriptions/28aefbe7-e2af-4b4a-9ce1-92d6672c31bd/resourceGroups/rg-ytsumm-prd/providers/Microsoft.KeyVault/vaults/kv-ytsumm-prd"
}

import {
  to = module.key_vault.azurerm_role_assignment.secrets_officer[0]
  id = "/subscriptions/28aefbe7-e2af-4b4a-9ce1-92d6672c31bd/resourceGroups/rg-ytsumm-prd/providers/Microsoft.KeyVault/vaults/kv-ytsumm-prd/providers/Microsoft.Authorization/roleAssignments/fde6c717-0024-8ad6-efd0-ce353b6928f3"
}
