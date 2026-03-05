# =============================================================================
# Squad Teams Bot — Azure Bot Service + Entra ID App
# =============================================================================
# Cross-project bot for Squad agent notifications via Microsoft Teams.
# One bot serves all project channels; only TEAMS_CHANNEL_ID differs per repo.

# Entra ID Application for Squad Teams Bot
data "azuread_client_config" "current" {}

resource "azuread_application" "squad_teams_bot" {
  display_name     = "squad-teams-bot"
  sign_in_audience = "AzureADMyOrg"
}

resource "azuread_application_password" "squad_teams_bot" {
  application_id = azuread_application.squad_teams_bot.id
  display_name   = "squad-teams-bot-secret"
  end_date       = "2028-01-01T00:00:00Z"
}

# Azure Bot Service (F0 = free tier, 10k messages/month)
resource "azurerm_bot_service_azure_bot" "squad" {
  name                = "bot-squad-${local.name_prefix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = "global"
  sku                 = "F0"
  microsoft_app_id        = azuread_application.squad_teams_bot.client_id
  microsoft_app_type      = "SingleTenant"
  microsoft_app_tenant_id = data.azuread_client_config.current.tenant_id
  tags                    = local.common_tags
}

# Enable Teams channel on the bot
resource "azurerm_bot_channel_ms_teams" "squad" {
  bot_name            = azurerm_bot_service_azure_bot.squad.name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_bot_service_azure_bot.squad.location
}

# Store credentials in existing Key Vault
resource "azurerm_key_vault_secret" "teams_app_id" {
  name         = "squad-teams-app-id"
  value        = azuread_application.squad_teams_bot.client_id
  key_vault_id = module.key_vault.id
}

resource "azurerm_key_vault_secret" "teams_app_password" {
  name         = "squad-teams-app-password"
  value        = azuread_application_password.squad_teams_bot.value
  key_vault_id = module.key_vault.id
}
