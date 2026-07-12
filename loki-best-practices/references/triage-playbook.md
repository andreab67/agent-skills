# Loki triage playbook — by failure surface

Consult this after classifying an incident into one of the six surfaces (see SKILL.md § "Triage by failure surface"). Each surface lists the symptoms, the proof to gather, and the fix.

## Ingestion (write path)

The chatty surface. Rejections surface as HTTP 4xx on `/loki/api/v1/push` and as counter increases on `loki_discarded_samples_total{reason}` and `loki_discarded_bytes_total{reason}`. Always check the `reason` label before deciding what to change.

- **Don't raise per-stream limits as a first move.** A single stream lives on one ingester; cranking `per_stream_rate_limit` OOMs that pod. Fix the label set instead.
- **`stream_limit` is almost always a high-cardinality label.** Run `logcli series '{tenant="..."}' --analyze-labels` — sort the output by uniques, find the label with thousands of values (request ID, trace ID, full URL path), drop it at the agent or move to structured metadata.
- **`out_of_order` after a Promtail restart** usually means the positions file wasn't persisted. Mount `positions.yaml` on a `hostPath` (DaemonSet) or PVC (Deployment).
- **WAL replay stuck** means either an OOMKill on startup (set `replay_memory_ceiling` to ~75% of pod memory so replay flushes early), a full PVC (expand it or move to a bigger node), or a corrupt segment (identify from the panic line, `rm` only that file, restart — RF covers the loss).
- **Chunks not flushing** while ingest is hot = object storage write failing silently. `kubectl logs ... | grep -i "failed to flush\|s3\|gcs\|azure"` and `kubectl exec` a test fetch against the bucket from the pod.

## Deployment & configuration

First-install and version-bump landmines. Most manifest as Loki refusing to start (CrashLoopBackOff) or silently routing data to nowhere.

- **Helm deployment-mode collision** ("more than zero replicas for both single binary and simple scalable"): pick one — SingleBinary for < 1 TB/day, SimpleScalable for HA at scale, Distributed via the dedicated chart. Zero out the others explicitly.
- **Schema period must be 24h.** TSDB and modern boltdb-shipper require it. Don't edit the existing `period_config` — add a *new* entry with `from:` set to next UTC midnight and roll out the config before that date.
- **TSDB migration** that returns "no data" for pre-migration ranges: both `period_config` entries must share the same `object_store` and chunk path prefix. Keep the legacy `boltdb_shipper` block until the old period ages out of retention.
- **Replication factor exceeds healthy ingester count**: writes return `at least N live replicas required`. Match RF to ingester count (1 ingester → RF 1, 3 ingesters → RF 3) and use PDBs + topology spread so a rolling node upgrade can't take more than one ingester down.
- **`Cannot run Scalable targets without an object storage backend`**: SimpleScalable and Distributed need shared object storage. Filesystem is dev-only.

## Integration

Loki rarely fails in isolation. Misalignment with Grafana, Promtail/Alloy, OTel, or Kubernetes networking presents as "missing data" rather than a clean error.

- **Grafana "No data"** with healthy querier: check time range, datasource URL (cluster-internal vs external), and `X-Scope-OrgID` header on multi-tenant clusters. The querier logs will show the query was received and returned 0 rows — that's the proof it's not a Loki problem.
- **OTel structured metadata rejected**: Loki < 3.0 requires `limits_config.allow_structured_metadata: true` AND schema `v13`. Always use the otlphttp exporter, never the legacy `loki` exporter (it appends `/v1/logs` incorrectly).
- **OTel `endpoint` misuse**: setting `endpoint: http://loki/loki/api/v1/push` makes the exporter append `/v1/logs` and you get a 404. Set `endpoint: http://loki/otlp` and let the exporter append, or use `logs_endpoint:` to override with the full path.
- **Memberlist DNS failures on startup**: confirm the service is headless (`clusterIP: None`) and that UDP+TCP 7946 is open in any NetworkPolicy. The chart ships a working memberlist Service — don't hand-write `join_members`.
- **NetworkPolicy blocking gossip/HTTP/gRPC**: bundle an `allow-loki-intracluster` policy permitting 7946, 3100, and 9095 between pods labeled `app.kubernetes.io/name: loki`.

## Query performance

The read path is bound by index lookups, chunk decode, and querier parallelism. Slow queries are nearly always a label-cardinality or time-range-vs-shard interaction.

- **"too many outstanding requests"**: raise `query_scheduler.max_outstanding_requests_per_tenant` and `frontend.max_outstanding_per_tenant` together (both default 100). Enable `query_range.parallelise_shardable_queries: true`. Capacity formula: `max_outstanding >= panels × time_window/split × shards × users`.
- **"query length too large"**: narrow stream selectors first (moving `{namespace="prod"}` → `{namespace="prod", app="frontend"}` typically cuts bytes 10–100×). Tune `split_queries_by_interval: 15m`. Only then raise `max_query_length` and `max_querier_bytes_read`.
- **High-cardinality explosion**: `loki_ingester_memory_streams` climbs without log volume rising. Run `logcli series --analyze-labels` and you'll find a label with thousands of values. Drop it at the agent, restart ingesters to release dead streams.
- **Expensive regex**: replace `{app="x"} |~ ".*error.*"` with `{app="x"} |= "error"` — substring is much faster than regex. Put the cheapest filter first; LogQL evaluates left-to-right. Enable `query_range.results_cache` for repeat dashboards.

## Storage backend

Object storage failures are insidious — the write side rarely surfaces them quickly. Chunks land in the WAL, the ingester thinks all is well, then flushing fails 30 minutes later.

- **S3 `WebIdentityErr` / IRSA failure**: confirm the service-account annotation, the trust policy's `system:serviceaccount:<ns>:<sa>` exactly matches, and the OIDC issuer URL matches AWS EKS's current value. Codify IRSA in Terraform next to the chart.
- **S3 lifecycle deleting active chunks**: Loki owns retention through the compactor, not S3 lifecycle rules. Audit `aws s3api get-bucket-lifecycle-configuration` and disable any rule shorter than `retention_period + 7d`. Already-deleted chunks are unrecoverable.
- **Compactor stuck**: requires `delete_request_store`, `working_directory` writable (use a PVC so marker files survive restart), index period 24h, exactly 1 replica. Alert on `time() - loki_compactor_apply_retention_last_successful_run_timestamp_seconds > 3600`.
- **`context deadline exceeded` on object storage**: check S3 for `503 SlowDown`, add a memcached chunk cache, confirm Loki and bucket are in the same region (cross-region multiplies latency 5–10×).
- **Index gateway slow**: run as StatefulSet + PVC so the local index cache survives restarts; target > 90% cache hit ratio via `loki_index_gateway_cache_hits_total`.

## High availability

HA in Loki is a write-quorum game: ring health, RF math, and rolling upgrades that don't break either.

- **"too many unhealthy instances"**: ingester exited ungracefully (OOMKill, node loss, SIGKILL on drain). Go to `/ring` and click "Forget" for each UNHEALTHY entry (or POST `/ring?forget=<instance_id>`). Set `terminationGracePeriodSeconds: ≥ 600` and a PreStop hook calling `/ingester/shutdown`.
- **Rolling upgrade across schema boundary**: schema bumps and binary upgrades must be two separate releases, 48h apart. Pre-flight with `loki -verify-config` for both versions.
- **Compactor singleton conflict**: `compactor.replicas: 1`, PDB `minAvailable: 0`. Never run a compactor in two clusters against the same bucket.
- **Ruler HA**: enable ring-based sharding (`ruler.ring.kvstore.store: memberlist`, `ruler.enable_sharding: true`). Alert on `loki_ruler_rule_evaluation_failures_total > 0` and `time() - loki_ruler_last_evaluation_timestamp_seconds > 300`.
- **Memberlist IP reuse / ghost members**: set distinct `memberlist.cluster_label` per Loki cluster — gossip is rejected from mismatched labels.
- **Inconsistent reads after partial ingester loss**: do NOT forget an ingester until it has flushed (`/ingester/flush_handler`). If the PVC survives, spin up a replacement pod with the same PVC and let it replay the WAL.
