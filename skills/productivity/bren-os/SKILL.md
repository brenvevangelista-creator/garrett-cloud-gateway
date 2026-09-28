---
name: bren-os
use_when: Use when touching Bren's spine DB, briefing, or OS.
description: Supabase spine DB (hermes-jarvis/wbeuhshmqsfuqvzelmui, Seoul), credentials ~/.config/bren-os/env, CLI ~/.local/bin/bren-os, Obsidian views ~/growth-engine/OS/, project docs ~/projects/bren-os/ARCHITECTURE.md + TEAM-SETUP.md, Lolo Buds team (Bren CEO, James Ops, Kenneth Area, Kevin Sales, Bryan Commissary) + TEP (Phoebe + Katrina), Telegram groups for each department, Hermes cron briefings 7am+10pm via OpenClaw.
---

# Bren OS — Skill Reference

## Key paths
- Spine credentials: `~/.config/bren-os/env` (chmod 600) — contains SUPABASE_PROJECT_REF, SUPABASE_SERVICE_ROLE_KEY, MANUS_API_KEY
- CLI wrapper: `~/.local/bin/bren-os` (capture/task/tasks/done/log/inbox/file/biz/brief/expense/expenses/compliance/compliance-add/compliance-alerts)
- Manus CLI: `~/.local/bin/manus-cli` (status, update-lolo, update-ep, task, publish, domains)
- Website scanner: `~/.local/bin/scan-websites` (also at `~/home-os/supabase/scripts/scan-websites`)
- Obsidian views: `~/growth-engine/OS/`
- Architecture doc: `~/projects/bren-os/ARCHITECTURE.md`
- Team setup: `~/projects/bren-os/TEAM-SETUP.md`
- Departments: `~/projects/bren-os/DEPARTMENTS.md`
- Agents & Skills: `~/projects/bren-os/AGENTS-SKILLS.md`
- LigaPass product: `~/projects/ligapass/` (SPEC.md, demo/, research/, supabase/migrations/)
- Growth engine (marketing): `~/growth-engine/`
- Home OS app: `~/home-os/`
- Postiz Docker: `~/projects/marketing-tools/postiz/`
- ComfyUI: `/Users/brenevangelista/Documents/comfy/ComfyUI/`
- Hermes cron config: `~/.hermes/cron/jobs.json`

## Pitfalls
- Cron jobs break silently when model changes. The `cronjob_manage` update action does NOT support changing model/provider — edit `~/.hermes/cron/jobs.json` directly (JSON with `jobs` array). Clear `last_error` and `last_status` fields after fixing.
- Env file uses `SUPABASE_PROJECT_REF` not `SUPABASE_URL`. Scripts must construct URL as `https://${SUPABASE_PROJECT_REF}.supabase.co`. Lines may or may not have `export` prefix.
- Supabase REST API upsert needs BOTH `on_conflict` query param AND `Prefer: resolution=merge-duplicates` header. Missing either = silent failure. See references/supabase-rest-api.md.
- `npx tsx -e "..."` fails on top-level await. Write a script file under `supabase/scripts/` with async `main()` and run `npx tsx <file>` instead.
- Port 5000 is Apple AirTunes on macOS — Postiz remapped to port 4007.
- Postiz auth: LOCAL provider (not 'email'). Registration requires `provider: 'LOCAL'`.
- When writing JSON payloads to curl via `execSync`, always write to a temp file and use `-d @file` — inline JSON with embedded quotes breaks shell parsing even with careful escaping.
- SPA sites (Manus-generated or similar) don't have REST APIs — the backend is tRPC at `/api/trpc/<procedure>`. Discover procedures by fetching the admin JS chunk from the HTML source and searching for `/api/trpc/` string literals.
- HttpOnly auth cookies (`staff_session`, `app_session_id`) can't be read by JavaScript but are visible to CDP via `cdp('Network.getCookies')`. For curl-based scripts, parse the `Set-Cookie` response header (write headers to file with `-D`), not the response body.
- Auth strategies differ per site even with same credentials. Always test curl auth first (fast, scriptable), fall back to browser CDP cookie extraction when curl returns 500. Store extracted cookies in env file for headless reuse.
- `Path(__file__).resolve().parent.parent` in Python files under `src/` reaches the wrong directory (e.g. `oracle/desktop/` instead of `oracle/`). Count actual nesting depth from the file to the project root. Files in `project/src/module/` need `.parent.parent.parent` (3 levels). Verify with a quick `print(ROOT)` after defining it.

## Knowledge graph & Obsidian vault
- Graph builder: `~/projects/bren-os/build-knowledge-graph.py` (run to regenerate)
- Vault builder: `~/projects/bren-os/build-obsidian-vault.py` (run to regenerate vault)
- Knowledge graph: `~/projects/bren-os/graphify-out/graph.json` (56 nodes, 149 edges)
- Graph report: `~/projects/bren-os/graphify-out/GRAPH_REPORT.md`
- Obsidian vault: `~/bren-os-vault/` (45 files, registered in Obsidian)
- MCP server: `bren-os-graph` (registered with Claude Code, exposes query_graph, get_node, get_neighbors, shortest_path)

## Database
- Project: hermes-jarvis (ref: wbeuhshmqsfuqvzelmui, Seoul ap-northeast-2)
- 54+ tables, 85+ RLS policies, 15 migrations (0010-0015)
- Migrations: `~/home-os/supabase/migrations/`
- Apply: `cd ~/home-os && npm run db:push` (uses `pg` npm package, NOT psql)
- Scripts: briefing.ts, obsidian-export.ts, bren-os-cli.ts, manus-cli.ts, scan-websites.ts in `~/home-os/supabase/scripts/`
- Env file: `~/.config/bren-os/env` — uses `SUPABASE_PROJECT_REF` (not `SUPABASE_URL`), scripts must construct URL as `https://${SUPABASE_PROJECT_REF}.supabase.co`

## Team (Lolo Bud's)
- Bren (CEO) — strategy, money, team building
- James Notarte (Ops) — compliance, LGU, branch operations
- Kenneth Evangelista (Area Mgr) — branch efficiency, compliance monitoring
- Kevin Evangelista (Sales) — franchise pipeline, onboarding
- Bryan Evangelista (Commissary) — production, supply chain, deliveries
- Phoebe + Katrina — TEP operations

## Cron jobs
- Morning Briefing (7am): 8dcb47b6a742 → Telegram via OpenClaw
- Nightly Business Briefing (10pm): 1fa4454adec1 → Telegram + voice via OpenClaw — runs `scan-websites.ts` first, includes live revenue data
- Daily Compliance Scan (8am): e566c5f5dd33 → Telegram via OpenClaw
- All pinned to model `qwen3:14b-64k` / provider `custom`
- Config: `~/.hermes/cron/jobs.json` (JSON with `jobs` array)

## Telegram
- Bot: @GAS_OPS_bot (OpenClaw gateway, needs Node 24 via nvm)
- Owner: telegram:1608993620
- Secretary skill: ~/.openclaw/skills/bren-os-secretary/SKILL.md
- Group chats planned: Lolo Buds Ops, TEP Ops, Commissary, Franchise Pipeline

## Skills built (in ~/.hermes/skills/)
- compliance-tracker — permits, expiry, LGU procedures
- branch-profiles — all branch locations and details
- lgu-procedures — per-city permit procedures
- comfyui — ComfyUI + Wan 2.1 video generation

## Agent task separation (STANDING RULE)
User directive: "do not edit or interchange tasks" between Lolo Buds and Espresso Playground.
- Each scanner/script targets ONE site — never mix LB and EP data in the same write path.
- `scan-admin.ts` handles both sites but writes separate snapshots per domain. This is fine — the snapshots don't cross.
- `manus-cli` commands are site-specific (`update-lolo` vs `update-ep`).
- Cron jobs are shared (secretary reads from all snapshots) but never write to the websites.
- Only `manus-cli` writes to websites. Scanners are read-only. `bren-os-cli` only touches the spine DB.

| Agent | Reads From | Writes To | Never Touches |
|-------|-----------|-----------|---------------|
| scan-admin.ts | LB tRPC, EP tRPC | admin_snapshots table | Website UI, expenses |
| scan-websites.ts | Public pages | website_metrics table | Auth, admin data |
| bren-os-cli | Spine DB | Spine DB | Websites |
| manus-cli | Manus API | LB + EP websites | Spine DB |
| Secretary (cron) | Spine DB | Daily reports | Websites |

## Expense write capabilities
- **Lolo Buds:** Full write via tRPC — `finance.logExpense` (create), `admin.updateExpense`, `admin.approveExpense`, `admin.rejectExpense`, `admin.deleteExpense`. Input: scope, branchId, category, amount, description, receiptUrl, expenseDate.
- **Espresso Playground:** No expense write endpoints in tRPC. Write via Manus API tasks only (natural language).
- Data flow: Branch staff → Website → scan-admin (pull) → Spine DB (reconcile). Bren/James → bren-os-cli → Spine DB → future expense-push script → Website.
- Spine DB is source of truth for expenses. Website data is pulled for reconciliation, not the other way around.

## Agent tiers
- Tier 3 (Opus): strategic thinking, planning, complex analysis — Central Brain
- Tier 2 (Sonnet): department work — marketing, purchasing, compliance, sales
- Tier 1 (Haiku): routine — filing, alerts, reports, data entry

## Website scanner (public data)
- Script: `~/home-os/supabase/scripts/scan-websites.ts` (300 lines)
- Shell wrapper: `~/home-os/supabase/scripts/scan-websites` (also symlinked to `~/.local/bin/`)
- Table: `website_metrics` (migration 0015) — (domain, metric_date, metric_key) unique constraint
- Pulls live data from lolobuds.vip + espressoplayground.vip franchise pages
- Captures: revenue, branch counts, menu pricing, franchise pricing, ordering/rewards availability
- Uses Supabase REST API directly (no JS client) — see references/supabase-rest-api.md
- Supports `--dry` flag for testing
- Wired into nightly briefing cron (runs before briefing generation)
- Command: `scan-websites` or `npx tsx ~/home-os/supabase/scripts/scan-websites.ts`
- Limitation: only captures publicly visible franchise page data, not per-branch daily sales or delivery platform orders

## Admin dashboard scanner (authenticated data)
- Script: `~/home-os/supabase/scripts/scan-admin.ts` (246 lines)
- Table: `admin_snapshots` (migration 0016) — (domain, snapshot_date, snapshot_type) unique constraint, data JSONB
- Credentials: `~/.config/bren-os/env` → LB_ADMIN_EMAIL, LB_ADMIN_PASSWORD, TEP_ADMIN_EMAIL, TEP_ADMIN_PASSWORD, LB_SESSION_COOKIE, EP_SESSION_COOKIE
- **LB auth:** `POST /api/trpc/auth.login` with `{"json":{"email":"...","password":"***"}}` → `staff_session` cookie in `Set-Cookie` response header (30-day rolling JWT, auto-refreshes)
- **EP auth:** `auth.login` returns HTTP 500 via curl — only browser CDP works. Use stored `app_session_id` cookie (~1 year expiry). When it expires, user must log in once via browser.
- LB endpoints: admin.dashboard, admin.branches, admin.branchPerformanceReport, admin.dailyBreakevenOverview, admin.expensesByCategory, admin.customers, admin.commissaryExecutiveSummary
- EP endpoints: admin.dashboard, admin.getFranchiseDashboard, admin.getFranchiseInsights, admin.getTerritories
- Supports `--dry` flag for testing
- Writes to `admin_snapshots` table via Supabase PostgREST upsert

## Manus API
- CLI: `~/.local/bin/manus-cli` (wrapper for `~/home-os/supabase/scripts/manus-cli.ts`)
- Key stored: `~/.config/bren-os/env` (MANUS_API_KEY)
- 6 projects: Lolo Buds, The Espresso Playground, Manjari Cove, Manjari Residences, Growth Architect Studio, Jarvis HQ
- Agent-based (natural language tasks), free tier 300 credits/day
- Best for: occasional website updates (new branches, promos, pricing changes)
- Complementary to Postiz for social media posting

## Marketing tools
- **Postiz** — social media scheduler, Docker at `http://localhost:4007` (port 5000 = Apple AirTunes)
  - Account: `bren@phoebren.com`, provider LOCAL, password in Postiz .env
  - Docker dir: `~/projects/marketing-tools/postiz/`
  - Host .env volume-mounted: `./.env:/app/.env:ro`
  - Needs social platform API keys for actual posting (TikTok, Facebook, Instagram)
- **Jaaz** — Canva alternative, `/Applications/Jaaz.app` v1.0.30 arm64
- **ComfyUI** — local video generation with Wan 2.1, at `/Users/brenevangelista/Documents/comfy/ComfyUI`
  - MPS 25.8GB, ~7-13 min/video, 2 test videos produced
  - Workflow: `user/default/workflows/wan21_marketing_t2v.json`

## Oracle (voice-first assistant)
- Project: `~/projects/oracle/`
- Architecture: 6-tier desktop app (pywebview) + brain-and-memory system
- Desktop app: `/Applications/Oracle.app` (shell-script launcher → venv → shell.py)
- Living Mind 3D visualization: port 3333 (three.js neural graph)
- Agent definition: `~/.hermes/agents/oracle.md`
- Supabase tables: `oracle_conversations`, `oracle_memory`, `oracle_knowledge` (migration 0019)
- Key source files (all under `~/projects/oracle/src/`):
  - `brain.py` — system prompt assembly (identity + knowledge + memory), model calls, memory tools, auto-extractor, drift checkpoint, working memory windowing (50 turns)
  - `memory_tools.py` — dual-storage memory (local markdown truth + Supabase sync), save/recall/list/forget with keyword scoring, dedupe on write
  - `extractor.py` — session-end memory extraction, proposal parsing, dedup against existing
  - `supabase_store.py` — Supabase CRUD for conversations, memory, knowledge
- Identity: `~/projects/oracle/IDENTITY.md` (standalone prose, not inline YAML)
- Knowledge base: `~/projects/oracle/knowledge/` (bren.md, businesses.md, tech-stack.md)
- Memory files: `~/projects/oracle/memory/*.md` (YAML frontmatter + markdown body)
- Memory index: `~/projects/oracle/memory/index.json` (hooks + types, rebuildable)
- Config: `~/projects/oracle/config.yaml` (model/provider settings)
- Provider: Ollama `qwen3:14b-64k` (local, no API cost)
- Dual storage pattern: local markdown files = source of truth, Supabase = backup/portable sync
- Memory format: YAML frontmatter (`type`, `hook`, `created`, `updated`) + markdown body
- User commands: `/save <fact>`, `/recall <query>`, `/forget <file>`, `/memories`
- ROOT path from `src/` files: `Path(__file__).resolve().parent.parent.parent` (3 levels up to reach `oracle/` root)

## Lolo Buds REST API (lolobuds.vip/api/) — Public read + draft write

- Base URL: `https://lolobuds.vip`
- Auth: `Authorization: Bearer <key>` header
- Read-only key: `LOLO_BUDS_API_KEY` — shared across GET endpoints
- Draft key: `LOLO_BUDS_EXPENSE_DRAFT_KEY` — POST /expenses only (draft, pending Bren approval)
- Both stored in `~/.config/bren-os/env` (chmod 600)
- Endpoints: `/api/branches`, `/api/sales?date=YYYY-MM-DD`, `/api/inventory?branch=N`, `/api/expenses`, `/api/franchisees`, `/api/reports/daily?date=YYYY-MM-DD`, `/api/reports/today`
- **Daily report** (`/api/reports/daily`) returns `{branches: [{name, items: [{name, qty}]}]}` — per-branch sales by menu item
- **B1T1 items count as 2 pieces per order** — multiply qty by 2 for actual piece count
- **No production/commissary delivery endpoint exists** — only POS sales data available via API
- **Forecast engine uses SALES data, not PRODUCTION data** — forecast.json has `chicken_recommended` and `liempo_recommended` fields based on POS sales history. If commissary produces more than branches sell, forecast underestimates. To get true production numbers, must check commissary portal UI directly.
- **NEVER use read-only key for writes** — draft key has write-scoped permissions only
- Approval: Bren approves drafts via lolobuds.vip admin (PATCH /api/expenses/:id/approve with president session)

### Agent boundaries for REST API
| Agent | Reads | Writes | Never |
|-------|-------|--------|-------|
| Expense bot | — | POST /expenses (draft only) | Approve, modify ledger |
| Production dashboard | GET /sales, /inventory, /reports | — | Write anything |
| Hermes (hermes) | GET /* | — | Approve, modify |

## Pending / blocked
- Postiz needs social platform API keys (TikTok, Facebook, Instagram) for posting
- TikTok account creation deferred (user has no TikTok account yet)
- Fish Audio credits depleted (blocks TTS testing)
- API credits exhausted (HTTP 402) — blocks OpenClaw Telegram brain, Hermes subagent delegations
- lolobuds.vip/locations page broken (404) — needs fixing via Manus API
- Volleyball/badminton/pickleball LigaPass research blocked on credits (basketball done)
