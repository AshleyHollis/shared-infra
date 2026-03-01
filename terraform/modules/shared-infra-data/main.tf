data "terraform_remote_state" "shared_infra" {
  backend = "azurerm"

  config = {
    resource_group_name  = "rg-ytsummarizer-tfstate"
    storage_account_name = "stytsummarizertfstate"
    container_name       = "tfstate"
    key                  = "shared-infra.tfstate"
    use_oidc             = true
  }
}
