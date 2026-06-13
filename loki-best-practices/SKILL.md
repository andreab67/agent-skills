---
name: loki-best-practices
description: Operational Grafana Loki workflows for production environments — diagnosing ingest rejections (rate_limited, per_stream_rate_limit, stream_limit, out_of_order, line_too_long, invalid_labels), WAL replay failures, stuck compactors, broken chunk flushing, schema/period misconfiguration, Helm deployment-mode collisions, IRSA/object-storage breakage, S3 lifecycle conflicts; tuning limits_config, runtime overrides, and per-tenant quotas; designing label sets that don't explode cardinality; debugging Promtail/Alloy/OTel push pipelines (4xx/429 responses, structured metadata rejections, `/loki/api/v1/push/v1/logs` 404s); fixing query performance (max_outstanding_requests, max_query_length, expensive regex, shardable parallelism); operating the ruler in HA; recovering ring/memberlist health (UNHEALTHY entries, IP reuse, ghost members); upgrading across schema-period boundaries; alerting on the right Loki metrics. Use this skill whenever the user mentions Loki, LogQL, Promtail, Alloy, log ingestion, log discards, `loki_discarded_samples_total`, `/ring`, WAL replay, compactor retention, chunk flushing, Loki Helm chart, log cardinality, "query length too large", "too many outstanding requests", "stream limit exceeded", or anything involving a Loki incident, push failure, slow query, schema upgrade, or HA problem — even if they don't say "Loki" explicitly but the context is clearly a Grafana-stack log pipeline. Do NOT use for greenfield log-shipping tooling decisions (pick the agent first) — this skill assumes Loki is already deployed.
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

If the rate is non-zero, the `reason` label is the entire diagnosis. Map it:

| Reason | Root cause class | Fix path |
| --- | --- | --- |
| `rate_limited` | Tenant `ingestion_rate_mb` / `ingestion_burst_size_mb` exceeded | Runtime overrides per tenant, or scale distributors (global strategy) |
| `per_stream_rate_limit` | One hot stream > 3 MB/s | Split the stream at the agent with a discriminating label — do NOT just crank the limit |
| `stream_limit` | Active streams > `max_global_streams_per_user` (default 5000) | Find the high-cardinality label and drop it / move to structured metadata |
| `out_of_order` / `too_far_behind` | Clock skew, log replay, agent timestamp regex broken | Fix NTP first, then widen `out_of_order_time_window` if real |
| `line_too_long` | Line > `max_line_size` (default 256 KB) | Set `max_line_size_truncate: true`, or split at source |
| `greater_than_max_sample_age` | Entry > `reject_old_samples_max_age` (default 7d) | Per-tenant override for backfill, revert after |
| `invalid_labels` / `missing_labels` / `duplicate_label_names` | Agent pipeline bug (often OTel attribute names with dots) | Sanitize at the agent — any non-zero rate here is a config bug |

Default first-look commands (all of these are in the cheatsheet at the bottom — keep them in muscle memory):

```bash
# Discarded samples broken down by reason — the single most useful query
curl -s http://loki:3100/metrics | grep '^loki_discarded_samples_total' | sort -k 2 -n -r | head

# Ring health (any of: ingester, ruler, scheduler, index-gateway, compactor)
curl -s http://loki:3100/ring | grep -E "ACTIVE|LEAVING|UNHEALTHY"

# Current effective config (Loki dumps the resolved YAML)
curl -s http://loki:3100/config

# Runtime overrides (per-tenant limits hot-reloaded)
curl -s http://loki:3100/runtime_config

# Service status — which modules booted, which are degraded
curl -s http://loki:3100/services

# Per-tenant analyze — find the high-cardinality label
logcli series '{tenant="foo"}' --analyze-labels --since=1h

# Memberlist members — detect ghosts / IP reuse
curl -s http://loki:3100/memberlist
```

Note: Loki's official container image is distroless and has no shell. Run the curls from a sidecar (gateway nginx pod), via `kubectl port-forward svc/loki 3100:3100`, or by calling the binary with an explicit `command:` array — never `sh -c`.

### 2. Triage by failure surface

The playbook breaks into six surfaces. For every reported symptom, classify first, then look up the entry. Don't skip classification — it saves the wrong-rabbit-hole tax.

#### 2a. Ingestion (write path)

The chatty surface. Rejections surface as HTTP 4xx on `/loki/api/v1/push` and as counter increases on `loki_discarded_samples_total{reason}` and `loki_discarded_bytes_total{reason}`. Always check the `reason` label before deciding what to change.

- **Don't raise per-stream limits as a first move.** A single stream lives on one ingester; cranking `per_stream_rate_limit` OOMs that pod. Fix the label set instead.
- **`stream_limit` is almost always a high-cardinality label.** Run `logcli series '{tenant="..."}' --analyze-labels` — sort the output by uniques, find the label with thousands of values (request ID, trace ID, full URL path), drop it at the agent or move to structured metadata.
- **`out_of_order` after a Promtail restart** usually means the positions file wasn't persisted. Mount `positions.yaml` on a `hostPath` (DaemonSet) or PVC (Deployment).
- **WAL replay stuck** means either an OOMKill on startup (set `replay_memory_ceiling` to ~75% of pod memory so replay flushes early), a full PVC (expand it or move to a bigger node), or a corrupt segment (identify from the panic line, `rm` only that file, restart — RF covers the loss).
- **Chunks not flushing** while ingest is hot = object storage write failing silently. `kubectl logs ... | grep -i "failed to flush\|s3\|gcs\|azure"` and `kubectl exec` a test fetch against the bucket from the pod.

#### 2b. Deployment & configuration

First-install and version-bump landmines. Most manifest as Loki refusing to start (CrashLoopBackOff) or silently routing data to nowhere.

- **Helm deployment-mode collision** ("more than zero replicas for both single binary and simple scalable"): pick one — SingleBinary for < 1 TB/day, SimpleScalable for HA at scale, Distributed via the dedicated chart. Zero out the others explicitly.
- **Schema period must be 24h.** TSDB and modern boltdb-shipper require it. Don't edit the existing `period_config` — add a *new* entry with `from:` set to next UTC midnight and roll out the config before that date.
- **TSDB migration** that returns "no data" for pre-migration ranges: both `period_config` entries must share the same `object_store` and chunk path prefix. Keep the legacy `boltdb_shipper` block until the old period ages out of retention.
- **Replication factor exceeds healthy ingester count**: writes return `at least N live replicas required`. Match RF to ingester count (1 ingester → RF 1, 3 ingesters → RF 3) and use PDBs + topology spread so a rolling node upgrade can't take more than one ingester down.
- **`Cannot run Scalable targets without an object storage backend`**: SimpleScalable and Distributed need shared object storage. Filesystem is dev-only.
- **memcached chunk/results caches default to absurd sizes.** The `grafana/loki` chart ships `chunksCache.allocatedMemory: 8192` and `resultsCache.allocatedMemory: 1024` (MB). That number is *both* memcached's `-m` flag *and* the pod's memory request **and** limit, computed as `allocatedMemory × 1.2` Mi — so the chunk cache alone reserves `8192 × 1.2 = 9830Mi` and the two caches together pin **~11Gi per cluster**, scheduled whether or not your log volume justifies it. On a single-binary / home-scale deployment this is routinely the single largest memory reservation in the namespace, and because the cache pods are BestEffort-adjacent giants they're the first thing to block scheduling or evict neighbours (verified in the field: a 16Gi worker sitting at 89% MEM requests was almost entirely this one pod). Right-size to the working set — `chunksCache.allocatedMemory: 1024` + `resultsCache.allocatedMemory: 256` covers < ~50 GB/day and drops the footprint to ~1.5Gi. These keys deep-merge under `helm upgrade --reuse-values -f`, so the fix is a two-line values overlay; the StatefulSet's memcached `-m` and `resources` both move together. Set `enabled: false` only if you can tolerate cold object-storage reads on every query.

#### 2c. Integration

Loki rarely fails in isolation. Misalignment with Grafana, Promtail/Alloy, OTel, or Kubernetes networking presents as "missing data" rather than a clean error.

- **Grafana "No data"** with healthy querier: check time range, datasource URL (cluster-internal vs external), and `X-Scope-OrgID` header on multi-tenant clusters. The querier logs will show the query was received and returned 0 rows — that's the proof it's not a Loki problem.
- **OTel structured metadata rejected**: Loki < 3.0 requires `limits_config.allow_structured_metadata: true` AND schema `v13`. Always use the otlphttp exporter, never the legacy `loki` exporter (it appends `/v1/logs` incorrectly).
- **OTel `endpoint` misuse**: setting `endpoint: http://loki/loki/api/v1/push` makes the exporter append `/v1/logs` and you get a 404. Set `endpoint: http://loki/otlp` and let the exporter append, or use `logs_endpoint:` to override with the full path.
- **Memberlist DNS failures on startup**: confirm the service is headless (`clusterIP: None`) and that UDP+TCP 7946 is open in any NetworkPolicy. The chart ships a working memberlist Service — don't hand-write `join_members`.
- **NetworkPolicy blocking gossip/HTTP/gRPC**: bundle an `allow-loki-intracluster` policy permitting 7946, 3100, and 9095 between pods labeled `app.kubernetes.io/name: loki`.

#### 2d. Query performance

The read path is bound by index lookups, chunk decode, and querier parallelism. Slow queries are nearly always a label-cardinality or time-range-vs-shard interaction.

- **"too many outstanding requests"**: raise `query_scheduler.max_outstanding_requests_per_tenant` and `frontend.max_outstanding_per_tenant` together (both default 100). Enable `query_range.parallelise_shardable_queries: true`. Capacity formula: `max_outstanding >= panels × time_window/split × shards × users`.
- **"query length too large"**: narrow stream selectors first (moving `{namespace="prod"}` → `{namespace="prod", app="frontend"}` typically cuts bytes 10–100×). Tune `split_queries_by_interval: 15m`. Only then raise `max_query_length` and `max_querier_bytes_read`.
- **High-cardinality explosion**: `loki_ingester_memory_streams` climbs without log volume rising. Run `logcli series --analyze-labels` and you'll find a label with thousands of values. Drop it at the agent, restart ingesters to release dead streams.
- **Expensive regex**: replace `{app="x"} |~ ".*error.*"` with `{app="x"} |= "error"` — substring is much faster than regex. Put the cheapest filter first; LogQL evaluates left-to-right. Enable `query_range.results_cache` for repeat dashboards.

#### 2e. Storage backend

Object storage failures are insidious — the write side rarely surfaces them quickly. Chunks land in the WAL, the ingester thinks all is well, then flushing fails 30 minutes later.

- **S3 `WebIdentityErr` / IRSA failure**: confirm the service-account annotation, the trust policy's `system:serviceaccount:<ns>:<sa>` exactly matches, and the OIDC issuer URL matches AWS EKS's current value. Codify IRSA in Terraform next to the chart.
- **S3 lifecycle deleting active chunks**: Loki owns retention through the compactor, not S3 lifecycle rules. Audit `aws s3api get-bucket-lifecycle-configuration` and disable any rule shorter than `retention_period + 7d`. Already-deleted chunks are unrecoverable.
- **Compactor stuck**: requires `delete_request_store`, `working_directory` writable (use a PVC so marker files survive restart), index period 24h, exactly 1 replica. Alert on `time() - loki_compactor_apply_retention_last_successful_run_timestamp_seconds > 3600`.
- **`context deadline exceeded` on object storage**: check S3 for `503 SlowDown`, add a memcached chunk cache, confirm Loki and bucket are in the same region (cross-region multiplies latency 5–10×).
- **Index gateway slow**: run as StatefulSet + PVC so the local index cache survives restarts; target > 90% cache hit ratio via `loki_index_gateway_cache_hits_total`.

#### 2f. High availability

HA in Loki is a write-quorum game: ring health, RF math, and rolling upgrades that don't break either.

- **"too many unhealthy instances"**: ingester exited ungracefully (OOMKill, node loss, SIGKILL on drain). Go to `/ring` and click "Forget" for each UNHEALTHY entry (or POST `/ring?forget=<instance_id>`). Set `terminationGracePeriodSeconds: ≥ 600` and a PreStop hook calling `/ingester/shutdown`.
- **Rolling upgrade across schema boundary**: schema bumps and binary upgrades must be two separate releases, 48h apart. Pre-flight with `loki -verify-config` for both versions.
- **Compactor singleton conflict**: `compactor.replicas: 1`, PDB `minAvailable: 0`. Never run a compactor in two clusters against the same bucket.
- **Ruler HA**: enable ring-based sharding (`ruler.ring.kvstore.store: memberlist`, `ruler.enable_sharding: true`). Alert on `loki_ruler_rule_evaluation_failures_total > 0` and `time() - loki_ruler_last_evaluation_timestamp_seconds > 300`.
- **Memberlist IP reuse / ghost members**: set distinct `memberlist.cluster_label` per Loki cluster — gossip is rejected from mismatched labels.
- **Inconsistent reads after partial ingester loss**: do NOT forget an ingester until it has flushed (`/ingester/flush_handler`). If the PVC survives, spin up a replacement pod with the same PVC and let it replay the WAL.

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

The eight things that take down clusters most often. Memorize these — they cover the bulk of real incidents.

1. **Helm chart deployment-mode collision** — `singleBinary` and `simple-scalable` replicas both set; install hard-fails. Pick one.
2. **Schema period not 24h** on TSDB / modern boltdb-shipper — Loki refuses to start.
3. **S3 lifecycle policy shorter than retention** — silent data loss; Loki never sees the deletes coming.
4. **Replication factor exceeds healthy ingester count after a node drain** — writes 500 until the ring heals.
5. **IRSA / Workload Identity misconfigured** — chunks never flush; WAL fills; ingester eventually OOMs.
6. **High-cardinality label leaks** — request ID, trace ID, or full URL added as a label. Streams explode, queries melt.
7. **Compactor not actually running** (or running as two replicas) — retention silently broken.
8. **memcached cache `allocatedMemory` left at chart defaults** — `chunksCache` (8192) + `resultsCache` (1024) reserve ~11Gi *per cluster* regardless of log volume (request/limit = `allocatedMemory × 1.2` Mi). Not an outage, but the namespace's biggest memory hog — blocks scheduling and is first to evict neighbours. Right-size to the working set (1024 / 256).

## Diagnostic command cheatsheet

The 10 highest-value commands for triage. Save these — they cover ~80% of incident first-response.

```bash
# 1. Discarded samples broken down by reason — the single most useful query
curl -s http://loki:3100/metrics \
  | grep '^loki_discarded_samples_total' \
  | sort -k 2 -n -r | head

# 2. Ring health (any of: ingester, ruler, scheduler, index-gateway, compactor)
curl -s http://loki:3100/ring | grep -E "ACTIVE|LEAVING|UNHEALTHY"

# 3. Current effective config (Loki dumps the resolved YAML)
curl -s http://loki:3100/config

# 4. Runtime overrides (per-tenant limits hot-reloaded)
curl -s http://loki:3100/runtime_config

# 5. Service status — which modules booted, which are degraded
curl -s http://loki:3100/services

# 6. Per-tenant analyze — find the high-cardinality label
logcli series '{tenant="foo"}' --analyze-labels --since=1h

# 7. Memberlist members — detect ghosts / IP reuse
curl -s http://loki:3100/memberlist

# 8. Force a flush before draining an ingester (must hit the pod, not svc)
curl -s -X POST http://<ingester-pod-ip>:3100/ingester/flush_handler

# 9. Graceful shutdown — flushes WAL, leaves ring cleanly
curl -s -X POST http://<ingester-pod-ip>:3100/ingester/shutdown

# 10. CPU profile during a slow-query incident (30s)
curl -s "http://loki:3100/debug/pprof/profile?seconds=30" > loki-cpu.pprof
```

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
