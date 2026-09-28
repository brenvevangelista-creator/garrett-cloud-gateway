---
name: garrett-workflow-board
description: "Execute queued Garrett workflow board tasks via MCP."
tags: [mcp, workflow, garrett, task-execution, supabase]
version: "1.0"
author: Hermes Agent
license: internal
metadata:
  hermes:
    tags: [mcp, workflow, garrett, task-execution, supabase, task-board]
    related_skills: [bren-os-lolobuds, garrett-vault]
---

# Garrett Workflow Board

## When to Use

- A user says "check the workflow board", "do your queued tasks", or "what's on the board".
- A cron job or hook triggers task polling.
- Any reference to the Garrett task queue, work items, or MCP workflow board.

The Garrett workflow board is an MCP-backed task queue stored in Supabase table `garrett_work_items`. Tasks are assigned to agents (hermes, claude, codex) and have statuses, acceptance criteria, and evidence.

## Querying Tasks

1. Use `tool_search(queries=["garrett workflow board"])` to discover the exact MCP tool name (it may differ across environments).
2. Call the discovered tool with `owner="hermes"` (or the relevant agent) to get assigned tasks.
3. Filter for `status="queued"` to find actionable tasks.

PITFALL: Do NOT try to invoke `99-meta/automation/shared-workflow/bridge.py` directly via terminal. It is an MCP server, not a CLI. It must be called through the MCP tool interface.

## Executing Acceptance Criteria

1. Read the task's `acceptance` field — it contains exact terminal commands or steps.
2. Execute each command **exactly as written**. Do not interpret, paraphrase, or skip steps.
3. If any command errors, STOP immediately. Set status to `blocked` and paste the exact error as a note.
4. Collect raw terminal output as evidence — do not summarize or truncate it.

## Status State Machine

```
queued → in_progress → review → done
queued → in_progress → blocked (on error)
```

PITFALL: You **cannot skip states**. Attempting `queued → review` directly fails silently or with an error. Always transition one step at a time: first to `in_progress`, then to `review` (or `blocked`).

Each transition increments `version`. Read the current version from the task before calling `workflow_update` — pass it as `expected_version` for optimistic concurrency.

## Transition Procedure

1. `queued → in_progress`: Set `status="in_progress"`, `expected_version` = current version, `note="Starting execution."`
2. `in_progress → review`: Set `status="review"`, `expected_version` = incremented version, `note=` summary of what was done, `evidence=` array of raw terminal output strings.
3. `in_progress → blocked`: Set `status="blocked"`, `note=` the exact error.

## Evidence Format

Evidence is an array of strings in the `evidence` field of `workflow_update`. Each string is raw terminal output from one step. The acceptance criteria typically specify which steps to capture — usually the verification/listing steps near the end.

PITFALL: Do NOT summarize evidence. The reviewer (Claude) needs raw output to verify on disk.

## Review Handoff

When a task reaches `review`, the reviewer (typically Claude) verifies the work on disk and writes any required follow-up files (e.g., `context/README.md` pointers). The reviewer transitions to `done` after verification.
