# agent-skills

[![Browse on skills.sh](https://img.shields.io/badge/skills.sh-andreab67%2Fagent--skills-blue)](https://skills.sh/andreab67/agent-skills)

Personal collection of [agent skills](https://skills.sh/) for use with Claude Code and other LLM agents. Each skill is a reusable instruction set that primes the agent with domain knowledge, workflow patterns, and failure playbooks — so you don't have to re-explain the same context every session.

**Catalog:** <https://skills.sh/andreab67/agent-skills>

## Skills

| Skill | Docs | Description |
| ----- | ---- | ----------- |
| [`postgres-ops`](./postgres-ops/SKILL.md) | [docs](./docs/postgres-ops.md) | Production PostgreSQL operations: incident diagnosis, query plan analysis, HA/DR design, migrations, connection pooling, observability, and federal/DoD hardening (STIG, pgaudit, RLS). |
| [`nextjs-monorepo-ci`](./nextjs-monorepo-ci/SKILL.md) | [docs](./docs/nextjs-monorepo-ci.md) | GitLab CI/CD for Next.js monorepos: six-stage pipeline (validate → security → build → obfuscate → package → notify), Kaniko unprivileged builds, Semgrep, gitleaks, javascript-obfuscator, Harbor registry, IndexNow post-deploy ping. |
| [`k8s-nextjs-deploy`](./k8s-nextjs-deploy/SKILL.md) | [docs](./docs/k8s-nextjs-deploy.md) | Kubernetes deployment patterns for Next.js apps: Deployment/Service/Ingress manifests, Harbor pull secret rotation, Traefik + cert-manager TLS, Linkerd service mesh, multi-app namespaces, failure diagnosis (ImagePullBackOff, CreateContainerConfigError). |
| [`confluence-to-nextjs`](./confluence-to-nextjs/SKILL.md) | [docs](./docs/confluence-to-nextjs.md) | Migrate Atlassian Confluence pages to a self-hosted Next.js knowledge base: fetch via REST API v2, convert storage-format HTML to semantic JSX, anchor navigation, sticky table of contents, and Vitest test patterns. |
| [`ubuntu24-stig`](./ubuntu24-stig/SKILL.md) | [docs](./docs/ubuntu24-stig.md) | DISA STIG V1R1 hardening for Ubuntu 24.04 LTS on AWS EC2: OpenSCAP scanning with correct benchmark IDs, idempotent remediation shell script for MAC-2_Sensitive, auditd rules, SSH FIPS 140-3 ciphers, PAM lockout/pwquality, AIDE integrity monitoring, and AWS skip list. |
| [`login-gov`](./login-gov/SKILL.md) | [docs](./docs/login-gov.md) | Integrate applications with login.gov federal identity provider: OIDC authorization code flow, private_key_jwt client authentication, ACR value selection (auth-only, IAL2, facial-match, PIV/CAC), user attribute scopes, sandbox setup, token validation, and Partner Portal configuration. |
| [`arcgis-enterprise-k8s`](./arcgis-enterprise-k8s/SKILL.md) | [docs](./docs/arcgis-enterprise-k8s.md) | Deploy and operate ArcGIS Enterprise on Kubernetes 12.0: deployment profiles (Dev/Standard/Enhanced HA), EKS/AKS/GKE/OpenShift sizing, persistent volume planning, L4/L7 load balancer configuration, TLS requirements, upgrade procedures, and pod failure diagnosis. |
| [`loki-best-practices`](./loki-best-practices/SKILL.md) | [docs](./docs/loki-best-practices.md) | Production Grafana Loki operations: reason-keyed ingest-discard triage (`rate_limited`, `stream_limit`, `out_of_order`, `invalid_labels`), WAL replay and chunk-flush recovery, Helm deployment-mode and schema-period pitfalls, OTel/Promtail/Alloy push debugging, query-performance tuning (`max_outstanding_requests`, cardinality, regex rewrites), S3/IRSA and compactor retention, ring health and HA rolling upgrades, and the seven alerts every Loki cluster should have. |
| [`session-handoff`](./session-handoff/SKILL.md) | [docs](./docs/session-handoff.md) | Rescue critical session context to persistent auto-memory before `/clear`, `/compact`, or any conversation wipe. One-sentence rescue test (*would re-reading the repo recover this?*), six categories mapped to `user`/`feedback`/`project`/`reference`, hard exclusions for secrets and code-derivable facts, consistent slug-prefix tagging for retrieval, review-before-write via `AskUserQuestion`, conflict resolution against stale entries, anti-patterns gallery, and a worked end-to-end example. Optional `UserPromptSubmit` hook intercepts `/clear` for true auto-activation. |
| [`anthropic-sdk`](./anthropic-sdk/SKILL.md) | [docs](./docs/anthropic-sdk.md) | Anthropic Python SDK expert: Messages API, streaming, multi-turn tool use loop, `count_tokens()` pre-flight, prompt caching with `cache_control`, vision input, model selection (Opus 4.7 / Sonnet 4.6 / Haiku 4.5) with pricing table and cost estimation helper. |
| [`openai-sdk`](./openai-sdk/SKILL.md) | [docs](./docs/openai-sdk.md) | OpenAI Python SDK expert: chat completions, streaming, function calling with tool_call loop, JSON structured output, embeddings, tiktoken token counting with `count_message_tokens()` helper, GPT-4o/mini/o1/o3 pricing table, and cost estimation. |
| [`kilo-gateway`](./kilo-gateway/SKILL.md) | [docs](./docs/kilo-gateway.md) | Kilo.ai OpenAI-compatible gateway over 500+ models: `base_url="https://api.kilo.ai/api/gateway"`, BYOK setup (zero Kilo markup), `provider/model-name` routing format, Python/TypeScript/cURL/LangChain patterns, prompt-cache header, and free-model `:free` suffix. |
| [`openrouter`](./openrouter/SKILL.md) | [docs](./docs/openrouter.md) | OpenRouter unified API over 300+ models: OpenAI-compatible chat/streaming/JSON-mode, model fallbacks and `openrouter/auto` routing, sampling-parameter guide, plus account/analytics endpoints for dashboards — `/credits`, `/keys`, `/activity` (management-key-only, last-30-completed-UTC-days lag), beta `/analytics/query`, and the `/models` pricing catalog (full field reference). |

## Install

Install a single skill globally:

```bash
npx skills add andreab67/agent-skills@postgres-ops -g -y
npx skills add andreab67/agent-skills@nextjs-monorepo-ci -g -y
npx skills add andreab67/agent-skills@k8s-nextjs-deploy -g -y
npx skills add andreab67/agent-skills@confluence-to-nextjs -g -y
npx skills add andreab67/agent-skills@ubuntu24-stig -g -y
npx skills add andreab67/agent-skills@login-gov -g -y
npx skills add andreab67/agent-skills@arcgis-enterprise-k8s -g -y
npx skills add andreab67/agent-skills@loki-best-practices -g -y
npx skills add andreab67/agent-skills@session-handoff -g -y
npx skills add andreab67/agent-skills@anthropic-sdk -g -y
npx skills add andreab67/agent-skills@openai-sdk -g -y
npx skills add andreab67/agent-skills@kilo-gateway -g -y
npx skills add andreab67/agent-skills@openrouter -g -y
```

Or install all skills at once:

```bash
for skill in postgres-ops nextjs-monorepo-ci k8s-nextjs-deploy confluence-to-nextjs ubuntu24-stig login-gov arcgis-enterprise-k8s loki-best-practices session-handoff anthropic-sdk openai-sdk kilo-gateway openrouter; do
  npx skills add "andreab67/agent-skills@$skill" -g -y
done
```

## How skills work

Each skill lives in its own directory with a `SKILL.md` file. The frontmatter declares:

- **`name`** — used by the skills CLI for install/reference
- **`description`** — the trigger condition that tells the agent when to activate this skill

When a skill is active, the agent reads the full `SKILL.md` and follows its workflow, terminology, and failure patterns rather than relying on generic training data.

## Contributing

Bug reports, fixes, and new skills welcome — see [`CONTRIBUTING.md`](./CONTRIBUTING.md) for scope, layout, and PR conventions.

## License

BSD 3-Clause — see [LICENSE](./LICENSE)
