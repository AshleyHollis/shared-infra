# shared-infra — Claude Code Project Instructions

## Project Location
/home/openclaw/dev/shared-infra

## What This Repo Is
Shared Azure infrastructure and GitHub Actions for all AshleyHollis consumer repos.

**Changes here affect ALL consumer repos (yt-summarizer, meal-planner). Treat every change as high impact.**

- `terraform/` — AKS, ACR, Key Vault, OIDC, workload identity (shared Azure resources)
- `.github/actions/` — 53 composite GitHub Actions referenced by consumer repos as `AshleyHollis/shared-infra/.github/actions/<name>@v1`
- `.github/workflows/` — Reusable workflows (build-and-push, deploy-to-aks, terraform-reusable, etc.)
- `k8s/` — ArgoCD app definitions, cluster secrets
- `terraform/modules/shared-infra-data/` — Data module consumer repos use to look up shared resource IDs

## Consumer Repos That Depend On This
- **yt-summarizer** — `/home/openclaw/dev/yt-summarizer` — references actions @v1, reusable workflows, shared-infra-data module
- **meal-planner** — references same actions and workflows

## Session Recovery (MANDATORY — read this first every session)

```bash
cd /home/openclaw/dev/shared-infra
cat PENDING.md 2>/dev/null          # active task state — read this first
git log --oneline -20               # recent commits
git status                          # uncommitted changes
```

If PENDING.md describes an in-progress task, continue it without asking Peter to re-explain.

### PENDING.md protocol

There are two types of sessions. Each has a different role:

**Inbound sessions** (triggered by a Discord message — short, < 5 min):
- Understand the request, estimate size, spawn a background agent if large
- **NEVER write PENDING.md** — put all task context in the spawn-agent.sh task description
- Exit immediately after spawning

**Background agents** (spawned via spawn-agent.sh — long-running, no timeout):
- **Write PENDING.md immediately on start**: task name, approach, files, progress, next steps
- **Update PENDING.md after every significant action**
- **If you see `=== CONTEXT COMPACTION TRIGGERED ===`**: update PENDING.md immediately
- **Task complete**: clear PENDING.md, then post result to Discord

### Automatic hooks (configured in .claude/settings.json)
- **SessionStart**: records session start time; injects PENDING.md content if a task is in progress
- **PreCompact**: outputs a reminder to update PENDING.md before context is summarized
- **Stop**: if session ran ≥ 5 min and PENDING.md has content → posts ⚠️ crash alert to Discord (#shared-infra)

---

## Session Limits and When to Spawn

This inbound session has a hard 30-minute timeout. Background agents have NO timeout.

| Task size | Action |
|-----------|--------|
| < 20 min | Do it in this session |
| > 20 min | Write context to PENDING.md, spawn agent, stop |

**Large tasks**: Terraform plan/apply, multi-file action refactors, anything touching infra shared with meal-planner, waiting for CI/CD pipelines.

### Spawn pattern
```bash
# 1. Put task context in the spawn message (not PENDING.md — that's for the agent)
bash /home/openclaw/.openclaw/workspace/scripts/spawn-agent.sh \
  1485029874145169583 \
  "Do <task>. cd /home/openclaw/dev/shared-infra first. <full context here>. Post result to this channel when done."

# GH Actions monitoring
bash /home/openclaw/.openclaw/workspace/scripts/spawn-gh-monitor.sh <run-id> 1485029874145169583
```

**NEVER say 'monitoring', 'watching', or 'continuing to monitor'** — those mean you are about to poll inline. Spawn instead.

---

## Key Azure Resources (managed by this repo's Terraform)

| Resource | Name |
|----------|------|
| Resource Group | rg-ytsumm-prd-ci |
| AKS Cluster | aks-ytsumm-prd-ci |
| ACR | acrytsummprdci |
| Key Vault | kv-ytsumm-prd-ci |
| Terraform state | stytsummarizertfstate / shared-infra.tfstate |

## Terraform Notes
- State backend: Azure Blob Storage (`stytsummarizertfstate`, key: `shared-infra.tfstate`)
- Run `terraform plan` before any apply
- Consumer repos use `terraform/modules/shared-infra-data/` to look up resource IDs via `terraform_remote_state`
- OIDC / workload identity: changes here require coordinated updates in consumer repos

## GitHub Actions Notes
- All 53 composite actions are in `.github/actions/`
- Consumer repos pin to `@v1` tag — breaking changes require a version bump
- Reusable workflows in `.github/workflows/` are called by consumer repos via `uses: AshleyHollis/shared-infra/.github/workflows/<name>.yml@v1`
