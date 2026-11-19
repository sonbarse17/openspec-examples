# Example 2: Gated CI/CD pipeline to AWS ECS

**Start here.** This is the smaller example. It has one change, three capabilities, and a short Python app.

**The scenario:** a Python service has no automated route to production. Builds, security checks, database migrations and releases are all manual. This change specifies a GitHub Actions pipeline with tests, security scans, immutable images, controlled migrations, staged promotion with approval, health checks and automatic rollback.

```sh
cd "Example 2"
openspec list                                  # production-cicd-pipeline  5/18 tasks
openspec status --change production-cicd-pipeline
openspec show production-cicd-pipeline
```

---

## Guided tour

Read the files in this order. For each one, look for the points listed under it.

### 1. [proposal.md](openspec/changes/production-cicd-pipeline/proposal.md): why this change exists

- **Why** is two sentences about the problem. It doesn't mention any tools.
- **Capabilities** lists three new areas of behavior. Each one gets its own folder under `specs/`.
- The **Assumptions** line (ECS Fargate, RDS, Alembic and so on) makes guesses visible so that reviewers can correct them. Use the same pattern when the requirements are unclear.
- **Impact** includes **Out of scope**. This is often the most useful line in a proposal.

### 2. Specs: what must be true

| Capability | File | What it guarantees |
|---|---|---|
| `ci-build-and-scan` | [spec.md](openspec/changes/production-cicd-pipeline/specs/ci-build-and-scan/spec.md) | Tests and scans gate every PR, and one image per commit is built |
| `database-migrations` | [spec.md](openspec/changes/production-cicd-pipeline/specs/database-migrations/spec.md) | Migrations run once, in order, before the new version gets traffic |
| `deployment-and-rollback` | [spec.md](openspec/changes/production-cicd-pipeline/specs/deployment-and-rollback/spec.md) | Staging before prod, an approval gate, health checks, rollback |

Open `deployment-and-rollback`. Notice:

- Every requirement uses **SHALL** or **MUST**, and every requirement has WHEN/THEN scenarios.
- Scenarios cover the **failure path** as well as the success path. Examples are "Staging failure", "Rejected" and "Unhealthy release". In DevOps work the failure scenarios matter most.
- The specs never name a tool. "Roll back to the last known good image" doesn't say how.

### 3. [design.md](openspec/changes/production-cicd-pipeline/design.md): how it will be built, and why

Each decision states the choice **and** the rejected alternative:

- *Migrations run as a one-off ECS task, not at app startup*, because startup migrations race each other across replicas.
- *The image is built once and tagged with the commit SHA*, because rebuilding per environment means the image you deploy isn't the one you tested.
- *GitHub OIDC rather than stored AWS keys*, because stored keys are long-lived secrets.

**Risks / Trade-offs** pairs each risk with a mitigation. For example, a destructive migration would break rollback, so the design adopts an expand/contract migration rule.

### 4. [tasks.md](openspec/changes/production-cicd-pipeline/tasks.md): the steps

- Tasks are grouped by capability.
- **Every task ends with a verify step**, for example "verify a seeded vulnerable dep and fake secret each fail the run". That's how you know a task is done.
- 5 of 18 are ticked. This change is still in progress.

---

## Tracing specs to code

This is the main skill to practice: for every scenario, find what enforces it.

| Requirement (spec) | Enforced by (code) |
|---|---|
| Automatic rollback | [_deploy-env.yml](.github/workflows/_deploy-env.yml): records the current task definition, then restores it if the health check fails |
| Post-deploy health checks | [scripts/health-check.sh](scripts/health-check.sh) (10 tries × 15s) against `/health` in [app/main.py](app/main.py), which checks the database |
| Health endpoint returns 503 when the DB is down | [tests/test_health.py](tests/test_health.py) |
| Migrations run before the traffic switch | `_deploy-env.yml`: a one-off ECS task runs `alembic upgrade head`, and a non-zero exit stops the deploy |
| Production approval | [deploy.yml](.github/workflows/deploy.yml): `environment: production` with required reviewers |
| Serialized deploys | `concurrency:` group per environment in `_deploy-env.yml` |
| Manual rollback | [rollback.yml](.github/workflows/rollback.yml) (`workflow_dispatch` with environment and image tag) |
| Security gates | [ci.yml](.github/workflows/ci.yml): pip-audit, gitleaks, CodeQL, Trivy |
| Release and rollback runbook | [docs/cicd.md](docs/cicd.md) |

**Try this:** pick any scenario in `specs/ci-build-and-scan/spec.md` and find the line in `ci.yml` that makes it true. If you can't find one, either a task is still open or there's a gap in the spec.

## Run the app tests (optional)

```sh
python -m venv .venv && . .venv/bin/activate     # Windows: .venv\Scripts\activate
pip install -r requirements-dev.txt
pytest
```

When you're done, continue with [Example 1](../Example%201/README.md).
