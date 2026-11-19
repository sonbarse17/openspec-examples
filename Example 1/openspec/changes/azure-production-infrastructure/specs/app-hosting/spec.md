# Spec Delta

## Purpose

Defines how the application is hosted and exposed: an App Service reachable only through an internal Application Gateway, never directly from the internet.

## ADDED Requirements

### Requirement: App Service without public access
The App Service SHALL have public network access disabled and be reachable only via a private endpoint.

#### Scenario: Direct public request rejected
- **WHEN** a request is sent to the App Service default hostname from the internet
- **THEN** access is denied

### Requirement: Outbound traffic through the VNet
The App Service SHALL use regional VNet integration for outbound calls to private resources.

#### Scenario: Reaching private PostgreSQL
- **WHEN** the app connects to the database hostname
- **THEN** the connection traverses the VNet to the database private endpoint

### Requirement: Internal Application Gateway
Traffic SHALL enter via an Application Gateway v2 with a private frontend IP only, no public IP, with WAF enabled.

#### Scenario: Internal client request
- **WHEN** a client with network line-of-sight sends HTTPS to the gateway private IP
- **THEN** the gateway forwards it to the App Service and returns the response

#### Scenario: Malicious request blocked
- **WHEN** a request matches a WAF managed rule in Prevention mode (UAT, Prod)
- **THEN** the gateway blocks it with HTTP 403

### Requirement: TLS enforcement
Client-facing and gateway-to-backend traffic SHALL use HTTPS with TLS 1.2 or higher, with certificates sourced from Key Vault.

#### Scenario: Plain HTTP
- **WHEN** a client connects over HTTP
- **THEN** it is redirected to HTTPS or refused

### Requirement: Backend health probing
The gateway SHALL probe the app health endpoint and route only to healthy backends.

#### Scenario: Unhealthy backend
- **WHEN** the health probe fails
- **THEN** the gateway returns 502/503 rather than routing to the failed backend
