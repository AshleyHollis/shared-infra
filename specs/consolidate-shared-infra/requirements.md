# Requirements: Consolidate Shared Infrastructure

## Goal

Eliminate cross-repo coupling and duplication by consolidating shared Azure infrastructure (RG, AKS, ACR, KV, DNS, OIDC) and 48 GitHub Actions into a single shared-infra monorepo, giving each app repo a clean, stable interface to platform resources.

## User Stories

### US-1: Bootstrap State Backend
**As a** platform operator, **I want** a dedicated Terraform state backend for shared-infra, **so that** shared infrastructure state is independent of any app repo.

**Acceptance Criteria:**
- [ ] AC-1.1: Azure Storage Account and container exist for shared-infra state (can reuse `stytsummarizertfstate` with new container/key)
- [ ] AC-1.2: Backend config uses azurerm provider with Azure Blob Storage
- [ ] AC-1.3: Blob versioning enabled on state storage account for rollback capability
- [ ] AC-1.4: Bootstrap is documented as a repeatable process (Azure CLI script or separate bootstrap config)
- [ ] AC-1.5: `terraform init` succeeds against the new backend without errors

### US-2: Configure OIDC Authentication
**As a** platform operator, **I want** GitHub Actions to authenticate to Azure via OIDC (workload identity federation), **so that** no long-lived secrets are stored in GitHub.

**Acceptance Criteria:**
- [ ] AC-2.1: Azure AD app registration has federated credentials for shared-infra repo (main branch + PR branches)
- [ ] AC-2.2: GitHub Actions workflows use `id-token: write` permission
- [ ] AC-2.3: `terraform plan` and `terraform apply` authenticate via OIDC in CI
- [ ] AC-2.4: No client secrets stored in GitHub repository secrets for Azure auth

### US-3: Consolidate Shared Resources into Single Root Module
**As a** platform operator, **I want** all shared Azure resources defined in a single Terraform root module, **so that** one `terraform apply` provisions the entire platform layer.

**Acceptance Criteria:**
- [ ] AC-3.1: Root module declares: Resource Group (`rg-ytsumm-prd`), Key Vault (`kv-ytsumm-prd`), ACR (`acrytsummprd`), AKS (`aks-ytsumm-prd`), DNS zone, GitHub OIDC app registration
- [ ] AC-3.2: Provider pinned to azurerm >= 4.57.0, < 5.0
- [ ] AC-3.3: Terraform version constrained to >= 1.7.0 (required for `removed`/`import` blocks)
- [ ] AC-3.4: `.terraform.lock.hcl` committed to version control
- [ ] AC-3.5: `terraform plan` shows no changes after initial import (config matches deployed state exactly)
- [ ] AC-3.6: `prevent_destroy = true` lifecycle set on AKS, ACR, Key Vault, and Resource Group
- [ ] AC-3.7: Resource count stays under 100 in single root module

### US-4: Expose Outputs as Stable API
**As an** app developer, **I want** shared-infra to expose resource identifiers and connection info as Terraform outputs, **so that** app repos can consume them without hardcoding resource names.

**Acceptance Criteria:**
- [ ] AC-4.1: `outputs.tf` exposes at minimum: resource group name, resource group ID, key vault name, key vault ID, ACR login server, ACR name, AKS cluster name, AKS resource group (node), OIDC client ID, DNS zone name
- [ ] AC-4.2: No sensitive values (passwords, keys, connection strings) in outputs
- [ ] AC-4.3: Outputs documented with `description` attribute on each output block
- [ ] AC-4.4: Outputs file treated as versioned API -- changes noted in release tags

### US-5: Migrate State from yt-summarizer
**As a** platform operator, **I want** to move shared resource state from yt-summarizer's `prod.tfstate` to shared-infra's state, **so that** shared resources are managed from one place.

**Acceptance Criteria:**
- [ ] AC-5.1: Migration uses `removed` blocks in yt-summarizer and `import` blocks in shared-infra (Terraform >= 1.7)
- [ ] AC-5.2: Migration follows dependency order: Resource Group -> DNS Zone -> Key Vault -> ACR -> AKS
- [ ] AC-5.3: `terraform plan` in shared-infra shows no changes after each batch import (config matches deployed state)
- [ ] AC-5.4: `terraform plan` in yt-summarizer shows only `removed` operations (no destroy) after each batch
- [ ] AC-5.5: State backup taken before each migration batch (`terraform state pull > backup-<batch>.tfstate`)
- [ ] AC-5.6: Zero downtime -- no resources recreated or destroyed during migration
- [ ] AC-5.7: yt-summarizer retains app-specific resources (SQL, storage queues/containers, SWA, ArgoCD, Auth0) in its state

### US-6: Create Data-Only Consumer Module
**As an** app developer, **I want** a reusable Terraform module that wraps `terraform_remote_state`, **so that** my app repo can consume shared outputs without hardcoding backend config.

**Acceptance Criteria:**
- [ ] AC-6.1: Module located at `modules/shared-infra-data/` in shared-infra repo
- [ ] AC-6.2: Module encapsulates azurerm backend config (storage account, container, key) for shared-infra state
- [ ] AC-6.3: Module re-exports all shared-infra outputs as module outputs
- [ ] AC-6.4: Consumer repos use module source with version pinning (git tag ref)
- [ ] AC-6.5: Usage example documented in module README or inline comments

### US-7: Update Consumer Repos
**As an** app developer, **I want** yt-summarizer and meal-planner to reference shared-infra outputs instead of hardcoded resource names, **so that** cross-repo coupling is eliminated.

**Acceptance Criteria:**
- [ ] AC-7.1: yt-summarizer replaces inline shared resource definitions with data-only module references
- [ ] AC-7.2: meal-planner replaces hardcoded Key Vault name (`kv-ytsumm-prd`) and Resource Group name (`rg-ytsumm-prd`) with data-only module outputs
- [ ] AC-7.3: `terraform plan` in both consumer repos shows no infrastructure changes after migration
- [ ] AC-7.4: meal-planner no longer depends on yt-summarizer for any Terraform state or resource

### US-8: Consolidate GitHub Actions
**As a** platform operator, **I want** all 48 custom GitHub Actions centralized in shared-infra, **so that** updates propagate to all consumers from one source.

**Acceptance Criteria:**
- [ ] AC-8.1: All 48 composite actions exist under `actions/<action-name>/action.yml` in shared-infra
- [ ] AC-8.2: Actions are functionally identical to current implementations (no behavior changes during migration)
- [ ] AC-8.3: Each action has `name`, `description`, and typed `inputs`/`outputs` defined
- [ ] AC-8.4: Secrets required by actions are passed via `inputs` (not accessed directly)
- [ ] AC-8.5: shared-infra repo is public (required for personal GitHub account cross-repo sharing)
- [ ] AC-8.6: Consumer repos reference actions as `AshleyHollis/shared-infra/actions/<name>@v1`

### US-9: Create Reusable Workflows
**As an** app developer, **I want** reusable CI/CD workflow templates in shared-infra, **so that** common pipeline patterns (Terraform plan/apply, container build, deploy) are standardized.

**Acceptance Criteria:**
- [ ] AC-9.1: Reusable workflows defined in `.github/workflows/` with `workflow_call` trigger
- [ ] AC-9.2: At minimum: terraform-plan, terraform-apply, build-and-push-image, deploy-to-aks workflows
- [ ] AC-9.3: Workflows accept inputs for repo-specific config (working directory, environment, image name)
- [ ] AC-9.4: Workflows support `secrets: inherit` for Azure/GitHub credentials
- [ ] AC-9.5: Workflow filenames treated as stable API (renaming breaks callers)
- [ ] AC-9.6: Consumer repos successfully call reusable workflows from their own CI/CD

### US-10: Version and Release Actions
**As a** platform operator, **I want** unified semantic versioning with major-tag pinning for shared actions and workflows, **so that** consumers get compatible updates without breakage.

**Acceptance Criteria:**
- [ ] AC-10.1: Releases use semantic versioning (e.g., v1.0.0, v1.1.0, v2.0.0)
- [ ] AC-10.2: Major tags (e.g., `v1`) are mutable and point to latest compatible release
- [ ] AC-10.3: Consumer repos pin to major tag (`@v1`) for automatic minor/patch updates
- [ ] AC-10.4: Breaking changes increment major version
- [ ] AC-10.5: CHANGELOG or release notes document changes per version

### US-11: CI/CD for shared-infra Itself
**As a** platform operator, **I want** automated plan-on-PR and apply-on-merge for the shared-infra repo, **so that** infrastructure changes are reviewed and applied safely.

**Acceptance Criteria:**
- [ ] AC-11.1: `terraform plan` runs on every PR that modifies `*.tf` or `modules/**` files
- [ ] AC-11.2: Plan output posted as PR comment
- [ ] AC-11.3: `terraform apply` runs on merge to main (auto-approve)
- [ ] AC-11.4: `terraform fmt -check` and `terraform validate` run as CI checks
- [ ] AC-11.5: `actionlint` runs on PRs modifying `.github/workflows/**` or `actions/**`
- [ ] AC-11.6: Apply fails fast if plan shows resource destruction (manual override required)

## Functional Requirements

| ID | Requirement | Priority | Acceptance Criteria |
|----|-------------|----------|---------------------|
| FR-1 | Single root module for all shared Azure resources | High | `terraform apply` provisions RG, KV, ACR, AKS, DNS, OIDC in one run |
| FR-2 | azurerm backend with OIDC auth for state storage | High | `terraform init` connects to Azure Blob; no stored secrets |
| FR-3 | `removed` + `import` blocks for state migration | High | Resources transfer between states with zero downtime |
| FR-4 | `prevent_destroy = true` on critical resources | High | Plan rejects accidental destroy of AKS, ACR, KV, RG |
| FR-5 | Data-only consumer module wrapping `terraform_remote_state` | High | App repos consume outputs without knowing backend config |
| FR-6 | 48 composite actions in `actions/` directory | High | All actions available at `shared-infra/actions/<name>@v1` |
| FR-7 | Reusable workflows with `workflow_call` trigger | Medium | Consumer repos call shared workflows for plan, apply, build, deploy |
| FR-8 | Path-based CI triggers for Terraform files | Medium | Only `*.tf` and `modules/**` changes trigger plan/apply |
| FR-9 | Semantic versioning with major-tag pinning | Medium | `@v1` resolves to latest v1.x.x release |
| FR-10 | Outputs documented with `description` attributes | Medium | Every output block includes descriptive text |
| FR-11 | State backup before each migration batch | High | Backup files recoverable if migration fails |
| FR-12 | Consumer repos migrate to data-only module | High | No hardcoded resource names in yt-summarizer or meal-planner TF |
| FR-13 | Public repository for cross-repo action sharing | High | Actions accessible from yt-summarizer and meal-planner |
| FR-14 | `.terraform.lock.hcl` committed to repo | Medium | Provider versions consistent across environments |

## Non-Functional Requirements

| ID | Requirement | Metric | Target |
|----|-------------|--------|--------|
| NFR-1 | Plan execution time | Wall clock for `terraform plan` | < 60 seconds for full plan |
| NFR-2 | State file size | Bytes | < 1 MB (well under with ~15 resources) |
| NFR-3 | Zero-downtime migration | Resource availability during migration | 100% uptime for all migrated resources |
| NFR-4 | Security -- no sensitive outputs | Sensitive values in `outputs.tf` | Zero sensitive values exposed |
| NFR-5 | Security -- OIDC only | Stored Azure credentials | Zero long-lived secrets in GitHub |
| NFR-6 | State locking | Concurrent access prevention | Azure Blob lease mechanism active |
| NFR-7 | Rollback capability | State recovery | Blob versioning + manual backups enable rollback |
| NFR-8 | Action compatibility | Breaking changes to consumers | Zero breaking changes during initial migration |
| NFR-9 | CI feedback time | PR plan comment posted | < 5 minutes from PR creation |
| NFR-10 | Maintainability | Single source of truth | 1 repo owns all shared infra definitions |

## Glossary

- **Root module**: Top-level Terraform configuration directory containing `main.tf`, `variables.tf`, `outputs.tf`
- **Data-only module**: A Terraform module whose sole purpose is reading remote state and re-exporting outputs; contains no resources
- **`removed` block**: Terraform >= 1.7 construct that declares a resource is no longer managed in this state, without destroying it
- **`import` block**: Terraform >= 1.5 construct that imports an existing cloud resource into state declaratively
- **Composite action**: GitHub Actions action type defined in `action.yml` that runs steps in the caller's runner context
- **Reusable workflow**: GitHub Actions workflow with `workflow_call` trigger, callable from other repos
- **Major-tag pinning**: Versioning strategy where a mutable tag (e.g., `v1`) always points to the latest compatible release
- **OIDC federation**: Authentication method where GitHub Actions exchanges a short-lived token with Azure AD, eliminating stored secrets
- **Platform layer**: Shared infrastructure resources (compute, networking, identity) consumed by multiple applications
- **Consumer repo**: An application repository (yt-summarizer, meal-planner) that depends on shared-infra outputs
- **State migration**: Moving Terraform resource ownership from one state file to another without destroying/recreating the resource
- **azurerm backend**: Terraform backend that stores state in Azure Blob Storage with native blob lease locking

## Out of Scope

- **personal-ai-landing-zone**: Fully independent architecture (azurerm v3.x, Container Apps). No cross-references.
- **Resource renaming**: Existing names (`rg-ytsumm-prd`, `kv-ytsumm-prd`, etc.) kept as-is. Renaming is a separate follow-up spec.
- **Multi-environment support**: Production only. Dev/staging environments are a future concern.
- **Kubernetes manifests and ArgoCD config**: Managed outside Terraform. Not part of this consolidation.
- **Auth0 configuration**: Remains in yt-summarizer (app-specific).
- **Application-level CI/CD**: App-specific build/test/deploy logic stays in each app repo. Only shared workflow templates are in scope.
- **Per-action versioning**: Using unified repo-level tags, not per-action prefixed tags.
- **State encryption at rest**: Azure Storage handles encryption by default. No custom encryption layer.
- **Terraform Cloud / Spacelift**: Using self-managed CI/CD with GitHub Actions, not a managed Terraform platform.

## Dependencies

| ID | Dependency | Required By | Status |
|----|-----------|-------------|--------|
| DEP-1 | Azure subscription with active resources | All user stories | Exists |
| DEP-2 | Terraform >= 1.7.0 installed in CI | US-3, US-5 | Must verify |
| DEP-3 | azurerm provider >= 4.57.0 | US-3 | Exists in app repos |
| DEP-4 | Azure AD app registration with OIDC federated credentials | US-2 | Exists in yt-summarizer; needs shared-infra credentials added |
| DEP-5 | Storage account for TF state (`stytsummarizertfstate`) | US-1 | Exists |
| DEP-6 | shared-infra repo set to public visibility | US-8, US-9 | Must verify/configure |
| DEP-7 | Resource IDs for all shared resources (for import blocks) | US-5 | Must collect via `az resource show` |
| DEP-8 | Exact Terraform config matching deployed state | US-5 | Must reverse-engineer from yt-summarizer TF files |
| DEP-9 | Access to yt-summarizer and meal-planner repos for consumer updates | US-7 | Exists |

## Unresolved Questions

1. **Public vs private repo**: Is `AshleyHollis` a personal GitHub account? If yes, shared-infra must be public for cross-repo action sharing. Confirm before GitHub Actions migration.
2. **OIDC app registration**: Reuse existing Azure AD app from yt-summarizer (add federated credentials for shared-infra) or create a new app registration?
3. **State backend key**: Use new container in existing `stytsummarizertfstate` or new key in existing container? Recommend new key (`shared-infra.tfstate`) in existing container.
4. **Action differences**: Are all 48 actions byte-identical between repos, or are there drift/modifications to reconcile?
5. **AKS cluster access**: After migration, how do consumer repos authenticate to AKS for deployments? Via shared OIDC credentials or separate kubeconfig?

## Success Criteria

- Single `terraform apply` in shared-infra provisions all shared Azure resources
- meal-planner has zero Terraform dependencies on yt-summarizer
- 48 GitHub Actions maintained in one location; consumer repos reference `@v1`
- `terraform plan` in all three repos (shared-infra, yt-summarizer, meal-planner) shows zero changes after full migration
- All CI/CD pipelines pass without manual intervention after migration

## Next Steps

1. Approve requirements (or flag changes needed)
2. Generate implementation plan with task breakdown and dependency graph
3. Begin parallel tracks: Terraform consolidation + GitHub Actions migration
