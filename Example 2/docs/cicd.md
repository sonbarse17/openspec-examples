# CI/CD runbook

## Flow
PR: lint, test, pip-audit, gitleaks, CodeQL, build + Trivy scan.
`main`: same, then push image `<ecr>/app:<sha>`, deploy staging, wait for approval, deploy production.
Each environment deploy: record current task definition, register a new one, run `alembic upgrade head` as a one-off ECS task, update the service, health check, auto-rollback if the health check or service update fails.
A failed migration stops before the service is touched, so the old version keeps serving.

## One-time setup
- Branch protection on `main`: require PR and status checks `test`, `dependency-audit`, `secret-scan`, `codeql`, `image`.
- GitHub Environments `staging` and `production`; add required reviewers to `production`.
- Per-environment variables: `AWS_ROLE_ARN`, `ECR_REGISTRY`, `ECS_CLUSTER`, `ECS_SERVICE`, `TASK_SUBNETS`, `TASK_SECURITY_GROUPS`, `HEALTH_URL`. Repo variable: `AWS_ROLE_ARN_BUILD` (ECR push).
- IAM roles trust `token.actions.githubusercontent.com`; limit `sub` to `repo:<org>/<repo>:environment:<env>` (build role: `repo:<org>/<repo>:ref:refs/heads/main`).
- The app container must be named `app` in the ECS task definition, and the task must receive `DATABASE_URL`.

## Migrations: expand/contract
Rollback never reverses schema, so every migration must work with the previous app version. Add columns nullable or defaulted; never drop or rename in the same release as the code change. Remove old columns in a later release.

## Manual rollback
Actions, Rollback, choose the environment and an earlier commit SHA already in ECR. It runs the same deploy path (the migration step is a no-op if the DB is already at head).
