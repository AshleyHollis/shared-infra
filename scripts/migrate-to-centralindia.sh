#!/usr/bin/env bash
# =============================================================================
# Migrate Shared Infrastructure from East Asia to Central India
# =============================================================================
# This script automates the full migration:
#   1. Pre-flight checks
#   2. Create resources via Azure CLI in Central India
#   3. Migrate Key Vault secrets
#   4. Remove old resources from Terraform state
#   5. Terraform apply (import new resources, create dependencies)
#   6. Get kubeconfig
#   7. Verify
#
# Usage:
#   ./scripts/migrate-to-centralindia.sh
#
# Prerequisites:
#   - Azure CLI logged in with sufficient permissions
#   - Terraform installed
#   - jq installed
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
SUBSCRIPTION_ID="28aefbe7-e2af-4b4a-9ce1-92d6672c31bd"
REGION="centralindia"
OLD_RG="rg-ytsumm-prd"
NEW_RG="rg-ytsumm-prd-ci"
OLD_KV="kv-ytsumm-prd"
NEW_KV="kv-ytsumm-prd-ci"
NEW_AKS="aks-ytsumm-prd-ci"
NEW_ACR="acrytsummprdci"
NEW_IDENTITY="id-ytsumm-prd-ci-eso"
K8S_VERSION="1.33"
NODE_VM_SIZE="Standard_B4als_v2"
NODE_COUNT=1
NODE_POOL_NAME="system2"
OS_DISK_SIZE_GB=128
SECRETS_OFFICER_PRINCIPAL_ID="eac9556a-cd81-431f-a1ec-d6940b2d92d3"
TERRAFORM_DIR="$(cd "$(dirname "$0")/../terraform" && pwd)"
SECRETS_BACKUP_FILE="$(mktemp)"

# ---------------------------------------------------------------------------
# Helper functions
# ---------------------------------------------------------------------------
info()  { echo "===> $*"; }
error() { echo "ERROR: $*" >&2; exit 1; }

cleanup() {
  if [[ -f "$SECRETS_BACKUP_FILE" ]]; then
    rm -f "$SECRETS_BACKUP_FILE"
  fi
}
trap cleanup EXIT

# =============================================================================
# Step 1: Pre-flight checks
# =============================================================================
info "Step 1: Pre-flight checks"

command -v az >/dev/null 2>&1   || error "Azure CLI (az) is not installed"
command -v terraform >/dev/null 2>&1 || error "Terraform is not installed"
command -v jq >/dev/null 2>&1   || error "jq is not installed"
command -v kubectl >/dev/null 2>&1 || error "kubectl is not installed"

az account show >/dev/null 2>&1 || error "Not logged into Azure CLI. Run: az login"

CURRENT_SUB=$(az account show --query id -o tsv)
if [[ "$CURRENT_SUB" != "$SUBSCRIPTION_ID" ]]; then
  info "Switching to subscription $SUBSCRIPTION_ID"
  az account set --subscription "$SUBSCRIPTION_ID"
fi

az keyvault show --name "$OLD_KV" --query name -o tsv >/dev/null 2>&1 \
  || error "Old Key Vault '$OLD_KV' not found. Is it accessible?"

info "Pre-flight checks passed"

# =============================================================================
# Step 2: Create resources via Azure CLI
# =============================================================================
info "Step 2: Creating resources in $REGION"

# 2a. Resource Group
info "  Creating resource group: $NEW_RG"
az group create \
  --name "$NEW_RG" \
  --location "$REGION" \
  --tags Environment=prod Project=shared-infra ManagedBy=terraform \
  --output none

# 2b. Azure Container Registry
info "  Creating ACR: $NEW_ACR"
az acr create \
  --name "$NEW_ACR" \
  --resource-group "$NEW_RG" \
  --sku Basic \
  --location "$REGION" \
  --tags Environment=prod Project=shared-infra ManagedBy=terraform \
  --output none

# 2c. Key Vault
info "  Creating Key Vault: $NEW_KV"
az keyvault create \
  --name "$NEW_KV" \
  --resource-group "$NEW_RG" \
  --location "$REGION" \
  --enable-rbac-authorization true \
  --enable-purge-protection true \
  --retention-days 7 \
  --sku standard \
  --tags Environment=prod Project=shared-infra ManagedBy=terraform \
  --output none

# 2d. AKS Cluster
info "  Creating AKS cluster: $NEW_AKS (this may take several minutes)"
az aks create \
  --name "$NEW_AKS" \
  --resource-group "$NEW_RG" \
  --location "$REGION" \
  --kubernetes-version "$K8S_VERSION" \
  --node-count "$NODE_COUNT" \
  --node-vm-size "$NODE_VM_SIZE" \
  --nodepool-name "$NODE_POOL_NAME" \
  --node-osdisk-size "$OS_DISK_SIZE_GB" \
  --network-plugin azure \
  --load-balancer-sku standard \
  --enable-oidc-issuer \
  --enable-workload-identity \
  --dns-name-prefix "ytsumm-prd-ci" \
  --tags Environment=prod Project=shared-infra ManagedBy=terraform \
  --generate-ssh-keys \
  --output none

# 2e. User Assigned Identity for External Secrets Operator
info "  Creating managed identity: $NEW_IDENTITY"
az identity create \
  --name "$NEW_IDENTITY" \
  --resource-group "$NEW_RG" \
  --location "$REGION" \
  --tags Environment=prod Project=shared-infra ManagedBy=terraform \
  --output none

info "All resources created in $REGION"

# =============================================================================
# Step 3: Migrate Key Vault secrets
# =============================================================================
info "Step 3: Migrating Key Vault secrets"

SECRET_NAMES=$(az keyvault secret list --vault-name "$OLD_KV" --query "[].name" -o tsv)

if [[ -z "$SECRET_NAMES" ]]; then
  info "  No secrets found in $OLD_KV — skipping migration"
else
  # Export secrets to temp file
  info "  Exporting secrets from $OLD_KV"
  echo "[]" > "$SECRETS_BACKUP_FILE"

  while IFS= read -r secret_name; do
    [[ -z "$secret_name" ]] && continue
    info "    Exporting: $secret_name"
    secret_value=$(az keyvault secret show \
      --vault-name "$OLD_KV" \
      --name "$secret_name" \
      --query "value" -o tsv)

    # Append to JSON array
    jq --arg name "$secret_name" --arg value "$secret_value" \
      '. += [{"name": $name, "value": $value}]' \
      "$SECRETS_BACKUP_FILE" > "${SECRETS_BACKUP_FILE}.tmp" \
      && mv "${SECRETS_BACKUP_FILE}.tmp" "$SECRETS_BACKUP_FILE"
  done <<< "$SECRET_NAMES"

  SECRET_COUNT=$(jq length "$SECRETS_BACKUP_FILE")
  info "  Exported $SECRET_COUNT secret(s)"

  # Grant current user temporary access to new KV for secret import
  CURRENT_USER_OID=$(az ad signed-in-user show --query id -o tsv 2>/dev/null || true)
  if [[ -n "$CURRENT_USER_OID" ]]; then
    info "  Granting temporary Key Vault Secrets Officer role to current user"
    az role assignment create \
      --assignee "$CURRENT_USER_OID" \
      --role "Key Vault Secrets Officer" \
      --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$NEW_RG/providers/Microsoft.KeyVault/vaults/$NEW_KV" \
      --output none 2>/dev/null || true

    # Wait for RBAC propagation
    info "  Waiting for RBAC propagation (30s)"
    sleep 30
  fi

  # Import secrets into new KV using temp files to handle special characters
  info "  Importing secrets into $NEW_KV"
  TEMP_SECRET_FILE="$(mktemp)"
  jq -c '.[]' "$SECRETS_BACKUP_FILE" | while IFS= read -r entry; do
    name=$(echo "$entry" | jq -r '.name')
    echo "$entry" | jq -r '.value' > "$TEMP_SECRET_FILE"
    info "    Importing: $name"
    az keyvault secret set \
      --vault-name "$NEW_KV" \
      --name "$name" \
      --file "$TEMP_SECRET_FILE" \
      --encoding utf-8 \
      --output none
  done
  rm -f "$TEMP_SECRET_FILE"

  info "  Secrets migration complete"
fi

# =============================================================================
# Step 4: Remove old resources from Terraform state
# =============================================================================
info "Step 4: Removing old resources from Terraform state"

cd "$TERRAFORM_DIR"

terraform init -input=false

# Resources to remove from state (old East Asia references)
STATE_RESOURCES=(
  "azurerm_resource_group.main"
  "module.aks.azurerm_kubernetes_cluster.aks"
  "module.acr.azurerm_container_registry.acr"
  "module.key_vault.azurerm_key_vault.vault"
  'module.key_vault.azurerm_role_assignment.secrets_officer[0]'
  "azurerm_user_assigned_identity.external_secrets"
  "azurerm_federated_identity_credential.external_secrets"
  "azurerm_role_assignment.external_secrets_kv_reader"
  'module.github_oidc.azurerm_role_assignment.acr_push[0]'
)

for resource in "${STATE_RESOURCES[@]}"; do
  info "  Removing: $resource"
  terraform state rm "$resource" 2>/dev/null || info "    (not in state, skipping)"
done

info "State cleanup complete"

# =============================================================================
# Step 5: Terraform apply
# =============================================================================
info "Step 5: Running terraform apply"

terraform apply -auto-approve -input=false

info "Terraform apply complete"

# =============================================================================
# Step 6: Get kubeconfig
# =============================================================================
info "Step 6: Getting kubeconfig for new cluster"

az aks get-credentials \
  --name "$NEW_AKS" \
  --resource-group "$NEW_RG" \
  --overwrite-existing

# =============================================================================
# Step 7: Verify
# =============================================================================
info "Step 7: Verifying migration"

info "  Checking cluster nodes..."
kubectl get nodes

info "  Checking Key Vault secrets..."
az keyvault secret list --vault-name "$NEW_KV" --query "[].name" -o tsv

info "  Checking AKS OIDC issuer..."
az aks show --name "$NEW_AKS" --resource-group "$NEW_RG" \
  --query oidcIssuerProfile.issuerUrl -o tsv

# =============================================================================
# Step 8: Summary
# =============================================================================
echo ""
echo "============================================="
echo "  Migration Complete!"
echo "============================================="
echo ""
echo "  Region:          $REGION"
echo "  Resource Group:  $NEW_RG"
echo "  AKS Cluster:     $NEW_AKS"
echo "  ACR:             $NEW_ACR"
echo "  Key Vault:       $NEW_KV"
echo "  Identity:        $NEW_IDENTITY"
echo ""
echo "  Next steps:"
echo "    1. Redeploy ArgoCD and cluster workloads"
echo "    2. Update consumer repos if they reference old resource names"
echo "    3. Delete old resource group when ready:"
echo "       az group delete --name $OLD_RG --yes --no-wait"
echo ""
