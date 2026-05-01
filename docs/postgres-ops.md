# postgres-ops

Production-grade PostgreSQL operations skill. Primes Claude with the SRE mindset, diagnostic queries, and playbooks needed to work effectively on live Postgres systems.

## Install

```bash
npx skills add andreab67/agent-skills@postgres-ops -g -y
```

## What it does

Transforms Claude into a Postgres SRE: rather than generic SQL help, you get hypothesis-driven diagnosis, runnable queries, explicit safety warnings before destructive operations, and per-workload reasoning for every tuning recommendation.

## Capabilities

| Area | What you get |
|------|-------------|
| **Incident diagnosis** | Ready-to-run queries for pg_stat_activity, blocking chains, pg_stat_statements top queries, bloat/vacuum status, replication lag |
| **Query plan analysis** | EXPLAIN ANALYZE interpretation: row-estimate vs actual mismatch, dominant cost node, buffer cache hit rate, index/rewrite/partitioning recommendations |
| **HA / DR design** | Streaming and logical replication, Patroni, pgBackRest, WAL-G, PITR planning, RTO/RPO validation |
| **Schema migrations** | Forward + rollback DDL, table-rewrite detection, expand-contract zero-downtime patterns, EF Core / Alembic / Flyway / Flyway / raw SQL |
| **Major version upgrades** | pg_upgrade (in-place) vs logical replication cutover comparison, extension compatibility check |
| **Connection pooling** | pgBouncer transaction-mode math, RDS Proxy, PgCat, prepared-statement caveats |
| **Security & compliance** | Role design, RLS, pgaudit, TLS enforcement, STIG/SRG line-item guidance, CIS benchmark gaps |
| **Observability** | postgres_exporter, pg_stat_statements, auto_explain, Loki log shipping, Grafana dashboard structure, SLO definition |

## Example prompts

- *"We have a query that's taking 30 seconds in prod. Here's the EXPLAIN ANALYZE output — what's wrong?"*
- *"Our Postgres instance hit max_connections. Walk me through diagnosing the cause and fixing it without downtime."*
- *"I need to add a NOT NULL column to a 200M-row table without locking. What's the expand-contract pattern for this?"*
- *"We're upgrading from Postgres 14 to 16. What's the fastest upgrade path and what should I check first?"*
- *"Help me size pgBouncer pool for 50 app replicas hitting a single Postgres primary."*
- *"Our DISA STIG audit is next week. What are the Postgres controls I need to have in place?"*

## What it won't do

- Scaffold new CRUD features — use `nextjs-react-postgres-builder` for that
- Answer generic SQL language questions with no operational context (e.g., "what does LATERAL do")
- Cover other database engines (MySQL, SQL Server, Cosmos DB)

## Assumptions

The skill assumes you are a **senior engineer** working on a production system. It skips introductory explanations and jumps straight to evidence-driven workflow. If you want more explanatory output, say so in your prompt.

## Related skills

- [`k8s-nextjs-deploy`](./k8s-nextjs-deploy.md) — if your Postgres is running in Kubernetes
- [`ubuntu24-stig`](./ubuntu24-stig.md) — OS-level STIG hardening for the server running Postgres
