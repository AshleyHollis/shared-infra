#!/usr/bin/env bash
set -euo pipefail

# Connect the OpenClaw K3s cluster to Azure Arc with workload identity enabled.
# Prerequisites:
# - K3s is installed and running.
# - Azure CLI is authenticated with permission to create Arc-enabled Kubernetes resources.
# - KUBECONFIG points to a readable kubeconfig for the K3s cluster.
# - Required providers are registered in the subscription.

ARC_CLUSTER_NAME="${ARC_CLUSTER_NAME:-openclaw-ytsumm-prd}"
AZURE_RESOURCE_GROUP="${AZURE_RESOURCE_GROUP:-rg-ytsumm-prd-ci}"
AZURE_LOCATION="${AZURE_LOCATION:-centralindia}"
KUBECONFIG="${KUBECONFIG:-/etc/rancher/k3s/k3s.yaml}"

if [[ ! -r "${KUBECONFIG}" ]]; then
  echo "KUBECONFIG is not readable: ${KUBECONFIG}" >&2
  echo "Run as root on the VPS or set KUBECONFIG to a readable local copy." >&2
  exit 1
fi

if ! command -v az >/dev/null 2>&1; then
  echo "Azure CLI is required." >&2
  exit 1
fi

export KUBECONFIG

az extension add --name connectedk8s --upgrade --yes
az extension add --name k8s-extension --upgrade --yes

az connectedk8s connect \
  --name "${ARC_CLUSTER_NAME}" \
  --resource-group "${AZURE_RESOURCE_GROUP}" \
  --location "${AZURE_LOCATION}" \
  --kube-config "${KUBECONFIG}" \
  --enable-oidc-issuer \
  --enable-workload-identity

OIDC_ISSUER_URL="$(az connectedk8s show \
  --name "${ARC_CLUSTER_NAME}" \
  --resource-group "${AZURE_RESOURCE_GROUP}" \
  --query "oidcIssuerProfile.issuerUrl" \
  --output tsv)"

cat <<EOF
Azure Arc onboarding complete.

Use this for the shared-infra Terraform apply:

TF_VAR_openclaw_arc_oidc_issuer_url=${OIDC_ISSUER_URL}
TF_VAR_enable_openclaw_tunnel=true

Then configure K3s service account tokens to use the Arc issuer:

OPENCLAW_ARC_OIDC_ISSUER_URL=${OIDC_ISSUER_URL} scripts/configure-openclaw-workload-identity.sh

EOF
