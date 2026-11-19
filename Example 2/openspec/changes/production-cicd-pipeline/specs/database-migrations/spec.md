# Spec Delta

## Purpose

Applies schema changes safely and predictably as part of a release, so the database and application versions never drift apart unnoticed.

## ADDED Requirements

### Requirement: Migrations run before traffic shift
The pipeline SHALL apply pending database migrations in the target environment before the new application version receives traffic.

#### Scenario: Pending migrations
- **WHEN** a deploy contains new migrations
- **THEN** they are applied once, in order, and the deploy continues only if they succeed

#### Scenario: No pending migrations
- **WHEN** the database is already at the latest revision
- **THEN** the step succeeds without changing the schema

### Requirement: Migration failure halts release
The pipeline MUST stop the deploy when a migration fails and MUST NOT shift traffic to the new version.

#### Scenario: Migration error
- **WHEN** a migration command exits with an error
- **THEN** the deploy stops, the previous version keeps serving, and the failure is reported

### Requirement: Backward-compatible migrations
Migrations SHALL be compatible with the previous application version so that rollback does not require reversing the schema.

#### Scenario: Rollback after migration
- **WHEN** a deploy is rolled back after migrations succeeded
- **THEN** the previous application version runs correctly against the migrated schema

### Requirement: Single concurrent migration
The pipeline SHALL prevent two migration runs against the same environment at the same time.

#### Scenario: Concurrent releases
- **WHEN** a second deploy to the same environment starts during a migration
- **THEN** it waits until the first finishes
