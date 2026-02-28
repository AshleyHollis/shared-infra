# Research: consolidate-shared-infra

## Executive Summary

Consolidating shared infrastructure from yt-summarizer and meal-planner into a single shared-infra monorepo is technically viable and well-supported by industry patterns. The codebase contains ~30 Terraform resources in yt-summarizer (AKS, ACR, RG, KV, DNS, storage) and ~8 in meal-planner (SQL, storage, SWA), with meal-planner tightly coupled to yt-summarizer's resource group and Key Vault. Additionally, 48 custom GitHub Actions are duplicated identically across both repos. The recommended approach is: (1) single root Terraform module with azurerm backend and OIDC auth, (2) `removed` + `import` blocks for state migration, (3) composite actions + reusable workflows stored alongside Terraform in shared-infra.

## External Research

### Terraform Monorepo Patterns

- **Single root module is viable** for the current scope (~15 shared resources, well under the ~100 resource soft limit where plan times degrade)
- **Data-only module pattern** recommended by HashiCorp: wrap `terraform_remote_state` in a small module so consumers don't hardcode backend config
- **azurerm backend with OIDC auth** is the Azure standard: state in Azure Blob Storage, authenticate via workload identity federation from GitHub Actions
- **Plan-on-PR, apply-on-merge** with path-based triggers (`*.tf`, `modules/**`) is the standard CI/CD pattern
- **State backend bootstrap** is a chicken-and-egg problem solved with Azure CLI one-liner or separate bootstrap config

### GitHub Actions Sharing

- **Composite actions** for individual tasks (setup-terraform-azure, build-images, health-check) -- can't access `secrets.*` directly, must pass via `inputs`
- **Reusable workflows** for full pipeline templates (CI, deploy-AKS, cleanup) -- support `secrets: inherit`, environment protection rules
- **Store in `shared-infra/actions/`** (Option A monorepo) -- simpler for 2 consumer repos and 1 maintainer
- **Unified semantic versioning** with major-tag pinning (`@v1`) -- git tags apply to entire repo
- **Critical constraint**: If `AshleyHollis` is a personal GitHub account (not an org), shared-infra **must be public** for cross-repo action sharing

### Terraform State Migration

- **`removed` + `import` blocks** (Terraform >= 1.7) is HashiCorp's current recommendation for cross-state migration
- Declarative, PR-reviewable, safe dry-run via `terraform plan`
- `moved` block only works within same state file (useful for post-migration refactoring)
- `terraform state mv` is the legacy fallback (imperative, not version-controlled)
- Migration must follow dependency order: Resource Group -> DNS Zone -> Key Vault -> ACR -> AKS
- `prevent_destroy = true` lifecycle is critical safety net during migration

### Best Practices

- Keep root module under ~100 resources; split into layers if exceeded
- Treat `outputs.tf` as a versioned API contract -- breaking changes require consumer coordination
- Always commit `.terraform.lock.hcl` to prevent provider version drift
- Enable Azure Blob versioning on state storage for automatic rollback capability
- Never pin consumers to `@main` -- always use version tags

### Prior Art

| Pattern | Description | Source |
|---------|-------------|--------|
| Spacelift monorepo layout | `configurations/{app}/` + `modules/` at root | Spacelift Blog |
| Azure CAF Enterprise Scale | Multiple module declarations with remote state | Azure CAF Wiki |
| Azure Verified Module (AVM) | Production AKS+ACR pattern module | Azure GitHub |
| HashiCorp OIDC CI/CD Sample | Terraform + Azure + GitHub Actions OIDC | Microsoft Samples |

### Pitfalls to Avoid

| Pitfall | Impact | Mitigation |
|---------|--------|------------|
| Monolith state blast radius | Slow plans, lock contention | Keep under 100 resources; split later if needed |
| `terraform_remote_state` leaks full state | Security risk | Only output non-sensitive values; use data-only module |
| Output breaking changes | Cascading failures to all consumers | Treat outputs.tf as stable API; deprecate before removing |
| Missing `.terraform.lock.hcl` | Provider version drift | Always commit lock file |
| Resource recreation during migration | Downtime, data loss | Config must exactly match deployed state; validate with plan |
| Orphaned resources after partial migration | Untracked Azure resources | Back up state before removal; document resource IDs |
| Renaming reusable workflow .yml files | Breaks all callers | Treat filenames as stable API |
| Secrets in composite actions | Actions can't access `secrets.*` | Pass via inputs; use `secrets: inherit` for workflows |
| Private repo cross-repo sharing | Actions not accessible | Must be public repo (personal account) or use org |

## Codebase Analysis

### Existing Patterns

1. **Terraform State**: Shared Azure Blob Storage backend (`stytsummarizertfstate` in `rg-ytsummarizer-tfstate`). yt-summarizer uses `prod.tfstate`, meal-planner uses `meal-planner.tfstate`
2. **Provider Versions**: yt-summarizer and meal-planner both use azurerm >= 4.57.0 < 5.0. personal-ai-landing-zone uses older ~> 3.80
3. **Container Orchestration**: yt-summarizer uses AKS + ArgoCD; personal-ai-landing-zone uses Container Apps (independent)
4. **Secrets**: Azure Key Vault (`kv-ytsumm-prd`) with Workload Identity + External Secrets Operator
5. **CI/CD Auth**: GitHub OIDC federation via Azure AD app registration (configured in yt-summarizer)
6. **Frontend**: Azure Static Web Apps for both yt-summarizer (Standard) and meal-planner (Free)

### Resource Inventory

**YT-Summarizer (~30 resources)**:
- Resource Group: `rg-ytsumm-prd` (eastasia)
- AKS: `aks-ytsumm-prd` (Standard_B4als_v2, 1 node, K8s 1.33, Workload Identity)
- ACR: `acrytsummprd` (Basic SKU)
- Key Vault: `kv-ytsumm-prd` (purge protection, RBAC)
- Storage: `stytsummprd` (GRS, 3 containers, 4 queues)
- SQL: `sql-ytsumm-prd` (Basic tier, DB: ytsummarizer)
- SWA: `swa-ytsumm-prd` (Standard, Auth0 integration)
- ArgoCD: Helm chart v7.3.11
- GitHub OIDC: Azure AD app + 4 federated credentials
- Auth0: 2 apps (prod + preview), 3 connections, 2 test users, 1 action
- Workload Identity: User-assigned managed identity for ESO
- 9 Terraform modules: aks, argocd, auth0, container-registry, github-oidc, key-vault, sql-database, static-web-app, storage

**Meal-Planner (~8 resources)**:
- SQL: `sql-mealplan-prd` (Serverless GP_S_Gen5_1, DB: mealplanner)
- Storage: `stmealplaprd` (LRS, queue: meal-plan-jobs)
- SWA: `swa-mealplan-prd` (Free)
- Key Vault Secrets: 3 secrets in shared KV `kv-ytsumm-prd`
- Cross-repo refs: shared RG (`rg-ytsumm-prd`), shared Key Vault (`kv-ytsumm-prd`)

**GitHub Actions**: 48 custom actions duplicated identically across yt-summarizer and meal-planner, including: setup-terraform-azure, azure-acr-login, build-images, health-check, verify-k8s-deployment, terraform-plan, run-pytest, run-playwright-tests, cleanup-acr-images, and 39 more.

### Shared Resources (Candidates for shared-infra)

| Resource | Current Owner | Consumers |
|----------|--------------|-----------|
| Resource Group (`rg-ytsumm-prd`) | yt-summarizer | yt-summarizer, meal-planner |
| Key Vault (`kv-ytsumm-prd`) | yt-summarizer | yt-summarizer, meal-planner |
| ACR (`acrytsummprd`) | yt-summarizer | yt-summarizer |
| AKS (`aks-ytsumm-prd`) | yt-summarizer | yt-summarizer |
| TF State Storage (`stytsummarizertfstate`) | yt-summarizer | yt-summarizer, meal-planner |
| GitHub OIDC App Registration | yt-summarizer | yt-summarizer, meal-planner |
| DNS (if applicable) | yt-summarizer | yt-summarizer |
| 48 GitHub Actions | yt-summarizer (canonical) | yt-summarizer, meal-planner |

### App-Specific Resources (Stay in app repos)

**YT-Summarizer**: SQL Database, Storage queues/containers (transcripts, summaries, embeddings), SWA, ArgoCD, Auth0 apps/connections/users, Workload Identity

**Meal-Planner**: SQL Database, Storage queue (meal-plan-jobs), SWA, Key Vault secrets

### Dependencies Between Repos

- **meal-planner -> yt-summarizer**: Key Vault (kv-ytsumm-prd), Resource Group (rg-ytsumm-prd), TF state storage
- **meal-planner -> yt-summarizer**: GitHub OIDC credentials (shared)
- **Both repos**: 48 identical GitHub Actions
- **personal-ai-landing-zone**: Fully independent (different provider version, no cross-refs)

### Constraints

- meal-planner hardcodes Key Vault and RG names (must switch to remote state data sources)
- No `terraform_remote_state` data sources exist today -- all cross-repo refs are by name
- Azure provider version mismatch: personal-ai-landing-zone on v3.x vs others on v4.x
- ArgoCD manages K8s resources outside Terraform (not captured in state)
- Auth0 integration requires environment variables that can't be fully externalized

## Quality Commands

| Type | Command | Source |
|------|---------|--------|
| Terraform Validate | `terraform validate` | Standard Terraform CLI |
| Terraform Format | `terraform fmt -check` | Standard Terraform CLI |
| Terraform Plan | `terraform plan` | Standard Terraform CLI |
| Action Lint | `actionlint` | Recommended addition |

Recommended local CI: `terraform fmt -check && terraform validate && actionlint`

## Feasibility Assessment

| Aspect | Assessment | Notes |
|--------|------------|-------|
| Technical Viability | **High** | Well-trodden pattern for Azure; azurerm backend + remote state is mature |
| State Migration | **Medium risk** | `removed` + `import` blocks are safe but require exact config matching |
| GitHub Actions | **Low risk** | Copy + update references; parallel run period for validation |
| Effort Estimate | **L** | Terraform consolidation + state migration + GH Actions + consumer updates |
| Risk Level | **Medium** | Main risk is state migration; mitigated by backups + `prevent_destroy` |

## Recommendations for Requirements

1. **Single root module** for shared resources (RG, AKS, ACR, KV, DNS, networking) with azurerm backend and OIDC auth
2. **Data-only consumer module** wrapping `terraform_remote_state` for app repos to consume
3. **`removed` + `import` blocks** for state migration (Terraform >= 1.7)
4. **Composite actions in `shared-infra/actions/`** for 48 duplicated actions + reusable workflows in `.github/workflows/`
5. **Unified versioning** with major-tag pinning (`@v1`) for actions
6. **4-phase migration**: Extract -> Parallel Run -> Cut Over -> Workflow Migration
7. **Bootstrap state backend** as prerequisite (Azure CLI or separate config)
8. **`outputs.tf` as stable API** with documentation; breaking changes = new major version
9. **Resolve public/private repo constraint** before GitHub Actions migration

## Open Questions

1. **Public vs private**: Is `AshleyHollis` a GitHub Organization or personal account? Determines if shared-infra must be public for cross-repo action sharing.
2. **State backend bootstrap**: Manual Azure CLI or separate Terraform bootstrap config?
3. **Environment strategy**: Production only, or also dev/staging? Affects state file layout.
4. **OIDC federation**: Reuse existing Azure AD app registration from yt-summarizer, or create new one for shared-infra?
5. **Action differences**: Are all 48 actions truly identical between repos, or are there material differences to reconcile?
6. **AKS ownership**: Should AKS move to shared-infra (platform resource) or stay in yt-summarizer (app-specific)?
7. **Naming convention**: Rename resources during consolidation (e.g., `rg-ytsumm-prd` -> `rg-shared-prd`) or keep existing names?

## Sources

- [Spacelift: Terraform Monorepo Structure](https://spacelift.io/blog/terraform-monorepo)
- [HashiCorp: Terraform Monorepo vs Multi-Repo](https://www.hashicorp.com/en/blog/terraform-mono-repo-vs-multi-repo-the-great-debate)
- [HashiCorp: terraform_remote_state Data Source](https://developer.hashicorp.com/terraform/language/state/remote-state-data)
- [HashiCorp: Automate Terraform with GitHub Actions](https://developer.hashicorp.com/terraform/tutorials/automation/github-actions)
- [HashiCorp: Refactor Terraform State](https://developer.hashicorp.com/terraform/language/state/refactor)
- [HashiCorp: terraform state mv](https://developer.hashicorp.com/terraform/cli/commands/state/mv)
- [HashiCorp: How to Split State Files](https://support.hashicorp.com/hc/en-us/articles/7955227415059-How-to-Split-State-Files)
- [Microsoft: GitHub OIDC CI/CD with Terraform](https://learn.microsoft.com/en-us/samples/azure-samples/github-terraform-oidc-ci-cd/github-terraform-oidc-ci-cd/)
- [GitHub Docs: Reusing Workflows](https://docs.github.com/en/actions/reference/workflows-and-actions/reusing-workflow-configurations)
- [GitHub Docs: Managing Custom Actions](https://docs.github.com/en/actions/how-tos/create-and-publish-actions/manage-custom-actions)
- [GitHub Docs: Releasing and Maintaining Actions](https://docs.github.com/en/actions/how-tos/create-and-publish-actions/release-and-maintain-actions)
- [DEV Community: Composite Actions vs Reusable Workflows](https://dev.to/n3wt0n/composite-actions-vs-reusable-workflows-what-is-the-difference-github-actions-11kd)
- [Google Cloud: Terraform Best Practices for Root Modules](https://cloud.google.com/docs/terraform/best-practices/root-modules)
- [Azure CAF Enterprise Scale: Remote State Examples](https://github.com/Azure/terraform-azurerm-caf-enterprise-scale/wiki)
- [tfmigrate: GitOps State Migration Tool](https://github.com/minamijoyo/tfmigrate)
- [Spacelift: Terraform State Rollback](https://spacelift.io/blog/terraform-state-rollback)
