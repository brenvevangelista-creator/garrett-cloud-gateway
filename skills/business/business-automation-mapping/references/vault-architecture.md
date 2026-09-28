# Vault Architecture — 3-Layer Pattern

Implementation blueprint for structuring a multi-business knowledge vault that
AI agents can read, execute, and self-improve.

## The 3 Layers

| Layer | Role | Location | Format |
|---|---|---|---|
| 1 — Directives | What to do (SOPs) | `businesses/<id>/directives/` | Markdown |
| 2 — Orchestration | When & how (routing, decisions) | AI agent (in-context) | Runtime |
| 3 — Execution | Doing the work | `core/connectors/`, `businesses/<id>/execution/` | Python scripts |

The AI agent is Layer 2. It reads Layer 1 directives, calls Layer 3 tools, and
handles errors. It never does what a script can do deterministically.

## Directory Structure

```
<vault-root>/
├── core/
│   ├── AGENT-INSTRUCTIONS.md   ← master rules (always loaded)
│   ├── connectors/             ← reusable API clients (Layer 3)
│   └── schemas/                ← data shape definitions
├── templates/
│   ├── directives/             ← golden master SOP templates
│   └── execution/              ← script templates
└── businesses/
    └── <business-id>/
        ├── .env                ← keys, tokens (chmod 600, gitignored)
        ├── context/            ← company facts, brand voice, ICP, recipes
        ├── directives/         ← business-specific SOPs (Layer 1)
        ├── execution/          ← business-specific scripts (Layer 3)
        └── .tmp/               ← scratchpad, intermediates, audit logs
```

## Key Rules

### Connectors in core/ are shared muscle
API clients that multiple businesses use go in `core/connectors/`. Business-
specific scripts go in `businesses/<id>/execution/`. Never duplicate an API
client — check `core/connectors/` before writing new code.

### Directives are living documents
When a script breaks and you fix it, update the directive with what you learned
(API limits, timing, edge cases). The directive is the instruction set for the
next run — if it's stale, the next session repeats the same failure.

### Self-annealing loop
1. Read the directive
2. Run the execution script
3. If it breaks → fix the script
4. Test the fix
5. Update the directive with what you learned
6. System is now stronger for the next run

### Context files ground the agent
`context/` holds facts that never change mid-task: company profile, team roster,
product catalog, pricing tables, brand voice. The agent reads these before
acting — they're the "who are we and what do we sell" layer.

### .tmp/ is scratchpad, never source of truth
Everything in `.tmp/` is regenerated from API pulls. Never reference a `.tmp/`
file as authoritative — re-pull from the live source.

## Directive Format (Golden Master)

Every SOP directive should contain:
1. **Goal** — what does "done" look like?
2. **Inputs** — what data does this need?
3. **Tools/Scripts** — which connectors or execution scripts to use
4. **Process** — step-by-step, specific enough for a mid-level employee
5. **Output Format** — table structure, file naming, labeling requirements
6. **Edge Cases** — known API quirks, data quality issues
7. **Post-Run** — where to save output, when to update this directive

## Credential Handling

- Store all keys in `businesses/<id>/.env` (or `~/.config/bren-os/env` for
  cross-business secrets)
- Connectors read from env vars, never hardcode
- Never print secret values; report length/prefix shape only
- Distinct keys for read-only vs write operations

## Adding a New Business

1. Create `businesses/<id>/` with the 4 subdirs
2. Write `context/company-profile.md` (who, what, where)
3. Write `context/pricing-and-recipes.md` or equivalent economics file
4. Copy relevant directive templates from `templates/directives/`
5. Adapt connectors from `core/connectors/` or write business-specific ones
6. Test one full directive cycle before moving on
