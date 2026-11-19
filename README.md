# openspec-examples

Two examples of using [OpenSpec](https://github.com/Fission-AI/OpenSpec) (spec-driven development) for DevOps work. In each folder, an OpenSpec change (proposal, specs, design and tasks) sits next to the code it drives.

| Example | What it builds | OpenSpec change | Status |
|---|---|---|---|
| [Example 1](Example%201/) | Terraform platform on Azure (Dev/UAT/Prod) with nothing reachable from the public internet: VNet, internal App Gateway WAF v2, App Service, PostgreSQL, Key Vault, managed identity, monitoring | `azure-production-infrastructure` (6 capabilities) | 7/18 tasks |
| [Example 2](Example%202/) | GitHub Actions pipeline to AWS ECS: tests, security scans, immutable images, Alembic migrations, staged promotion with approval, health checks, auto-rollback | `production-cicd-pipeline` (3 capabilities) | 5/18 tasks |

## Layout

```
Example N/
  openspec/
    config.yaml
    changes/<change>/
      proposal.md        # why, what changes, impact
      specs/*/spec.md    # SHALL requirements + WHEN/THEN scenarios
      design.md          # decisions, rejected alternatives, risks
      tasks.md           # checklist, each task with a verify step
  ...                    # Terraform / workflows / app code implementing it
```

## Try it

```sh
npm install -g @fission-ai/openspec
cd "Example 1"
openspec list
openspec show azure-production-infrastructure
openspec validate --all
```

All values in `*.tfvars` are placeholders (`00000000-...`, `TODO`). Fill them in before applying anything.
