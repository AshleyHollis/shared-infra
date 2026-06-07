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

resource "azurerm_role_assignment" "github_oidc_key_vault_secrets_user" {
  scope                = module.key_vault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.github_oidc.service_principal_object_id
}

import {
  to = module.key_vault.azurerm_key_vault.vault
  id = "/subscriptions/28aefbe7-e2af-4b4a-9ce1-92d6672c31bd/resourceGroups/rg-ytsumm-prd-ci/providers/Microsoft.KeyVault/vaults/kv-ytsumm-prd-ci"
}

import {
  to = module.key_vault.azurerm_role_assignment.secrets_officer[0]
  id = "/subscriptions/28aefbe7-e2af-4b4a-9ce1-92d6672c31bd/resourceGroups/rg-ytsumm-prd-ci/providers/Microsoft.KeyVault/vaults/kv-ytsumm-prd-ci/providers/Microsoft.Authorization/roleAssignments/9bdcfc58-afc3-4278-b94b-17f2d5f90aed"
}
