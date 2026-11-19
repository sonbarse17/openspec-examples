# Learn OpenSpec with DevOps examples

This repo teaches [OpenSpec](https://github.com/Fission-AI/OpenSpec) through two realistic DevOps projects. It's for engineers who have never used OpenSpec. You can read through it in about an hour, and the hands-on exercises take another hour.

**What you'll be able to do afterwards:**

- Explain what OpenSpec is and why a DevOps team would use it
- Read a change and follow each requirement to the code that enforces it
- Write your own change, using both ADDED and MODIFIED requirements
- Validate a change and archive it, so its requirements become part of the project's specs
- Use OpenSpec with an AI coding agent
- Start using OpenSpec in your own repo

---

## 1. What OpenSpec is

OpenSpec is a CLI plus a set of slash commands for AI coding agents. They let a team agree on **what a change must do** before anyone writes the code.

Every piece of work is a **change**: a folder of short Markdown files that the team reviews like code. A change says:

- **Why** the work is needed (`proposal.md`)
- **What must be true** when it's done (`specs/<capability>/spec.md`)
- **How** it will be built and which alternatives were rejected (`design.md`)
- **The steps**, each with its own check (`tasks.md`)

When the change ships, you **archive** it. Its requirements are merged into `openspec/specs/`, which always describes what the system does today.

### Why DevOps teams use it

| Without OpenSpec | With OpenSpec |
|---|---|
| Reviewers read a 400-line `terraform plan` and try to work out the intent | Reviewers read "PostgreSQL SHALL have no public network access" and check the code against it |
| "Done" means the pipeline is green | "Done" means every scenario has a test or gate that proves it |
| Why OIDC and not access keys? Ask whoever wrote it | `design.md` records the decision and the rejected alternatives |
| An AI agent guesses at your architecture | The agent works from the agreed spec and task list |
| Platform docs go stale | `openspec/specs/` is updated every time a change is archived |

---

## 2. Core concepts

Learn these five ideas and the rest of the repo will make sense.

**Change**: one unit of work, kept in `openspec/changes/<change-name>/`. It's active until you archive it.

**Capability**: one area of behavior, such as `deployment-and-rollback` or `network-foundation`. Each capability has its own folder under `specs/`.

**Requirement**: a statement that uses **SHALL** or **MUST**. Each requirement needs at least one scenario.

**Scenario**: a concrete **WHEN / THEN** example. Write it so that it can become a test.

```markdown
### Requirement: Production approval
Production deployment MUST require approval from a designated reviewer before it starts.

#### Scenario: Rejected
- **WHEN** a reviewer rejects the deployment
- **THEN** nothing is deployed to production
```

**Delta**: the spec files inside a change only describe what that change alters. Each section starts with one of these headings:

| Heading | Meaning | When archived |
|---|---|---|
| `## ADDED Requirements` | A new requirement | Appended to `openspec/specs/<capability>/spec.md` |
| `## MODIFIED Requirements` | Replaces an existing requirement. Use the same `### Requirement:` title and write the **full** new text | Replaces the old block |
| `## REMOVED Requirements` | Deletes a requirement | Removed from the spec |
| `## RENAMED Requirements` | Changes a requirement's title | Title updated |

### The lifecycle

```
 propose ──► review ──► apply ──► verify ──► archive
   │           │          │          │          │
 proposal    team PR    code +     scenarios  specs/ updated,
 specs       on the     tasks.md   proven     change moved to
 design      Markdown   ticked     by tests   changes/archive/
 tasks
```

### Repo layout

```
openspec/
  config.yaml                  # schema + your team's rules (optional)
  specs/                       # current state of the system (built by archiving)
    <capability>/spec.md
  changes/
    <change-name>/             # work in progress
      proposal.md
      specs/<capability>/spec.md   # deltas
      design.md
      tasks.md
    archive/                   # finished changes, dated
```

---

## 3. Install

You need Node.js 22.20 or later.

```sh
npm install -g @fission-ai/openspec
openspec --version          # these examples were made with 2.1.0
```

Then clone this repo:

```sh
git clone https://github.com/sonbarse17/openspec-examples.git
cd openspec-examples
```

---

## 4. Learning path

Work through the steps in order. Each one builds on the last.

| Step | What you do | Where | Time |
|---|---|---|---|
| 1 | Read a small change and follow its specs into the pipeline code | [Example 2: CI/CD pipeline](Example%202/README.md) | 20 min |
| 2 | Read a larger change with six capabilities, applied to Terraform | [Example 1: Azure infrastructure](Example%201/README.md) | 25 min |
| 3 | Write, validate and archive your own changes | [EXERCISES.md](EXERCISES.md) | 45 min |
| 4 | Do the same work with an AI agent | [EXERCISES.md, exercise 4](EXERCISES.md#exercise-4-drive-it-with-an-ai-agent) | 15 min |
| 5 | Set up OpenSpec in your own repo | [Section 6](#6-use-it-in-your-own-repo) | 10 min |

Example 2 comes first because it's smaller: three capabilities and a short Python app.

| | Example 1 | Example 2 |
|---|---|---|
| Domain | Infrastructure as Code | CI/CD |
| Stack | Terraform, Azure | GitHub Actions, Docker, AWS ECS, Alembic |
| Change | `azure-production-infrastructure` | `production-cicd-pipeline` |
| Capabilities | 6 | 3 |
| Progress | 7/18 tasks | 5/18 tasks |

Both changes are deliberately **unfinished**, so you can see what a change looks like partway through: some tasks are ticked and others are still open.

---

## 5. Command cheat sheet

Run these from inside an example folder, such as `cd "Example 2"`.

| Command | What it does |
|---|---|
| `openspec list` | Active changes with task progress |
| `openspec list --specs` | Current specs, with their requirement counts |
| `openspec view` | Interactive dashboard |
| `openspec show <change>` | Print a change |
| `openspec show <change> --json --deltas-only` | Only what the change adds, modifies or removes |
| `openspec status --change <change>` | Which artifacts are done, and what to do next |
| `openspec new change <name>` | Create an empty change folder |
| `openspec instructions <artifact> --change <name>` | Instructions for writing the next artifact (this is what AI agents read) |
| `openspec validate <change> --strict` | Check the change's structure (use it in CI) |
| `openspec validate --all` | Check every change and spec |
| `openspec archive <change> --yes` | Merge the deltas into `specs/` and move the change to `archive/` |

**Slash commands for AI agents** (set up by `openspec init`):

| Command | What the agent does |
|---|---|
| `/opsx:explore` | Talks through an idea with you, without writing any files |
| `/opsx:propose` | Writes the proposal, specs, design and tasks in one go |
| `/opsx:apply` | Implements the tasks and ticks them off |
| `/opsx:verify` | Checks the code against the specs |
| `/opsx:archive` | Archives the finished change |

---

## 6. Use it in your own repo

```sh
cd your-repo
openspec init --tools claude          # or: github-copilot, cursor, codex, all, none
```

This creates `openspec/` and installs the slash commands for the tools you pick. Next:

1. **Put team rules in `openspec/config.yaml`**, so every new proposal follows them:
   ```yaml
   schema: spec-driven
   context: |
     All cloud resources must carry owner and cost-center tags.
     Production changes must include a rollback plan in design.md.
     No long-lived cloud credentials; use OIDC.
   rules:
     tasks:
       - Every task ends with a concrete verify step
   ```
2. **Add a spec check to CI**, so a malformed spec fails the PR:
   ```yaml
   - run: npm install -g @fission-ai/openspec
   - run: openspec validate --all --strict
   ```
3. **Review the change folder in the PR before the code.** Agreeing on the Markdown is much cheaper than rewriting the implementation.
4. **Archive only after the change is running in production**, so `specs/` describes what is actually deployed.

---

## 7. Common mistakes

- **Scenarios that can't be tested.** "THEN the system is secure" can't be checked. "THEN a request from the internet is denied" can. If you can't turn a THEN into an assertion, rewrite it.
- **A partial MODIFIED block.** When archived, a MODIFIED block replaces the whole requirement. Copy the full requirement with all of its scenarios, then edit it.
- **Requirements without SHALL or MUST.** Strict validation fails them.
- **One huge change.** If the proposal lists 15 capabilities, split it. Example 1, with six, is already at the upper end.
- **Archiving too early.** Archived changes update `specs/`, so if you archive before the change ships, the specs describe something that doesn't exist yet.
- **Putting the "how" in specs.** Specs say what must be true. Tool choices such as Trivy or OIDC belong in `design.md`.

---

## FAQ

**Is this only for AI-assisted work?** No. The CLI and file format work fine on their own. AI agents get more out of it because the spec keeps them on track.

**Isn't this just a design doc?** It's closer to a design doc that the CLI can check. Requirements and scenarios follow a fixed structure, the CLI validates them, and archiving keeps `specs/` up to date.

**Does it replace Terraform tests or pipeline gates?** No. It tells you which tests and gates you need. Each scenario should map to one of them, as the tracing tables in each example show.

**Are the examples deployable?** They're realistic but not production-ready. Every subscription ID, address and email in `*.tfvars` is a placeholder (`00000000-...`, `TODO`). The workflow files live inside the example folders, so GitHub won't run them.
