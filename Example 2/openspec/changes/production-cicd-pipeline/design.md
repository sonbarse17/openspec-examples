# Design

## Context

Greenfield: no application code or infrastructure exists in this repo. Assumptions are listed in proposal.md (ECS Fargate, ECR, RDS Postgres, Alembic, pytest). AWS infrastructure is created outside this change.

## Goals / Non-Goals

**Goals:**
- One workflow set, fully gated, no long-lived secrets.
- Build once, deploy the same image everywhere.
- Fast, automatic rollback using ECS's previous task definition.

**Non-Goals:**
- Provisioning AWS resources (Terraform/CDK), canary/blue-green, observability setup, multi-region.

## Decisions

- **Workflows**: `ci.yml` (PR + main: lint, test, scan, build, push), `deploy.yml` (runs after CI on main: staging then production), `rollback.yml` (manual `workflow_dispatch`). Alternative: one monolith file; rejected for readability and so rollback is independently runnable.
- **Scanning tools**: `pip-audit` (deps), `gitleaks` (secrets), CodeQL (SAST), Trivy (image). All free and easy to run in Actions. Fail on HIGH/CRITICAL.
- **Auth**: GitHub OIDC to per-environment IAM roles with trust policy limited to this repo and the environment. Alternative: stored access keys; rejected as long-lived secrets.
- **Image**: tag = commit SHA, never `latest`. Built once in CI, promoted by tag. Alternative: rebuild per environment; rejected because the tested artifact would differ from the deployed one.
- **Migrations**: run `alembic upgrade head` as a one-off ECS task using the new image, before updating the service; the pipeline waits for the exit code. Alternative: run on app startup; rejected as it races across replicas. An expand/contract rule keeps the schema backward compatible so rollback never reverses schema.
- **Approvals**: GitHub Environments `staging` (no gate) and `production` (required reviewers). Branch protection on `main`.
- **Deploy**: render a new ECS task definition with the image tag, update the service, `aws ecs wait services-stable`.
- **Health checks**: curl the ALB `/health` endpoint with retries (e.g. 10 x 15s). On failure, the rollback job redeploys the task definition revision recorded before the deploy, then re-checks.
- **Concurrency**: `concurrency: group: deploy-<env>, cancel-in-progress: false` serializes deploys and migrations.

## Risks / Trade-offs

- Destructive migration breaks rollback → expand/contract convention, review checklist item.
- Shallow health endpoint passes bad releases → `/health` must check DB connectivity; ECS deployment circuit breaker as a second layer.
- Failed rollback leaves production degraded → rollback job fails loudly; manual `rollback.yml` as fallback.
- Assumed stack may be wrong → workflows take env-level parameters, so swapping targets is a localized edit.
