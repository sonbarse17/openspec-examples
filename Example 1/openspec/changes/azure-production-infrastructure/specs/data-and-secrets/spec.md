# Spec Delta

## Purpose

Defines storage of application data and secrets: a private PostgreSQL Flexible Server and a Key Vault, both reachable only over private endpoints.

## ADDED Requirements

### Requirement: Private PostgreSQL
PostgreSQL Flexible Server SHALL have public network access disabled, require TLS, and be reachable only through a private endpoint.

#### Scenario: Public connection refused
- **WHEN** a client outside the VNet connects to the server
- **THEN** the connection fails

### Requirement: Entra ID database authentication
The application SHALL authenticate to PostgreSQL with its managed identity; no static application password SHALL be used.

#### Scenario: Token-based login
- **WHEN** the app connects to the database
- **THEN** it authenticates with an Entra ID access token

### Requirement: Database resilience by environment
Prod SHALL enable zone-redundant HA and geo-redundant backups; Dev and UAT MAY use reduced redundancy. Backup retention SHALL be set per environment.

#### Scenario: Prod failover capability
- **WHEN** the primary zone fails in Prod
- **THEN** the server fails over to the standby

### Requirement: Private Key Vault
Key Vault SHALL have public network access disabled, use RBAC authorization, and enable soft-delete and purge protection.

#### Scenario: Secret deletion recoverable
- **WHEN** a secret is deleted
- **THEN** it remains recoverable for the retention period and cannot be purged early

### Requirement: Secrets via Key Vault references
Application secrets SHALL be supplied to App Service as Key Vault references, not plaintext app settings.

#### Scenario: Setting resolution
- **WHEN** the app starts
- **THEN** secret settings resolve from Key Vault using the managed identity
