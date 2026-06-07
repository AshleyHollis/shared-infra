#!/usr/bin/env bash
set -euo pipefail

# Bootstrap the OpenClaw VPS as a single-node K3s cluster for pull-based GitOps.
# Run on the VPS as root before Azure Arc onboarding and Terraform apply.

K3S_CHANNEL="${K3S_CHANNEL:-stable}"
K3S_KUBECONFIG_MODE="${K3S_KUBECONFIG_MODE:-600}"
K3S_TLS_SAN="${K3S_TLS_SAN:-}"
ARGOCD_VERSION="${ARGOCD_VERSION:-v3.4.3}"
TAILSCALE_INTERFACE="${TAILSCALE_INTERFACE:-tailscale0}"

require_root() {
  if [[ "$(id -u)" -ne 0 ]]; then
    echo "This script must run as root." >&2
    exit 1
  fi
}

install_k3s() {
  local install_args=(
    server
    --disable traefik
    --disable servicelb
    --write-kubeconfig-mode "${K3S_KUBECONFIG_MODE}"
  )

  if [[ -n "${K3S_TLS_SAN}" ]]; then
    install_args+=(--tls-san "${K3S_TLS_SAN}")
  fi

  if command -v k3s >/dev/null 2>&1; then
    echo "K3s is already installed."
    if [[ -n "${K3S_TLS_SAN}" ]] \
      && [[ -f /etc/systemd/system/k3s.service ]] \
      && ! grep -Fq "${K3S_TLS_SAN}" /etc/systemd/system/k3s.service; then
      echo "K3s TLS SAN ${K3S_TLS_SAN} is not configured in the existing service." >&2
    fi
    return
  fi

  curl -sfL https://get.k3s.io | INSTALL_K3S_CHANNEL="${K3S_CHANNEL}" sh -s - \
    "${install_args[@]}"
}

detect_k3s_tls_san() {
  if [[ -n "${K3S_TLS_SAN}" ]] || ! command -v tailscale >/dev/null 2>&1; then
    return
  fi

  K3S_TLS_SAN="$(tailscale ip -4 2>/dev/null | head -n 1 || true)"
}

install_tools() {
  if ! command -v helm >/dev/null 2>&1; then
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
  fi

  if ! command -v argocd >/dev/null 2>&1 \
    || ! argocd version --client --short 2>/dev/null | grep -Fq "${ARGOCD_VERSION}"; then
    curl -sSL -o /usr/local/bin/argocd \
      "https://github.com/argoproj/argo-cd/releases/download/${ARGOCD_VERSION}/argocd-linux-amd64"
    chmod 0755 /usr/local/bin/argocd
  fi
}

configure_firewall() {
  if command -v ufw >/dev/null 2>&1; then
    ufw allow in on "${TAILSCALE_INTERFACE}" to any port 6443 proto tcp comment "K3s API over Tailscale" || true
    ufw deny 80/tcp || true
    ufw deny 443/tcp || true
  fi
}

install_argocd() {
  export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
  kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
  kubectl apply --server-side --force-conflicts -n argocd \
    -f "https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_VERSION}/manifests/install.yaml"
  kubectl -n argocd rollout status deployment/argocd-server --timeout=300s
}

require_root
detect_k3s_tls_san
install_k3s
install_tools
configure_firewall
install_argocd

echo "OpenClaw K3s bootstrap complete."
echo "Use KUBECONFIG=/etc/rancher/k3s/k3s.yaml for local root kubectl access on the VPS."
echo "Next: run scripts/connect-openclaw-arc.sh, apply Terraform, then run scripts/apply-openclaw-gitops.sh."
