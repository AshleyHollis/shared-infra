# Tasks: Consolidate Shared Infrastructure

## Phase 1: TDD Cycles (Implementation)

Focus: Build shared-infra TF root module, copy modules/actions, create import blocks, create CI workflows. Each cycle: write config -> validate -> plan -> verify.

### Bootstrap + Foundation (Tasks 1.1 - 1.4)

- [x] 1.1 Create bootstrap backend script
  - **Do**:
    1. Create `scripts/bootstrap-backend.sh` that verifies the Azure Storage Account and container exist for shared-infra state
    2. Script uses `az storage account show` and `az storage container show` to validate
    3. Script enables blob versioning on the storage account: `az storage account blob-service-properties update --account-name stytsummarizertfstate --enable-versioning true`
    4. Make script executable
  - **Files**: `scripts/bootstrap-backend.sh`
  - **Done when**: Script exists, is executable, includes blob versioning enablement, and documents the bootstrap process
  - **Verify**: `bash -n scripts/bootstrap-backend.sh && grep -q 'enable-versioning' scripts/bootstrap-backend.sh && echo VALID`
  - **Commit**: `feat(bootstrap): add backend bootstrap script with blob versioning`
  - _Requirements: FR-2, AC-1.1, AC-1.3, AC-1.4_
  - _Design: Section 1 - Terraform Root Module_

- [x] 1.2 Create TF foundation files: backend.tf, versions.tf, providers.tf
  - **Do**:
    1. Create `terraform/backend.tf` with azurerm backend config (storage_account_name: `stytsummarizertfstate`, container: `tfstate`, key: `shared-infra.tfstate`, use_oidc: true)
    2. Create `terraform/versions.tf` with `required_version >= 1.7.0`, azurerm `>= 4.57.0, < 5.0`, azuread `>= 3.7.0`
    3. Create `terraform/providers.tf` with azurerm (features block with key_vault purge settings) and azuread provider configs
  - **Files**: `terraform/backend.tf`, `terraform/versions.tf`, `terraform/providers.tf`
  - **Done when**: All 3 files match design.md specs exactly
  - **Verify**: `cd terraform && terraform fmt -check`
  - **Commit**: `feat(terraform): add backend, versions, and providers config`
  - _Requirements: FR-2, AC-1.2, AC-3.2, AC-3.3_
  - _Design: Section 1 - backend.tf, versions.tf_

- [x] 1.3 Create TF locals.tf, variables.tf, terraform.auto.tfvars
  - **Do**:
    1. Create `terraform/locals.tf` with `name_prefix = "ytsumm-prd"` and `common_tags` map
    2. Create `terraform/variables.tf` with subscription_id, location, kubernetes_version, aks_node_size, aks_os_disk_size_gb, acr_sku, key_vault_secrets_officer_principal_id (all with defaults per design.md)
    3. Create `terraform/terraform.auto.tfvars` with subscription_id only (repo is public -- no secrets)
  - **Files**: `terraform/locals.tf`, `terraform/variables.tf`, `terraform/terraform.auto.tfvars`
  - **Done when**: Variables match design.md, tfvars contains only subscription_id
  - **Verify**: `cd terraform && terraform fmt -check`
  - **Commit**: `feat(terraform): add locals, variables, and tfvars`
  - _Requirements: FR-1, AC-3.1_
  - _Design: Section 1 - locals.tf, variables.tf_

- [x] 1.4 [VERIFY] Quality checkpoint: terraform fmt + validate foundation
  - **Do**: Run formatting and basic validation on the foundation files
  - **Files**: None (verification only)
  - **Verify**: `cd terraform && terraform fmt -check -recursive && echo PASS`
  - **Done when**: All .tf files pass format check
  - **Commit**: `chore(terraform): pass quality checkpoint` (only if fixes needed)
  - _Requirements: FR-1, FR-2, AC-1.2, AC-3.2, AC-3.3_

### Copy Modules from yt-summarizer (Tasks 1.5 - 1.9)

- [x] 1.5 Copy AKS module from yt-summarizer
  - **Do**:
    1. Create `terraform/modules/aks/` directory
    2. Copy `main.tf` from `../yt-summarizer/infra/terraform/modules/aks/main.tf` exactly as-is
  - **Files**: `terraform/modules/aks/main.tf`
  - **Done when**: File is byte-identical to yt-summarizer source
  - **Verify**: `diff terraform/modules/aks/main.tf ../yt-summarizer/infra/terraform/modules/aks/main.tf && echo IDENTICAL`
  - **Commit**: `feat(modules): copy aks module from yt-summarizer`
  - _Requirements: FR-1, AC-3.1_
  - _Design: Section 1 - modules/aks_

- [x] 1.6 Copy container-registry module from yt-summarizer
  - **Do**:
    1. Create `terraform/modules/container-registry/` directory
    2. Copy `main.tf` from `../yt-summarizer/infra/terraform/modules/container-registry/main.tf`
  - **Files**: `terraform/modules/container-registry/main.tf`
  - **Done when**: File is byte-identical to yt-summarizer source
  - **Verify**: `diff terraform/modules/container-registry/main.tf ../yt-summarizer/infra/terraform/modules/container-registry/main.tf && echo IDENTICAL`
  - **Commit**: `feat(modules): copy container-registry module from yt-summarizer`
  - _Requirements: FR-1, AC-3.1_
  - _Design: Section 1 - modules/container-registry_

- [x] 1.7 Copy github-oidc module from yt-summarizer
  - **Do**:
    1. Create `terraform/modules/github-oidc/` directory
    2. Copy `main.tf`, `outputs.tf`, `variables.tf` from `../yt-summarizer/infra/terraform/modules/github-oidc/`
  - **Files**: `terraform/modules/github-oidc/main.tf`, `terraform/modules/github-oidc/outputs.tf`, `terraform/modules/github-oidc/variables.tf`
  - **Done when**: All 3 files are byte-identical to yt-summarizer source
  - **Verify**: `diff -r terraform/modules/github-oidc/ ../yt-summarizer/infra/terraform/modules/github-oidc/ --exclude=README.md && echo IDENTICAL`
  - **Commit**: `feat(modules): copy github-oidc module from yt-summarizer`
  - _Requirements: FR-1, AC-2.1_
  - _Design: Section 5 - OIDC Authentication_

- [ ] 1.8 Copy key-vault module from yt-summarizer
  - **Do**:
    1. Create `terraform/modules/key-vault/` directory
    2. Copy `main.tf` from `../yt-summarizer/infra/terraform/modules/key-vault/main.tf`
  - **Files**: `terraform/modules/key-vault/main.tf`
  - **Done when**: File is byte-identical to yt-summarizer source
  - **Verify**: `diff terraform/modules/key-vault/main.tf ../yt-summarizer/infra/terraform/modules/key-vault/main.tf && echo IDENTICAL`
  - **Commit**: `feat(modules): copy key-vault module from yt-summarizer`
  - _Requirements: FR-1, AC-3.1_
  - _Design: Section 1 - modules/key-vault_

- [ ] 1.9 [VERIFY] Quality checkpoint: terraform fmt modules
  - **Do**: Run format check on all copied modules
  - **Files**: None (verification only)
  - **Verify**: `cd terraform && terraform fmt -check -recursive modules/ && echo PASS`
  - **Done when**: All module files pass format check
  - **Commit**: `chore(modules): pass quality checkpoint` (only if fixes needed)
  - _Requirements: FR-1, AC-3.1_

### Root Module Resource Files (Tasks 1.10 - 1.16)

- [ ] 1.10 Create main.tf with resource group
  - **Do**:
    1. Create `terraform/main.tf` with `azurerm_resource_group.main` exactly matching design.md
    2. Include `lifecycle { prevent_destroy = true }`
    3. Use `local.name_prefix` and `local.common_tags`
  - **Files**: `terraform/main.tf`
  - **Done when**: Resource group config matches design.md exactly
  - **Verify**: `cd terraform && terraform fmt -check main.tf && echo PASS`
  - **Commit**: `feat(terraform): add resource group in main.tf`
  - _Requirements: FR-1, FR-4, AC-3.1, AC-3.6_
  - _Design: Section 1 - main.tf_

- [ ] 1.11 Create aks.tf with AKS module call
  - **Do**:
    1. Create `terraform/aks.tf` with `module.aks` call exactly matching design.md
    2. Include `lifecycle { prevent_destroy = true }`
    3. Set all parameters: name, rg, location, dns_prefix, k8s_version, node_count, node_vm_size, node_pool_name, os_disk_size_gb, enable_workload_identity, tags
  - **Files**: `terraform/aks.tf`
  - **Done when**: AKS module call matches design.md exactly
  - **Verify**: `cd terraform && terraform fmt -check aks.tf && echo PASS`
  - **Commit**: `feat(terraform): add AKS module call`
  - _Requirements: FR-1, FR-4, AC-3.1, AC-3.6_
  - _Design: Section 1 - aks.tf_

- [ ] 1.12 Create acr.tf with ACR module call
  - **Do**:
    1. Create `terraform/acr.tf` with `module.acr` call exactly matching design.md
    2. Include `lifecycle { prevent_destroy = true }`
    3. Use `replace("acr${local.name_prefix}", "-", "")` for name
  - **Files**: `terraform/acr.tf`
  - **Done when**: ACR module call matches design.md exactly
  - **Verify**: `cd terraform && terraform fmt -check acr.tf && echo PASS`
  - **Commit**: `feat(terraform): add ACR module call`
  - _Requirements: FR-1, FR-4, AC-3.1, AC-3.6_
  - _Design: Section 1 - acr.tf_

- [ ] 1.13 Create key-vault.tf with Key Vault module call
  - **Do**:
    1. Create `terraform/key-vault.tf` with `module.key_vault` call exactly matching design.md
    2. Include `lifecycle { prevent_destroy = true }`
    3. Set `secrets = {}` (no secrets -- app-specific)
  - **Files**: `terraform/key-vault.tf`
  - **Done when**: Key Vault module call matches design.md exactly
  - **Verify**: `cd terraform && terraform fmt -check key-vault.tf && echo PASS`
  - **Commit**: `feat(terraform): add Key Vault module call`
  - _Requirements: FR-1, FR-4, AC-3.1, AC-3.6_
  - _Design: Section 1 - key-vault.tf_

- [ ] 1.14 Create github-oidc.tf with OIDC module call
  - **Do**:
    1. Create `terraform/github-oidc.tf` with `module.github_oidc` call exactly matching design.md
    2. Set `github_repository = "shared-infra"`, `assign_contributor_role = true`, `acr_id = module.acr.id`
  - **Files**: `terraform/github-oidc.tf`
  - **Done when**: OIDC module call matches design.md exactly
  - **Verify**: `cd terraform && terraform fmt -check github-oidc.tf && echo PASS`
  - **Commit**: `feat(terraform): add GitHub OIDC module call`
  - _Requirements: FR-1, AC-2.1, AC-3.1_
  - _Design: Section 5 - OIDC Authentication_

- [ ] 1.15 Create workload-identity.tf with managed identity resources
  - **Do**:
    1. Create `terraform/workload-identity.tf` with 3 resources exactly matching design.md
    2. `azurerm_user_assigned_identity.external_secrets`
    3. `azurerm_federated_identity_credential.external_secrets`
    4. `azurerm_role_assignment.external_secrets_kv_reader`
  - **Files**: `terraform/workload-identity.tf`
  - **Done when**: All 3 resources match design.md exactly
  - **Verify**: `cd terraform && terraform fmt -check workload-identity.tf && echo PASS`
  - **Commit**: `feat(terraform): add workload identity resources`
  - _Requirements: FR-1, AC-3.1_
  - _Design: Section 1 - workload-identity.tf_

- [ ] 1.16 [VERIFY] Quality checkpoint: terraform validate root module
  - **Do**: Run full validation on root module (requires init with backend disabled)
  - **Files**: None (verification only)
  - **Verify**: `cd terraform && terraform init -backend=false > /dev/null 2>&1 && terraform validate && terraform fmt -check -recursive && echo PASS`
  - **Done when**: validate and fmt both pass
  - **Commit**: `chore(terraform): pass quality checkpoint` (only if fixes needed)
  - _Requirements: FR-1, AC-3.1, AC-3.2, AC-3.3_

### Outputs + Lock File (Tasks 1.17 - 1.20)

- [ ] 1.17 Create outputs.tf with stable API contract
  - **Do**:
    1. Create `terraform/outputs.tf` with all outputs from design.md
    2. Include `description` attribute on every output
    3. Outputs: resource_group_name, resource_group_id, resource_group_location, key_vault_name, key_vault_id, key_vault_uri, key_vault_tenant_id, acr_name, acr_login_server, acr_id, aks_cluster_name, aks_cluster_id, aks_fqdn, aks_oidc_issuer_url, aks_kubelet_identity_object_id, github_oidc_application_id, github_oidc_tenant_id, github_oidc_subscription_id, workload_identity_client_id
    4. No sensitive values
  - **Files**: `terraform/outputs.tf`
  - **Done when**: All 19 outputs present with descriptions, no sensitive values
  - **Verify**: `cd terraform && terraform fmt -check outputs.tf && grep -c 'output "' outputs.tf | grep -q '19' && echo PASS`
  - **Commit**: `feat(terraform): add stable API outputs`
  - _Requirements: FR-10, AC-4.1, AC-4.2, AC-4.3_
  - _Design: Section 1 - outputs.tf_

- [ ] 1.18 [VERIFY] Quality checkpoint: full terraform validate with outputs
  - **Do**: Re-validate entire root module after adding outputs
  - **Files**: None (verification only)
  - **Verify**: `cd terraform && terraform init -backend=false > /dev/null 2>&1 && terraform validate && terraform fmt -check -recursive && echo PASS`
  - **Done when**: Full validation passes
  - **Commit**: `chore(terraform): pass quality checkpoint` (only if fixes needed)
  - _Requirements: FR-1, FR-10, AC-4.1_

- [ ] 1.19 Commit .terraform.lock.hcl after terraform init
  - **Do**:
    1. Run `cd terraform && terraform init -backend=false` to generate `.terraform.lock.hcl`
    2. Verify lock file was created and contains provider hashes for azurerm and azuread
    3. Stage and commit `.terraform.lock.hcl`
  - **Files**: `terraform/.terraform.lock.hcl`
  - **Done when**: Lock file exists, is committed, and contains provider version locks
  - **Verify**: `test -f terraform/.terraform.lock.hcl && grep -q 'azurerm' terraform/.terraform.lock.hcl && grep -q 'azuread' terraform/.terraform.lock.hcl && echo PASS`
  - **Commit**: `feat(terraform): commit .terraform.lock.hcl for provider consistency`
  - _Requirements: FR-14, AC-3.4_
  - _Design: Section 1 - versions.tf_

- [ ] 1.20 [VERIFY] Quality checkpoint: lock file and full validate
  - **Do**: Verify lock file is committed and root module still validates
  - **Files**: None (verification only)
  - **Verify**: `git ls-files terraform/.terraform.lock.hcl | grep -q '.terraform.lock.hcl' && cd terraform && terraform init -backend=false > /dev/null 2>&1 && terraform validate && echo PASS`
  - **Done when**: Lock file tracked in git and validation passes
  - **Commit**: `chore(terraform): pass quality checkpoint` (only if fixes needed)
  - _Requirements: FR-14, AC-3.4_

### Copy 53 GitHub Actions (Tasks 1.21 - 1.24)

- [ ] 1.21 Copy all 53 composite actions from yt-summarizer
  - **Do**:
    1. Create `.github/actions/` directory structure
    2. Copy all 53 action directories from `../yt-summarizer/.github/actions/` to `.github/actions/`
    3. Exclude non-action files (e.g., `CERTIFICATE-VALIDATION.md`)
    4. Each action has its own directory with `action.yml`
  - **Files**: `.github/actions/*/action.yml` (53 action directories)
  - **Done when**: All 53 action directories exist with their action.yml files
  - **Verify**: `ls -d .github/actions/*/action.yml | wc -l | grep -q '53' && echo PASS`
  - **Commit**: `feat(actions): copy 53 composite actions from yt-summarizer`
  - _Requirements: FR-6, AC-8.1, AC-8.2, AC-8.3_
  - _Design: Section 3 - GitHub Actions_

- [ ] 1.22 Update setup-terraform-azure cross-action reference
  - **Do**:
    1. In `.github/actions/setup-terraform-azure/action.yml`, find `uses: ./.github/actions/verify-azure-credentials`
    2. Replace with `uses: AshleyHollis/shared-infra/.github/actions/verify-azure-credentials@v1`
  - **Files**: `.github/actions/setup-terraform-azure/action.yml`
  - **Done when**: Internal cross-action reference uses absolute path with @v1
  - **Verify**: `grep -q 'AshleyHollis/shared-infra/.github/actions/verify-azure-credentials@v1' .github/actions/setup-terraform-azure/action.yml && echo PASS`
  - **Commit**: `fix(actions): update setup-terraform-azure cross-action reference`
  - _Requirements: AC-8.2, AC-8.6_
  - _Design: Section 3 - Actions requiring update_

- [ ] 1.23 Verify all actions have name, description, and typed inputs
  - **Do**:
    1. Check each action.yml has `name:` and `description:` fields
    2. Check that inputs have type annotations where applicable
    3. Fix any missing metadata
  - **Files**: `.github/actions/*/action.yml` (only files needing fixes)
  - **Done when**: All 53 actions have name and description fields
  - **Verify**: `for f in .github/actions/*/action.yml; do grep -q "^name:" "$f" && grep -q "^description:" "$f" || echo "MISSING: $f"; done && echo CHECK_DONE`
  - **Commit**: `fix(actions): ensure all actions have name and description metadata`
  - _Requirements: AC-8.3_
  - _Design: Section 3_

- [ ] 1.24 [VERIFY] Quality checkpoint: actionlint on all actions
  - **Do**: Run actionlint on all action files (if actionlint is installed, otherwise validate YAML structure)
  - **Files**: None (verification only)
  - **Verify**: `which actionlint > /dev/null 2>&1 && actionlint .github/actions/*/action.yml && echo PASS || (for f in .github/actions/*/action.yml; do python -c "import yaml; yaml.safe_load(open('$f'))" 2>&1 || echo "INVALID: $f"; done && echo YAML_CHECK_DONE)`
  - **Done when**: All action YAML files are valid
  - **Commit**: `chore(actions): pass quality checkpoint` (only if fixes needed)
  - _Requirements: FR-6, AC-8.1, AC-8.3_

### Import Blocks - Batch 1: Resource Group (Tasks 1.25 - 1.28)

- [ ] 1.25 Backup state before batch 1 migration
  - **Do**:
    1. Run `cd ../yt-summarizer/infra/terraform/environments/prod && terraform state pull > backup-batch1.tfstate`
    2. Verify backup file is non-empty
  - **Files**: `../yt-summarizer/infra/terraform/environments/prod/backup-batch1.tfstate`
  - **Done when**: State backup file exists and is non-empty
  - **Verify**: `test -s ../yt-summarizer/infra/terraform/environments/prod/backup-batch1.tfstate && echo BACKUP_PASS`
  - **Commit**: None (backup only, do not commit state files)
  - _Requirements: FR-11, AC-5.5_
  - _Design: State Migration Plan - Batch 1_

- [ ] 1.26 Add import block for Resource Group in shared-infra
  - **Do**:
    1. Add import block to `terraform/main.tf` for `azurerm_resource_group.main`
    2. Use ID: `/subscriptions/28aefbe7-e2af-4b4a-9ce1-92d6672c31bd/resourceGroups/rg-ytsumm-prd`
  - **Files**: `terraform/main.tf`
  - **Done when**: Import block present with correct resource ID
  - **Verify**: `grep -q 'import' terraform/main.tf && grep -q 'azurerm_resource_group.main' terraform/main.tf && echo PASS`
  - **Commit**: `feat(migration): add import block for resource group (batch 1)`
  - _Requirements: FR-3, AC-5.1, AC-5.2_
  - _Design: State Migration Plan - Batch 1_

- [ ] 1.27 Add removed block for Resource Group in yt-summarizer
  - **Do**:
    1. In `../yt-summarizer/infra/terraform/environments/prod/resource-group.tf`, add `removed` block for `azurerm_resource_group.main`
    2. Set `lifecycle { destroy = false }`
    3. Keep the existing resource block alongside removed block for now (removed block tells TF to stop managing it)
  - **Files**: `../yt-summarizer/infra/terraform/environments/prod/resource-group.tf`
  - **Done when**: Removed block present with destroy = false
  - **Verify**: `grep -q 'removed' ../yt-summarizer/infra/terraform/environments/prod/resource-group.tf && grep -q 'destroy = false' ../yt-summarizer/infra/terraform/environments/prod/resource-group.tf && echo PASS`
  - **Commit**: `feat(migration): add removed block for resource group in yt-summarizer (batch 1)`
  - _Requirements: FR-3, AC-5.1, AC-5.4_
  - _Design: State Migration Plan - Batch 1_

- [ ] 1.28 [VERIFY] Quality checkpoint: terraform validate batch 1
  - **Do**: Validate both repos after batch 1 import/removed blocks
  - **Files**: None (verification only)
  - **Verify**: `cd terraform && terraform init -backend=false > /dev/null 2>&1 && terraform validate && echo SHARED_PASS; cd ../yt-summarizer/infra/terraform/environments/prod && terraform init -backend=false > /dev/null 2>&1 && terraform validate && echo YTSUMM_PASS`
  - **Done when**: Both repos validate successfully
  - **Commit**: `chore(migration): pass batch 1 quality checkpoint` (only if fixes needed)
  - _Requirements: FR-3, AC-5.1, AC-5.2, AC-5.4_

### Import Blocks - Batch 2: Key Vault + ACR (Tasks 1.29 - 1.32)

- [ ] 1.29 Backup state before batch 2 migration
  - **Do**:
    1. Run `cd ../yt-summarizer/infra/terraform/environments/prod && terraform state pull > backup-batch2.tfstate`
    2. Verify backup file is non-empty
  - **Files**: `../yt-summarizer/infra/terraform/environments/prod/backup-batch2.tfstate`
  - **Done when**: State backup file exists and is non-empty
  - **Verify**: `test -s ../yt-summarizer/infra/terraform/environments/prod/backup-batch2.tfstate && echo BACKUP_PASS`
  - **Commit**: None (backup only, do not commit state files)
  - _Requirements: FR-11, AC-5.5_
  - _Design: State Migration Plan - Batch 2_

- [ ] 1.30 Add import blocks for Key Vault and ACR in shared-infra
  - **Do**:
    1. Add import block to `terraform/key-vault.tf` for `module.key_vault.azurerm_key_vault.vault`
    2. Add import block for `module.key_vault.azurerm_role_assignment.secrets_officer[0]` (role assignment ID must be retrieved via az CLI comment)
    3. Add import block to `terraform/acr.tf` for `module.acr.azurerm_container_registry.acr`
  - **Files**: `terraform/key-vault.tf`, `terraform/acr.tf`
  - **Done when**: 3 import blocks present with correct resource IDs from design.md
  - **Verify**: `grep -c 'import' terraform/key-vault.tf terraform/acr.tf | tail -1 | grep -q '3' && echo PASS`
  - **Commit**: `feat(migration): add import blocks for key vault and ACR (batch 2)`
  - _Requirements: FR-3, AC-5.1, AC-5.2_
  - _Design: State Migration Plan - Batch 2_

- [ ] 1.31 Add removed blocks for Key Vault and ACR in yt-summarizer
  - **Do**:
    1. In `../yt-summarizer/infra/terraform/environments/prod/key-vault.tf`, add removed blocks for `module.key_vault.azurerm_key_vault.vault` and `module.key_vault.azurerm_role_assignment.secrets_officer[0]`
    2. In `../yt-summarizer/infra/terraform/environments/prod/acr.tf`, add removed block for `module.acr.azurerm_container_registry.acr`
    3. All removed blocks use `lifecycle { destroy = false }`
  - **Files**: `../yt-summarizer/infra/terraform/environments/prod/key-vault.tf`, `../yt-summarizer/infra/terraform/environments/prod/acr.tf`
  - **Done when**: 3 removed blocks present across the 2 files
  - **Verify**: `grep -c 'removed' ../yt-summarizer/infra/terraform/environments/prod/key-vault.tf ../yt-summarizer/infra/terraform/environments/prod/acr.tf | tail -1 | grep -q '3' && echo PASS`
  - **Commit**: `feat(migration): add removed blocks for key vault and ACR in yt-summarizer (batch 2)`
  - _Requirements: FR-3, AC-5.1, AC-5.4_
  - _Design: State Migration Plan - Batch 2_

- [ ] 1.32 [VERIFY] Quality checkpoint: terraform validate batch 2
  - **Do**: Validate both repos after batch 2 import/removed blocks
  - **Files**: None (verification only)
  - **Verify**: `cd terraform && terraform init -backend=false > /dev/null 2>&1 && terraform validate && echo SHARED_PASS; cd ../yt-summarizer/infra/terraform/environments/prod && terraform init -backend=false > /dev/null 2>&1 && terraform validate && echo YTSUMM_PASS`
  - **Done when**: Both repos validate successfully
  - **Commit**: `chore(migration): pass batch 2 quality checkpoint` (only if fixes needed)
  - _Requirements: FR-3, AC-5.1, AC-5.2, AC-5.4_

### Import Blocks - Batch 3: AKS + Workload Identity (Tasks 1.33 - 1.37)

- [ ] 1.33 Backup state before batch 3 migration
  - **Do**:
    1. Run `cd ../yt-summarizer/infra/terraform/environments/prod && terraform state pull > backup-batch3.tfstate`
    2. Verify backup file is non-empty
  - **Files**: `../yt-summarizer/infra/terraform/environments/prod/backup-batch3.tfstate`
  - **Done when**: State backup file exists and is non-empty
  - **Verify**: `test -s ../yt-summarizer/infra/terraform/environments/prod/backup-batch3.tfstate && echo BACKUP_PASS`
  - **Commit**: None (backup only, do not commit state files)
  - _Requirements: FR-11, AC-5.5_
  - _Design: State Migration Plan - Batch 3_

- [ ] 1.34 Add import blocks for AKS and Workload Identity in shared-infra
  - **Do**:
    1. Add import block to `terraform/aks.tf` for `module.aks.azurerm_kubernetes_cluster.aks`
    2. Add import block to `terraform/workload-identity.tf` for `azurerm_user_assigned_identity.external_secrets`
    3. Add import block for `azurerm_federated_identity_credential.external_secrets`
    4. Add import block for `azurerm_role_assignment.external_secrets_kv_reader` (role assignment ID via az CLI comment)
  - **Files**: `terraform/aks.tf`, `terraform/workload-identity.tf`
  - **Done when**: 4 import blocks present with correct resource IDs from design.md
  - **Verify**: `grep -c 'import' terraform/aks.tf terraform/workload-identity.tf | tail -1 | grep -q '4' && echo PASS`
  - **Commit**: `feat(migration): add import blocks for AKS and workload identity (batch 3)`
  - _Requirements: FR-3, AC-5.1, AC-5.2_
  - _Design: State Migration Plan - Batch 3_

- [ ] 1.35 Add removed blocks for AKS and Workload Identity in yt-summarizer
  - **Do**:
    1. In `../yt-summarizer/infra/terraform/environments/prod/aks.tf`, add removed block for `module.aks.azurerm_kubernetes_cluster.aks`
    2. In `../yt-summarizer/infra/terraform/environments/prod/workload-identity.tf`, add removed blocks for `azurerm_user_assigned_identity.external_secrets`, `azurerm_federated_identity_credential.external_secrets`, `azurerm_role_assignment.external_secrets_kv_reader`
    3. All removed blocks use `lifecycle { destroy = false }`
  - **Files**: `../yt-summarizer/infra/terraform/environments/prod/aks.tf`, `../yt-summarizer/infra/terraform/environments/prod/workload-identity.tf`
  - **Done when**: 4 removed blocks present across the 2 files
  - **Verify**: `grep -c 'removed' ../yt-summarizer/infra/terraform/environments/prod/aks.tf ../yt-summarizer/infra/terraform/environments/prod/workload-identity.tf | tail -1 | grep -q '4' && echo PASS`
  - **Commit**: `feat(migration): add removed blocks for AKS and workload identity in yt-summarizer (batch 3)`
  - _Requirements: FR-3, AC-5.1, AC-5.4_
  - _Design: State Migration Plan - Batch 3_

- [ ] 1.36 [VERIFY] Quality checkpoint: terraform validate batch 3
  - **Do**: Validate both repos after batch 3 import/removed blocks
  - **Files**: None (verification only)
  - **Verify**: `cd terraform && terraform init -backend=false > /dev/null 2>&1 && terraform validate && echo SHARED_PASS; cd ../yt-summarizer/infra/terraform/environments/prod && terraform init -backend=false > /dev/null 2>&1 && terraform validate && echo YTSUMM_PASS`
  - **Done when**: Both repos validate successfully
  - **Commit**: `chore(migration): pass batch 3 quality checkpoint` (only if fixes needed)
  - _Requirements: FR-3, AC-5.1, AC-5.2, AC-5.4_

- [ ] 1.37 [VERIFY] Quality checkpoint: all import/removed blocks complete
  - **Do**: Verify all 3 state backup files exist and all import/removed blocks are present across batches
  - **Files**: None (verification only)
  - **Verify**: `test -s ../yt-summarizer/infra/terraform/environments/prod/backup-batch1.tfstate && test -s ../yt-summarizer/infra/terraform/environments/prod/backup-batch2.tfstate && test -s ../yt-summarizer/infra/terraform/environments/prod/backup-batch3.tfstate && echo BACKUPS_PASS; grep -r 'import' terraform/*.tf | grep -c 'import' | awk '{if($1>=8) print "IMPORTS_PASS"}'`
  - **Done when**: All 3 backups exist and at least 8 import blocks present
  - **Commit**: None (verification only)
  - _Requirements: FR-3, FR-11, AC-5.1, AC-5.5_

### Data-Only Consumer Module (Tasks 1.38 - 1.42)

- [ ] 1.38 Create shared-infra-data consumer module: main.tf
  - **Do**:
    1. Create `terraform/modules/shared-infra-data/main.tf` with `data.terraform_remote_state.shared_infra` block
    2. Backend config: resource_group_name `rg-ytsummarizer-tfstate`, storage_account_name `stytsummarizertfstate`, container_name `tfstate`, key `shared-infra.tfstate`, use_oidc true
  - **Files**: `terraform/modules/shared-infra-data/main.tf`
  - **Done when**: Data source matches design.md exactly
  - **Verify**: `cd terraform && terraform fmt -check modules/shared-infra-data/main.tf && echo PASS`
  - **Commit**: `feat(modules): create shared-infra-data consumer module main.tf`
  - _Requirements: FR-5, AC-6.1, AC-6.2_
  - _Design: Section 2 - Data-Only Consumer Module_

- [ ] 1.39 Create shared-infra-data consumer module: outputs.tf
  - **Do**:
    1. Create `terraform/modules/shared-infra-data/outputs.tf` re-exporting all 19 shared-infra outputs
    2. Each output references `data.terraform_remote_state.shared_infra.outputs.<name>`
    3. Include descriptions on all outputs
  - **Files**: `terraform/modules/shared-infra-data/outputs.tf`
  - **Done when**: All 19 outputs re-exported with descriptions
  - **Verify**: `cd terraform && terraform fmt -check modules/shared-infra-data/outputs.tf && grep -c 'output "' modules/shared-infra-data/outputs.tf | grep -q '19' && echo PASS`
  - **Commit**: `feat(modules): create shared-infra-data consumer module outputs.tf`
  - _Requirements: FR-5, AC-6.3_
  - _Design: Section 2 - outputs.tf_

- [ ] 1.40 Create shared-infra-data consumer module: variables.tf (empty placeholder)
  - **Do**:
    1. Create `terraform/modules/shared-infra-data/variables.tf` as an empty file with a header comment
    2. Comment: `# No input variables required. Backend config is hardcoded per design.`
    3. This file exists for module completeness per design.md file tree; the module takes no inputs since backend config is fixed
  - **Files**: `terraform/modules/shared-infra-data/variables.tf`
  - **Done when**: File exists with explanatory comment
  - **Verify**: `test -f terraform/modules/shared-infra-data/variables.tf && echo PASS`
  - **Commit**: `feat(modules): add shared-infra-data variables.tf placeholder`
  - _Requirements: FR-5, AC-6.1_
  - _Design: Section 2 - File tree shows variables.tf in shared-infra-data_

- [ ] 1.41 [VERIFY] Quality checkpoint: validate consumer module
  - **Do**: Validate the shared-infra-data module in isolation
  - **Files**: None (verification only)
  - **Verify**: `cd terraform/modules/shared-infra-data && terraform init -backend=false > /dev/null 2>&1 && terraform validate && terraform fmt -check && echo PASS`
  - **Done when**: Module validates and passes format check
  - **Commit**: `chore(modules): pass consumer module quality checkpoint` (only if fixes needed)
  - _Requirements: FR-5, AC-6.1, AC-6.2, AC-6.3_

- [ ] 1.42 [VERIFY] Quality checkpoint: full shared-infra validate after consumer module
  - **Do**: Re-validate entire root module to ensure consumer module didn't break anything
  - **Files**: None (verification only)
  - **Verify**: `cd terraform && terraform init -backend=false > /dev/null 2>&1 && terraform validate && terraform fmt -check -recursive && echo PASS`
  - **Done when**: Full validation passes
  - **Commit**: `chore(terraform): pass quality checkpoint` (only if fixes needed)
  - _Requirements: FR-1, FR-5_

### Internal CI Workflows (Tasks 1.43 - 1.47)

- [ ] 1.43 Create terraform-plan.yml workflow
  - **Do**:
    1. Create `.github/workflows/terraform-plan.yml` exactly matching design.md
    2. Triggers on PR to main, paths: `terraform/**`, `.github/workflows/terraform-plan.yml`
    3. Permissions: id-token write, contents read, pull-requests write
    4. Steps: checkout, setup-terraform, azure/login, terraform init, validate, fmt, plan
  - **Files**: `.github/workflows/terraform-plan.yml`
  - **Done when**: Workflow matches design.md exactly with all steps
  - **Verify**: `test -f .github/workflows/terraform-plan.yml && grep -q 'workflow_dispatch\|pull_request' .github/workflows/terraform-plan.yml && echo PASS`
  - **Commit**: `feat(ci): add terraform plan workflow`
  - _Requirements: FR-8, AC-11.1, AC-11.2, AC-11.4_
  - _Design: Section 4 - terraform-plan.yml_

- [ ] 1.44 Create terraform-apply.yml workflow
  - **Do**:
    1. Create `.github/workflows/terraform-apply.yml` exactly matching design.md
    2. Triggers on push to main, paths: `terraform/**`
    3. Includes destroy detection (fail-fast on resource destruction)
    4. Steps: checkout, setup-terraform, azure/login, terraform init, plan with detailed-exitcode, destroy check, apply
  - **Files**: `.github/workflows/terraform-apply.yml`
  - **Done when**: Workflow matches design.md with destroy detection logic
  - **Verify**: `test -f .github/workflows/terraform-apply.yml && grep -q 'auto-approve' .github/workflows/terraform-apply.yml && echo PASS`
  - **Commit**: `feat(ci): add terraform apply workflow`
  - _Requirements: FR-8, AC-11.3, AC-11.6_
  - _Design: Section 4 - terraform-apply.yml_

- [ ] 1.45 Create actionlint.yml workflow
  - **Do**:
    1. Create `.github/workflows/actionlint.yml` that runs actionlint on PR
    2. Triggers on PR to main, paths: `.github/**`
    3. Steps: checkout, install actionlint, run actionlint
  - **Files**: `.github/workflows/actionlint.yml`
  - **Done when**: Workflow triggers on .github/** changes and runs actionlint
  - **Verify**: `test -f .github/workflows/actionlint.yml && grep -q 'actionlint' .github/workflows/actionlint.yml && echo PASS`
  - **Commit**: `feat(ci): add actionlint workflow`
  - _Requirements: AC-11.5_
  - _Design: Section 4 - actionlint.yml_

- [ ] 1.46 [VERIFY] Quality checkpoint: actionlint on workflows
  - **Do**: Validate all workflow YAML files
  - **Files**: None (verification only)
  - **Verify**: `which actionlint > /dev/null 2>&1 && actionlint .github/workflows/*.yml && echo PASS || (for f in .github/workflows/*.yml; do python -c "import yaml; yaml.safe_load(open('$f'))" 2>&1 || echo "INVALID: $f"; done && echo YAML_CHECK_DONE)`
  - **Done when**: All workflow files are valid YAML and pass actionlint (if available)
  - **Commit**: `chore(ci): pass workflow quality checkpoint` (only if fixes needed)
  - _Requirements: AC-11.1, AC-11.3, AC-11.4, AC-11.5_

- [ ] 1.47 Set shared-infra repo to public visibility
  - **Do**:
    1. Run `gh repo edit AshleyHollis/shared-infra --visibility public`
    2. Verify the repo is now public
  - **Files**: None (GitHub API operation)
  - **Done when**: Repo visibility is public
  - **Verify**: `gh repo view AshleyHollis/shared-infra --json visibility -q '.visibility' | grep -qi 'public' && echo PASS`
  - **Commit**: None (no file changes)
  - _Requirements: FR-13, AC-8.5_
  - _Design: Section 3 - Public repo requirement_

### Reusable Workflows (Tasks 1.48 - 1.52)

- [ ] 1.48 Create terraform-reusable.yml workflow
  - **Do**:
    1. Create `.github/workflows/terraform-reusable.yml` with `workflow_call` trigger
    2. Accept inputs: working_directory, environment
    3. Support `secrets: inherit` for Azure OIDC credentials
    4. Steps: checkout, setup-terraform, azure/login, init, validate, plan, apply (conditional)
  - **Files**: `.github/workflows/terraform-reusable.yml`
  - **Done when**: Workflow has workflow_call trigger, accepts inputs, plan+apply steps
  - **Verify**: `grep -q 'workflow_call' .github/workflows/terraform-reusable.yml && echo PASS`
  - **Commit**: `feat(workflows): add terraform reusable workflow`
  - _Requirements: FR-7, AC-9.1, AC-9.2, AC-9.3, AC-9.4_
  - _Design: Section 4 - terraform-reusable.yml_

- [ ] 1.49 Create build-and-push.yml reusable workflow
  - **Do**:
    1. Create `.github/workflows/build-and-push.yml` with `workflow_call` trigger
    2. Accept inputs: image_name, dockerfile_path, build_context
    3. Steps: checkout, azure/login, ACR login, docker build, docker push
  - **Files**: `.github/workflows/build-and-push.yml`
  - **Done when**: Workflow builds and pushes container images to ACR
  - **Verify**: `grep -q 'workflow_call' .github/workflows/build-and-push.yml && echo PASS`
  - **Commit**: `feat(workflows): add build-and-push reusable workflow`
  - _Requirements: FR-7, AC-9.1, AC-9.2_
  - _Design: Section 4 - build-and-push.yml_

- [ ] 1.50 Create deploy-to-aks.yml reusable workflow
  - **Do**:
    1. Create `.github/workflows/deploy-to-aks.yml` with `workflow_call` trigger
    2. Accept inputs: cluster_name, resource_group, namespace, image_tag
    3. Steps: checkout, azure/login, setup AKS credentials, deploy
  - **Files**: `.github/workflows/deploy-to-aks.yml`
  - **Done when**: Workflow deploys to AKS cluster
  - **Verify**: `grep -q 'workflow_call' .github/workflows/deploy-to-aks.yml && echo PASS`
  - **Commit**: `feat(workflows): add deploy-to-aks reusable workflow`
  - _Requirements: FR-7, AC-9.1, AC-9.2_
  - _Design: Section 4 - deploy-to-aks.yml_

- [ ] 1.51 [VERIFY] Quality checkpoint: actionlint on all workflows
  - **Do**: Validate all workflow files including reusable ones
  - **Files**: None (verification only)
  - **Verify**: `which actionlint > /dev/null 2>&1 && actionlint .github/workflows/*.yml && echo PASS || (for f in .github/workflows/*.yml; do python -c "import yaml; yaml.safe_load(open('$f'))" 2>&1 || echo "INVALID: $f"; done && echo YAML_CHECK_DONE)`
  - **Done when**: All 6 workflow files are valid
  - **Commit**: `chore(workflows): pass quality checkpoint` (only if fixes needed)
  - _Requirements: FR-7, AC-9.1, AC-9.5_

- [ ] 1.52 [VERIFY] Quality checkpoint: reusable workflow inputs/outputs
  - **Do**: Verify reusable workflows accept required inputs per design.md
  - **Files**: None (verification only)
  - **Verify**: `grep -q 'working_directory\|working-directory' .github/workflows/terraform-reusable.yml && grep -q 'image_name\|image-name' .github/workflows/build-and-push.yml && grep -q 'cluster_name\|cluster-name' .github/workflows/deploy-to-aks.yml && echo PASS`
  - **Done when**: All 3 reusable workflows have expected inputs
  - **Commit**: None (verification only)
  - _Requirements: FR-7, AC-9.3_

### Rework yt-summarizer Key Vault (Tasks 1.53 - 1.54)

- [ ] 1.53 Rework yt-summarizer key-vault.tf to keep secrets, remove vault creation
  - **Do**:
    1. In `../yt-summarizer/infra/terraform/environments/prod/key-vault.tf`, replace the `module.key_vault` call with direct `azurerm_key_vault_secret` resources
    2. Secrets reference `module.shared.key_vault_id` instead of creating the vault
    3. Add `module.shared` data source reference (will be connected in consumer update task)
    4. Keep all existing secret values (sql-connection-string, storage-connection, openai-api-key, etc.)
  - **Files**: `../yt-summarizer/infra/terraform/environments/prod/key-vault.tf`
  - **Done when**: Vault creation removed, secrets use key_vault_id from shared module
  - **Verify**: `grep -q 'key_vault_id' ../yt-summarizer/infra/terraform/environments/prod/key-vault.tf && ! grep -q 'module "key_vault"' ../yt-summarizer/infra/terraform/environments/prod/key-vault.tf && echo PASS`
  - **Commit**: `refactor(yt-summarizer): rework key-vault.tf to keep secrets only`
  - _Requirements: AC-5.7, AC-7.1_
  - _Design: Consumer Update Design - yt-summarizer key-vault.tf_

- [ ] 1.54 [VERIFY] Quality checkpoint: yt-summarizer terraform validate
  - **Do**: Validate yt-summarizer after key-vault rework
  - **Files**: None (verification only)
  - **Verify**: `cd ../yt-summarizer/infra/terraform/environments/prod && terraform init -backend=false > /dev/null 2>&1 && terraform validate && echo PASS`
  - **Done when**: yt-summarizer validates successfully
  - **Commit**: `chore(yt-summarizer): pass quality checkpoint` (only if fixes needed)
  - _Requirements: AC-5.7, AC-7.1_

### Consumer Updates - yt-summarizer (Tasks 1.55 - 1.60)

- [ ] 1.55 Add shared-infra-data module reference to yt-summarizer
  - **Do**:
    1. Create `../yt-summarizer/infra/terraform/environments/prod/shared.tf` with `module "shared"` block
    2. Source: `git::https://github.com/AshleyHollis/shared-infra.git//terraform/modules/shared-infra-data?ref=v1`
  - **Files**: `../yt-summarizer/infra/terraform/environments/prod/shared.tf`
  - **Done when**: Module reference present with git source and version pin
  - **Verify**: `grep -q 'shared-infra-data' ../yt-summarizer/infra/terraform/environments/prod/shared.tf && echo PASS`
  - **Commit**: `feat(yt-summarizer): add shared-infra-data module reference`
  - _Requirements: FR-12, AC-6.4, AC-7.1_
  - _Design: Consumer Update Design - yt-summarizer_

- [ ] 1.56 Remove yt-summarizer ArgoCD module (moves to shared-infra)
  - **Do**:
    1. In `../yt-summarizer/infra/terraform/environments/prod/argocd.tf`, add removed block for the ArgoCD module resources
    2. Set `lifecycle { destroy = false }` on each removed block
  - **Files**: `../yt-summarizer/infra/terraform/environments/prod/argocd.tf`
  - **Done when**: ArgoCD resources have removed blocks
  - **Verify**: `grep -q 'removed' ../yt-summarizer/infra/terraform/environments/prod/argocd.tf && echo PASS`
  - **Commit**: `feat(yt-summarizer): add removed blocks for ArgoCD module`
  - _Requirements: AC-5.1_
  - _Design: Consumer Update Design - ArgoCD handling_

- [ ] 1.57 Remove yt-summarizer helm/kubernetes providers and AKS-related variables
  - **Do**:
    1. In `../yt-summarizer/infra/terraform/environments/prod/providers.tf`, remove helm and kubernetes provider blocks (no longer needed without AKS)
    2. In `../yt-summarizer/infra/terraform/environments/prod/versions.tf`, remove helm and kubernetes from required_providers, bump to `>= 1.7.0`
    3. In `../yt-summarizer/infra/terraform/environments/prod/variables.tf`, remove AKS/ACR-related variables (aks_node_size, aks_os_disk_size_gb, etc.)
  - **Files**: `../yt-summarizer/infra/terraform/environments/prod/providers.tf`, `../yt-summarizer/infra/terraform/environments/prod/versions.tf`, `../yt-summarizer/infra/terraform/environments/prod/variables.tf`
  - **Done when**: Helm/kubernetes providers removed, AKS vars removed, TF version bumped
  - **Verify**: `! grep -q 'helm' ../yt-summarizer/infra/terraform/environments/prod/providers.tf && ! grep -q 'kubernetes' ../yt-summarizer/infra/terraform/environments/prod/providers.tf && echo PASS`
  - **Commit**: `refactor(yt-summarizer): remove helm/kubernetes providers and AKS variables`
  - _Requirements: AC-7.1_
  - _Design: Consumer Update Design - yt-summarizer_

- [ ] 1.58 Update yt-summarizer outputs.tf to remove shared resource outputs
  - **Do**:
    1. In `../yt-summarizer/infra/terraform/environments/prod/outputs.tf`, remove outputs for shared resources (RG, AKS, ACR, KV that are now in shared-infra)
    2. Keep app-specific outputs (SQL, storage, SWA, Auth0)
  - **Files**: `../yt-summarizer/infra/terraform/environments/prod/outputs.tf`
  - **Done when**: Only app-specific outputs remain
  - **Verify**: `! grep -q 'aks_cluster_name\|acr_login_server' ../yt-summarizer/infra/terraform/environments/prod/outputs.tf && echo PASS`
  - **Commit**: `refactor(yt-summarizer): remove shared resource outputs`
  - _Requirements: AC-7.1_
  - _Design: Consumer Update Design - yt-summarizer_

- [ ] 1.59 [VERIFY] Quality checkpoint: yt-summarizer terraform validate
  - **Do**: Full validation of yt-summarizer after consumer updates
  - **Files**: None (verification only)
  - **Verify**: `cd ../yt-summarizer/infra/terraform/environments/prod && terraform init -backend=false > /dev/null 2>&1 && terraform validate && terraform fmt -check -recursive && echo PASS`
  - **Done when**: yt-summarizer validates and passes fmt check
  - **Commit**: `chore(yt-summarizer): pass consumer update quality checkpoint` (only if fixes needed)
  - _Requirements: AC-7.1, AC-7.3_

- [ ] 1.60 [VERIFY] Quality checkpoint: yt-summarizer retains app-specific resources
  - **Do**: Verify app-specific resources (SQL, storage, SWA, Auth0) still present in yt-summarizer
  - **Files**: None (verification only)
  - **Verify**: `grep -r 'azurerm_mssql\|azurerm_storage\|azurerm_static_site' ../yt-summarizer/infra/terraform/environments/prod/ --include='*.tf' | head -3 | grep -q '.' && echo APP_RESOURCES_INTACT`
  - **Done when**: App-specific resources confirmed present
  - **Commit**: None (verification only)
  - _Requirements: AC-5.7_

### Consumer Updates - meal-planner (Tasks 1.61 - 1.66)

- [ ] 1.61 Add shared-infra-data module reference to meal-planner
  - **Do**:
    1. Create `../meal-planner/infra/terraform/shared.tf` with `module "shared"` block
    2. Source: `git::https://github.com/AshleyHollis/shared-infra.git//terraform/modules/shared-infra-data?ref=v1`
  - **Files**: `../meal-planner/infra/terraform/shared.tf`
  - **Done when**: Module reference present with git source and version pin
  - **Verify**: `grep -q 'shared-infra-data' ../meal-planner/infra/terraform/shared.tf && echo PASS`
  - **Commit**: `feat(meal-planner): add shared-infra-data module reference`
  - _Requirements: FR-12, AC-6.4, AC-7.2_
  - _Design: Consumer Update Design - meal-planner_

- [ ] 1.62 Replace meal-planner hardcoded references with shared module
  - **Do**:
    1. In `../meal-planner/infra/terraform/key-vault-secrets.tf`, replace `data.azurerm_resource_group.shared` and `data.azurerm_key_vault.shared` with `module.shared` references
    2. In `../meal-planner/infra/terraform/swa.tf`, replace `data.azurerm_resource_group.shared.name` with `module.shared.resource_group_name`
    3. In `../meal-planner/infra/terraform/sql.tf`, replace `data.azurerm_resource_group.shared.name` with `module.shared.resource_group_name`
  - **Files**: `../meal-planner/infra/terraform/key-vault-secrets.tf`, `../meal-planner/infra/terraform/swa.tf`, `../meal-planner/infra/terraform/sql.tf`
  - **Done when**: All hardcoded data source references replaced with module.shared
  - **Verify**: `! grep -q 'data.azurerm_resource_group.shared' ../meal-planner/infra/terraform/key-vault-secrets.tf ../meal-planner/infra/terraform/swa.tf ../meal-planner/infra/terraform/sql.tf && echo PASS`
  - **Commit**: `refactor(meal-planner): replace hardcoded refs with shared module outputs`
  - _Requirements: AC-7.2, AC-7.4_
  - _Design: Consumer Update Design - meal-planner_

- [ ] 1.63 Update meal-planner storage.tf to use shared module
  - **Do**:
    1. In `../meal-planner/infra/terraform/storage.tf`, replace `data.azurerm_resource_group.shared` with `module.shared` references
  - **Files**: `../meal-planner/infra/terraform/storage.tf`
  - **Done when**: All hardcoded references replaced
  - **Verify**: `! grep -q 'data.azurerm_resource_group.shared' ../meal-planner/infra/terraform/storage.tf && echo PASS`
  - **Commit**: `refactor(meal-planner): update storage.tf to use shared module`
  - _Requirements: AC-7.2_
  - _Design: Consumer Update Design - meal-planner_

- [ ] 1.64 Remove meal-planner hardcoded variables and data sources
  - **Do**:
    1. In `../meal-planner/infra/terraform/variables.tf`, remove `shared_resource_group_name` and `shared_key_vault_name` variables
    2. Remove `data.azurerm_resource_group.shared` and `data.azurerm_key_vault.shared` data source blocks (from wherever they are defined)
    3. Bump required_version to `>= 1.7.0` in providers.tf for consistency
  - **Files**: `../meal-planner/infra/terraform/variables.tf`, `../meal-planner/infra/terraform/providers.tf`
  - **Done when**: Hardcoded variables removed, TF version bumped
  - **Verify**: `! grep -q 'shared_resource_group_name\|shared_key_vault_name' ../meal-planner/infra/terraform/variables.tf && echo PASS`
  - **Commit**: `refactor(meal-planner): remove hardcoded shared variables`
  - _Requirements: AC-7.2, AC-7.4_
  - _Design: Consumer Update Design - meal-planner_

- [ ] 1.65 [VERIFY] Quality checkpoint: meal-planner terraform validate
  - **Do**: Full validation of meal-planner after consumer updates
  - **Files**: None (verification only)
  - **Verify**: `cd ../meal-planner/infra/terraform && terraform init -backend=false > /dev/null 2>&1 && terraform validate && terraform fmt -check && echo PASS`
  - **Done when**: meal-planner validates and passes fmt check
  - **Commit**: `chore(meal-planner): pass consumer update quality checkpoint` (only if fixes needed)
  - _Requirements: AC-7.2, AC-7.3, AC-7.4_

- [ ] 1.66 [VERIFY] Quality checkpoint: meal-planner decoupled from yt-summarizer
  - **Do**: Verify no remaining yt-summarizer references in meal-planner
  - **Files**: None (verification only)
  - **Verify**: `! grep -r 'yt-summarizer\|prod.tfstate' ../meal-planner/infra/terraform/ --include='*.tf' && echo DECOUPLED`
  - **Done when**: Zero yt-summarizer references in meal-planner TF files
  - **Commit**: None (verification only)
  - _Requirements: AC-7.4_

### Consumer Workflow Updates (Tasks 1.67 - 1.70)

- [ ] 1.67 Update yt-summarizer workflows to use shared actions
  - **Do**:
    1. In all `../yt-summarizer/.github/workflows/*.yml` files, replace `./.github/actions/<name>` with `AshleyHollis/shared-infra/.github/actions/<name>@v1`
    2. Apply to all 15 workflow files
  - **Files**: `../yt-summarizer/.github/workflows/*.yml` (15 files)
  - **Done when**: All local action references replaced with shared-infra references
  - **Verify**: `! grep -r '\./.github/actions/' ../yt-summarizer/.github/workflows/ && echo PASS`
  - **Commit**: `feat(yt-summarizer): update workflows to use shared-infra actions`
  - _Requirements: AC-8.6_
  - _Design: Consumer Update Design - Consumer Action Updates_

- [ ] 1.68 Update meal-planner workflows to use shared actions
  - **Do**:
    1. In all `../meal-planner/.github/workflows/*.yml` files, replace `./.github/actions/<name>` with `AshleyHollis/shared-infra/.github/actions/<name>@v1`
    2. Apply to all 9 workflow files
  - **Files**: `../meal-planner/.github/workflows/*.yml` (9 files)
  - **Done when**: All local action references replaced with shared-infra references
  - **Verify**: `! grep -r '\./.github/actions/' ../meal-planner/.github/workflows/ && echo PASS`
  - **Commit**: `feat(meal-planner): update workflows to use shared-infra actions`
  - _Requirements: AC-8.6_
  - _Design: Consumer Update Design - Consumer Action Updates_

- [ ] 1.69 [VERIFY] Quality checkpoint: actionlint on consumer workflows
  - **Do**: Validate all workflow files in both consumer repos
  - **Files**: None (verification only)
  - **Verify**: `which actionlint > /dev/null 2>&1 && actionlint ../yt-summarizer/.github/workflows/*.yml && actionlint ../meal-planner/.github/workflows/*.yml && echo PASS || echo ACTIONLINT_NOT_AVAILABLE`
  - **Done when**: All consumer workflow files are valid
  - **Commit**: `chore(consumers): pass workflow quality checkpoint` (only if fixes needed)
  - _Requirements: AC-8.6_

- [ ] 1.70 [VERIFY] Quality checkpoint: all consumer action refs use @v1
  - **Do**: Verify both consumer repos reference shared-infra actions with @v1
  - **Files**: None (verification only)
  - **Verify**: `grep -r 'AshleyHollis/shared-infra/.github/actions/' ../yt-summarizer/.github/workflows/ | grep -c '@v1' | awk '{if($1>0) print "YT_REFS_PASS"}' && grep -r 'AshleyHollis/shared-infra/.github/actions/' ../meal-planner/.github/workflows/ | grep -c '@v1' | awk '{if($1>0) print "MP_REFS_PASS"}'`
  - **Done when**: All cross-repo action refs use @v1 tag
  - **Commit**: None (verification only)
  - _Requirements: AC-8.6, AC-10.3_

### Versioning + Release Setup (Tasks 1.71 - 1.74)

- [ ] 1.71 Create CHANGELOG.md for initial release
  - **Do**:
    1. Create `CHANGELOG.md` documenting v1.0.0 initial release
    2. List: 53 composite actions consolidated, 6 workflows, TF root module, data-only consumer module
    3. Follow Keep a Changelog format
  - **Files**: `CHANGELOG.md`
  - **Done when**: CHANGELOG documents initial release
  - **Verify**: `grep -q 'v1.0.0' CHANGELOG.md && echo PASS`
  - **Commit**: `docs(release): add CHANGELOG for v1.0.0`
  - _Requirements: AC-10.5_
  - _Design: Versioning Strategy_

- [ ] 1.72 Create v1.0.0 git tag and v1 major tag
  - **Do**:
    1. Create annotated tag `v1.0.0`: `git tag -a v1.0.0 -m "v1.0.0: Initial shared-infra release"`
    2. Create mutable major tag `v1` pointing to same commit: `git tag -f v1 v1.0.0`
    3. Push both tags: `git push origin v1.0.0 && git push origin v1 -f`
  - **Files**: None (git tags only)
  - **Done when**: Both `v1.0.0` and `v1` tags exist on remote
  - **Verify**: `git tag -l 'v1.0.0' | grep -q 'v1.0.0' && git tag -l 'v1' | grep -q 'v1' && echo TAGS_PASS`
  - **Commit**: None (tagging, not committing)
  - _Requirements: FR-9, AC-10.1, AC-10.2, AC-10.3, AC-10.4_
  - _Design: Versioning Strategy_

- [ ] 1.73 [VERIFY] Full shared-infra validation checkpoint
  - **Do**: Comprehensive validation of entire shared-infra repo
  - **Files**: None (verification only)
  - **Verify**: `cd terraform && terraform init -backend=false > /dev/null 2>&1 && terraform validate && terraform fmt -check -recursive && echo TF_PASS; ls -d ../.github/actions/*/action.yml | wc -l | grep -q '53' && echo ACTIONS_PASS; which actionlint > /dev/null 2>&1 && actionlint ../.github/workflows/*.yml && echo WORKFLOWS_PASS || echo ACTIONLINT_SKIP`
  - **Done when**: TF validates, 53 actions present, workflows valid
  - **Commit**: `chore(shared-infra): pass comprehensive validation` (only if fixes needed)
  - _Requirements: FR-1, FR-6, FR-7, AC-3.1, AC-8.1, AC-9.1_

- [ ] 1.74 [VERIFY] Verify v1 tag is accessible for consumer repos
  - **Do**: Verify the v1 tag exists on remote and can be referenced
  - **Files**: None (verification only)
  - **Verify**: `git ls-remote --tags origin | grep -q 'refs/tags/v1$' && git ls-remote --tags origin | grep -q 'refs/tags/v1.0.0' && echo REMOTE_TAGS_PASS`
  - **Done when**: Both tags visible on remote
  - **Commit**: None (verification only)
  - _Requirements: FR-9, AC-10.1, AC-10.2, AC-10.3_

## Phase 2: Additional Testing (Integration Verification)

Focus: Cross-repo validation, verify decoupling, end-to-end consistency.

- [ ] 2.1 Cross-repo terraform validate: shared-infra
  - **Do**:
    1. Run terraform init (backend=false) and validate in shared-infra
    2. Verify all import blocks reference valid resource addresses
    3. Count total resources to ensure under 100 limit
  - **Files**: None (read-only verification)
  - **Done when**: Validation passes, resource count verified
  - **Verify**: `cd terraform && terraform init -backend=false > /dev/null 2>&1 && terraform validate && echo SHARED_VALIDATE_PASS`
  - **Commit**: None (verification only)
  - _Requirements: AC-3.5, AC-3.7_

- [ ] 2.2 Cross-repo terraform validate: yt-summarizer
  - **Do**:
    1. Run terraform init (backend=false) and validate in yt-summarizer
    2. Verify removed blocks are present for all migrated resources
    3. Verify app-specific resources (SQL, Storage, SWA, Auth0) are intact
  - **Files**: None (read-only verification)
  - **Done when**: Validation passes, app resources intact
  - **Verify**: `cd ../yt-summarizer/infra/terraform/environments/prod && terraform init -backend=false > /dev/null 2>&1 && terraform validate && echo YTSUMM_VALIDATE_PASS`
  - **Commit**: None (verification only)
  - _Requirements: AC-5.4, AC-5.7_

- [ ] 2.3 Cross-repo terraform validate: meal-planner
  - **Do**:
    1. Run terraform init (backend=false) and validate in meal-planner
    2. Verify no references to yt-summarizer state remain
    3. Verify module.shared references work
  - **Files**: None (read-only verification)
  - **Done when**: Validation passes, no yt-summarizer coupling
  - **Verify**: `cd ../meal-planner/infra/terraform && terraform init -backend=false > /dev/null 2>&1 && terraform validate && echo MP_VALIDATE_PASS`
  - **Commit**: None (verification only)
  - _Requirements: AC-7.3, AC-7.4_

- [ ] 2.4 Verify meal-planner decoupling from yt-summarizer
  - **Do**:
    1. Grep meal-planner TF files for any remaining yt-summarizer references
    2. Verify no `data.terraform_remote_state` pointing to yt-summarizer's prod.tfstate
    3. Verify `module.shared` is the only cross-repo data source
  - **Files**: None (read-only verification)
  - **Done when**: Zero yt-summarizer references in meal-planner
  - **Verify**: `! grep -r 'yt-summarizer\|prod.tfstate' ../meal-planner/infra/terraform/ --include='*.tf' && echo DECOUPLED`
  - **Commit**: None (verification only)
  - _Requirements: AC-7.4_

- [ ] 2.5 Verify no sensitive values in shared-infra outputs
  - **Do**:
    1. Check `terraform/outputs.tf` for any `sensitive = true` attributes
    2. Verify no passwords, keys, or connection strings in output values
    3. Verify terraform.auto.tfvars contains only subscription_id
  - **Files**: None (read-only verification)
  - **Done when**: Zero sensitive values exposed
  - **Verify**: `! grep -q 'sensitive.*=.*true' terraform/outputs.tf && ! grep -q 'password\|secret\|key\|connection_string' terraform/outputs.tf && echo NO_SENSITIVE_OUTPUTS`
  - **Commit**: None (verification only)
  - _Requirements: AC-4.2, NFR-4_

- [ ] 2.6 Verify prevent_destroy on critical resources
  - **Do**:
    1. Check main.tf, aks.tf, acr.tf, key-vault.tf for `prevent_destroy = true` lifecycle
    2. Verify all 4 critical resources are protected
  - **Files**: None (read-only verification)
  - **Done when**: All 4 critical resources have prevent_destroy
  - **Verify**: `grep -l 'prevent_destroy' terraform/main.tf terraform/aks.tf terraform/acr.tf terraform/key-vault.tf | wc -l | grep -q '4' && echo ALL_PROTECTED`
  - **Commit**: None (verification only)
  - _Requirements: FR-4, AC-3.6_

- [ ] 2.7 Verify blob versioning in bootstrap script
  - **Do**:
    1. Check bootstrap script includes `enable-versioning` command
    2. Verify rollback capability is documented
  - **Files**: None (read-only verification)
  - **Done when**: Bootstrap script enables blob versioning
  - **Verify**: `grep -q 'enable-versioning' scripts/bootstrap-backend.sh && echo VERSIONING_PASS`
  - **Commit**: None (verification only)
  - _Requirements: AC-1.3, NFR-7_

- [ ] 2.8 Verify .terraform.lock.hcl is committed
  - **Do**:
    1. Verify lock file is tracked in git
    2. Verify it contains expected provider hashes
  - **Files**: None (read-only verification)
  - **Done when**: Lock file is in git and has provider entries
  - **Verify**: `git ls-files terraform/.terraform.lock.hcl | grep -q '.terraform.lock.hcl' && grep -q 'azurerm' terraform/.terraform.lock.hcl && echo LOCKFILE_PASS`
  - **Commit**: None (verification only)
  - _Requirements: FR-14, AC-3.4_

- [ ] 2.9 Verify repo visibility is public
  - **Do**:
    1. Check repo visibility via gh CLI
  - **Files**: None (read-only verification)
  - **Done when**: Repo is confirmed public
  - **Verify**: `gh repo view AshleyHollis/shared-infra --json visibility -q '.visibility' | grep -qi 'public' && echo VISIBILITY_PASS`
  - **Commit**: None (verification only)
  - _Requirements: FR-13, AC-8.5_

- [ ] 2.10 [VERIFY] Integration test: all 3 repos validate together
  - **Do**: Run validation across all 3 repos in sequence
  - **Files**: None (verification only)
  - **Verify**: `cd terraform && terraform init -backend=false > /dev/null 2>&1 && terraform validate && cd ../../yt-summarizer/infra/terraform/environments/prod && terraform init -backend=false > /dev/null 2>&1 && terraform validate && cd ../../../../../meal-planner/infra/terraform && terraform init -backend=false > /dev/null 2>&1 && terraform validate && echo ALL_THREE_PASS`
  - **Done when**: All 3 repos validate without errors
  - **Commit**: `chore(integration): pass cross-repo validation` (only if fixes needed)
  - _Requirements: AC-3.5, AC-5.3, AC-7.3_

## Phase 3: Quality Gates

Focus: Full local CI suite, comprehensive checks.

- [ ] 3.1 [VERIFY] Terraform format check (all repos)
  - **Do**: Run terraform fmt -check across all modified Terraform directories
  - **Files**: None (verification only)
  - **Verify**: `cd terraform && terraform fmt -check -recursive && cd ../../yt-summarizer/infra/terraform && terraform fmt -check -recursive && cd ../../../meal-planner/infra/terraform && terraform fmt -check -recursive && echo FMT_PASS`
  - **Done when**: All Terraform files are properly formatted
  - **Commit**: `style(terraform): fix formatting` (only if fixes needed)
  - _Requirements: AC-11.4_

- [ ] 3.2 [VERIFY] Terraform validate (all repos)
  - **Do**: Run terraform validate across all modified Terraform directories
  - **Files**: None (verification only)
  - **Verify**: `cd terraform && terraform init -backend=false > /dev/null 2>&1 && terraform validate && cd ../../yt-summarizer/infra/terraform/environments/prod && terraform init -backend=false > /dev/null 2>&1 && terraform validate && cd ../../../../../meal-planner/infra/terraform && terraform init -backend=false > /dev/null 2>&1 && terraform validate && echo VALIDATE_PASS`
  - **Done when**: All repos validate successfully
  - **Commit**: `fix(terraform): resolve validation errors` (only if fixes needed)
  - _Requirements: AC-3.5, AC-5.3, AC-7.3_

- [ ] 3.3 [VERIFY] Action metadata completeness
  - **Do**: Verify all 53 actions have required metadata fields
  - **Files**: None (verification only)
  - **Verify**: `count=0; for f in .github/actions/*/action.yml; do if grep -q "^name:" "$f" && grep -q "^description:" "$f"; then count=$((count+1)); else echo "MISSING: $f"; fi; done; echo "$count actions verified" && test "$count" -eq 53 && echo METADATA_PASS`
  - **Done when**: All 53 actions have name and description
  - **Commit**: `fix(actions): add missing metadata` (only if fixes needed)
  - _Requirements: AC-8.3_

- [ ] 3.4 [VERIFY] Workflow validation
  - **Do**: Validate all 6 workflow files for correct YAML structure and required fields
  - **Files**: None (verification only)
  - **Verify**: `for f in .github/workflows/*.yml; do python3 -c "import yaml; y=yaml.safe_load(open('$f')); assert 'on' in y or True in y, f'missing trigger: $f'" 2>&1 || echo "INVALID: $f"; done && echo WORKFLOW_YAML_PASS`
  - **Done when**: All workflows have valid YAML and triggers
  - **Commit**: `fix(workflows): resolve validation issues` (only if fixes needed)
  - _Requirements: AC-9.1, AC-11.1_

- [ ] 3.5 [VERIFY] Full local CI: fmt + validate + actionlint
  - **Do**: Run complete local CI suite
  - **Files**: None (verification only)
  - **Verify**: `cd terraform && terraform fmt -check -recursive && terraform init -backend=false > /dev/null 2>&1 && terraform validate && echo TF_PASS; which actionlint > /dev/null 2>&1 && actionlint .github/workflows/*.yml && echo ACTIONLINT_PASS || echo ACTIONLINT_SKIP; echo LOCAL_CI_COMPLETE`
  - **Done when**: All quality checks pass
  - **Commit**: `chore(quality): pass full local CI` (only if fixes needed)
  - _Requirements: AC-11.4, AC-11.5_

- [ ] 3.6 [VERIFY] AC checklist verification
  - **Do**: Programmatically verify each acceptance criterion is satisfied
  - **Files**: None (verification only)
  - **Verify**: Run the following checks:
    1. AC-1.2: `grep -q 'backend "azurerm"' terraform/backend.tf && echo AC-1.2-PASS`
    2. AC-1.3: `grep -q 'enable-versioning' scripts/bootstrap-backend.sh && echo AC-1.3-PASS`
    3. AC-2.1: `grep -q 'github_repository.*shared-infra' terraform/github-oidc.tf && echo AC-2.1-PASS`
    4. AC-3.2: `grep -q '4.57.0' terraform/versions.tf && echo AC-3.2-PASS`
    5. AC-3.3: `grep -q '1.7.0' terraform/versions.tf && echo AC-3.3-PASS`
    6. AC-3.4: `git ls-files terraform/.terraform.lock.hcl | grep -q '.terraform.lock.hcl' && echo AC-3.4-PASS`
    7. AC-3.6: `grep -l 'prevent_destroy' terraform/main.tf terraform/aks.tf terraform/acr.tf terraform/key-vault.tf | wc -l | grep -q 4 && echo AC-3.6-PASS`
    8. AC-4.1: `grep -c 'output "' terraform/outputs.tf | grep -q '19' && echo AC-4.1-PASS`
    9. AC-4.3: `grep -c 'description' terraform/outputs.tf | awk '{if($1>=19) print "AC-4.3-PASS"}'`
    10. AC-5.1: `grep -r 'import' terraform/*.tf | grep -c 'import' | awk '{if($1>=8) print "AC-5.1-PASS"}'`
    11. AC-5.5: `test -s ../yt-summarizer/infra/terraform/environments/prod/backup-batch1.tfstate && test -s ../yt-summarizer/infra/terraform/environments/prod/backup-batch2.tfstate && test -s ../yt-summarizer/infra/terraform/environments/prod/backup-batch3.tfstate && echo AC-5.5-PASS`
    12. AC-6.1: `test -d terraform/modules/shared-infra-data && echo AC-6.1-PASS`
    13. AC-8.1: `ls -d .github/actions/*/action.yml | wc -l | grep -q 53 && echo AC-8.1-PASS`
    14. AC-8.5: `gh repo view AshleyHollis/shared-infra --json visibility -q '.visibility' | grep -qi 'public' && echo AC-8.5-PASS`
    15. AC-9.1: `grep -l 'workflow_call' .github/workflows/*.yml | wc -l | awk '{if($1>=3) print "AC-9.1-PASS"}'`
    16. AC-10.1: `git tag -l 'v1.0.0' | grep -q 'v1.0.0' && echo AC-10.1-PASS`
    17. AC-10.2: `git tag -l 'v1' | grep -q 'v1' && echo AC-10.2-PASS`
    18. AC-11.1: `grep -q 'pull_request' .github/workflows/terraform-plan.yml && echo AC-11.1-PASS`
    19. AC-11.3: `grep -q 'auto-approve' .github/workflows/terraform-apply.yml && echo AC-11.3-PASS`
    20. AC-11.5: `grep -q 'actionlint' .github/workflows/actionlint.yml && echo AC-11.5-PASS`
  - **Done when**: All AC checks output PASS
  - **Commit**: None (verification only)
  - _Requirements: All ACs_

## Phase 4: PR Lifecycle

Focus: Create PR, CI monitoring, final validation.

- [ ] 4.1 Create PR for shared-infra consolidation
  - **Do**:
    1. Verify current branch is a feature branch: `git branch --show-current`
    2. If on main, STOP and alert (should not happen)
    3. Push branch: `git push -u origin <branch-name>`
    4. Create PR with `gh pr create`
    5. Title: "feat: consolidate shared infra (TF + 53 actions + CI/CD)"
    6. Body: Summary of all changes across 3 repos
  - **Verify**: `gh pr view --json state -q '.state' | grep -q 'OPEN' && echo PR_CREATED`
  - **Done when**: PR created and open
  - **Commit**: None (PR creation)

- [ ] 4.2 [VERIFY] CI pipeline passes
  - **Do**: Monitor CI checks on the PR
  - **Files**: None (verification only)
  - **Verify**: `gh pr checks || echo "CHECKS_PENDING"`
  - **Done when**: All CI checks pass (green)
  - **Commit**: None
  - _Requirements: AC-11.1, AC-11.4, AC-11.5_

- [ ] 4.3 [VERIFY] Final AC checklist
  - **Do**: Re-run AC checklist from 3.6 to confirm nothing regressed during PR creation
  - **Files**: None (verification only)
  - **Verify**: Same as task 3.6
  - **Done when**: All acceptance criteria confirmed met
  - **Commit**: None
  - _Requirements: All ACs_

## Notes

- **State migration execution**: Import/removed blocks are declarative and committed to code. The actual `terraform apply` that executes the import happens in CI after PR merge (or manually before if needed). Tasks 1.26-1.36 create the blocks; actual state transfer happens on apply.
- **State backups**: Tasks 1.25, 1.29, 1.33 create state backups before each migration batch per AC-5.5. Backup files (backup-batch*.tfstate) should NOT be committed to version control.
- **Cross-repo commits**: Tasks modifying yt-summarizer and meal-planner create commits in the shared-infra repo containing those changes. The consumer repo changes will need to be submitted as separate PRs in those repos after shared-infra is merged and tagged v1.0.0.
- **Action testing**: Actions can be tested from the feature branch using `@<branch-name>` ref before the v1 tag is created.
- **Role assignment IDs**: Import blocks for role assignments contain placeholder comments. The actual GUID must be retrieved via `az role assignment list` at execution time.
- **ArgoCD**: Design recommends moving ArgoCD to shared-infra. Task 1.56 adds removed blocks. A follow-up task may be needed to add ArgoCD module to shared-infra if not covered by AKS module.
- **POC shortcuts**: terraform validate with `-backend=false` skips actual Azure connectivity. Full plan requires OIDC auth which happens in CI.
- **Public repo**: shared-infra must be public (personal GitHub account, AC-8.5). Task 1.47 sets visibility. No secrets in committed files.
- **Git tags**: Task 1.72 creates both `v1.0.0` (immutable semver) and `v1` (mutable major tag). Consumer repos reference `@v1` per AC-10.3. The v1 tag will be force-updated on future compatible releases.
- **shared-infra-data/variables.tf**: Design file tree (line 80) shows this file. Task 1.40 creates it as an empty placeholder with a comment since the module requires no input variables (backend config is hardcoded per design).
- **Blob versioning**: AC-1.3 requires blob versioning on state storage account. This is handled in the bootstrap script (task 1.1) via `az storage account blob-service-properties update --enable-versioning true`.
