# Loki command & discard-reason reference

Diagnostic commands and the `loki_discarded_samples_total{reason}` → fix mapping. SKILL.md points here from § "Diagnose like an SRE".

## Discard `reason` → root cause → fix

Group discards by `reason` — the label is the entire diagnosis:

```promql
sum by (reason) (rate(loki_discarded_samples_total[5m]))
```

| Reason | Root cause class | Fix path |
| --- | --- | --- |
| `rate_limited` | Tenant `ingestion_rate_mb` / `ingestion_burst_size_mb` exceeded | Runtime overrides per tenant, or scale distributors (global strategy) |
| `per_stream_rate_limit` | One hot stream > 3 MB/s | Split the stream at the agent with a discriminating label — do NOT just crank the limit |
| `stream_limit` | Active streams > `max_global_streams_per_user` (default 5000) | Find the high-cardinality label and drop it / move to structured metadata |
| `out_of_order` / `too_far_behind` | Clock skew, log replay, agent timestamp regex broken | Fix NTP first, then widen `out_of_order_time_window` if real |
| `line_too_long` | Line > `max_line_size` (default 256 KB) | Set `max_line_size_truncate: true`, or split at source |
| `greater_than_max_sample_age` | Entry > `reject_old_samples_max_age` (default 7d) | Per-tenant override for backfill, revert after |
| `invalid_labels` / `missing_labels` / `duplicate_label_names` | Agent pipeline bug (often OTel attribute names with dots) | Sanitize at the agent — any non-zero rate here is a config bug |

## Diagnostic command cheatsheet

The highest-value commands for triage — they cover ~80% of incident first-response.

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

Note: Loki's official container image is distroless and has no shell. Run the curls from a sidecar (gateway nginx pod), via `kubectl port-forward svc/loki 3100:3100`, or by calling the binary with an explicit `command:` array — never `sh -c`.
