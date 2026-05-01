# agent-skills

Personal collection of [agent skills](https://skills.sh/) for use with Claude Code and other LLM agents. Each skill is a reusable instruction set that primes the agent with domain knowledge, workflow patterns, and failure playbooks — so you don't have to re-explain the same context every session.

## Skills

| Skill | Description |
|-------|-------------|
| [`postgres-ops`](./postgres-ops/SKILL.md) | Production PostgreSQL operations: incident diagnosis, query plan analysis, HA/DR design, migrations, connection pooling, observability, and federal/DoD hardening (STIG, pgaudit, RLS). |
| [`nextjs-monorepo-ci`](./nextjs-monorepo-ci/SKILL.md) | GitLab CI/CD for Next.js monorepos: six-stage pipeline (validate → security → build → obfuscate → package → notify), Kaniko unprivileged builds, Semgrep, gitleaks, javascript-obfuscator, Harbor registry, IndexNow post-deploy ping. |
| [`k8s-nextjs-deploy`](./k8s-nextjs-deploy/SKILL.md) | Kubernetes deployment patterns for Next.js apps: Deployment/Service/Ingress manifests, Harbor pull secret rotation, Traefik + cert-manager TLS, Linkerd service mesh, multi-app namespaces, failure diagnosis (ImagePullBackOff, CreateContainerConfigError). |
| [`confluence-to-nextjs`](./confluence-to-nextjs/SKILL.md) | Migrate Atlassian Confluence pages to a self-hosted Next.js knowledge base: fetch via REST API v2, convert storage-format HTML to semantic JSX, anchor navigation, sticky table of contents, and Vitest test patterns. |

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
for skill in postgres-ops nextjs-monorepo-ci k8s-nextjs-deploy confluence-to-nextjs; do
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
