#!/bin/sh
# Registers the default namespace once the frontend is healthy. Idempotent.
set -eu

NAMESPACE=${DEFAULT_NAMESPACE:-default}
RETENTION=${DEFAULT_NAMESPACE_RETENTION:-72h}
export TEMPORAL_ADDRESS=${TEMPORAL_ADDRESS:-temporal:7233}
MAX_ATTEMPTS=${MAX_ATTEMPTS:-60}

attempt=1
until temporal operator cluster health >/dev/null 2>&1; do
  if [ "$attempt" -ge "$MAX_ATTEMPTS" ]; then
    echo "Temporal at $TEMPORAL_ADDRESS not healthy after $MAX_ATTEMPTS attempts" >&2
    exit 1
  fi
  echo "Waiting for Temporal at $TEMPORAL_ADDRESS (attempt $attempt/$MAX_ATTEMPTS)..."
  attempt=$((attempt + 1))
  sleep 5
done

if temporal operator namespace describe -n "$NAMESPACE" >/dev/null 2>&1; then
  echo "Namespace '$NAMESPACE' already exists"
else
  temporal operator namespace create -n "$NAMESPACE" --retention "$RETENTION"
  echo "Namespace '$NAMESPACE' created (retention $RETENTION)"
fi
