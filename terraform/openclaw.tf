locals {
  openclaw_tunnel_dns_records = {
    for hostname in var.openclaw_tunnel_dns_hostnames :
    trimsuffix(hostname, ".ashleyhollis.com") => hostname
  }
}

resource "azurerm_federated_identity_credential" "external_secrets_openclaw" {
  count = var.openclaw_arc_oidc_issuer_url == null ? 0 : 1

  name                = "fedcred-${local.name_prefix}-eso-openclaw"
  resource_group_name = azurerm_resource_group.main.name
  parent_id           = azurerm_user_assigned_identity.external_secrets.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = var.openclaw_arc_oidc_issuer_url
  subject             = "system:serviceaccount:external-secrets:azure-keyvault-reader"

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_role_assignment" "external_secrets_acr_pull" {
  scope                = module.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.external_secrets.principal_id
}

resource "cloudflare_zero_trust_tunnel_cloudflared" "openclaw" {
  count = var.enable_openclaw_tunnel ? 1 : 0

  account_id = var.cloudflare_account_id
  name       = "openclaw-yt-summarizer"
  config_src = "cloudflare"

  lifecycle {
    prevent_destroy = true
  }
}

data "cloudflare_zero_trust_tunnel_cloudflared_token" "openclaw" {
  count = var.enable_openclaw_tunnel ? 1 : 0

  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.openclaw[0].id
}

resource "cloudflare_dns_record" "openclaw" {
  for_each = var.enable_openclaw_tunnel ? local.openclaw_tunnel_dns_records : {}

  zone_id = var.cloudflare_zone_id
  name    = each.key
  content = "${cloudflare_zero_trust_tunnel_cloudflared.openclaw[0].id}.cfargotunnel.com"
  type    = "CNAME"
  ttl     = 1
  proxied = true

  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "openclaw" {
  count = var.enable_openclaw_tunnel ? 1 : 0

  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.openclaw[0].id

  config = {
    ingress = concat(
      [
        for hostname, service in var.openclaw_tunnel_ingress : {
          hostname = hostname
          service  = service
        }
      ],
      [
        {
          service = "http_status:404"
        }
      ]
    )
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_key_vault_secret" "openclaw_cloudflare_tunnel_token" {
  count = var.enable_openclaw_tunnel ? 1 : 0

  name         = "cloudflare-tunnel-token"
  value        = data.cloudflare_zero_trust_tunnel_cloudflared_token.openclaw[0].token
  key_vault_id = module.key_vault.id

  lifecycle {
    prevent_destroy = true
  }
}
