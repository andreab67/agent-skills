# loki-best-practices

[![View on skills.sh](https://img.shields.io/badge/skills.sh-loki--best--practices-blue)](https://skills.sh/andreab67/agent-skills/loki-best-practices)

Production-grade Grafana Loki operations skill. Primes Claude with the SRE mindset, diagnostic commands, and playbooks needed to work effectively on live Loki clusters.

## Install

```bash
npx skills add andreab67/agent-skills@loki-best-practices -g -y
```

## What it does

Transforms Claude into a Loki SRE: rather than generic LogQL help, you get hypothesis-driven diagnosis rooted in `loki_discarded_samples_total{reason}`, runnable curl/kubectl/logcli commands, explicit safety warnings before destructive operations (forgetting ring members, removing WAL segments, disabling S3 lifecycle rules), and per-surface playbooks for ingestion, deployment, integration, query performance, storage, and HA.

## Capabilities

| Area | What you get |
| --- | --- |
| **Ingest diagnosis** | Reason-keyed triage table for `rate_limited`, `per_stream_rate_limit`, `stream_limit`, `out_of_order`, `too_far_behind`, `line_too_long`, `greater_than_max_sample_age`, `invalid_labels`; fix vs. prevention guidance for each |
| **WAL & flushing** | Recovery for stuck/corrupt WAL replay, full PVC, OOM during replay, `replay_memory_ceiling` tuning; chunk-flush failure diagnosis when object storage breaks silently |
| **Deployment & config** | Helm chart deployment-mode collision, schema period 24h requirement, TSDB migration without losing pre-migration data, RF vs ingester-count math, SimpleScalable storage requirements |
| **Integration** | Grafana "No data" with healthy querier, multi-tenant `X-Scope-OrgID` semantics, Promtail positions persistence, OTel structured metadata, OTel exporter `endpoint` pitfalls (`/v1/logs` 404), memberlist DNS and NetworkPolicy gotchas |
| **Query performance** | "too many outstanding requests" capacity formula, `max_query_length` triage order (selector → split → bytes → length), high-cardinality label hunt with `logcli --analyze-labels`, regex-vs-substring rewrite patterns |
| **Storage** | IRSA / WebIdentity diagnosis, S3 lifecycle vs. retention conflict, compactor stuck-state, `context deadline exceeded` triage, index-gateway cache hit ratio targets |
| **HA** | UNHEALTHY ring entries, ungraceful-shutdown recovery, schema-boundary rolling upgrades, compactor singleton enforcement, ruler HA + sharding, memberlist IP reuse and `cluster_label` isolation |
| **Observability of Loki** | The seven alerts every cluster should have, with PromQL ready to paste |

## Example prompts

- *"Our distributor is logging `rate limit exceeded for user fake` and Grafana is missing data. Walk me through the fix without dropping logs."*
- *"`loki_ingester_memory_streams` jumped from 5k to 80k overnight. What broke and how do I find it?"*
- *"The Loki StatefulSet won't start after a Helm upgrade — pod logs say `active schema or upcoming schema are not set to a period of 24h`. How do I recover?"*
- *"OTel collector is logging HTTP 404 with URL ending in `/loki/api/v1/push/v1/logs`. What did I configure wrong?"*
- *"We added an S3 lifecycle rule and now queries return `NoSuchKey` for chunks within retention. What do I do?"*
- *"Two ingesters showed up as UNHEALTHY in `/ring` after a node drain. Writes are returning 500. Safe to forget them?"*
- *"How do I tell if my compactor is actually applying retention, and what alert should I have on it?"*

## What it won't do

- Greenfield "Loki vs Elasticsearch / OpenSearch" architecture decisions — that's an upstream conversation
- Pick between Promtail and Alloy for a new install (use the Grafana Agent migration guide)
- Answer generic LogQL syntax questions with no operational context

## Assumptions

The skill assumes you are a **senior engineer** running Loki in Kubernetes, with at least one cluster already deployed. It skips intros to LogQL, chunks, and ingesters and jumps straight to evidence-driven workflow. If you want more explanatory output, say so in your prompt.

It also assumes Loki's official distroless container — diagnostic commands route through a sidecar (gateway nginx), `kubectl port-forward`, or an explicit `command:` array, never `sh -c` against the loki container itself.

## Related skills

- [`k8s-nextjs-deploy`](./k8s-nextjs-deploy.md) — Kubernetes deployment patterns (StatefulSets, PDBs, NetworkPolicies) Loki runs on top of
- [`postgres-ops`](./postgres-ops.md) — Postgres slow-query logs are a common Loki ingestion source
