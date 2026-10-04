# Temporal on a VM with Docker Compose

Single-node Temporal **1.32.0** (UI **2.55.0**) backed by PostgreSQL 16.
Postgres handles both persistence and (advanced) visibility, so there is no Elasticsearch.

| Service | Purpose |
|---|---|
| `postgresql` | Data store, named volume `postgres-data`, not published to the host |
| `temporal-schema-setup` | One-shot: creates/migrates schemas, exits 0 (idempotent) |
| `temporal` | All server roles in one process; gRPC on `7233` |
| `temporal-create-namespace` | One-shot: creates the default namespace (idempotent) |
| `temporal-ui` | Web UI on `8080` |
| `admin-tools` | On-demand CLI shell (`tools` profile) |

The `Dockerfile` builds two thin images on top of the official ones, with
`dynamicconfig/` and `scripts/` baked in, so nothing is bind-mounted from the host.

## Run

```bash
cp .env.example .env    # set POSTGRES_PASSWORD; review NUM_HISTORY_SHARDS (fixed after first boot)
docker compose up -d --build
docker compose ps -a    # setup/namespace jobs should show "Exited (0)"
```

- UI: `http://<vm>:8080`
- SDK/CLI: `<vm>:7233`
- CLI from the VM: `docker compose run --rm admin-tools temporal workflow list`

## Security

There is **no authentication and no TLS** on 7233 or 8080: anyone who can reach them
can read and start, terminate, or reset workflows. Restrict them with the cloud firewall
or security group. Docker-published ports bypass `ufw`/`firewalld` INPUT rules, so
host firewall rules won't block them. You can also set `BIND_ADDRESS` in `.env` to a
private IP or to `127.0.0.1`.

## Operations

- **Upgrade:** bump `TEMPORAL_VERSION` one minor at a time, then `docker compose up -d --build`.
  The schema job applies migrations before the server starts. Check the
  [release notes](https://github.com/temporalio/temporal/releases) for each step.
- **Dynamic config:** edit `dynamicconfig/production.yaml`, then rebuild and restart.
- **Backups:** `docker compose exec postgresql pg_dumpall -U temporal > backup.sql`
  (or snapshot the volume). Everything Temporal stores is in Postgres.
- **Logs:** the json-file driver rotates them at 5 × 50 MB per container.
