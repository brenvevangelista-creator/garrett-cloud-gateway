---
name: central-os
description: Use when working on Bren's central OS, home-os, or spine DB.
---

# Bren's Central OS (the "Jarvis" project)

Long-running project: one always-on digital secretary for schedule, family,
businesses, marketing, sales, ops, inventory. Agreed architecture (don't relitigate):

- **Spine** — one Postgres (Supabase, the existing `~/home-os` project) holds all facts.
- **Brain** — agents (Hermes cron, growth-engine roles) read/write the spine; no private agent state.
- **Interface** — chat capture + briefings first; dashboards later.
- Build order: spine → daily briefing → single capture channel (Telegram/chat → `inbox_items`) → one domain organ per month (CRM, inventory sync, finance, research) → tiered autonomy last (auto vs approval-gated, per growth-engine's pattern; money/legal never auto).

## Key artifacts (already built)

- `~/home-os/supabase/migrations/0010_spine.sql` — spine tables: `businesses` (seeded with all 11 of Bren's entities incl. `family`), `entities`, `business_tasks` (OPEN/WAITING/DONE/DROPPED, priority 1–5, `waiting_on`), `spine_events` (append-only, insert+select only even for admin), `inbox_items` (NEW/FILED/DISMISSED capture door). All admin-only RLS.
- `~/home-os/scripts/briefing.ts` — morning briefing; `npx tsx scripts/briefing.ts [YYYY-MM-DD]` prints markdown (calendar → overdue biz tasks → due today → waiting → household tasks → bills ≤7d → low/expiring stock → unfiled inbox → yesterday's spine_events). Plain stdout by design so any runner (Hermes cron, launchd, Vercel cron) can deliver it.

## home-os codebase conventions (follow exactly when adding migrations)

- Migrations in `supabase/migrations/NNNN_name.sql`, applied in filename order by `npm run db:push` (`supabase/scripts/push.ts`, one transaction per file). Must be **idempotent**: `create table if not exists`, enums via `do $$ begin create type … exception when duplicate_object then null; end $$`, `drop policy if exists` before `create policy`.
- RLS helpers exist in 0001: `is_admin()`, `is_kitchen()`, `is_staff()`, `is_member()`. Money/sensitive tables get **no policy at all** for lower roles (DB-enforced, not UI-hidden). Run `npm run test:rls` after schema changes.
- Attach `select public.attach_audit('<table>')` and a `fn_touch()` before-update trigger on mutable tables.
- Env in `.env.local` (`DATABASE_URL` = pooler URI). Timezone `Asia/Manila`, currency PHP, dates `DD MMM YYYY`.
- Household `tasks`/`calendar_events` already exist (0007) — business tasks are deliberately a **separate table** (different lifecycle, admin-only).

## Current state / next steps (as of Sep 2026)

- Old Supabase project `awjbfqlifoaibmdejmzr` no longer exists (NXDOMAIN; free-tier deletion, not pause). Waiting on Bren to create a new project and provide `DATABASE_URL` + URL + anon/service keys.
- Then: update `.env.local`, `npm run db:push` (all 10 migrations), `npm run db:seed`, run first briefing, wire Hermes cron for ~7am Asia/Manila delivery.
- Related repos: `~/growth-engine` (marketing agent vault, keep as-is but log outcomes to `spine_events`), `~/lolo-buds-money`, home-os ROADMAP #1 = ERP↔home-os inventory sync.

## Pitfalls

- Don't build "one app for everything" or add agents before the spine has data — briefing quality forces data flow.
- Don't create parallel state stores; every new organ hangs off the same Supabase.
- A paused Supabase project still resolves DNS; NXDOMAIN on `<ref>.supabase.co` means deleted.