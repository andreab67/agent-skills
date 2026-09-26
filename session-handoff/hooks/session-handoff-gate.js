#!/usr/bin/env node
// session-handoff-gate.js
//
// Optional UserPromptSubmit hook for Claude Code. Blocks the first /clear in a
// session, tells the user to run the session-handoff skill first, then lets
// the second /clear through.
//
// UserPromptSubmit fires on EVERY prompt and has no `matcher` support (Claude
// Code's own docs: "always fires on every occurrence"), so this script — not
// any settings.json matcher — is what decides whether a given prompt is a
// /clear. Non-/clear prompts exit 0 immediately with no state write and no
// output, so they are never touched.
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
//              "hooks": [
//                { "type": "command", "command": "node ~/.claude/hooks/session-handoff-gate.js" }
//              ]
//            }
//          ]
//        }
//      }
//
//   4. Verify it locally: type /clear once. You should see the block message
//      before the conversation clears. Claude Code's docs don't guarantee the
//      built-in /clear command is delivered to UserPromptSubmit at all — if
//      you don't see the block message, this hook cannot help you (see
//      references/clear-hook.md for the fallback).
//
// To disarm without saving (you really want to nuke the context):
//   rm ~/.claude/state/session-handoff-armed.json && re-type /clear

const fs = require('fs');
const path = require('path');
const os = require('os');

const STATE_DIR = path.join(os.homedir(), '.claude', 'state');
const STATE_FILE = path.join(STATE_DIR, 'session-handoff-armed.json');
const CLEAR_RE = /^\/clear\s*$/;

let input = '';
process.stdin.on('data', (chunk) => { input += chunk; });
process.stdin.on('end', () => {
  let payload;
  try {
    payload = JSON.parse(input);
  } catch {
    // Malformed/empty payload — fail open so we never block the user on a
    // parse error.
    process.exit(0);
  }

  // UserPromptSubmit has no matcher support, so this script has to do the
  // routing itself: ignore every prompt that isn't exactly /clear.
  const prompt = String((payload && payload.prompt) ?? '').trim();
  if (!CLEAR_RE.test(prompt)) {
    process.exit(0);
  }

  const sessionId = (payload && payload.session_id) || 'unknown';

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

  // First /clear — arm the session and block, telling the USER (not the
  // agent — UserPromptSubmit's block reason on exit 0 is shown to the user)
  // to run the session-handoff skill first.
  state[sessionId] = 'armed';
  fs.writeFileSync(STATE_FILE, JSON.stringify(state));

  process.stdout.write(JSON.stringify({
    decision: 'block',
    reason:
      'Blocked /clear once: run /session-handoff (or ask Claude to run the ' +
      'session-handoff skill) to save context first, then send /clear ' +
      'again to proceed.',
  }));
  // Not process.exit(): stdout to a pipe is asynchronous on macOS, and exit()
  // would drop the pending write, turning the block into a silent pass.
  process.exitCode = 0;
});
