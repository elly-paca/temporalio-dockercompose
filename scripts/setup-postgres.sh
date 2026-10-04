#!/bin/sh
# Creates/upgrades the Temporal and visibility schemas. Idempotent: safe to run
# on every `docker compose up`, and it applies new schema versions when
# TEMPORAL_VERSION is bumped.
set -eu

: "${POSTGRES_SEEDS:?POSTGRES_SEEDS is required}"
: "${POSTGRES_USER:?POSTGRES_USER is required}"
: "${POSTGRES_PWD:?POSTGRES_PWD is required}"
DB_PORT=${DB_PORT:-5432}
DBNAME=${DBNAME:-temporal}
VISIBILITY_DBNAME=${VISIBILITY_DBNAME:-temporal_visibility}
SCHEMA_DIR=/etc/temporal/schema/postgresql/v12

export SQL_PASSWORD="$POSTGRES_PWD"

sql() {
  temporal-sql-tool --plugin postgres12 --ep "$POSTGRES_SEEDS" -p "$DB_PORT" -u "$POSTGRES_USER" "$@"
}

echo "Waiting for PostgreSQL at $POSTGRES_SEEDS:$DB_PORT..."
until nc -z -w 5 "$POSTGRES_SEEDS" "$DB_PORT"; do sleep 2; done

for pair in "$DBNAME:temporal" "$VISIBILITY_DBNAME:visibility"; do
  db=${pair%%:*}
  schema=${pair##*:}
  echo "Setting up database '$db' ($schema schema)"
  sql --db "$db" create
  sql --db "$db" setup-schema -v 0.0
  sql --db "$db" update-schema -d "$SCHEMA_DIR/$schema/versioned"
done

echo "PostgreSQL schema setup complete"
