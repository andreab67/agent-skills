# k8s-nextjs-deploy

[![View on skills.sh](https://img.shields.io/badge/skills.sh-k8s--nextjs--deploy-blue)](https://skills.sh/andreab67/agent-skills/k8s-nextjs-deploy)

Kubernetes deployment skill for containerized Next.js applications. Covers the full manifest set, Harbor registry authentication, Traefik ingress with automatic TLS, and practical failure diagnosis.

## Install

```bash
npx skills add andreab67/agent-skills@k8s-nextjs-deploy -g -y
```

## What it does

Provides ready-to-use Kubernetes manifests and operational playbooks for running Next.js apps in a cluster. The skill knows the specific failure modes that arise with Harbor pull secrets, Traefik cert-manager TLS, and Linkerd sidecar injection — and carries the exact commands and ordering needed to recover.

## Coverage

| Topic | Details |
|-------|---------|
| **Manifests** | Deployment, Service, Ingress (Traefik + cert-manager), with resource requests/limits and security context |
| **Registry auth** | Harbor pull secret creation, rotation, and `rollout restart` after credential refresh |
| **TLS** | Traefik `ingressClassName`, cert-manager `cluster-issuer` annotation, multi-subdomain SAN |
| **Service mesh** | Linkerd sidecar injection via namespace annotation |
| **Env vars** | Required Next.js standalone env (`HOSTNAME=0.0.0.0`, `NODE_ENV`, `NEXT_TELEMETRY_DISABLED`, OTel settings) |
| **Multi-context** | `kubectl config get-contexts / use-context` for managing multiple clusters |
| **Namespace recovery** | Full apply order when a namespace is deleted (namespace → deployments → services → ingress → secrets) |

## Example prompts

- *"Our pods are stuck in `ImagePullBackOff`. How do I diagnose and fix this?"*
- *"I rotated the Harbor robot account token. How do I update the pull secret without downtime?"*
- *"Add a new subdomain `kb.example.com` to the existing Traefik ingress."*
- *"The namespace got accidentally deleted. Walk me through restoring everything in the right order."*
- *"One pod is in `CreateContainerConfigError`. What does that mean and how do I fix it?"*
- *"Show me a production-ready Next.js Deployment manifest with proper resource limits."*

## Common failure patterns

| Error | Cause | Fix |
|-------|-------|-----|
| `ImagePullBackOff` / `401 Unauthorized` | Stale or missing pull secret | Rotate pull secret → `rollout restart` |
| `repository does not exist` | Wrong image path or Harbor project name | Check project name matches image reference |
| `CreateContainerConfigError` | Missing `secretKeyRef` secret | Recreate the referenced K8s secret |
| Pod stuck after namespace delete | Namespace re-created but secrets not | Apply secrets before deployments |

## Prerequisites

- A running Kubernetes cluster with Traefik ingress controller and cert-manager installed
- A Harbor registry with a robot account
- `kubectl` configured with the correct context

## What it won't do

- Non-Kubernetes deployments (Docker Compose, Vercel, bare-metal)
- Stateful workloads like databases (requires StatefulSets — separate concern)
- Helm chart authoring

## Related skills

- [`nextjs-monorepo-ci`](./nextjs-monorepo-ci.md) — the CI pipeline that builds the images this skill deploys
- [`arcgis-enterprise-k8s`](./arcgis-enterprise-k8s.md) — deploying a more complex stateful application on Kubernetes
