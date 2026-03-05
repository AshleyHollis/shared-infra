# =============================================================================
# Squad Teams Bot — Azure Bot Service
# =============================================================================
# Cross-project bot for Squad agent notifications via Microsoft Teams.
# One bot serves all project channels; only TEAMS_CHANNEL_ID differs per repo.
#
# The Entra ID app is registered manually in the M365 dev tenant
# (3049dfaf-427f-45e4-b8a7-911c3f497ca4) because Terraform authenticates
# to the shared-infra tenant and can't manage apps cross-tenant.
# App credentials are stored in Key Vault via az CLI.

# Azure Bot Service (F0 = free tier, 10k messages/month)
resource "azurerm_bot_service_azure_bot" "squad" {
  name                    = "bot-squad-${local.name_prefix}"
  resource_group_name     = azurerm_resource_group.main.name
  location                = "global"
  sku                     = "F0"
  microsoft_app_id        = var.squad_teams_bot_app_id
  microsoft_app_type      = "SingleTenant"
  microsoft_app_tenant_id = var.squad_teams_bot_tenant_id
  tags                    = local.common_tags
}

# Enable Teams channel on the bot
resource "azurerm_bot_channel_ms_teams" "squad" {
  bot_name            = azurerm_bot_service_azure_bot.squad.name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_bot_service_azure_bot.squad.location
}
