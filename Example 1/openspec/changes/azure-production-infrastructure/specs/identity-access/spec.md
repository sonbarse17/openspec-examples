# Spec Delta

## Purpose

Defines how workloads and deployers authenticate and are authorized, using managed identities and least-privilege RBAC instead of stored credentials.

## ADDED Requirements

### Requirement: Managed identity for workloads
The App Service and Application Gateway SHALL each use a user-assigned managed identity.

#### Scenario: No stored credentials
- **WHEN** the environment is deployed
- **THEN** no client secrets or passwords for these workloads exist in code, variables or state

### Requirement: Least-privilege RBAC
Role assignments SHALL be scoped to the specific resource and grant only the needed role.

#### Scenario: App reads secrets only
- **WHEN** the app identity is assigned on Key Vault
- **THEN** it holds Key Vault Secrets User and cannot modify secrets

#### Scenario: Gateway reads certificates
- **WHEN** the gateway identity is assigned on Key Vault
- **THEN** it can read the TLS certificate secret and nothing else

### Requirement: Keyless deployment identity
Terraform deployments SHALL authenticate via OIDC workload identity federation, with separate identities per environment.

#### Scenario: Dev identity isolation
- **WHEN** the Dev deploy identity runs against Prod
- **THEN** the operation is denied
