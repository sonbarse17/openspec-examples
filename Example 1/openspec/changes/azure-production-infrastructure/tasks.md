# Tasks

## 1. Repository and state bootstrap

- [x] 1.1 Create `infra/` layout (one root + modules, `envs/<env>.tfvars`/`.backend.hcl`) with pinned provider versions; verify `terraform init -backend=false` succeeds in each env
- [ ] 1.2 Provision per-environment remote state storage (private, locking, versioning) and deploy OIDC identities; verify `terraform init` against the backend and a state lock test
- [ ] 1.3 Add `fmt`, `validate`, `tflint` and `checkov` checks and a pipeline with a manual approval gate for Prod; verify a PR run passes and Prod apply waits for approval

## 2. Network foundation

- [x] 2.1 Implement `network` module (VNet, subnets, NSGs, private DNS zones + links) with CIDR-overlap validation; verify `terraform test` asserts no overlap and default-deny inbound
- [x] 2.2 Document the CIDR plan in `infra/README.md`; verified it matches `infra/address-plan.json` (CIDRs live there, not in tfvars)

## 3. Identity

- [x] 3.1 Implement `identity` module (app + gateway user-assigned identities, scoped RBAC); verify plan shows only Secrets User / required roles
- [x] 3.2 Verify no secret/password variables exist (`grep`/checkov check passes)

## 4. Key Vault and PostgreSQL

- [x] 4.1 Implement `keyvault` module (RBAC, purge protection, public access off, private endpoint, DNS); verify test asserts those properties
- [x] 4.2 Implement `database` module (Flexible Server, private endpoint, TLS, Entra auth, per-env HA/backup); verify test asserts public access disabled and Prod HA on
- [ ] 4.3 Document and script the one-time Entra DB principal setup; verify the app identity can connect in Dev

## 5. App Service and Application Gateway

- [ ] 5.1 Implement `app` module (plan, app, VNet integration, private endpoint, public access off, Key Vault references); verify direct public request is denied in Dev
- [ ] 5.2 Implement internal WAF_v2 gateway (private frontend, HTTPS listener with Key Vault cert, health probe, redirect); verify HTTPS from inside the network returns 200 and HTTP redirects
- [ ] 5.3 Confirm WAF mode per env (Detection in Dev, Prevention in UAT/Prod); verify a test SQLi string returns 403 in UAT

## 6. Observability

- [ ] 6.1 Implement `monitoring` module (Log Analytics, App Insights, diagnostic settings for all resources); verify logs from each resource appear in the workspace in Dev
- [ ] 6.2 Add alerts (5xx, unhealthy hosts, DB CPU/storage/failed connections, Key Vault failures) and per-env action groups; verify a forced failure in Dev fires a notification

## 7. Environment rollout

- [ ] 7.1 Apply Dev, then UAT, then Prod via pipeline; verify each plan is clean on a second run (no drift)
- [ ] 7.2 Add `prevent_destroy`/resource locks on Prod data resources; verify a destroy plan is rejected
- [ ] 7.3 Write runbook (access, DNS, cert rotation, alert response) in `infra/README.md`; verify a teammate can follow it to reach Dev

## Workflow follow-up

- Archive the change after Prod apply is verified.
