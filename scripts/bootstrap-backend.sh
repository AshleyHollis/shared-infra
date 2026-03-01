#!/usr/bin/env bash
# bootstrap-backend.sh
#
# Bootstrap script for shared-infra Terraform state backend.
#
# This script verifies that the Azure Storage Account and blob container
# used for Terraform remote state already exist, then enables blob
# versioning on the storage account for automatic state file history.
#
# Prerequisites:
#   - Azure CLI installed and authenticated (az login)
#   - Sufficient permissions on the storage account
#
# Usage:
#   ./scripts/bootstrap-backend.sh
#
# The state backend reuses the existing storage account (stytsummarizertfstate)
# with a new key (shared-infra.tfstate) in the existing container (tfstate).
# No new Azure resources are created -- this script only validates and
# configures the existing infrastructure.

set -euo pipefail

STORAGE_ACCOUNT="stytsummarizertfstate"
RESOURCE_GROUP="rg-ytsummarizer-tfstate"
CONTAINER_NAME="tfstate"

echo "=== Shared-Infra State Backend Bootstrap ==="
echo ""

# Step 1: Verify the storage account exists
echo "Verifying storage account '${STORAGE_ACCOUNT}' exists..."
az storage account show \
  --name "${STORAGE_ACCOUNT}" \
  --resource-group "${RESOURCE_GROUP}" \
  --output none
echo "  Storage account verified."

# Step 2: Verify the blob container exists
echo "Verifying blob container '${CONTAINER_NAME}' exists..."
az storage container show \
  --name "${CONTAINER_NAME}" \
  --account-name "${STORAGE_ACCOUNT}" \
  --auth-mode login \
  --output none
echo "  Blob container verified."

# Step 3: Enable blob versioning on the storage account
echo "Enabling blob versioning on '${STORAGE_ACCOUNT}'..."
az storage account blob-service-properties update \
  --account-name "${STORAGE_ACCOUNT}" \
  --resource-group "${RESOURCE_GROUP}" \
  --enable-versioning true \
  --output none
echo "  Blob versioning enabled."

echo ""
echo "=== Bootstrap Complete ==="
echo "State backend is ready for shared-infra.tfstate"
