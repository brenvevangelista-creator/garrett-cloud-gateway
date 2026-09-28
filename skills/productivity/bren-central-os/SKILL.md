---
name: bren-central-os
description: Use when touching Bren's spine DB, briefing, or OS.
---

# Bren's Central OS (Jarvis / smart-secretary project)

Bren is building an always-on digital secretary covering schedule, family, all
businesses, marketing, sales, ops, inventory, admin, and research. Architecture
agreed with him: **Spine (one Postgres) → Brain (agents) → Interface (chat/dashboards)**.
Rule: facts live in the spine, intelligence in agents, no agent keeps private state.

## Where things live

- Project root: `~/home-os` (Next.js 15 + Supabase; timezone Asia/Manila, PHP currency).
- Migrations: `~/home-os/supabase/migrations/*.sql`, applied idempotently by
  `npm run db:push` (runs `supabase/scripts/push.ts` against `DATABASE_URL` in `.env.local`).
- Spine migration: `0010_spine.sql` — tables `businesses` (11 seeded: phoebren,
  pagmaya, balabac-eco-resort, lolo-buds, espresso-playground,
  growth-architect-studio, manjari-cove, manjari-residences, kingdom-capital,
  satori-real-estate, family), `entities`, `business_tasks`, `spine_events`
  (append-only, insert+select only even for admins), `inbox_items` (capture door).
  All spine tables are ADMIN-ONLY via RLS — staff/family roles have no policies on
  them at all (same pattern as `bill_period_amounts`). Preserve this when extending.
- Briefing: `~/home-os/supabase/scripts/briefing.ts` — read-only report (calendar,
  bills due 7d, business tasks, low stock, NEW inbox items, last-26h spine events);
  logs itself to `spine_events` with kind='briefing' (excluded from its own output).
- Cron: Hermes job `8dcb47b6a742` "Morning Briefing", daily 7am, workdir
  `~/home-os`, runs `npx tsx supabase/scripts/briefing.ts`. Gateway installed as
  launchd service `ai.hermes.gateway`.
- Related but separate: `~/growth-engine` (marketing agent vault, own CLAUDE.md);
  it should eventually LOG outcomes into `spine_events`, not hold its own state.

## Workflow rules

1. **Extend, don't fork.** New domains (CRM, finance, logistics) become new
   migrations in home-os, hanging off `businesses`/`entities` — never a new database.
2. Read existing migrations (esp. `0001_foundation.sql` helpers `is_admin()`,
   `fn_touch()`, `attach_audit()`) before writing a new one; reuse those patterns.
3. Migrations must stay idempotent (`if not exists`, `drop policy if exists`,
   enum-create wrapped in `do $$ ... exception when duplicate_object $$`).
4. Autonomy is tiered: agents draft/propose by default; auto-execute only where
   Bren explicitly promoted it. Money and legal actions never auto-execute.
5. Log meaningful actions to `spine_events` (source, kind, business_id, summary,
   payload) so the briefing sees them next morning.

## Garrett Folder — Canonical Structure

`~/Desktop/Garrett/` is the **brain layer** — 31GB total, mostly business-unit docs/assets.

```
~/Desktop/Garrett/
├── IDENTITY.md             ← canonical identity (183 lines, synced to ~/projects/oracle/IDENTITY.md)
├── brain.py                ← symlink → ~/projects/oracle/src/brain.py (540 lines)
├── brain/                  ← symlinks to canonical sources
│   ├── IDENTITY.md         → ~/projects/oracle/IDENTITY.md
│   ├── brain.py            → ~/projects/oracle/brain.py (stale — use root brain.py instead)
│   ├── knowledge/          → ~/projects/oracle/knowledge/
│   ├── north-star.md       → ~/north-star.md
│   ├── central-intelligence → self (Garrett/central-intelligence/)
│   └── legacy-system-os    → self (Garrett/legacy-system-os/)
├── central-intelligence/   ← operational docs (branches, team, recipes, API, P&L)
│   └── lolo-buds/          ← LOLOBUDS_MASTER.md + per-topic files
├── business-units/         ← 15 companies (9.7GB Lolo Buds, 8.6GB Pagmaya, etc.)
├── departments/            ← SOUL files for 6 departments
├── legacy-system-os/       ← sales scripts, content, skills
├── dashboard/              ← symlink → ~/projects/oracle/dashboard
├── docs/                   ← shared docs (29MB)
└── personal/               ← personal docs (5MB)
```

### Single source of truth rules

1. **Canonical files live in ONE place** — other locations symlink to it. Never maintain two copies.
2. **Garrett/garrett/IDENTITY.md** is the canonical identity (183 lines). `~/projects/oracle/IDENTITY.md` is synced from it.
3. **LOLOBUDS_MASTER.md** lives in `Garrett/central-intelligence/lolo-buds/` — the only copy.
4. **brain.py** canonical = `~/projects/oracle/src/brain.py` (540 lines). Garrett root has a symlink.
5. When consolidating: `wc -l` both copies, keep the larger/more complete one as canonical, symlink or delete the other.
6. `find ~ -maxdepth 5 -name "FILENAME"` to audit for duplicates before adding new content.

### Cleanup rules (removing installed tools)

When user says "delete everything" for a Docker-based tool:
1. `docker stop` running containers first (check with `docker ps -a --filter "ancestor=IMAGE"`)
2. `docker rmi` the images
3. `docker volume rm` associated volumes
4. `docker system prune -f` to reclaim space
5. Also remove: Python venvs, npm npx caches (`~/.npm/_npx/`), state dirs (`~/.<tool>-state/`), temp files (`/tmp/<tool>*`)
6. Verify with `docker images | grep`, `ls`, and `df -h /`

Pitfall: removing a Docker image fails if a container (even stopped) still references it. Always `docker rm -f` containers before `docker rmi`.

## Pitfalls

- `npx tsx -e "..."` fails on top-level await (cjs output). Write a script file
  under `supabase/scripts/` with an async `main()` and run `npx tsx <file>` instead.
- Env: `.env.local` is filled in; scripts load it via `dotenv` `config({path:'.env.local'})`.
  In shell, `set -a && source .env.local && set +a`. Never print the values.
- A migration file existing does NOT mean it's applied — check via PostgREST/psql
  (e.g. `businesses` 404'd until `db:push` was run). Verify, then push.
- Seeded `bill_periods` can show as overdue in the briefing; flagged to Bren
  2026-09-04, unresolved — don't "fix" data without asking.

## Roadmap agreed with Bren (next steps in order)

3. Telegram capture door → files raw messages into `inbox_items` (pending his bot setup;
   then point cron deliver at telegram).
4. One organ per month: calendar sync, CRM, ERP↔inventory sync (home-os ROADMAP #1),
   finance, research briefs.
5. Tiered autonomy last.