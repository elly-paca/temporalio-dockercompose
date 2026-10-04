# syntax=docker/dockerfile:1
#
# Thin layers over the official Temporal images that bake in this repo's
# dynamic config and setup scripts, so the VM only needs the built images,
# docker-compose.yml and .env (no bind-mounted config).
#
# Server and admin-tools MUST be the same version: admin-tools carries the
# schema files that the server version expects.
ARG TEMPORAL_VERSION=1.32.0

# ---- schema setup / namespace bootstrap / admin shell -----------------------
FROM temporalio/admin-tools:${TEMPORAL_VERSION} AS admin-tools
COPY --chmod=755 scripts/ /scripts/

# ---- server -----------------------------------------------------------------
FROM temporalio/server:${TEMPORAL_VERSION} AS server
COPY --chown=temporal:temporal dynamicconfig/ /etc/temporal/config/dynamicconfig/
ENV DYNAMIC_CONFIG_FILE_PATH=/etc/temporal/config/dynamicconfig/production.yaml
