# Entry format spec

The exact shape of each auto-memory entry. SKILL.md § "Format each entry" points here.

## Frontmatter (non-negotiable — the auto-memory system parses it)

```markdown
---
name: {{short-kebab-case-slug}}
description: {{one specific line — what future-you uses to judge relevance}}
metadata:
  type: {{user | feedback | project | reference}}
---

{{body}}
```

## Tagging convention

The `name:` slug is the tag. Use these prefixes consistently — they sort naturally in the index and make `[[links]]` unambiguous:

| Prefix | Use for | Example |
| --- | --- | --- |
| `user_` | User role, environment, expertise | `user_role_sre_lead` |
| `feedback_` | Working rules, corrections, validated approaches | `feedback_no_inline_styles` |
| `project_` | Goals, scope, deadlines, decisions, pending work | `project_q2_migration_scope` |
| `reference_` | External system locations | `reference_grafana_oncall_board` |

## Body structure differs by type

- `user` / `reference`: prose, 1–4 sentences. Lead with the fact. Done.
- `feedback` / `project`: lead with the rule/fact in one sentence, then on a new line:
  - `**Why:**` — the reason the user gave (past incident, constraint, stakeholder ask). This is what lets future-you judge edge cases instead of blindly following the rule.
  - `**How to apply:**` — when/where this kicks in.

Link related entries with `[[other-name]]` — the slug, no path, no extension. A `[[link]]` to a name that doesn't exist yet is fine; it marks something worth writing later.

## Token budget

Aim for under 150 words per entry body. Memories that bloat future context lose their value.
