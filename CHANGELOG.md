# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- Migrate all shared infrastructure from East Asia to Central India (`centralindia`) for Azure OpenAI LLM access
- Adopt region-aware naming convention `{type}-{workload}-{env}-{region}`: name prefix `ytsumm-prd` → `ytsumm-prd-ci`
- Key Vault renamed from `kv-ytsumm-prd` to `kv-ytsumm-prd-ci` (purge protection reserves old name 90 days)
- Update import blocks to reference new Central India resource IDs
- Remove import blocks for workload identity resources (Terraform creates fresh)
- Update ClusterSecretStore vault URL to new Key Vault

### Added

- Migration script `scripts/migrate-to-centralindia.sh` automating: Azure CLI resource creation, Key Vault secret migration, Terraform state cleanup, and verification

## [v1.0.0] - 2026-03-01

### Added

- Terraform root module managing shared Azure infrastructure (RG, AKS, ACR, Key Vault, OIDC, Workload Identity)
- 53 GitHub Actions composite actions consolidated from yt-summarizer
- 6 GitHub Actions workflows (3 internal CI + 3 reusable)
- Data-only consumer module (`shared-infra-data`) for cross-repo state access
- State migration via import/removed blocks for zero-downtime resource transfer
- Bootstrap script for backend storage validation
