---
name: loki-best-practices
description: Operational Grafana Loki troubleshooting for already-deployed stacks — ingest rejections (rate/stream limits, out-of-order, line-too-long, invalid labels), WAL replay and chunk-flush failures, stuck compactors, ring/memberlist health, limits_config and per-tenant overrides, label cardinality, Promtail/Alloy/OTel push errors, slow LogQL queries, IRSA/object-storage breakage, and schema-period upgrades. Use whenever the user mentions Loki, LogQL, Promtail, Alloy, log ingestion or discards, `loki_discarded_samples_total`, the `/ring`, WAL replay, the Loki Helm chart, log cardinality, or any Loki incident, push failure, slow query, schema upgrade, or HA problem — even in a Grafana-stack log context that doesn't say "Loki". Do NOT use for greenfield log-tooling choices — this assumes Loki is already deployed. (Full trigger list and per-surface diagnostics are in the body's "When to use" section.)
---

# loki-best-practices

Production-grade Grafana Loki operations: diagnosis, performance, storage, HA, and observability. Assume the user is a senior engineer running Loki in Kubernetes — skip introductions to LogQL and chunks and go straight to evidence-driven SRE workflow.

## When to use

Trigger on operational Loki tasks:

- **Ingest incidents**: HTTP 429/4xx from distributor, `loki_discarded_samples_total` rising, push retries from Promtail/Alloy/OTel, "rate limit exceeded", "stream limit", "out of order", "too far behind", "line too long", "invalid labels".
- **WAL & flush failures**: ingester CrashLoopBackOff during replay, `loki_ingester_wal_replay_active` stuck at 1, `loki_ingester_chunks_flushed_total` flat while ingest is hot, OOMKilled on startup, full WAL PVC.
- **Deployment & config**: Helm chart `singleBinary` vs `simple-scalable` mode collisions, "schema period must be 24h", TSDB migration that hides pre-migration data, missing object-storage backend on scalable targets, replication-factor vs ingester-count mismatch.
- **Integration breakage**: Grafana datasource "No data" with active streams, multi-tenant `X-Scope-OrgID` returning partial results, Promtail positions lost on restart, OTel structured metadata rejected, OTel `endpoint` misconfigured (`/loki/api/v1/push/v1/logs` 404), memberlist DNS failures, NetworkPolicies blocking gossip/HTTP/gRPC.
- **Query performance**: "too many outstanding requests", `max_query_length` exceeded, `max_query_series` reached, high-cardinality label explosion, expensive `|~` regex without prior `|=` line filter, sharding/parallelism tuning.
- **Storage**: S3 `WebIdentityErr` / IRSA failures, S3 lifecycle deleting active chunks, compactor stuck or running as two replicas, `context deadline exceeded` on object storage, index-gateway slow chunk reads.
- **HA**: UNHEALTHY ring entries after node loss, ungraceful shutdown leaving stranded chunks, schema bump during rolling upgrade, two compactors running simultaneously, ruler firing in duplicate or not at all, memberlist IP reuse / ghost members.
- **Observability of Loki itself**: which metrics to alert on, what to scrape, what cache hit ratios to target.

Do NOT trigger for:

- Greenfield "should we use Loki or Elasticsearch / OpenSearch" decisions — that's an architecture conversation, not an ops skill.
- Choosing between Promtail and Alloy for a new install (use the Grafana Agent migration guide).
- Generic LogQL syntax questions ("what does `unwrap` do") with no operational context.

## Instructions

### 1. Diagnose like an SRE

For any Loki incident, follow hypothesis → evidence → fix → verification. Never propose a fix without naming the metric or endpoint that proves the diagnosis first.

**Always start at `loki_discarded_samples_total`** — the write path tells you almost everything. Group by `reason` and the failure mode tells you what to fix:

```promql
sum by (reason) (rate(loki_discarded_samples_total[5m]))
```

If the rate is non-zero, the `reason` label is the entire diagnosis — map each reason to its root-cause class and fix path in **[references/command-reference.md](references/command-reference.md#discard-reason--root-cause--fix)**. That file also carries the 10-command triage cheatsheet and the distroless-image caveat (run curls from a sidecar or `kubectl port-forward svc/loki 3100:3100`, never `sh -c` — the official image has no shell).

### 2. Triage by failure surface

The playbook breaks into six surfaces. Classify the symptom first, then look up the matching entry in **[references/triage-playbook.md](references/triage-playbook.md)** — each entry has the symptoms, the proof to gather, and the fix. Don't skip classification; it saves the wrong-rabbit-hole tax.

- **Ingestion (write path)** — 4xx on `/loki/api/v1/push`, `loki_discarded_samples_total{reason}` climbing; fix the label set before raising per-stream limits, persist Promtail positions, unstick WAL replay.
- **Deployment & configuration** — CrashLoopBackOff, Helm single-vs-scalable mode collision, 24h schema period, RF-vs-ingester-count math, missing object-storage backend.
- **Integration** — Grafana "No data" with a healthy querier, OTel `endpoint` 404s / structured-metadata rejections, memberlist DNS, NetworkPolicy gaps on 7946/3100/9095.
- **Query performance** — "too many outstanding requests", "query length too large", cardinality explosions, expensive `|~` regex before a `|=` filter.
- **Storage backend** — S3 `WebIdentityErr`/IRSA, S3 lifecycle deleting live chunks, stuck/duplicate compactor, cross-region latency.
- **High availability** — UNHEALTHY ring entries after node loss, schema-boundary rolling upgrades, compactor singleton conflict, ruler HA, flush-before-forget.

### 3. Label design is the load-bearing decision

Most Loki problems trace back to one label that should never have been a label. Treat these as code-review red lines:

- **Cap labels at ~10–15 per stream.** More than that and the index grows linearly with stream count.
- **Never label by:** request ID, trace ID, user ID, session ID, full URL path, hash, IP, or anything else that takes more than ~100 distinct values per workload.
- **Move variable values to structured metadata** (requires Loki ≥ 3.0, schema v13, `allow_structured_metadata: true`). It's queryable via `| label_format` at read time without bloating the index.
- **Treat any non-zero `loki_discarded_samples_total{reason="invalid_labels"}` rate as a config bug,** not background noise.

### 4. Runtime overrides over restarts

Per-tenant limits hot-reload from `overrides.yaml` — no restart needed. Verify a change took via `curl /runtime_config`.

```yaml
overrides:
  my-tenant:
    ingestion_rate_mb: 16
    ingestion_burst_size_mb: 32
    max_global_streams_per_user: 50000
```

Most Helm charts hot-reload the runtime ConfigMap via the `loki-sc-rules` sidecar or equivalent. Confirm before touching the StatefulSet.

### 5. Upgrade discipline

For Loki minor/patch upgrades:

- Read the [upgrade guide](https://grafana.com/docs/loki/latest/setup/upgrade/) for the target version, every time. Loki has historically been chatty about breaking changes in point releases.
- Validate both old and new configs with `loki -verify-config` in CI.
- For HA: roll one ingester at a time, watch the ring, wait for the new pod to reach ACTIVE before moving on. PDB `maxUnavailable: 1`.

For schema bumps:

- **Always set `from:` at least 24h in the future** (next UTC midnight is the safe default). Never backdate.
- Roll out the schema change first, on the old binary. Then upgrade the binary 48h later. Two separate releases.

For object-storage migrations:

- Both old and new `period_config` entries must point at the same chunk path or the old data becomes unreachable. Keep the legacy block until retention has aged out everything in it.

### 6. Observability of Loki itself

Bake these alerts in from day one:

- `rate(loki_discarded_samples_total[5m]) by (reason) > 0` — any reason except a brief blip is a config bug.
- `loki_ingester_wal_replay_active == 1 for 30m` — stuck WAL.
- `rate(loki_ingester_chunks_flushed_total[10m]) == 0 and rate(loki_distributor_lines_received_total[10m]) > 0` — object storage broken.
- `time() - loki_compactor_apply_retention_last_successful_run_timestamp_seconds > 3600` — compactor stalled.
- `loki_ingester_memory_streams > <cap>` — cardinality climbing toward limit.
- `cortex_query_frontend_queue_length > 100` — query saturation.
- `loki_ruler_rule_evaluation_failures_total > 0` — broken alert/recording rule.

Scrape Loki's own `/metrics` into the same Prometheus that scrapes the apps it ingests from. If Loki goes down, you still need to see why.

### 7. Output discipline

- Give complete, runnable commands — no placeholders for endpoint URLs, no `<your-bucket>` stubs without a comment showing how to compute it.
- Call out destructive operations explicitly (`POST /ring?forget=`, `rm` on WAL segments, disabling S3 lifecycle rules, `helm rollback`).
- For any limit-tuning recommendation, state the capacity math behind it (the `max_outstanding` formula, the per-stream-on-one-ingester memory implication, the cross-region latency multiplier).
- When uncertain about a Loki version's behavior, say so and name the version where the behavior changed. Loki has moved fast between 2.x → 3.x → 3.7.

## Most common pitfalls (top P1 hit list)

The seven things that take down clusters most often. Memorize these — they cover the bulk of real incidents.

1. **Helm chart deployment-mode collision** — `singleBinary` and `simple-scalable` replicas both set; install hard-fails. Pick one.
2. **Schema period not 24h** on TSDB / modern boltdb-shipper — Loki refuses to start.
3. **S3 lifecycle policy shorter than retention** — silent data loss; Loki never sees the deletes coming.
4. **Replication factor exceeds healthy ingester count after a node drain** — writes 500 until the ring heals.
5. **IRSA / Workload Identity misconfigured** — chunks never flush; WAL fills; ingester eventually OOMs.
6. **High-cardinality label leaks** — request ID, trace ID, or full URL added as a label. Streams explode, queries melt.
7. **Compactor not actually running** (or running as two replicas) — retention silently broken.

## Diagnostic command cheatsheet

The 10 highest-value triage commands — discards-by-reason, ring health, resolved config, runtime overrides, service status, `--analyze-labels`, memberlist, ingester flush/shutdown, and a CPU pprof — live in **[references/command-reference.md](references/command-reference.md#diagnostic-command-cheatsheet)**. They cover ~80% of incident first-response.

## Example prompts

- *"Our distributor is logging `rate limit exceeded for user fake` and Grafana is missing data. Walk me through the fix without dropping logs."*
- *"`loki_ingester_memory_streams` jumped from 5k to 80k overnight. What broke and how do I find it?"*
- *"The Loki StatefulSet won't start after a Helm upgrade — pod logs say `active schema or upcoming schema are not set to a period of 24h`. How do I recover?"*
- *"OTel collector is logging HTTP 404 with URL ending in `/loki/api/v1/push/v1/logs`. What did I configure wrong?"*
- *"We added an S3 lifecycle rule and now queries return `NoSuchKey` for chunks within retention. What do I do?"*
- *"Two ingesters showed up as UNHEALTHY in `/ring` after a node drain. Writes are returning 500. Safe to forget them?"*
- *"How do I tell if my compactor is actually applying retention, and what alert should I have on it?"*
- *"Promtail keeps re-reading every log file after a restart, and we're getting flooded with `too_far_behind` discards. Fix?"*

## Related skills

- [`k8s-nextjs-deploy`](../k8s-nextjs-deploy/SKILL.md) — Kubernetes deployment patterns (StatefulSets, PDBs, NetworkPolicies) Loki runs on top of
- [`postgres-ops`](../postgres-ops/SKILL.md) — Postgres slow-query logs are a common Loki ingestion source; see its observability section for the shipping pattern
