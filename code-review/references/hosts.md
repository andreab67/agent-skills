# Host-specific subagent mechanics

How to run the angle scans (Phase 1) and skeptics (Phase 2) on each host. The
rule everywhere: the orchestrator stays on the session's model; delegated
readers run on the cheapest capable tier the host offers.

## Claude Code

- Use the `Agent` tool (subagent_type `general-purpose` or `Explore`).
- `model: "haiku"` for angle scans and skeptics; bump the cross-file tracer
  (Angle C) to `model: "sonnet"` on large or refactor-heavy diffs.
- Launch all 10 angle agents in a single message so they run concurrently;
  same for the skeptic batch in Phase 2.
- Note: Claude Code also ships a native `/code-review`. When it is available,
  prefer it — this skill is the portable equivalent for hosts that lack it.

## hermes-agent (native session)

- Use `delegate_task(tasks=[{goal, context}, …])` — one task per angle, one
  batch call. Children default to `role: 'leaf'` and route to the configured
  cheap delegation model automatically; do not override the model per task.
- Do not set `toolsets=[]` on child tasks (it strips inherited MCP tools).
- Phase 2 skeptics: a second `delegate_task` batch, one task per candidate.

## Kilo Code

- Use `new_task` — one subtask per angle, in a mode configured with a cheaper
  model (e.g. a "reviewer" mode pinned to a flat-cost or budget model).
- Subtasks run sequentially in Kilo; keep each brief tight so the total stays
  cheap. Collect each subtask's candidate list from its completion result.

## Codex CLI

- If collaborator/subagent spawning is available in your version, one worker
  per angle on the cheapest model tier.
- Otherwise: sequential focused self-passes, one angle at a time. Consider
  switching to a cheaper model for the read-heavy passes and back for
  synthesis, if the session supports model switching.

## Cursor / AnythingLLM (no subagents)

- Sequential focused passes, one angle brief at a time — never merge angles
  into one pass; merged passes miss what dedicated lenses catch.
- Keep the phase separation strict: finish all 10 find passes before any
  verification; verify each candidate in its own focused step.
