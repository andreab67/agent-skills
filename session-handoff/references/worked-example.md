# Worked example — the bar for a good handoff

Session: 90-minute design discussion about migrating a service from EC2 to ECS. User is the platform lead. The session produced a 4-file diff (Terraform module + Dockerfile + IAM policy), a draft PR description, and a verbal agreement on rollout sequencing.

**Scan produces 11 candidates.** Triage:

| # | Candidate | Decision | Reason |
| --- | --- | --- | --- |
| 1 | "User is the platform lead, owns ECS migration" | **Keep** as `user_role_platform_lead` | Durable user fact; not in repo. |
| 2 | "Service runs on ECS Fargate, not EC2" | Drop | In the Terraform diff. Rescue test fails. |
| 3 | "Migration deadline is end of Q2" | **Keep** as `project_ecs_migration_q2_deadline` | Not in repo; concrete date; high cost if forgotten. |
| 4 | "User prefers Terraform over CDK because team knows HCL" | **Keep** as `feedback_prefer_terraform_for_iac` | Validated approach with reasoning; applies to future IaC decisions. |
| 5 | "We agreed to deploy to staging first, prod on the following Tuesday" | **Keep** as `project_ecs_rollout_2026_05_27` | Agreed sequenced plan; date converted from "next Tuesday" to absolute. |
| 6 | "The bug where the health check returned 503 was a missing IAM permission" | Drop | Bug fixed in this session, fix is in the IAM policy diff, why is in the commit. |
| 7 | "User mentioned Datadog dashboard `dash/abc123` is the canonical service view" | **Keep** as `reference_datadog_service_dash` | External system pointer; not in repo. |
| 8 | "User said 'no inline styles' in the dashboard repo we'll touch next" | Drop | Wrong scope — that rule belongs in that repo's memory, not this one. Flag for the user. |
| 9 | "The legal team flagged session token storage as the driver for the migration" | **Keep** as `project_ecs_migration_driver_legal` | Non-obvious motivation; future scope decisions should favor compliance. |
| 10 | "We considered using App Runner but ruled it out for VPC reasons" | Drop | Document in the PR description (which is being written). Memory would be a stale duplicate. |
| 11 | "The AWS account ID is 625000724342" | Drop | Account ID is in `terraform.tfvars`. Repo wins. |

**6 keep, 5 drop.** Show this exact table to the user via the > 4 flow, get approval, write 6 files + 6 `MEMORY.md` lines, confirm:

```text
Saved 6 entries to ~/.claude/projects/c--Users-andreab-platform-svc/memory/:
  - user_role_platform_lead (user) — owns ECS migration
  - project_ecs_migration_q2_deadline (project) — end of Q2 2026
  - feedback_prefer_terraform_for_iac (feedback) — team knows HCL, not TS
  - project_ecs_rollout_2026_05_27 (project) — staging then prod 2026-05-27
  - reference_datadog_service_dash (reference) — dash/abc123
  - project_ecs_migration_driver_legal (project) — compliance, not tech debt
Updated 0 existing.
Skipped 5 candidates: 2 in repo, 1 fixed bug, 1 wrong repo (flagged), 1 in PR description.

Safe to /clear now.
```

That's the bar. If your output looks meaningfully different from this for a comparable session, re-read the rescue test.
