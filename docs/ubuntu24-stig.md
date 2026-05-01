# ubuntu24-stig

DISA STIG V1R1 hardening skill for Ubuntu 24.04 LTS on AWS EC2. Knows the exact OpenSCAP benchmark IDs, the AWS-specific skip list, and carries an idempotent remediation script for the MAC-2_Sensitive profile.

## Install

```bash
npx skills add andreab67/agent-skills@ubuntu24-stig -g -y
```

## What it does

Guides you through scanning an Ubuntu 24.04 EC2 instance with OpenSCAP, interpreting results, and applying remediation — either rule by rule or via the bundled `remediate-mac2-sensitive.sh` script. The skill knows which rules are inapplicable on headless EC2 (no GUI, no PIV/CAC, AWS-managed boot) and includes the exact `auditd`, SSH, PAM, and sysctl fixes with their STIG rule IDs.

## Bundled files

| File | Purpose |
|------|---------|
| `remediate-mac2-sensitive.sh` | Idempotent shell script applying the full MAC-2_Sensitive profile; skips AWS-inapplicable rules automatically |

## Coverage

| Category | Rules addressed |
|----------|----------------|
| **auditd** | Installation, service enablement, audit rules for identity files, privilege escalation, sudoers, module loading, file attribute changes, file access |
| **SSH** | FIPS 140-3 ciphers, MACs, KexAlgorithms; client and server configs in drop-in files |
| **PAM** | `pwquality` (minlen 15, complexity requirements, difok 8), `faillock` (3 attempts, permanent lock) |
| **AIDE** | Installation, initial database build, daily cron check |
| **sysctl** | `kernel.dmesg_restrict`, `net.ipv4.tcp_syncookies` |
| **System hygiene** | Password aging, session timeout (TMOUT=600), concurrent session limit, Ctrl-Alt-Delete mask, USB storage disable |
| **Permissions** | auditd config file permissions, journalctl permissions, root login lock |

## Example prompts

- *"How do I run an OpenSCAP SCAP scan on Ubuntu 24.04 with the DISA STIG benchmark?"*
- *"My scan is failing with `Failed to locate a datastream`. What's the correct benchmark ID?"*
- *"STIG rule SV-270690 failed — how do I configure PAM lockout after 3 failed attempts?"*
- *"Which STIG rules should I skip on an AWS EC2 instance?"*
- *"How do I configure SSH FIPS 140-3 ciphers for Ubuntu 24.04?"*
- *"Walk me through setting up AIDE integrity monitoring."*

## AWS EC2 skip list

These rules are automatically skipped as inapplicable on headless EC2:

| Rule | Reason |
|------|--------|
| SV-270692 | Graphical logon banner — no desktop environment |
| SV-270674, SV-270675 | Session lock / GRUB password — AWS console manages boot |
| SV-270721, SV-270722 | Smartcard SSH — PIV/CAC not used on EC2 |
| SV-270672, SV-270673 | PIV credentials — no smartcard reader |
| SV-270736–270738 | PKI cert path validation — OCSP infra not applicable |

## Prerequisites

- Ubuntu 24.04 LTS EC2 instance (not Ubuntu 22.04 — different benchmark)
- Root/sudo access
- STIG benchmark XML downloaded from [public.cyber.mil/stigs/downloads/](https://public.cyber.mil/stigs/downloads/)
- `openscap-scanner` and `openscap-common` packages

## Important notes

- **Always snapshot or create an AMI before running the remediation script** — it changes system configuration
- FIPS mode enablement (SV-270744) requires an Ubuntu Pro subscription — the script skips it and notes the requirement
- The STIG benchmark is versioned; V1R1 is the version this skill targets. DISA releases updates periodically — verify the current revision at public.cyber.mil before a compliance audit

## What it won't do

- Ubuntu 22.04 (use `U_CAN_Ubuntu_22-04_LTS V1R2` benchmark)
- RHEL, Amazon Linux, or other distros
- Graphical workstation hardening

## Related skills

- [`postgres-ops`](./postgres-ops.md) — STIG hardening for the PostgreSQL layer running on this server
