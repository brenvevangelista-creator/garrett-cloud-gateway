# Bren OS — state ledger (update at end of each working session)

Last updated: 2026-09-08

## Current state
- Supabase project: hermes-jarvis (wbeuhshmqsfuqvzelmui, Seoul)
- 56+ tables, 90+ RLS policies, 16 migrations (0010-0016)
- 20 entities: 16 Lolo Bud's (6 active + commissary + pre-launch + opening-soon), 4 TEP
- 2 franchise packages, 8 territories
- Website metrics table populated with live data from both franchise sites
- Admin snapshots table populated with authenticated data from both admin dashboards

## Infrastructure status
- Hermes cron: 3 jobs all pinned to qwen3:14b-64k/custom, all running
- Postiz: Docker at port 4007, account bren@phoebren.com, LOCAL auth
- Jaaz: /Applications/Jaaz.app v1.0.30
- ComfyUI: MPS 25.8GB, Wan 2.1 T2V 1.3B, 2 test videos produced
- ECC: 68 agents, 97 skills (developer + security profiles)
- Manus API: 6 projects, manus-cli operational
- Website scanner: scan-websites.ts operational, wired into nightly cron
- Admin scanner: scan-admin.ts operational (246 lines), cookie-based auth, writes to admin_snapshots
- LB tRPC auth: curl works (auth.login → staff_session cookie, 30-day rolling)
- EP tRPC auth: curl fails (500), browser CDP only, app_session_id cookie (~1 year)

## Agent task separation
User standing rule: "do not edit or interchange tasks" between LB and EP.
- Scanners are read-only, manus-cli is the only website writer, bren-os-cli only touches spine DB
- LB has full expense write API (finance.logExpense + 5 admin mutations)
- EP has no expense write endpoints — Manus API tasks only

## Blocked
- Postiz needs social platform API keys for actual posting
- Fish Audio credits depleted
- API credits exhausted (HTTP 402) on OpenClaw/Hermes subagent
- lolobuds.vip/locations page returns 404
- LigaPass volleyball/badminton/pickleball research blocked on credits
- EP cookie refresh needed when app_session_id expires (~1 year)

## Agreed next steps
1. Build expense-push script (spine DB → LB tRPC finance.logExpense)
2. Social media platform API keys for Postiz (when Bren is ready)
3. TikTok account creation (deferred)
4. LigaPass separate Supabase project (when credits available)
5. Fix lolobuds.vip/locations via Manus API