module "key_vault" {
  source = "./modules/key-vault"

  name                         = "kv-${local.name_prefix}"
  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  purge_protection_enabled     = true
  secrets_officer_principal_id = var.key_vault_secrets_officer_principal_id

  secrets = {}

  tags = local.common_tags

  lifecycle {
    prevent_destroy = true
  }
}
