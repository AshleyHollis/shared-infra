# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v1.0.0] - 2026-03-01

### Added

- Terraform root module managing shared Azure infrastructure (RG, AKS, ACR, Key Vault, OIDC, Workload Identity)
- 53 GitHub Actions composite actions consolidated from yt-summarizer
- 6 GitHub Actions workflows (3 internal CI + 3 reusable)
- Data-only consumer module (`shared-infra-data`) for cross-repo state access
- State migration via import/removed blocks for zero-downtime resource transfer
- Bootstrap script for backend storage validation
