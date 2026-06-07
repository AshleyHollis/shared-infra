#!/usr/bin/env bash
set -euo pipefail

# Configure K3s service account tokens to use the Azure Arc OIDC issuer.
# Run on the VPS as root after scripts/connect-openclaw-arc.sh has printed
# OPENCLAW_ARC_OIDC_ISSUER_URL.

KUBECONFIG="${KUBECONFIG:-/etc/rancher/k3s/k3s.yaml}"
OPENCLAW_ARC_OIDC_ISSUER_URL="${OPENCLAW_ARC_OIDC_ISSUER_URL:-}"

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run this script as root so it can write K3s config and restart K3s." >&2
  exit 1
fi

if [[ -z "${OPENCLAW_ARC_OIDC_ISSUER_URL}" ]]; then
  echo "OPENCLAW_ARC_OIDC_ISSUER_URL is required." >&2
  exit 1
fi

mkdir -p /etc/rancher/k3s/config.yaml.d
cat > /etc/rancher/k3s/config.yaml.d/20-openclaw-arc-workload-identity.yaml <<EOF
kube-apiserver-arg:
  - "service-account-issuer=${OPENCLAW_ARC_OIDC_ISSUER_URL}"
  - "service-account-max-token-expiration=24h"
EOF

systemctl restart k3s

export KUBECONFIG
kubectl wait --for=condition=Ready node --all --timeout=180s

echo "OpenClaw K3s workload identity issuer configured."
