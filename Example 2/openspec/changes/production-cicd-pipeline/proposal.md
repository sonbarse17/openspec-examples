# Proposal

## Why

The Python application has no automated path to production. Builds, security checks, schema changes and releases are manual, which makes releases slow, unaudited and hard to undo. A single GitHub Actions pipeline gives every change the same gated, reversible route to AWS.

## What Changes

- Add a GitHub Actions pipeline: build and test on every PR, deploy on merge to `main`.
- Add security gates: dependency audit, secret scan, static analysis, container image scan. High/critical findings block the pipeline.
- Build one immutable container image per commit and push it to Amazon ECR.
- Run database migrations as a controlled pipeline step before the new version takes traffic.
- Promote through `staging` then `production` GitHub Environments; production needs manual approval.
- Verify each deploy with health checks and roll back automatically on failure.
- Authenticate to AWS with GitHub OIDC; no long-lived AWS keys in GitHub.

**Assumptions** (no code exists yet; correct me if wrong): Python app packaged as a Docker image, running on ECS Fargate behind an ALB, PostgreSQL on RDS, Alembic for migrations, pytest for tests, one AWS account per environment, region `us-east-1`.

## Capabilities

### New Capabilities
- `ci-build-and-scan`: Build, test, security scanning and image publishing on PRs and `main`.
- `database-migrations`: Safe, ordered, auditable schema migration during a release.
- `deployment-and-rollback`: Environment promotion with approvals, deployment, health checks and rollback.

### Modified Capabilities
<!-- None: greenfield project, no existing specs. -->

## Impact

- New: `.github/workflows/*.yml`, `Dockerfile`, health endpoint contract on the app, deploy/rollback scripts.
- AWS: ECR repo, ECS services, IAM OIDC roles per environment, RDS access for the migration task.
- GitHub: `staging` and `production` Environments, required reviewers, branch protection on `main`.
- Out of scope: provisioning AWS infrastructure (IaC), blue/green via CodeDeploy, monitoring/alerting setup.
