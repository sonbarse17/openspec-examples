# Azure infrastructure (Terraform)

One root module, three environments. Code is identical; only `envs/<env>.tfvars` and `envs/<env>.backend.hcl` differ.

```
infra/
  main.tf variables.tf versions.tf   root stack
  address-plan.json                  VNet ranges per env (must not overlap; enforced + tested)
  modules/{network,identity,keyvault,database,app,gateway,monitoring,alerts}
  envs/{dev,uat,prod}.{tfvars,backend.hcl}
  bootstrap/                         one-time state storage + OIDC deploy identity (per env)
  scripts/create-db-principal.sh     one-time DB role for the app identity
  tests/                             terraform test (mocked provider, no Azure needed)
```

## CIDR plan (`address-plan.json`)

| Env | VNet | Gateway subnet (/24) | App integration (/24) | Private endpoints (/24) | Gateway IP |
|-----|------|------|------|------|------|
| dev | 10.10.0.0/16 | 10.10.0.0/24 | 10.10.1.0/24 | 10.10.2.0/24 | 10.10.0.10 |
| uat | 10.20.0.0/16 | 10.20.0.0/24 | 10.20.1.0/24 | 10.20.2.0/24 | 10.20.0.10 |
| prod | 10.30.0.0/16 | 10.30.0.0/24 | 10.30.1.0/24 | 10.30.2.0/24 | 10.30.0.10 |

## Local checks (no Azure needed)

```
cd infra && terraform init -backend=false
terraform fmt -check -recursive && terraform validate
for e in dev uat prod; do terraform test -var-file=envs/$e.tfvars; done
```

## First-time setup (per environment)

1. **Bootstrap** (Owner rights): `cd bootstrap && terraform apply -var environment=dev -var subscription_id=<sub> -var project=myapp -var location=<region> -var github_repo=<owner/repo>`. Creates the state storage account (Entra-only auth, firewalled, versioned) and an OIDC deploy identity. Set the printed client id, tenant id and subscription id as GitHub Environment variables `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`; add required reviewers to the `prod` Environment.
2. **Fill TODOs** in `envs/<env>.tfvars` (subscription, region, owner/cost-center, client CIDRs, DB admin group, alert recipients).
3. **Subscription feature**: register `Microsoft.Network/EnableApplicationGatewayNetworkIsolation` (required for a private-only Application Gateway v2).
4. **Two-phase first apply** (the gateway needs the TLS cert, the cert needs the vault):
   `terraform apply -target=module.keyvault -target=module.network ...`, upload the PFX to the vault as a secret `agw-tls` (from a host with VNet access; the vault is private), put its versionless secret id in `tls_certificate_secret_id`, then a normal apply.
5. **DB principal** (from inside the VNet): `scripts/create-db-principal.sh <database_fqdn> <app identity name>` (identity name = `id-app-myapp-<env>`).

State/Key Vault/DB are private, so applies that touch data-plane items need a runner with network access (self-hosted runner in the VNet, or add its IP to `state_allowed_ips`).

## Operations runbook

- **Reaching the app**: HTTPS to the gateway private IP (output `gateway_private_ip`) from VPN/ExpressRoute/peered networks; point internal DNS at it.
- **Cert rotation**: upload a new version of `agw-tls`; the gateway polls the versionless id (~4 h).
- **Alerts**: 5xx, unhealthy gateway hosts, DB CPU/storage/failed connections, Key Vault 401/403 → action group `ag-myapp-<env>`. Prod severity 1 and optionally webhooks (`alert_webhook_uris`) for paging.
- **Prod safety**: Key Vault and PostgreSQL carry `CanNotDelete` locks (`enable_locks`); Key Vault has purge protection.
