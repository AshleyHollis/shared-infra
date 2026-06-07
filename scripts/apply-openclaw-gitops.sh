#!/usr/bin/env bash
set -euo pipefail

# Apply the Argo CD Applications that let the OpenClaw K3s cluster pull its
# desired state from Git. Run after:
# 1. scripts/bootstrap-openclaw-k3s.sh
# 2. scripts/connect-openclaw-arc.sh
# 3. shared-infra Terraform apply with enable_openclaw_tunnel=true

KUBECONFIG="${KUBECONFIG:-/etc/rancher/k3s/k3s.yaml}"
SHARED_INFRA_DIR="${SHARED_INFRA_DIR:-/home/openclaw/dev/shared-infra}"
YT_SUMMARIZER_DIR="${YT_SUMMARIZER_DIR:-/home/openclaw/dev/yt-summarizer}"

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run this script as root so it can read ${KUBECONFIG}." >&2
  exit 1
fi

export KUBECONFIG

kubectl -n argocd get deployment argocd-server >/dev/null
kubectl apply -f "${SHARED_INFRA_DIR}/k8s/argocd/resource-customizations.yaml"
kubectl apply -f "${SHARED_INFRA_DIR}/k8s/argocd/infra-apps-openclaw.yaml"
kubectl apply -k "${YT_SUMMARIZER_DIR}/k8s/argocd/openclaw"

echo "OpenClaw GitOps applications applied."
