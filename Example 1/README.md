# Example 1: Private-by-default Azure platform with Terraform

**Read [Example 2](../Example%202/README.md) first.** This example is bigger and shows how OpenSpec scales to infrastructure.

**The scenario:** there is no codified Azure platform, so environments drift and databases and secrets could be exposed to the public internet. This change specifies one Terraform codebase for Dev, UAT and Prod. It covers the VNet, an internal Application Gateway (WAF v2), App Service, PostgreSQL Flexible Server, Key Vault, managed identities and monitoring, and **nothing is reachable from the public internet**.

```sh
cd "Example 1"
openspec list                                  # azure-production-infrastructure  7/18 tasks
openspec status --change azure-production-infrastructure
openspec show azure-production-infrastructure
```

---

## Guided tour

### 1. [proposal.md](openspec/changes/azure-production-infrastructure/proposal.md)

- The infrastructure is split into **six capabilities**. Each one is something you can reason about and test on its own.
- **Impact** names the costs and prerequisites up front: Azure cost driven by WAF v2 and PostgreSQL HA, plus network connectivity for clients to reach an internal gateway.

### 2. Specs: one per capability

| Capability | File | Example requirement |
|---|---|---|
| `network-foundation` | [spec.md](openspec/changes/azure-production-infrastructure/specs/network-foundation/spec.md) | VNet address spaces must not overlap across environments |
| `app-hosting` | [spec.md](openspec/changes/azure-production-infrastructure/specs/app-hosting/spec.md) | App Service is reachable only through the internal gateway |
| `data-and-secrets` | [spec.md](openspec/changes/azure-production-infrastructure/specs/data-and-secrets/spec.md) | PostgreSQL and Key Vault are private-endpoint only |
| `identity-access` | [spec.md](openspec/changes/azure-production-infrastructure/specs/identity-access/spec.md) | Managed identities, no stored credentials |
| `observability` | [spec.md](openspec/changes/azure-production-infrastructure/specs/observability/spec.md) | Diagnostics and alerts for every resource |
| `environment-delivery` | [spec.md](openspec/changes/azure-production-infrastructure/specs/environment-delivery/spec.md) | Same code everywhere, isolated state, prod approval gate |

Notice how **infrastructure requirements become scenarios**:

```markdown
#### Scenario: Internet inbound blocked
- **WHEN** a client on the public internet connects to any subnet address
- **THEN** the connection is denied
```

Each scenario is written so it can become a `terraform test` assertion or a policy check.

### 3. [design.md](openspec/changes/azure-production-infrastructure/design.md)

These decisions are typical of an infrastructure design:

- *One root module with per-environment `tfvars` and `backend.hcl` files.* Rejected: Terraform workspaces, which isolate Prod less well, and three copied root directories, which drift apart.
- *PostgreSQL through a private endpoint, not delegated-subnet mode*, so every service is reached privately in the same way.
- *Prod protection uses `CanNotDelete` locks*, because `prevent_destroy` can't be set differently per environment. This is the kind of detail future maintainers need to know.

### 4. [tasks.md](openspec/changes/azure-production-infrastructure/tasks.md)

- The tasks are ordered by dependency: state, then network, then identity, then data, then app, then monitoring, then rollout.
- Every task has a verify step, such as "verify a test SQLi string returns 403 in UAT".
- 7 of 18 are done. The network, identity and data modules are written. The app module, gateway, monitoring and rollout tasks are still open.

---

## Tracing specs to code

| Requirement | Enforced by |
|---|---|
| No public access on App Service, PostgreSQL, Key Vault; gateway internal only | [infra/tests/private-by-default.tftest.hcl](infra/tests/private-by-default.tftest.hcl), run `no_public_access_anywhere` |
| Prod has high availability enabled | The same test file, run `prod_resilience` |
| Address spaces don't overlap | Validation in [modules/network](infra/modules/network/main.tf); ranges come from [address-plan.json](infra/address-plan.json) |
| No stored credentials | [modules/identity](infra/modules/identity/main.tf) (scoped RBAC); [modules/database](infra/modules/database/main.tf) sets `password_auth_enabled = false` |
| Isolated state per environment | [envs/*.backend.hcl](infra/envs/) and [bootstrap/](infra/bootstrap/main.tf) |
| Prod apply needs approval | [.github/workflows/terraform.yml](.github/workflows/terraform.yml) with Environment required reviewers |
| Same code in every environment | [envs/{dev,uat,prod}.tfvars](infra/envs/): only sizes and retention differ |

## Run the tests without Azure (optional)

The tests use a mocked provider, so you don't need an Azure account.

```sh
cd infra
terraform init -backend=false
terraform test
```

More detail on the Terraform layout is in [infra/README.md](infra/README.md).

Next: [EXERCISES.md](../EXERCISES.md).
