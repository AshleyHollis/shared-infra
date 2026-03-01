module "github_oidc" {
  source = "./modules/github-oidc"

  github_organization     = "AshleyHollis"
  github_repository       = "shared-infra"
  assign_contributor_role = true
  acr_id                  = module.acr.id

  tags = local.common_tags
}
