# Hands-on exercises

You'll write real OpenSpec changes against [Example 2](Example%202/README.md). All four exercises take about an hour.

**Work on a practice branch**, so you can always go back to a clean repo:

```sh
git checkout -b practice
cd "Example 2"
```

When you're finished: `git checkout main && git branch -D practice`.

---

## Exercise 1: Archive a change and watch the specs get built

**Goal:** see how archiving turns change deltas into project specs.

```sh
openspec list --specs          # "No specs found." Nothing has been archived yet
openspec archive production-cicd-pipeline --yes
openspec list --specs
```

Expected output:

```
Specs:
  ci-build-and-scan           requirements 4
  database-migrations         requirements 4
  deployment-and-rollback     requirements 5
```

Now look at what changed:

- `openspec/specs/` now holds three `spec.md` files. They describe the system's current behavior.
- The change moved to `openspec/changes/archive/<date>-production-cicd-pipeline/`. That's your audit trail.

> In real work you'd archive only after all 18 tasks are done and the change is in production. Here you archive early so that the next exercises have specs to change.

---

## Exercise 2: Add a requirement (ADDED)

**Goal:** write a small change from scratch.

**The request:** "On-call only finds out about a rollback by reading the workflow logs. Post a message to the team chat channel when an automatic rollback runs."

**Step 1: create the change.**

```sh
openspec new change add-rollback-notification
openspec status --change add-rollback-notification
```

`status` shows which artifacts are missing, and in what order to write them.

**Step 2: write `openspec/changes/add-rollback-notification/proposal.md`.**

```markdown
## Why
On-call only learns about a rollback by reading the workflow logs.

## What Changes
- Post a message to the team chat channel when an automatic rollback runs.

## Capabilities
### Modified Capabilities
- `deployment-and-rollback`: add a rollback notification requirement.

## Impact
- `.github/workflows/_deploy-env.yml`, one new secret for the webhook URL.
```

**Step 3: write the delta.** Create `openspec/changes/add-rollback-notification/specs/deployment-and-rollback/spec.md`. The folder name must match the capability name.

```markdown
## ADDED Requirements

### Requirement: Rollback notification
The pipeline SHALL notify the team channel whenever an automatic rollback runs.

#### Scenario: Rollback announced
- **WHEN** an automatic rollback finishes
- **THEN** a message with environment, failed tag and restored tag is posted to the team channel
```

**Step 4: validate it.**

```sh
openspec validate add-rollback-notification --strict
# Change 'add-rollback-notification' is valid
```

To see what a failure looks like, delete the word `SHALL` and validate again. Then put it back.

**Step 5: write `design.md` and `tasks.md`.**

```sh
openspec instructions design --change add-rollback-notification
```

This prints the template and the guidance that an AI agent would follow. Keep both files short:

```markdown
<!-- design.md -->
## Context
Rollback already exists in _deploy-env.yml.

## Decisions
- Use a chat incoming webhook stored as a GitHub secret.
```

```markdown
<!-- tasks.md -->
## 1. Notify

- [ ] 1.1 Add a notify step after rollback in `_deploy-env.yml`; verify a forced bad deploy posts a message
```

**Step 6: check the status.**

```sh
openspec status --change add-rollback-notification     # 4/4 artifacts complete
```

**Step 7: archive it.** In real work you'd implement the task first and tick it.

```sh
openspec archive add-rollback-notification --yes
openspec list --specs      # deployment-and-rollback now has 6 requirements
```

Open `openspec/specs/deployment-and-rollback/spec.md`. Your requirement is at the bottom.

---

## Exercise 3: Change an existing requirement (MODIFIED)

**Goal:** learn the most common delta and the most common mistake with it.

**The request:** "The health check should give up after 3 minutes rather than an undefined timeout."

```sh
openspec new change tighten-health-timeout
```

Write a `proposal.md` (Why and What Changes are enough). Then create `openspec/changes/tighten-health-timeout/specs/deployment-and-rollback/spec.md`:

```markdown
## MODIFIED Requirements

### Requirement: Post-deploy health checks
After each deploy the pipeline SHALL poll the application health endpoint and treat the release as healthy only if it returns success within 3 minutes.

#### Scenario: Healthy release
- **WHEN** the health endpoint returns success within 3 minutes
- **THEN** the deploy is marked successful

#### Scenario: Unhealthy release
- **WHEN** the health endpoint fails or does not succeed within 3 minutes
- **THEN** the deploy is marked failed and rollback starts
```

Two rules:

1. The `### Requirement:` title must **exactly match** the one in `openspec/specs/deployment-and-rollback/spec.md`. That's how OpenSpec knows which requirement to replace.
2. Include the **whole** requirement with **all** of its scenarios. The block replaces the old one, so any scenario you leave out is deleted.

```sh
openspec validate tighten-health-timeout --strict
openspec show tighten-health-timeout --json --deltas-only    # "operation": "MODIFIED"
openspec archive tighten-health-timeout --yes                # Totals: + 0, ~ 1, - 0
```

**Check your understanding:** what would happen if you included only the "Unhealthy release" scenario?

<details><summary>Answer</summary>
The "Healthy release" scenario would disappear from the spec when you archive. Always copy the full requirement and then edit it.
</details>

**Follow-up:** the spec now says 3 minutes, but `scripts/health-check.sh` is called with `10 15` (10 tries × 15 seconds = 2.5 minutes). Is the code within the spec? This kind of spec-to-code check is what `/opsx:verify` does for you.

---

## Exercise 4: Drive it with an AI agent

**Goal:** see the same workflow with an agent writing the files.

```sh
openspec init --tools claude        # or github-copilot, cursor, codex...
```

Then in your agent:

```
/opsx:propose Add a smoke test job after staging deploy that calls /health and one
business endpoint; production must not start if it fails.
```

Review what it creates:

- [ ] Is the capability right? It should be a MODIFIED or ADDED delta to `deployment-and-rollback`, not a new capability.
- [ ] Is every THEN testable?
- [ ] Is there a failure scenario ("smoke test fails, so production is not deployed")?
- [ ] Does `design.md` name the alternative it rejected?
- [ ] Does every task have a verify step?
- [ ] Does `openspec validate <change> --strict` pass?

Then try `/opsx:apply` to implement it, `/opsx:verify` to check the code against the spec, and `/opsx:archive` to archive it.

**Takeaway:** the agent writes the first draft quickly. Your job is to review the spec, because once you approve it, everything after that is built from it.

---

## Exercise 5 (stretch): Your turn on Example 1

`cd "../Example 1"` and write a change by yourself, with no template to copy:

> "UAT and Prod must deny all outbound internet traffic from the app subnet except to Azure services."

Hints: which capability is this? (Look in `specs/`.) Is it ADDED or MODIFIED? Remember that `Example 1` has no archived specs yet, so you'd need to archive `azure-production-infrastructure` first, as you did in exercise 1. What's the WHEN/THEN, and how would `terraform test` prove it?

---

## Clean up

```sh
cd ..
git checkout main
git branch -D practice
```
