# Spec Delta

## Purpose

Promotes verified images through environments with human approval where required, confirms each release is healthy, and restores the last good version when it is not.

## ADDED Requirements

### Requirement: Staged promotion
The pipeline SHALL deploy to `staging` automatically after a successful `main` build and deploy to `production` only after staging succeeds.

#### Scenario: Staging success
- **WHEN** staging deploy and health checks pass
- **THEN** the production deploy becomes eligible and awaits approval

#### Scenario: Staging failure
- **WHEN** staging deploy or health checks fail
- **THEN** production is not deployed

### Requirement: Production approval
Production deployment MUST require approval from a designated reviewer before it starts.

#### Scenario: Awaiting approval
- **WHEN** the production job is reached
- **THEN** it pauses until a required reviewer approves or rejects

#### Scenario: Rejected
- **WHEN** a reviewer rejects the deployment
- **THEN** nothing is deployed to production

### Requirement: Post-deploy health checks
After each deploy the pipeline SHALL poll the application health endpoint and treat the release as healthy only if it returns success within a defined timeout.

#### Scenario: Healthy release
- **WHEN** the health endpoint returns success within the timeout
- **THEN** the deploy is marked successful

#### Scenario: Unhealthy release
- **WHEN** the health endpoint fails or times out
- **THEN** the deploy is marked failed and rollback starts

### Requirement: Automatic rollback
On a failed deploy or failed health check, the pipeline SHALL redeploy the last known good image and verify its health.

#### Scenario: Rollback succeeds
- **WHEN** a production deploy fails health checks
- **THEN** the previous image is restored, verified healthy, and the workflow still reports failure

#### Scenario: Manual rollback
- **WHEN** an operator triggers the rollback workflow with a target image tag
- **THEN** that image is deployed to the chosen environment and health-checked

### Requirement: Serialized deploys
The pipeline SHALL allow only one deploy per environment at a time.

#### Scenario: Overlapping deploys
- **WHEN** a deploy is already running for an environment
- **THEN** a newer one queues and does not run concurrently
