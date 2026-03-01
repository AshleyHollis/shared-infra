# shared-infra

Shared infrastructure repository providing reusable CI/CD components and Azure infrastructure for consumer repos (yt-summarizer, meal-planner).

## Repository Structure

```
.github/
  actions/          # 53 composite GitHub Actions (referenced as AshleyHollis/shared-infra/.github/actions/<name>@v1)
  workflows/        # Reusable GitHub Actions workflows (build-and-push, deploy-to-aks, terraform-plan, etc.)
terraform/          # Shared Azure infrastructure (AKS, ACR, Key Vault, OIDC, workload identity)
  modules/
    shared-infra-data/  # Data-only module for consumer repos to look up shared resource IDs
scripts/            # Bootstrap and sync scripts (backend init, ArgoCD manifest sync)
```

## Usage

Consumer repos reference shared actions and workflows via:

```yaml
# Composite action
uses: AshleyHollis/shared-infra/.github/actions/<action-name>@v1

# Reusable workflow
uses: AshleyHollis/shared-infra/.github/workflows/<workflow>.yml@v1
```

Consumer repos reference the shared-infra-data module to look up resource IDs:

```hcl
module "shared_infra" {
  source = "github.com/AshleyHollis/shared-infra//terraform/modules/shared-infra-data?ref=v1"
}
```
