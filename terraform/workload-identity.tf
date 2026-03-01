import {
  to = azurerm_user_assigned_identity.external_secrets
  id = "/subscriptions/28aefbe7-e2af-4b4a-9ce1-92d6672c31bd/resourceGroups/rg-ytsumm-prd/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-ytsumm-prd-eso"
}

import {
  to = azurerm_federated_identity_credential.external_secrets
  id = "/subscriptions/28aefbe7-e2af-4b4a-9ce1-92d6672c31bd/resourceGroups/rg-ytsumm-prd/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-ytsumm-prd-eso/federatedIdentityCredentials/fedcred-ytsumm-prd-eso"
}

import {
  to = azurerm_role_assignment.external_secrets_kv_reader
  id = "/subscriptions/28aefbe7-e2af-4b4a-9ce1-92d6672c31bd/resourceGroups/rg-ytsumm-prd/providers/Microsoft.KeyVault/vaults/kv-ytsumm-prd/providers/Microsoft.Authorization/roleAssignments/e284c75b-ac88-45c3-d30a-505b9b447512"
}

resource "azurerm_user_assigned_identity" "external_secrets" {
  name                = "id-${local.name_prefix}-eso"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags
}

resource "azurerm_federated_identity_credential" "external_secrets" {
  name                = "fedcred-${local.name_prefix}-eso"
  resource_group_name = azurerm_resource_group.main.name
  parent_id           = azurerm_user_assigned_identity.external_secrets.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = module.aks.oidc_issuer_url
  subject             = "system:serviceaccount:yt-summarizer:yt-summarizer-sa"
}

resource "azurerm_role_assignment" "external_secrets_kv_reader" {
  scope                = module.key_vault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.external_secrets.principal_id
}
