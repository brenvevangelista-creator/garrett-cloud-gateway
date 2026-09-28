---
name: superset-agents
description: Dispatch parallel coding agents via superset-sh worktrees.
---

# superset-sh Parallel Agent Orchestration

Dispatch isolated coding agents to work on separate branches in parallel, then merge results into main.

## Prerequisites

- superset-sh CLI installed (`~/.superset/bin/superset`) and authenticated
- Project created and host setup complete (see reference below)
- Claude Code CLI authenticated (`claude auth status` — if expired, `claude auth login` via local browser OAuth)

## Procedure

### 1. Create branches from main

```bash
cd <project-dir>
git checkout main
git checkout -b <branch-name>   # one per agent
git checkout main                # return to main
```

### 2. Create workspaces (one per agent)

```bash
superset workspaces create \
  --project <PROJECT_UUID> \
  --local \
  --branch <branch-name> \
  --name "<Agent Name>" \
  --agent claude \
  --prompt '<task instructions>'
```

- `--local` is REQUIRED for all `workspaces create` and `projects` commands on this machine.
- Use the project UUID, not the project name — name alone fails.
- Each workspace maps to exactly one git branch.
- **Git branch must exist before creating a workspace on it.** Create and commit on the branch first.

**If `workspaces create` says "Reused existing workspace":** it found an existing workspace on that branch and did NOT spawn an agent. You must start the agent separately:

```bash
superset agents create \
  --workspace <WS_UUID> \
  --agent claude \
  --prompt '<task instructions>' \
  --attachment <file>   # optional, repeatable
```

Check `superset workspaces list --local` to find the reused workspace UUID.

### 3. Launch agents in terminals

```bash
# Get terminal ID
terminal_id=$(superset terminals list --workspace <WS_UUID> --json | jq -r '.sessions[0].id')

# Launch with trust bypass
superset terminals send \
  --workspace <WS_UUID> \
  --terminal <terminal_id> \
  --text "claude -p --dangerously-skip-permissions '<agent prompt>'"
superset terminals send --workspace <WS_UUID> --terminal <terminal_id> --text ""
```

**CRITICAL:** `--text "C-c"` sends the literal string `C-c`, NOT a Ctrl+C signal. To interrupt an agent, send `--text "C-c"` then `--text ""` (Enter) twice — the terminal interprets the literal text as a key sequence.

### 4. Monitor agents

```bash
# Check progress
superset terminals read --workspace <WS_UUID> --terminal <terminal_id> --json \
  | jq -r '.text[-2000:]'

# Repeat until output contains completion signals or no "…" spinner
```

- Wait 45–90s between checks for coding agents.
- `terminals list` does NOT accept `--local` — only `ws create` and `projects setup` need it.

### 5. Commit agent work

**Agents make changes but DO NOT commit.** After an agent completes:

```bash
cd <worktree-path>   # ~/.superset/worktrees/<project-uuid>/<branch-name>/
git add -A
git diff --cached --stat   # review what changed
git commit -m "<type>(<scope>): <description>"
```

Worktree path pattern: `~/.superset/worktrees/<PROJECT_UUID>/<branch-name>/`

### 6. Merge to main

Worktrees share the same `.git` — all branches are visible from the main repo.

```bash
cd <project-dir>
git checkout main
git merge <branch-name> --no-edit
# Resolve conflicts if needed:
#   git checkout --theirs <conflicted-file>
#   git add <conflicted-file>
#   git commit --no-edit
```

## Pitfalls

- **`projects create` vs `projects setup`:** `create --import <dir>` imports a local git repo as a NEW project. `setup <UUID> --path <dir>` adopts an EXISTING project onto this host. Don't confuse them — `create` needs `--import` (not `--path`), and `setup` needs a project UUID.
- **Git repo must be initialized before `--import`.** Run `git init && git add -A && git commit` in the target directory before `projects create --import`.
- **`workspaces create` reuses silently.** If a workspace already exists on that branch, it returns "Reused existing workspace" without spawning an agent. Always follow up with `agents create` when reusing.
- **Pre-trust worktree directories globally** — add paths to `~/.claude/settings.json` → `trustedDirectories` array. Per-directory `.claude/settings.local.json` may not be read if the agent re-launches in a subshell. Global trust is reliable.
- **Claude Code OAuth requires a local browser** — headless browser is blocked by Cloudflare Turnstile. Run `claude auth login` in terminal; it opens `open <auth_url>` on the local machine automatically.
- **`-p --dangerously-skip-permissions` is mandatory** for non-interactive agent launches. Without `-p`, the trust dialog blocks and `--text` sends literal characters instead of selecting options.
- **Do not relaunch into a stuck terminal** — if an agent is stuck on a prompt, send `C-c` + Enter + `reset` + Enter to clear the shell, then launch fresh. Sending a new `claude -p` command into a dirty shell types it as text without executing.
- **Verify file contents after merge** — run `git diff --stat HEAD~N..HEAD` and spot-check key files. Agents self-report completion but may leave partial work.

## Reference: superset-sh Key Commands

| Command | Notes |
|---------|-------|
| `superset projects list` | Show projects |
| `superset projects create --name <N> --local --import <dir>` | Import existing local repo as new project |
| `superset projects setup <UUID> --local --path <dir>` | Adopt existing project on this host |
| `superset workspaces create --project <UUID> --local --branch <b> --name <n> --agent claude --prompt <p>` | Create workspace + spawn agent (reuses existing ws on same branch) |
| `superset agents create --workspace <UUID> --agent claude --prompt <p>` | Spawn agent on existing workspace |
| `superset workspaces list --local` | List workspaces |
| `superset workspaces get <UUID> --json` | Get workspace details (does NOT accept `--local`) |
| `superset terminals list --workspace <UUID>` | List terminal sessions (NO `--local`) |
| `superset terminals read --workspace <UUID> --terminal <ID> --json` | Read terminal output |
| `superset terminals send --workspace <UUID> --terminal <ID> --text <msg>` | Send text to terminal |

See `references/bren-os-project.md` for the Bren OS project UUIDs and IDs.
