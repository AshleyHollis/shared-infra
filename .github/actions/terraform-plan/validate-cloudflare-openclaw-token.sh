#!/bin/bash
set -euo pipefail

# Validate the Cloudflare token before OpenClaw tunnel Terraform runs. This
# intentionally uses read/list calls only so validation does not create or
# mutate Cloudflare resources.

if [[ "${ENABLE_OPENCLAW_TUNNEL:-}" != "true" ]]; then
  exit 0
fi

required_vars=(
  CLOUDFLARE_API_TOKEN
  CLOUDFLARE_ACCOUNT_ID
  CLOUDFLARE_ZONE_ID
)

for var_name in "${required_vars[@]}"; do
  if [[ -z "${!var_name:-}" ]]; then
    echo "::error::${var_name} is required when ENABLE_OPENCLAW_TUNNEL=true."
    exit 1
  fi
done

cloudflare_get() {
  local label="$1"
  local url="$2"
  local body_file
  local http_status

  body_file="$(mktemp)"
  http_status="$(
    curl -sS \
      -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
      -H "Content-Type: application/json" \
      -o "${body_file}" \
      -w "%{http_code}" \
      "${url}" || true
  )"

  if [[ ! "${http_status}" =~ ^2[0-9][0-9]$ ]] || ! jq -e '.success == true' "${body_file}" >/dev/null; then
    local errors
    errors="$(
      jq -r '.errors[]? | "code \(.code): \(.message)"' "${body_file}" 2>/dev/null \
        | paste -sd '; ' -
    )"
    rm -f "${body_file}"

    if [[ -n "${errors}" ]]; then
      echo "::error::Cloudflare token cannot ${label}: ${errors}"
    else
      echo "::error::Cloudflare token cannot ${label}: HTTP ${http_status}"
    fi

    exit 1
  fi

  rm -f "${body_file}"
}

cloudflare_get \
  "list Cloudflare tunnels for account ${CLOUDFLARE_ACCOUNT_ID}" \
  "https://api.cloudflare.com/client/v4/accounts/${CLOUDFLARE_ACCOUNT_ID}/cfd_tunnel?is_deleted=false&per_page=1"

cloudflare_get \
  "list DNS records for zone ${CLOUDFLARE_ZONE_ID}" \
  "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/dns_records?per_page=1"

echo "Cloudflare token has the tunnel and DNS read access required for OpenClaw tunnel planning."
