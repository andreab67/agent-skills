#!/usr/bin/env node
// session-handoff-gate.js
//
// Optional UserPromptSubmit hook for Claude Code. Blocks the first /clear in a
// session, injects a routing reason that tells the agent to run the
// session-handoff skill first, then lets the second /clear through.
//
// Install:
//   1. Copy this file to ~/.claude/hooks/session-handoff-gate.js
//   2. chmod +x ~/.claude/hooks/session-handoff-gate.js   (POSIX)
//   3. Add this to ~/.claude/settings.json (or .claude/settings.json):
//
//      {
//        "hooks": {
//          "UserPromptSubmit": [
//            {
//              "matcher": "^/clear\\s*$",
//              "hooks": [
//                { "type": "command", "command": "node ~/.claude/hooks/session-handoff-gate.js" }
//              ]
//            }
//          ]
//        }
//      }
//
// To disarm without saving (you really want to nuke the context):
//   rm ~/.claude/state/session-handoff-armed.json && re-type /clear

const fs = require('fs');
const path = require('path');
const os = require('os');

const STATE_DIR = path.join(os.homedir(), '.claude', 'state');
const STATE_FILE = path.join(STATE_DIR, 'session-handoff-armed.json');

let input = '';
process.stdin.on('data', (chunk) => { input += chunk; });
process.stdin.on('end', () => {
  let payload;
  try {
    payload = JSON.parse(input);
  } catch {
    // Malformed payload — fail open so we don't break /clear.
    process.exit(0);
  }
  const sessionId = payload.session_id || 'unknown';

  fs.mkdirSync(STATE_DIR, { recursive: true });

  let state = {};
  try {
    state = JSON.parse(fs.readFileSync(STATE_FILE, 'utf8'));
  } catch {
    // No prior state — treat as empty.
  }

  if (state[sessionId] === 'armed') {
    // Second /clear in this session — user has been through session-handoff
    // (or chose to skip it). Let it through and clear state.
    delete state[sessionId];
    fs.writeFileSync(STATE_FILE, JSON.stringify(state));
    process.exit(0);
  }

  // First /clear — arm the session and block, routing to session-handoff.
  state[sessionId] = 'armed';
  fs.writeFileSync(STATE_FILE, JSON.stringify(state));

  console.error(JSON.stringify({
    decision: 'block',
    reason:
      'Run the session-handoff skill first to preserve critical context. ' +
      'After it confirms entries are saved, re-type /clear to proceed.',
  }));
  process.exit(2);
});
