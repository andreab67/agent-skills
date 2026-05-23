# session-handoff

Rescue critical session context to persistent memory before `/clear`, `/compact`, or any conversation wipe. Invoked manually before ending a session; an optional hook can also gate `/clear` itself.

## Install

```bash
npx skills add andreab67/agent-skills@session-handoff -g -y
```

## What it does

Most of a session should die when you `/clear` — code is in the diff, decisions are in the commit, status is in the PR. But a small slice of what just happened is non-replaceable and would cost you hours to reconstruct. This skill finds that slice, gets your approval per entry, writes it to the auto-memory store using the `user`/`feedback`/`project`/`reference` schema, and confirms when it's safe to clear.

The whole skill rides on **one heuristic** — *would re-reading the repo recover this?* If yes, drop. If no, it's a rescue candidate. That single test eliminates ~80% of false saves.

## Capabilities

| Area | What you get |
| --- | --- |
| **Pre-flight** | Reads `MEMORY.md` first to reuse existing slug prefixes, detect duplicates, and surface contradictions with stale entries |
| **Six rescue categories** | Active project goals & scope, pending tasks with status, user preferences & constraints, established working rules, key background not in code/git, open questions / agreed next steps — each mapped to a specific `type:` |
| **The rescue test** | One-sentence heuristic applied to every candidate before anything else: *would re-reading the repo recover this?* |
| **Hard exclusions** | Secrets, code-derivable facts, git-history facts, fixed-bug recipes, anything in CLAUDE.md — refused even when explicitly asked |
| **Anti-patterns gallery** | Seven concrete "looks like rescuable context but isn't" examples a senior engineer would refuse |
| **Tagging convention** | Consistent `user_` / `feedback_` / `project_` / `reference_` slug prefixes for natural index sort and unambiguous `[[wiki-links]]` |
| **Review-before-write** | Always shows the keep list + drop list with reasons via `AskUserQuestion`; uses multi-select for ≤ 4 candidates, table-format for > 4 |
| **Conflict resolution** | Detects when a candidate contradicts an existing memory; updates in place with a dated note rather than writing duplicates |
| **Body structure by type** | `feedback`/`project` entries lead with the rule, then `**Why:**` and `**How to apply:**` lines — so future-you can judge edge cases instead of blindly following |
| **Date normalization** | Converts "Thursday" / "next week" / "after the demo" to absolute dates at extraction time |
| **Worked end-to-end example** | A 90-minute design session → 11 candidates → 6 keep, 5 drop, with the exact triage table |
| **Optional `/clear` hook** | `UserPromptSubmit` hook (ships in `hooks/session-handoff-gate.js`) that blocks the first `/clear`, routes to the skill, lets the second through |

## Example prompts

- *"I'm about to /clear. We just spent two hours on the auth migration plan — save what matters."*
- *"Wrap this up before I switch contexts. Don't lose the bit about the legal-driven rewrite."*
- *"Checkpoint and clear."*
- *"Before I /clear, show me the list of what you'd save."*
- *"Hand off this session — I'll resume from a new context tomorrow morning."*
- *"Save the Q2 milestone scope we agreed on, then I'll clear."*
- *"I'm switching to the other repo. Preserve only what's not in the PR description."*

## What it won't do

- Save the conversation transcript or full activity log — that's `/compact`'s job, not memory's.
- Save secrets, tokens, or credentials, regardless of how the user phrases the request.
- Save anything derivable from the repo, `git log`, or CLAUDE.md.
- Save debugging recipes for bugs fixed in the same session (the fix lives in the diff).
- Run after `/clear` has already executed — it tells you it's too late and offers the hook setup for next time.
- Replace ad-hoc memory writes during normal work — if you just want to save *one* fact mid-session, write the memory file directly; running the full extraction is overkill.

## Assumptions

The skill assumes you use Claude Code's auto-memory store at `~/.claude/projects/<project-slug>/memory/`, with the standard `user`/`feedback`/`project`/`reference` schema and an index file at `MEMORY.md`. If your project's auto-memory block isn't visible in the system prompt, the skill asks where to write.

It also assumes you'll invoke it manually before `/clear`. The hook in [Appendix A of the skill body](../session-handoff/SKILL.md#appendix-a-optional-hook-for-automatic-activation-on-clear) is opt-in for users who want `/clear` itself to gate the rescue flow.

## Related skills

This skill writes into the same auto-memory store other workflows consume. No peer skills in this repo today. Logical future neighbors: a `memory-prune` skill (drop stale entries on a cadence) and a `memory-search` skill (query before writing duplicates).
