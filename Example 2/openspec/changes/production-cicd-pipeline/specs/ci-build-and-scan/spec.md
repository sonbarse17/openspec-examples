# Spec Delta

## Purpose

Ensures every change is built, tested and security-scanned the same way, and that only verified, immutable artifacts can reach deployment.

## ADDED Requirements

### Requirement: Automated build and test
The pipeline SHALL lint, test and build the application on every pull request and every push to `main`.

#### Scenario: Pull request check
- **WHEN** a pull request is opened or updated
- **THEN** lint and tests run and the result is reported as a required status check

#### Scenario: Failing tests block merge
- **WHEN** any test fails
- **THEN** the check fails and the change cannot be merged to `main`

### Requirement: Security scanning gates
The pipeline SHALL scan for vulnerable dependencies, committed secrets, insecure code patterns and container image vulnerabilities, and MUST fail on high or critical findings.

#### Scenario: Vulnerable dependency
- **WHEN** a dependency has a known high or critical vulnerability
- **THEN** the pipeline fails and no image is published

#### Scenario: Secret detected
- **WHEN** a commit contains a credential-like secret
- **THEN** the pipeline fails with the file and line identified

### Requirement: Immutable image publishing
The pipeline SHALL publish one container image per `main` commit to the registry, tagged with the commit SHA, and only after all checks pass.

#### Scenario: Successful publish
- **WHEN** all checks pass on `main`
- **THEN** an image tagged with the commit SHA is pushed and that exact image is what later stages deploy

#### Scenario: Checks failed
- **WHEN** any check fails
- **THEN** no image is pushed

### Requirement: Keyless cloud authentication
The pipeline SHALL authenticate to AWS using short-lived OIDC credentials and MUST NOT store long-lived AWS access keys.

#### Scenario: Role scoped to environment
- **WHEN** a job targets an environment
- **THEN** it can assume only that environment's role, and only from the permitted repository and branch
