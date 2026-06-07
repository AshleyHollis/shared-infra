# OpenClaw Cloudflare Tunnel Runbook

This runbook covers the final activation path for exposing OpenClaw workloads
through Cloudflare Tunnel while keeping the VPS itself closed to public inbound
traffic.

## Exposure Model

- The OpenClaw VPS should keep inbound firewall policy deny-by-default.
- Do not expose K3s API, NodePort, LoadBalancer, HTTP, or HTTPS ports directly
  on the VPS public IP.
- Cloudflared runs inside K3s and creates outbound-only connections to
  Cloudflare.
- Public traffic enters through Cloudflare and is forwarded to the internal
  Gateway API service:
  `http://nginx-gateway-fabric.gateway-system.svc.cluster.local:80`.
- K3s API access remains private, currently through Tailscale and Azure Arc.

References:

- Cloudflare Tunnel overview:
  https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/
- Cloudflare Terraform tunnel guide:
  https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/deployment-guides/terraform/

## Secret Ownership

Keep secret rotation declarative:

- `yt-summarizer` GitHub secret `CLOUDFLARE_API_TOKEN` is the source value used
  by app Terraform.
- App Terraform writes Azure Key Vault secret `cloudflare-api-token`.
- Shared-infra Terraform reads `cloudflare-api-token` from Key Vault, creates
  Cloudflare tunnel resources, then writes Key Vault secret
  `cloudflare-tunnel-token`.
- External Secrets Operator syncs `cloudflare-tunnel-token` into the OpenClaw
  cluster for the cloudflared deployment.

Do not update Key Vault secrets manually unless recovering from an incident and
immediately reconciling Terraform afterward.

## Required Cloudflare Token Permissions

The token stored as `yt-summarizer` GitHub secret `CLOUDFLARE_API_TOKEN` must be
able to manage both the tunnel and DNS records:

| Scope | Permission |
| --- | --- |
| Account | Cloudflare Tunnel: Edit |
| Zone | DNS: Edit |

Limit the token resources to the Cloudflare account
`3b85dceddc3e916c4921948eaf8fc87f` and the `ashleyhollis.com` zone
`35fb09d98b33c17ad61ca337e6912a57` where possible.

## Validate Before Enabling

Shared-infra validates the token before Terraform plans OpenClaw tunnel
resources. To run the same read-only check locally from PowerShell:

```powershell
$env:ENABLE_OPENCLAW_TUNNEL = 'true'
$env:CLOUDFLARE_ACCOUNT_ID = '3b85dceddc3e916c4921948eaf8fc87f'
$env:CLOUDFLARE_ZONE_ID = '35fb09d98b33c17ad61ca337e6912a57'
$env:CLOUDFLARE_API_TOKEN = az keyvault secret show `
  --vault-name kv-ytsumm-prd-ci `
  --name cloudflare-api-token `
  --query value `
  --output tsv

bash .github/actions/terraform-plan/validate-cloudflare-openclaw-token.sh
$exitCode = $LASTEXITCODE

Remove-Item Env:\CLOUDFLARE_API_TOKEN -ErrorAction SilentlyContinue
Remove-Item Env:\ENABLE_OPENCLAW_TUNNEL -ErrorAction SilentlyContinue
Remove-Item Env:\CLOUDFLARE_ACCOUNT_ID -ErrorAction SilentlyContinue
Remove-Item Env:\CLOUDFLARE_ZONE_ID -ErrorAction SilentlyContinue

exit $exitCode
```

Expected success:

```text
Cloudflare token has the tunnel and DNS read access required for OpenClaw tunnel planning.
```

Known insufficient-token failures:

- `Cloudflare token cannot list Cloudflare tunnels ... code 10000: Authentication error`
- `Cloudflare token cannot list DNS records ... code 9109: Unauthorized to access requested resource`

## Activation Sequence

1. Rotate `CLOUDFLARE_API_TOKEN` in the `yt-summarizer` repository to a token
   with the permissions above.
2. Run the `yt-summarizer` production deploy workflow with Terraform enabled so
   app Terraform updates Key Vault secret `cloudflare-api-token`.
3. Confirm the read-only validation command above succeeds.
4. Set shared-infra repository variable `ENABLE_OPENCLAW_TUNNEL=true`.
5. Run shared-infra `Deploy` with `run_apply=true`,
   `k8s_target=openclaw`, and `enable_openclaw_tunnel=true`.
6. Confirm Terraform creates or updates the Cloudflare tunnel, DNS records,
   tunnel config, and Key Vault secret `cloudflare-tunnel-token`.
7. Refresh the OpenClaw `cloudflare-tunnel` Argo CD app and confirm cloudflared
   pods move to `Running`.
8. Verify public hosts route through Cloudflare to the Gateway API routes.

Keep `ENABLE_OPENCLAW_TUNNEL=false` until the token validation passes.
