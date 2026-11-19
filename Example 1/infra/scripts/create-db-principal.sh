#!/usr/bin/env bash
# One-time per environment: create the app's managed identity as a PostgreSQL role.
# Must run from inside the VNet (DB is private) as a member of the Entra DB admin group.
# Usage: create-db-principal.sh <db-fqdn> <identity-name> [database=postgres]
set -euo pipefail
host=$1; identity=$2; db=${3:-postgres}

# Harden: only allow identifier characters (identity name is interpolated into SQL).
[[ $identity =~ ^[A-Za-z0-9_-]+$ ]] || { echo "invalid identity name" >&2; exit 1; }

export PGPASSWORD
PGPASSWORD=$(az account get-access-token --resource-type oss-rdbms --query accessToken -o tsv)
admin=$(az ad signed-in-user show --query userPrincipalName -o tsv)

psql "host=$host dbname=$db user=$admin sslmode=require" -v ON_ERROR_STOP=1 <<SQL
SELECT * FROM pgaadauth_create_principal('$identity', false, false)
WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '$identity');
GRANT CONNECT ON DATABASE "$db" TO "$identity";
GRANT USAGE ON SCHEMA public TO "$identity";
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO "$identity";
SQL
