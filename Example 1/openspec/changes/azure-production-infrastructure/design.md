# Design

## Context

Greenfield Azure estate; no existing Terraform. See proposal.md for motivation and specs/ for requirements. Clients reach the app from a corporate network (VPN/ExpressRoute/peering) because the gateway is internal-only.

## Goals / Non-Goals

**Goals:**
- Private-by-default platform, identical across Dev/UAT/Prod except sizing.
- Zero stored credentials.

**Non-Goals:**
- Application code, CI for the app itself, multi-region DR, hub-spoke/ExpressRoute provisioning, custom domain DNS ownership.

## Decisions

- **Layout:** one root module in `infra/` + `infra/modules/{network,identity,keyvault,database,app,gateway,monitoring,alerts}`; per-env `envs/<env>.tfvars` + `envs/<env>.backend.hcl` (`terraform init -backend-config=...`) give separate state per env with zero duplicated code. Alt: Terraform workspaces — rejected (weaker Prod isolation); alt: three copied root dirs — rejected (drift). Prod protection is `CanNotDelete` locks (a `prevent_destroy` lifecycle cannot be conditional per env).
- **Provider:** `azurerm` (~> 4.x pinned), `azapi` only where azurerm lacks a feature.
- **Private connectivity:** private endpoints for App Service, Key Vault, PostgreSQL; PostgreSQL via private endpoint (not delegated-subnet mode) for a uniform pattern. Private DNS zones in the env VNet (zone ownership moves to a hub later if one exists).
- **Gateway:** Application Gateway WAF_v2, private frontend only. Note: v2 internal-only requires the `EnableApplicationGatewayNetworkIsolation` feature registration — verify per subscription. Backend = App Service private endpoint FQDN; TLS cert from Key Vault via gateway managed identity.
- **Identity:** user-assigned managed identities (created before consumers, avoiding RBAC propagation ordering issues). Key Vault in RBAC mode. DB uses Entra auth with the app identity as DB principal.
- **Deploy auth:** GitHub/Azure DevOps OIDC federation; one identity per env scoped to its subscription/resource group.
- **Env sizing (tfvars):** Dev: B/P1v3 single, burstable DB, WAF Detection, 30d logs. UAT: P1v3, GP DB no HA, WAF Prevention, 60d. Prod: P2v3 ×2 zone-redundant, GP DB zone-redundant HA + geo backup, WAF Prevention, 180d.
- **Tests:** `terraform validate`, `tflint`, `checkov`/`trivy config`, and `terraform test` with plan-level assertions for the no-public-access rules.

## Risks / Trade-offs

- Cost: WAF_v2 + HA DB in Prod is significant → smaller SKUs and autoscale in lower envs.
- Internal gateway feature registration/regional availability → check in Dev first.
- Private endpoint DNS misconfiguration is the most common failure → DNS zone links tested explicitly (resolution check task).
- Entra DB principal creation cannot be done by azurerm alone → one-time post-provision SQL step or script, documented.
- Deploy agent must reach private resources if it manages data-plane items (Key Vault secrets/certs) → use a self-hosted runner in the VNet or keep data-plane writes out of Terraform.

## Migration Plan

Greenfield: deploy Dev → UAT → Prod in order. Rollback = revert commit and re-apply; Key Vault and DB have soft-delete/backups, so destroy of Prod is guarded by `prevent_destroy` and resource locks.

## Open Questions

- Azure region(s) and subscription IDs; CIDR plan; CI platform (GitHub Actions vs Azure DevOps); alert recipients. These are tfvars/pipeline inputs and do not change the architecture.
