# Proposal

## Why

There is no codified Azure hosting platform for our application. Without one, environments drift, secrets and databases risk public exposure, and nothing is observable. We need a repeatable, private-by-default, Terraform-managed platform for Dev, UAT and Production.

## What Changes

- New Terraform root + reusable modules provisioning, per environment: resource group, VNet with private subnets/NSGs, internal Application Gateway (WAF v2), App Service (Linux) with VNet integration, PostgreSQL Flexible Server, Key Vault, private endpoints + private DNS zones, user-assigned managed identity, Log Analytics / App Insights, Azure Monitor alerts.
- Per-environment `*.tfvars` (dev, uat, prod) differing only in SKU, redundancy, retention and CIDR sizing.
- Remote state in Azure Storage with per-environment state files.
- No public network access on App Service, PostgreSQL or Key Vault; no passwords/connection secrets in code or state where avoidable (Entra ID auth, Key Vault references).

## Capabilities

### New Capabilities
- `network-foundation`: VNet, private subnets, NSGs, private DNS zones, per-environment address space.
- `app-hosting`: App Service plan/app with VNet integration, private endpoint, and internal Application Gateway fronting it.
- `data-and-secrets`: PostgreSQL Flexible Server and Key Vault, both private-endpoint only.
- `identity-access`: Managed identities and RBAC role assignments (no stored credentials).
- `observability`: Log Analytics, Application Insights, diagnostic settings, metric/log alerts, action groups.
- `environment-delivery`: Dev/UAT/Prod parameterization, remote state, and the Terraform module/layout conventions.

### Modified Capabilities
<!-- None: greenfield project, no existing specs. -->

## Impact

- New directory `infra/` (Terraform modules, `envs/{dev,uat,prod}`), backend storage account, and a deploy identity (service principal/OIDC) with rights on target subscriptions.
- Requires Azure subscription(s), address-space plan, and internal DNS/connectivity (VPN/ExpressRoute/peering) for clients to reach the internal gateway.
- Ongoing Azure cost, dominated by Application Gateway WAF v2, PostgreSQL HA and Premium App Service in Prod.
