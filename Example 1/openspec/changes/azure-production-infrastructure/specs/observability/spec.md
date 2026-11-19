# Spec Delta

## Purpose

Defines telemetry collection and alerting so operators learn of failures and security-relevant events before users report them.

## ADDED Requirements

### Requirement: Central log workspace
Each environment SHALL have a Log Analytics workspace with retention set per environment.

#### Scenario: Retention applied
- **WHEN** the workspace is deployed
- **THEN** its retention equals the environment configuration value

### Requirement: Diagnostic settings
App Service, Application Gateway (including WAF logs), PostgreSQL and Key Vault SHALL send logs and metrics to the workspace.

#### Scenario: Key Vault audit
- **WHEN** a secret is read
- **THEN** an audit event appears in the workspace

### Requirement: Application telemetry
The App Service SHALL be connected to a workspace-based Application Insights instance.

#### Scenario: Request tracing
- **WHEN** the app serves a request
- **THEN** request and dependency telemetry is recorded

### Requirement: Actionable alerts
Alerts SHALL cover at minimum: HTTP 5xx rate, gateway unhealthy hosts, database CPU, storage and connection failures, and Key Vault access failures, routed to an action group.

#### Scenario: Backend unhealthy
- **WHEN** gateway unhealthy host count exceeds zero for the evaluation window
- **THEN** the action group notifies the configured recipients

### Requirement: Environment-specific alert routing
Prod alerts SHALL page the on-call recipients; Dev and UAT alerts SHALL notify non-paging recipients.

#### Scenario: Prod alert severity
- **WHEN** a Prod alert fires
- **THEN** it is delivered to the Prod on-call action group
