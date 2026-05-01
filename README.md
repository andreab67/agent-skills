# agent-skills

Personal collection of [agent skills](https://skills.sh/) for use with Claude Code and other LLM agents. Each skill is a reusable instruction set that primes the agent with domain knowledge, workflow patterns, and failure playbooks — so you don't have to re-explain the same context every session.

## Skills

| Skill | Description |
| ----- | ----------- |
| [`postgres-ops`](./postgres-ops/SKILL.md) | Production PostgreSQL operations: incident diagnosis, query plan analysis, HA/DR design, migrations, connection pooling, observability, and federal/DoD hardening (STIG, pgaudit, RLS). |
| [`nextjs-monorepo-ci`](./nextjs-monorepo-ci/SKILL.md) | GitLab CI/CD for Next.js monorepos: six-stage pipeline (validate → security → build → obfuscate → package → notify), Kaniko unprivileged builds, Semgrep, gitleaks, javascript-obfuscator, Harbor registry, IndexNow post-deploy ping. |
| [`k8s-nextjs-deploy`](./k8s-nextjs-deploy/SKILL.md) | Kubernetes deployment patterns for Next.js apps: Deployment/Service/Ingress manifests, Harbor pull secret rotation, Traefik + cert-manager TLS, Linkerd service mesh, multi-app namespaces, failure diagnosis (ImagePullBackOff, CreateContainerConfigError). |
| [`confluence-to-nextjs`](./confluence-to-nextjs/SKILL.md) | Migrate Atlassian Confluence pages to a self-hosted Next.js knowledge base: fetch via REST API v2, convert storage-format HTML to semantic JSX, anchor navigation, sticky table of contents, and Vitest test patterns. |
| [`ubuntu24-stig`](./ubuntu24-stig/SKILL.md) | DISA STIG V1R1 hardening for Ubuntu 24.04 LTS on AWS EC2: OpenSCAP scanning with correct benchmark IDs, idempotent remediation shell script for MAC-2_Sensitive, auditd rules, SSH FIPS 140-3 ciphers, PAM lockout/pwquality, AIDE integrity monitoring, and AWS skip list. |
| [`login-gov`](./login-gov/SKILL.md) | Integrate applications with login.gov federal identity provider: OIDC authorization code flow, private_key_jwt client authentication, ACR value selection (auth-only, IAL2, facial-match, PIV/CAC), user attribute scopes, sandbox setup, token validation, and Partner Portal configuration. |
| [`arcgis-enterprise-k8s`](./arcgis-enterprise-k8s/SKILL.md) | Deploy and operate ArcGIS Enterprise on Kubernetes 12.0: deployment profiles (Dev/Standard/Enhanced HA), EKS/AKS/GKE/OpenShift sizing, persistent volume planning, L4/L7 load balancer configuration, TLS requirements, upgrade procedures, and pod failure diagnosis. |

## Install

Install a single skill globally:

```bash
npx skills add andreab67/agent-skills@postgres-ops -g -y
npx skills add andreab67/agent-skills@nextjs-monorepo-ci -g -y
npx skills add andreab67/agent-skills@k8s-nextjs-deploy -g -y
npx skills add andreab67/agent-skills@confluence-to-nextjs -g -y
```

Or install all skills at once:

```bash
for skill in postgres-ops nextjs-monorepo-ci k8s-nextjs-deploy confluence-to-nextjs ubuntu24-stig; do
  npx skills add andreab67/agent-skills@$skill -g -y
done
```

## How skills work

Each skill lives in its own directory with a `SKILL.md` file. The frontmatter declares:

- **`name`** — used by the skills CLI for install/reference
- **`description`** — the trigger condition that tells the agent when to activate this skill

When a skill is active, the agent reads the full `SKILL.md` and follows its workflow, terminology, and failure patterns rather than relying on generic training data.

## License

BSD 3-Clause — see [LICENSE](./LICENSE)
