# Tasks

## 1. Application prerequisites

- [ ] 1.1 Add a `Dockerfile` for the Python app and verify `docker build` and `docker run` start it
- [x] 1.2 Add a `/health` endpoint that checks DB connectivity and verify with a pytest test (200 healthy, 503 when DB unreachable)
- [x] 1.3 Add Alembic config and a baseline migration and verify `alembic upgrade head` runs on an empty DB

## 2. CI: build, test, scan (ci-build-and-scan)

- [ ] 2.1 Create `.github/workflows/ci.yml` with lint and pytest on PR/push and verify a failing test fails the run
- [ ] 2.2 Add pip-audit, gitleaks and CodeQL jobs and verify a seeded vulnerable dep and fake secret each fail the run
- [ ] 2.3 Add image build plus Trivy scan, and push to ECR tagged with the commit SHA only on `main`, and verify the tag appears in ECR
- [ ] 2.4 Configure GitHub OIDC role assumption (no AWS keys) and verify `aws sts get-caller-identity` succeeds in the workflow
- [x] 2.5 Document required branch protection and status checks in `docs/cicd.md`

## 3. Migrations (database-migrations)

- [ ] 3.1 Add a reusable migration step that runs `alembic upgrade head` as a one-off ECS task and fails on non-zero exit; verify with a passing and a deliberately failing migration
- [ ] 3.2 Add per-environment concurrency groups and verify two simultaneous runs serialize
- [x] 3.3 Document the expand/contract migration rule in `docs/cicd.md`

## 4. Deploy, health check, rollback (deployment-and-rollback)

- [ ] 4.1 Create `deploy.yml` with staging then production jobs, migration step first, and verify staging deploys the CI image tag
- [ ] 4.2 Configure the `production` Environment with required reviewers and verify the job pauses for approval and a rejection deploys nothing
- [x] 4.3 Add a post-deploy health-check script with retries and timeout and verify it fails against a broken release
- [ ] 4.4 Record the previous task definition before deploy and add automatic rollback on failure; verify a forced bad deploy is reverted and the workflow still reports failure
- [ ] 4.5 Create `rollback.yml` (`workflow_dispatch`, inputs: environment, image tag) and verify it redeploys and health-checks a chosen tag
- [ ] 4.6 Document the release, approval and rollback runbook in `docs/cicd.md` and verify each command is runnable as written

## 5. Integration

- [ ] 5.1 Run a full PR to production flow end to end in a sandbox AWS account and verify the scenarios in all three specs pass

## Workflow follow-up

- Archive the change after review and a successful end-to-end run.
