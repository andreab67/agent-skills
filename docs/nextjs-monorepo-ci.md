# nextjs-monorepo-ci

GitLab CI/CD pipeline skill for Next.js monorepos. Knows the six-stage pipeline structure, its failure patterns, and the specific quirks of obfuscating standalone Next.js output and building with Kaniko.

## Install

```bash
npx skills add andreab67/agent-skills@nextjs-monorepo-ci -g -y
```

## What it does

Helps you build, fix, and extend a six-stage GitLab CI pipeline purpose-built for Next.js monorepos. The skill carries institutional knowledge about artifact path quirks, obfuscation exclusions that prevent runtime crashes, and Kaniko authentication — the kind of gotchas that take hours to debug from scratch.

## Pipeline stages

```
validate → security → build → obfuscate → package → notify
```

| Stage | What runs |
|-------|-----------|
| **validate** | ESLint, TypeScript type-check (`tsc --noEmit`), Vitest / Jest with JUnit reports |
| **security** | Semgrep SAST + secrets scan, gitleaks with public-token allowlists, Hadolint Dockerfile lint |
| **build** | `npm ci && npm run build` per app, artifacts include `.next/` and `public/` |
| **obfuscate** | `javascript-obfuscator` on `.next/standalone` — excludes Turbopack runtime and externals chunks |
| **package** | Kaniko unprivileged Docker builds, push to Harbor registry |
| **notify** | IndexNow POST to notify search engines of updated pages |

## Example prompts

- *"My CI job is failing with `cp: cannot stat 'apps/web/.next'`. What's wrong?"*
- *"How do I add our new `apps/kb` app to the existing pipeline?"*
- *"gitleaks is blocking our pipeline on an IndexNow key. How do I add it to the allowlist?"*
- *"Our Next.js app crashes with `ChunkLoadError: _0x… is not a function` after the obfuscate stage. What's happening?"*
- *"How do I switch from Docker-in-Docker to Kaniko builds?"*
- *"Show me how to configure the Harbor pull credentials for the Kaniko job."*

## Key gotchas covered

- **Artifact paths**: After `cd apps/web && npm run build`, CI artifact paths must be relative to `$CI_PROJECT_DIR` — a subsequent `cp` breaks this.
- **Obfuscation exclusions**: `*[turbopack]*` and `*[externals]*` chunks must be excluded or the server crashes at startup with a `ChunkLoadError`.
- **Kaniko auth**: Harbor credentials must be written to `/kaniko/.docker/config.json` in `before_script` using base64-encoded auth, not mounted as a Docker config.
- **`.dockerignore`**: Must NOT exclude `.next/` — the pre-built standalone output is the entire build context.
- **gitleaks allowlists**: IndexNow keys (32-char hex) and Google Analytics Measurement IDs look like secrets to gitleaks and need explicit regex allowlists.

## What it won't do

- GitHub Actions pipelines (different syntax and runner model)
- Non-Next.js Node.js apps
- Multi-cloud registry setups other than Harbor

## Related skills

- [`k8s-nextjs-deploy`](./k8s-nextjs-deploy.md) — deploy the Docker images this pipeline builds
- [`confluence-to-nextjs`](./confluence-to-nextjs.md) — if you're adding a `kb` app to the monorepo
