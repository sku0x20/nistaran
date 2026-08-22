# Project Instructions

## Token discipline
- Minimize tokens. No filler, no restating the task, no verbose recaps.
- Responses: 1-2 sentences unless the user asks for detail. No headers/bullets for simple answers.
- Comments in code: rare. Only "why" (non-obvious constraint/reason), never "what".
- Reuse and cache: prefer grep/read over re-deriving; don't re-read files just edited; don't re-explore what's already known in-session.

## Models
- Advisor: Opus (default, no override).
- Subagents: pass `model: "haiku"` on every Agent call.

## Git
- Commit after every meaningful edit (working, reviewed change) — small, atomic commits, not batched at the end.
- Never commit without the user's changes actually working/passing basic checks.
- Follow the standard commit-safety rules (no force-push, no --no-verify, review staged diff for secrets).
