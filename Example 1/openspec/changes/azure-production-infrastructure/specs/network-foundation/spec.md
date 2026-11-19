# Spec Delta

## Purpose

Defines the private network boundary for each environment: address space, subnets, traffic filtering and private name resolution, so that no workload is reachable from the public internet.

## ADDED Requirements

### Requirement: Isolated virtual network per environment
Each environment SHALL have its own VNet with a non-overlapping address space, taken from environment configuration.

#### Scenario: Non-overlapping address spaces
- **WHEN** Dev, UAT and Prod are planned
- **THEN** their VNet CIDR ranges do not overlap, and the plan fails validation if they do

### Requirement: Dedicated private subnets
The VNet SHALL contain separate subnets for the Application Gateway, App Service VNet integration and private endpoints.

#### Scenario: Subnet separation
- **WHEN** the network is deployed
- **THEN** each tier resides in its own subnet with its own network security group, except subnets Azure requires to be NSG-free

### Requirement: Default-deny traffic filtering
NSGs SHALL deny inbound traffic from the internet and allow only the flows required between tiers.

#### Scenario: Internet inbound blocked
- **WHEN** a client on the public internet connects to any subnet address
- **THEN** the connection is denied

### Requirement: Private DNS for private endpoints
Private DNS zones SHALL be linked to the VNet for every private-endpoint service type used.

#### Scenario: Private name resolution
- **WHEN** a resource inside the VNet resolves the Key Vault or PostgreSQL hostname
- **THEN** it receives the private endpoint IP, not a public IP
