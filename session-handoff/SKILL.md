---
name: session-handoff
description: Run manually before ending a session — `/clear`, `/compact`, switching repos, or any context wipe — to rescue critical context that would otherwise die with the conversation. Trigger phrases include "about to /clear", "before I clear", "wrap up this session", "checkpoint before clearing", "hand off this session", "save context first", "preserve what we just figured out", "I'm switching repos", "/session-handoff". Extracts goals, pending tasks, preferences, working rules, key background, and open questions into the project's auto-memory store, applying a rescue test (skip anything derivable from code/git/CLAUDE.md) with explicit per-entry user approval before writing. Do NOT use for ad-hoc single-fact saves (write the memory file directly — full extraction is overkill), for sessions already captured by a diff and commit, or after `/clear` has already run (context is gone — say so and offer the hook setup). (Six categories, rescue test, and workflow are detailed in the body.)
---

# session-handoff

You are about to lose this session's working context. Most of it should die — code is in the diff, decisions are in the commit message, status is in the PR. But a small slice of what just happened is *non-replaceable* and would cost the user hours to reconstruct from scratch. Find that slice, get it approved, write it to persistent memory, then let the user clear.

This skill is invoked manually. The user runs you before `/clear`. There is an optional hook in [Appendix A](#appendix-a-optional-hook-for-automatic-activation-on-clear) that intercepts `/clear` itself, but the primary flow is: user types something like *"checkpoint before I clear"* → you run this skill → user `/clears`.

## When to use

- User says they are about to `/clear`, `/compact`, end the session, or switch projects.
- User says *"save context first"*, *"preserve this"*, *"checkpoint"*, *"hand off"*, or any variant where the intent is *"don't lose what we just figured out."*
- A long debugging or design session is being interrupted by an unrelated request and you judge that critical decisions aren't captured anywhere persistent yet.
- User types `/session-handoff` directly.

Do NOT use for:

- Routine *"remember that I prefer X"* mid-conversation. Write the single memory file directly — full extraction is overkill.
- Sessions whose entire output is a diff, a commit, and a PR description. Those artifacts are the memory.
- Calls *after* `/clear` has already executed. Context is gone. Say so plainly and offer the hook setup for next time.
- Saving the conversation transcript or full activity log. That's not what memory is for — push back and ask *"what was surprising or non-obvious about it?"*

## The single rescue test

Apply this to every candidate. One sentence, four words:

> **Would re-reading the repo recover this?**

If yes → skip. The repo, `git log`, `git blame`, planning docs, and CLAUDE.md are the source of truth for everything they cover. Memory is for the *gap* between those artifacts and what a future session needs to know.

If no → it's a rescue candidate. Send it to category triage (next section).

This single test eliminates ~80% of false saves. Apply it first, before anything else.

## The six categories

Each maps to a specific auto-memory `type:`. The `type:` is not cosmetic — it tells future sessions how to treat the entry.

| Category | `type:` | Save when... | Skip when... |
| --- | --- | --- | --- |
| **Active project goals & scope** | `project` | A goal, milestone target, deadline, or scope boundary crystallized this session and isn't yet in PROJECT.md / ROADMAP.md / a PR. | Already in a planning doc, commit, or issue tracker. |
| **Pending unresolved tasks** | `project` | Work interrupted mid-flight, OR a decision deferred with a clear owner / resume condition. Include status: *"waiting on X"*, *"blocked by Y"*, *"stub at file:line, finish after Z"*. | Captured in a TODO comment, ticket, or PLAN.md — those persist on their own. |
| **User preferences & constraints** | `user` | User revealed something durable about role, environment, expertise level, or hard constraints. *"I only have read access in prod."* *"I'm new to React."* | One-off stylistic preference for this PR only. Pick-a-color decisions. |
| **Established working rules** | `feedback` | User corrected your approach OR validated a non-obvious one, with reasoning that applies to future sessions. Include **Why:** and **How to apply:** lines. | *"Don't use that variable name"* — too local, captured by the diff. |
| **Key background context** | `project` or `reference` | Non-obvious history, prior incidents, stakeholder asks, or external-system locations that influence decisions and aren't in the repo. Use `reference` if it points outward (a Grafana board, a Linear project); `project` if it's internal motivation. | Anything derivable from `git log`, `git blame`, or reading the code. |
| **Open questions / agreed next steps** | `project` | Explicitly deferred decision (*"we'll decide X after the migration"*) or a sequenced plan the user verbally agreed to. **Convert relative dates to absolute** — "Thursday" becomes the actual date. | Hypothetical *"we could maybe also"* musings. Anything not actually agreed. |

**Hard exclusions — never save, even if the user explicitly asks:**

- Secrets, tokens, API keys, passwords, private URLs with embedded credentials, internal IPs of sensitive systems.
- Code patterns, file paths, function names, or architectural facts already true in the repo. *The file is the source of truth.*
- Git history facts, PR numbers, recent commit summaries. `git log` is authoritative.
- Debugging recipes for bugs fixed in this session. The fix is in the diff; the *why* belongs in the commit message.
- Anything already documented in CLAUDE.md or skill files.
- Ephemeral task state from this conversation with no future-session value.

If the user pushes back on an exclusion: *"What was surprising or non-obvious about it? That's the rescuable part."*

## Workflow

### 1. Pre-flight: read `MEMORY.md`

Before scanning the session, read the project's `MEMORY.md` index in full. This is non-negotiable and takes seconds:

```text
~/.claude/projects/<project-slug>/memory/MEMORY.md
```

The `<project-slug>` is the kebab-cased absolute project path (e.g., `c--Users-andreab-morning-review`). The current session's system prompt names the exact path in its `auto memory` block — copy it from there. If no auto-memory block is in context, ask the user where to write.

Reading `MEMORY.md` first does three things:

1. Lets you reuse existing `name:` slug prefixes consistently (so the index sorts naturally).
2. Surfaces candidates that already have a matching entry — those become **updates**, not new files.
3. Reveals contradictions: a new candidate that conflicts with an existing memory means one of them is stale.

### 2. Scan the session end-to-end

Read every user message and your own messages in this conversation. Build a candidate list under each of the six categories. Cast wide on this pass — pruning happens next.

For each candidate, capture three things in your working notes:

- **Verbatim quote** (if it's a `feedback` or `user` rule — the user's exact wording carries nuance).
- **Why-it-matters** — one sentence on the cost of losing it.
- **Resolves-existing?** — does it overlap with an existing `MEMORY.md` entry?

### 3. Apply the rescue test, then category triage

Walk each candidate through:

1. **Rescue test**: would re-reading the repo recover this? If yes → drop.
2. **Hard exclusion**: secret? code-derivable? in CLAUDE.md? → drop.
3. **Category fit**: which of the six does it match? If none → it's probably not rescuable; drop.
4. **Resolves-in-session**: did we already fix/answer it in this session? → usually drop. Save only if the resolution itself becomes a durable rule (then re-categorize as `feedback`).

What remains is the keep list. Token budget per entry: aim for under 150 words in the body. Memories that bloat future context lose their value.

### 4. Review with the user — never silently save

Show the keep list **and** the drop list with reasons. The drop list builds trust: the user sees you applied judgment, not just stenography.

Pick the flow by candidate count:

- **≤ 4 keep candidates**: one `AskUserQuestion` with a multi-select question, options = candidate names, descriptions = one-line preview. User checks which to save.
- **> 4 keep candidates**: print a numbered markdown table (slug | type | one-line summary), plus a separate numbered list of drops with one-phrase reasons each. Ask one open question: *"Which keepers should I drop, edit, or merge? Reply with numbers, or 'all good' to save as-is."*

Always surface for explicit review (regardless of count):

- Anything naming a person, a deadline, or a $-amount (high blast radius if wrong).
- Anything that **updates** an existing memory rather than creating new (offer side-by-side: old body vs proposed new).
- Anything containing a quoted user statement (verify wording is exact).

### 5. Format each entry

Frontmatter is non-negotiable — the auto-memory system parses it:

```markdown
---
name: {{short-kebab-case-slug}}
description: {{one specific line — what future-you uses to judge relevance}}
metadata:
  type: {{user | feedback | project | reference}}
---

{{body}}
```

**Tagging convention.** The `name:` slug is the tag. Use these prefixes consistently — they sort naturally in the index and make `[[links]]` unambiguous:

| Prefix | Use for | Example |
| --- | --- | --- |
| `user_` | User role, environment, expertise | `user_role_sre_lead` |
| `feedback_` | Working rules, corrections, validated approaches | `feedback_no_inline_styles` |
| `project_` | Goals, scope, deadlines, decisions, pending work | `project_q2_migration_scope` |
| `reference_` | External system locations | `reference_grafana_oncall_board` |

**Body structure differs by type:**

- `user` / `reference`: prose, 1–4 sentences. Lead with the fact. Done.
- `feedback` / `project`: lead with the rule/fact in one sentence, then on a new line:
  - `**Why:**` — the reason the user gave (past incident, constraint, stakeholder ask). This is what lets future-you judge edge cases instead of blindly following the rule.
  - `**How to apply:**` — when/where this kicks in.

Link related entries with `[[other-name]]` — the slug, no path, no extension. A `[[link]]` to a name that doesn't exist yet is fine; it marks something worth writing later.

### 6. Resolve conflicts with existing entries

If a candidate contradicts an existing memory, the new one wins by default (memories decay, the session is fresh). But:

- **Update the existing file in place** rather than writing a duplicate. Bump the `description:` to reflect the new content.
- **Note the change** in the user review step: *"Existing entry `project_db_owner` says Alice; this session says Bob took over Tuesday. Update?"*
- **If the conflict is subtle** (the existing memory is still partially true), prefer editing the body to add a dated note rather than overwriting wholesale.

### 7. Write entries + update the index

After approval, in one batch:

1. Write each entry file with the frontmatter above.
2. Append one line per new entry to `MEMORY.md`:

   ```markdown
   - [Short title](entry-name.md) — one-line hook under ~150 chars total
   ```

   Insert in topical order, not chronological — group with related entries already in the index.
3. For updates: edit the existing entry file in place; only touch `MEMORY.md` if the description changed enough that the index line needs to follow.

`MEMORY.md` is an **index of one-line pointers**. Never write memory content directly into it. Lines past ~200 get truncated when the index loads into context, so keep it tight.

### 8. Confirm and hand off

Send one final message — terse, structured:

```text
Saved N entries to <store-path>:
  - <slug-1> (type) — one-phrase recap
  - <slug-2> (type) — one-phrase recap
  ...
Updated M existing: <slugs>
Skipped K candidates: <reasons in one phrase each>

Safe to /clear now.
```

If the optional hook is active, the user will need to re-type `/clear` — the hook lets it through on the second attempt.

## Anti-patterns: what looks like rescuable context but isn't

A senior engineer would refuse all of these even if asked nicely. Internalize them.

1. **"Save the bug we just fixed."** No. The fix is in the diff. The reason is in the commit message. Memory would be a stale duplicate that contradicts the next time the same area changes.
2. **"Save that we agreed to use Postgres."** Check the repo first — if there's a `docker-compose.yml` with a `postgres:` service, it's already documented. Memory adds noise.
3. **"Save the list of files we touched."** That's `git diff --name-only`. Refuse.
4. **"Save my preference for tabs vs spaces."** Check `.editorconfig` and `.prettierrc`. If they exist, the repo is the source of truth. If they don't, *that itself* might be worth a one-line feedback memory: *"User prefers spaces; no .editorconfig in repo yet."*
5. **"Save the SQL query we figured out."** If it's in code, no. If it was a one-off ad-hoc query the user ran in psql and might want again → it's a `reference`, not a session rescue.
6. **"Save everything we discussed."** That's `/compact`, not this skill. Decline and explain.
7. **"Save the staging URL with the embedded token."** Hard exclusion. Even if asked. Even if the token is short-lived.

## Worked example

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

## Output discipline

- **Show, don't summarize, before saving.** The review step prints exact `name:` slugs and one-line previews. The user must be able to recognize each entry, not infer it.
- **Quote the user's wording for `feedback` entries**, then paraphrase. The original phrasing often carries nuance the paraphrase loses.
- **Convert relative dates to absolute** at extraction time — "Thursday", "next week", "after the demo" become real dates. Memories outlive the sessions that wrote them.
- **Name what you skipped and why.** *"Skipped: 3 in CLAUDE.md, 1 secret, 1 ephemeral debug state."* Trust grows when the user sees what didn't make the cut.
- **Refuse to widen scope.** If asked to save the whole conversation, push back: *"That's what `/compact` is for. This skill only rescues the non-replaceable parts."*
- **Treat the rescue test as load-bearing.** If a candidate fails it, drop without negotiation. Saving "just in case" is how memory stores rot.

## Example prompts

- *"I'm about to /clear. We just spent two hours on the auth migration plan — save what matters."*
- *"Wrap this up before I switch contexts. Don't lose the bit about the legal-driven rewrite."*
- *"Checkpoint and clear."*
- *"Before I /clear, show me the list of what you'd save."*
- *"Hand off this session — I'll resume from a new context tomorrow morning."*
- *"Save the Q2 milestone scope we agreed on, then I'll clear."*
- *"I'm switching to the other repo. Preserve only what's not in the PR description."*
- *"/session-handoff"*

## Appendix A: optional hook for automatic activation on `/clear`

Skip this if you're happy invoking the skill manually. The hook exists for users who want `/clear` to be the trigger itself.

Claude Code's `/clear` is a built-in that wipes the conversation. A skill cannot intercept it after the fact. The workaround is a `UserPromptSubmit` hook that blocks the *first* `/clear` in a session, injects a routing reason, and lets the *second* `/clear` through.

Add to `~/.claude/settings.json` (user-scope) or `.claude/settings.json` (project-scope):

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": "^/clear\\s*$",
        "hooks": [
          {
            "type": "command",
            "command": "node ~/.claude/hooks/session-handoff-gate.js"
          }
        ]
      }
    ]
  }
}
```

Then create `~/.claude/hooks/session-handoff-gate.js` (also shipped in this skill directory as `hooks/session-handoff-gate.js`):

```javascript
#!/usr/bin/env node
// Intercepts the first /clear in a session. Lets the second through so the
// user can actually clear after session-handoff finishes.
const fs = require('fs');
const path = require('path');
const os = require('os');

const STATE_DIR = path.join(os.homedir(), '.claude', 'state');
const STATE_FILE = path.join(STATE_DIR, 'session-handoff-armed.json');

let input = '';
process.stdin.on('data', c => input += c);
process.stdin.on('end', () => {
  let payload;
  try { payload = JSON.parse(input); } catch { process.exit(0); }
  const sessionId = payload.session_id || 'unknown';

  fs.mkdirSync(STATE_DIR, { recursive: true });
  let state = {};
  try { state = JSON.parse(fs.readFileSync(STATE_FILE, 'utf8')); } catch {}

  if (state[sessionId] === 'armed') {
    delete state[sessionId];
    fs.writeFileSync(STATE_FILE, JSON.stringify(state));
    process.exit(0); // let /clear through
  }

  state[sessionId] = 'armed';
  fs.writeFileSync(STATE_FILE, JSON.stringify(state));

  console.error(JSON.stringify({
    decision: 'block',
    reason: 'Run the session-handoff skill first to preserve critical context. After it confirms, re-type /clear to proceed.'
  }));
  process.exit(2);
});
```

Make it executable: `chmod +x ~/.claude/hooks/session-handoff-gate.js`. On Windows, ensure `node` is on PATH; otherwise wrap with a `.cmd` shim.

How it works: first `/clear` is blocked and the agent sees the routing reason → runs `session-handoff` → confirms saved → user re-types `/clear` → hook sees the session is already armed, lets it through, clears its state.

To disarm without saving (you really do want to nuke the context): `rm ~/.claude/state/session-handoff-armed.json` and re-type `/clear`.

## Related skills

This skill writes into the same auto-memory store other workflows consume. There are no peer skills in this repo today; future candidates include a `memory-prune` skill (drop stale entries on a cadence) and a `memory-search` skill (query before writing duplicates).
