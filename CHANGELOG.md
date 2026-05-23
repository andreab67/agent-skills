# Changelog

## v1.1.1 — 2026-05-23

Discoverability pass. No skill content changes.

- **README:** added skills.sh catalog badge and explicit `https://skills.sh/andreab67/agent-skills` cross-link at the top.
- **README install list:** added missing one-liners for `ubuntu24-stig`, `login-gov`, and `arcgis-enterprise-k8s` (the loop snippet already covered them; the per-skill snippet did not).
- **Per-skill docs (`docs/*.md`):** added a `View on skills.sh` shield linking each skill to its catalog page so GitHub viewers can install in one click.

Background: the skills.sh directory is populated by install telemetry. The repo is installable directly with `npx skills add andreab67/agent-skills`, but per-skill search hits only appear once the index crawls them. These README changes lower the friction for the first wave of installs.

## v1.1 — add session-handoff skill

See git log for details.

## v1.0 — initial release

Initial 8-skill release: arcgis-enterprise-k8s, confluence-to-nextjs, k8s-nextjs-deploy, login-gov, nextjs-monorepo-ci, postgres-ops, ubuntu24-stig, plus the bootstrap docs.
