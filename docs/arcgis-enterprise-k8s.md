# arcgis-enterprise-k8s

[![View on skills.sh](https://img.shields.io/badge/skills.sh-arcgis--enterprise--k8s-blue)](https://skills.sh/andreab67/agent-skills/arcgis-enterprise-k8s)

ArcGIS Enterprise on Kubernetes skill (version 12.0). Covers deployment profiles, node sizing, persistent volume planning, load balancer selection, TLS requirements, upgrade procedures, and pod failure diagnosis.

## Install

```bash
npx skills add andreab67/agent-skills@arcgis-enterprise-k8s -g -y
```

## What it does

Guides planning and execution of ArcGIS Enterprise Kubernetes deployments across EKS, AKS, GKE, OpenShift, Tanzu, and RKE2. The skill carries sizing tables, storage class recommendations per cloud, networking constraints (FQDN is immutable post-deploy), and the exact diagnostic commands for CrashLoopBackOff and storage failures.

## Supported platforms (v12.0)

EKS, AKS, GKE, Red Hat OpenShift (RHOS), VMware Tanzu, RKE2 — all requiring Kubernetes 1.32–1.33. x86_64 only; ARM is not supported.

## Deployment profiles

| Profile | Min nodes | Total vCPU | Total RAM | Use case |
|---------|-----------|-----------|-----------|----------|
| Enhanced Availability | 7 | 56 vCPU | 224 GiB | Production HA |
| Standard Availability | 4 | 32 vCPU | 128 GiB | Production single-site |
| Development | 3 | 24 vCPU | 96 GiB | Dev/test only |

**Per-node minimum**: 8 vCPU, 32 GiB RAM, 200 GiB root disk.

## Storage requirements

ArcGIS Enterprise requires multiple persistent volumes. Storage configuration cannot be changed without a full redeploy — plan before deploying.

| Data store | Storage type | Recommended class |
|------------|-------------|------------------|
| In-memory cache (Redis/Ignite) | Block SSD (RWO) | EKS: `gp3` / AKS: `managed-premium` / GKE: `pd-ssd` |
| Item packages | Block or Object (RWX) | Shared across pods |
| Relational DB (PostgreSQL ×2) | Block SSD (RWO) | Same as above |
| Spatiotemporal / index (Elasticsearch) | Block SSD (RWO) | Same as above |
| Queue (message broker) | Block (RWO) | Standard tier acceptable |

Use `gp3` (not `gp2`) on EKS. Use `reclaimPolicy: Retain` for all ArcGIS PVCs.

## Example prompts

- *"How many nodes do I need to run ArcGIS Enterprise on Kubernetes in production?"*
- *"What storage class should I use for ArcGIS PVCs on EKS?"*
- *"One of my ArcGIS pods is in CrashLoopBackOff. How do I diagnose it?"*
- *"Can I change the FQDN after deployment?"*
- *"Walk me through upgrading ArcGIS Enterprise Kubernetes from 11.x to 12.0."*
- *"What's the IP capacity I need to reserve in my VPC subnet for ArcGIS?"*
- *"Show me a StorageClass manifest for ArcGIS on EKS."*

## Critical constraints

- **FQDN is immutable** — set it to a real DNS name before deploying; changing it requires a full redeploy
- **x86_64 only** — ARM worker nodes are not supported
- **IP capacity** — initial deployment requires 47–66 pod IPs depending on profile; reserve extra for rolling upgrades
- **TLS** — FQDN must appear in both Common Name and SAN; self-signed certs are not supported in production
- **Scaling** — use the ArcGIS REST API or Manager UI to scale services, not `kubectl scale`

## Backup

Use cloud-native volume snapshots (EBS Snapshots on EKS, Managed Disk Snapshots on AKS) plus Esri's `webgisdr` tool for content backup. Always snapshot all PVCs before upgrades.

## Prerequisites

- Kubernetes cluster running 1.32–1.33 on a supported platform
- Valid ArcGIS Enterprise license file (`.json`) from [My Esri](https://my.esri.com)
- DNS name registered and resolvable before deployment
- Deployment scripts downloaded from My Esri
- Client workstation: RHEL 9, Ubuntu 24.04, or AlmaLinux 9

## What it won't do

- ArcGIS Enterprise traditional (Windows/Linux VM installer)
- ArcGIS Online (Esri-managed SaaS)
- ArcGIS Pro (desktop client)

## Related skills

- [`k8s-nextjs-deploy`](./k8s-nextjs-deploy.md) — general Kubernetes deployment patterns
- [`ubuntu24-stig`](./ubuntu24-stig.md) — OS hardening for worker nodes if self-managed
- [`login-gov`](./login-gov.md) — federal identity integration if fronting ArcGIS with login.gov
