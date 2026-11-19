# Spec Delta

## Purpose

Defines how Dev, UAT and Production are provisioned from one Terraform codebase with isolated state, differing only by configuration.

## ADDED Requirements

### Requirement: Single codebase, per-environment configuration
All environments SHALL be created from the same modules, differing only in variable values (SKUs, redundancy, CIDRs, retention).

#### Scenario: Environment parity
- **WHEN** a module change is applied to Dev, UAT then Prod
- **THEN** the same code runs in each and only variable values differ

### Requirement: Isolated remote state
Each environment SHALL use its own state file in an Azure Storage backend with locking and no public access.

#### Scenario: Concurrent apply
- **WHEN** two applies target the same environment
- **THEN** the second is blocked by the state lock

### Requirement: Validated and reviewed changes
Every change SHALL pass format check, validate and a reviewed plan before apply; Prod apply SHALL require manual approval.

#### Scenario: Prod approval gate
- **WHEN** a Prod plan is produced
- **THEN** apply does not proceed until an approver accepts it

### Requirement: Consistent naming and tagging
Resources SHALL follow one naming convention including environment, and carry environment, owner and cost-center tags.

#### Scenario: Untagged resource
- **WHEN** a resource lacks required tags
- **THEN** policy or validation flags it
