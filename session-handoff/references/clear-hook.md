# Optional hook: automatic activation on `/clear`

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
