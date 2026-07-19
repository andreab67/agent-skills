# code-review

[![View on skills.sh](https://img.shields.io/badge/skills.sh-code--review-blue)](https://skills.sh/andreab67/agent-skills/code-review)

Adversarially-verified multi-angle code review. Fans ten review angles (five bug-hunting, five quality) out to cheap subagents, refutes every candidate finding against the actual code, sweeps for coverage gaps, and reports only findings that survive — severity-ranked, most severe first.

## Install

```bash
npx skills add andreab67/agent-skills@code-review -g -y
```

## What it does

Most "review" output is padding: plausible-sounding nitpicks a senior engineer would never raise, pre-existing issues the diff didn't introduce, and things a linter already catches. This skill is built to emit the opposite — a short list where **every** item has a concrete failure scenario verified in the code. "No confirmed findings" is a valid, complete result.

The model running the skill is the **orchestrator**: it scopes the diff, briefs the passes, judges verdicts, and writes the report. All bulk reading — the angle scans and the skeptic verifications — is delegated to the cheapest capable subagent tier the host offers, so a thorough review stays cheap.

## Capabilities

| Area | What you get |
| --- | --- |
| **Scope** | Working tree + staged vs the merge-base by default, incl. untracked files; or a named MR/PR, branch, or commit range (GitLab `glab`/API, GitHub `gh`) |
| **Phase 1 — 10 angles** | Five bug lenses (line-by-line, removed-behavior, cross-file tracer, language-pitfall, wrapper/proxy correctness) and five quality lenses (reuse, simplification, efficiency, altitude, conventions) — each a dedicated pass, never merged |
| **Candidates, not verdicts** | Phase 1 returns `{file, line, claim, evidence, severity guess}`; judgment is deferred to Phase 2 |
| **Phase 2 — adversarial verify** | Each candidate gets a skeptic briefed to *refute* it, defaulting to refuted when uncertain; auto-refutes pre-existing issues, linter-catchable items, intentional supported changes, and silenced rules |
| **Phase 3 — gap sweep** | Names what Phase 1 didn't cover (untouched diff files, tests, migrations, configs, docs, TODO/FIXME, generated-vs-source drift) and routes new candidates back through verification |
| **Report discipline** | Severity-ranked critical → major → minor; each finding is one claim + `file:line` + a concrete failure scenario; confirmed findings only |
| **Host portability** | Subagent mechanics for Claude Code, hermes-agent (`delegate_task`), Kilo Code (`new_task`), Codex CLI, and no-subagent hosts (Cursor / AnythingLLM run the angles as strict sequential focused passes) — see `references/hosts.md` |

## Example prompts

- *"Review my changes before I open the MR."*
- *"Code-review this branch for bugs and quality."*
- *"Review the diff against main — I refactored the retry wrapper."*
- *"Is this commit range safe to ship?"*
- *"Review MR !412 in the payments repo."*
- *"Give me a code review — focus on what actually breaks, not style."*
- *"Sanity-check the removed-behavior risk in this rewrite."*

## What it won't do

- Pad the report to look thorough — an empty result is stated plainly with one line on what was checked.
- Re-flag pre-existing issues the diff didn't introduce, or anything a linter / typechecker / compiler already catches.
- Raise nitpicks a senior engineer wouldn't, or rules the code explicitly silences.
- Keep a finding without a concrete, code-verified failure scenario.
- Replace domain reviewers — infra-manifest review (`kubernetes-deployment-reviewer`), UI/design review, and plan/eval review are separate lenses.

## Related skills

Pairs with any host that can spawn cheap subagents for the read-heavy passes. On hosts without subagents (Cursor, AnythingLLM) it degrades gracefully to sequential focused passes. Domain-specific reviewers (Kubernetes manifests, frontend design) are complementary, not substitutes.
