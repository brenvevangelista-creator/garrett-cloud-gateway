---
name: lolobuds-api-integration
description: "Use when building Lolo Buds API scripts or bot commands."
---

# Lolo Buds API Integration

Build analysis scripts that query the lolobuds.vip API, surface results via Telegram, and wire into the daily pipeline.

## Procedure

### 1. Discover schema for the resource

```bash
curl -s https://lolobuds.vip/api/schema \
  -H "Authorization: Bearer $LOLO_BUDS_FULL_READ_API_KEY" \
  -H "User-Agent: LoloBudsBot/1.0" | jq '.resources[] | {name, display_name}'
```

Field names vary per resource — always verify against the live schema before coding.

### 2. Query via `/api/query` (NOT `/api/<resource>`)

```bash
curl -s "https://lolobuds.vip/api/query?resource=sales_items&from=2026-08-01&to=2026-08-31&limit=5000" \
  -H "Authorization: Bearer $LOLO_BUDS_FULL_READ_API_KEY" \
  -H "User-Agent: LoloBudsBot/1.0"
```

`/api/query` is paginated (`limit=5000&offset=`) and never top-five truncated. `/api/<resource>` endpoints may truncate.

### 3. Build the analysis script

- Working dir: `~/projects/oracle/agents/production-forecast/`
- Python: `~/projects/oracle/agents/expense-bot/venv/bin/python3`
- Credentials: `~/.config/bren-os/env` — two active keys, never mix:
  - `LOLO_BUDS_FULL_READ_API_KEY` for ALL read operations: `/api/schema`, `/api/query`, `/api/commissary/forecast`
  - `LOLO_BUDS_EXPENSE_DRAFT_KEY` for expense writes (`POST /api/expenses`)
  - `LOLO_BUDS_API_KEY` exists in env but is DEAD (401) and unused by the bot — ignore it
- Auth header: `Authorization: Bearer $KEY` — **NOT** `X-API-Key` (401s)
- **Read key cannot write.** `LOLO_BUDS_FULL_READ_API_KEY` returns 401 on write endpoints like `POST /api/expenses`. Write operations require `LOLO_BUDS_EXPENSE_DRAFT_KEY`.
- Base URL: `https://lolobuds.vip` (no trailing `/api`)
- **Use curl for ALL API calls** — `urllib` and `httpx` both get 403 from the WAF even with custom headers. Only `curl` subprocess works. See Procedure step 3 example code.
- Output: write JSON to `~/projects/oracle/dashboard/<name>.json`

```python
import json, os, subprocess, re
from pathlib import Path
from dotenv import load_dotenv

load_dotenv(Path.home() / ".config" / "bren-os" / "env")
API_KEY = os.environ.get("LOLO_BUDS_FULL_READ_API_KEY")
BASE_URL = "https://lolobuds.vip"  # NOT .../api
DASHBOARD = Path.home() / "projects" / "oracle" / "dashboard"

def api_get(path: str, params: dict = None, timeout: int = 30):
    """GET via curl subprocess — urllib gets 403 from the WAF even with a custom User-Agent."""
    url = f"{BASE_URL}{path}"
    if params:
        url += "?" + "&".join(f"{k}={v}" for k, v in params.items())
    try:
        result = subprocess.run(
            ["curl", "-s", "-f", "--max-time", str(timeout),
             "-H", f"Authorization: Bearer {API_KEY}",
             "-H", "Accept: application/json",
             "-H", "User-Agent: LoloBudsBot/2.0",
             url],
            capture_output=True, text=True, timeout=timeout + 5)
        if result.returncode != 0:
            return None
        # Strip control characters that break json.loads
        raw = re.sub(r'[\x00-\x1f\x7f-\x9f]', ' ', result.stdout)
        return json.loads(raw)
    except Exception as e:
        print(f"API error {path}: {e}")
        return None

def fetch_all(resource: str, from_date: str, to_date: str):
    """Paginate /api/query for large datasets."""
    all_rows, offset = [], 0
    while True:
        data = api_get("/api/query", {
            "resource": resource, "from": from_date,
            "to": to_date, "limit": 5000, "offset": offset
        })
        if not data:
            break
        # API returns "rows" not "data"
        batch = data.get("rows", [])
        all_rows.extend(batch)
        # Check has_more, not len(batch) < limit — API may return exactly limit rows
        if not data.get("has_more", False):
            break
        offset += 5000
    return all_rows
```

### 4. Add Telegram bot command

In `~/projects/oracle/agents/expense-bot/bot.py`:

- Add async handler after the last `*_command` function
- Register: `application.add_handler(CommandHandler("name", name_command))`
- Update `/help` text with one-liner
- Use `lolobuds_get()` / `lolobuds_query()` helpers (already defined in bot.py — uses curl subprocess)

**Bot env loading for cloud deployment:** The bot's `load_env()` reads `~/.config/bren-os/env` locally but returns empty dict if the file doesn't exist (Render/production). All config reads use `_get(key)` which checks `os.environ` first, then the file. When adding new config values, always use `_get("KEY_NAME")` — never `env["KEY"]` or `os.environ["KEY"]` directly.

**Render deployment:**
- Procfile must use `worker: python bot.py` (NOT `web:` — Telegram bots poll, they don't serve HTTP)
- Set all env vars in Render dashboard: `TELEGRAM_BOT_TOKEN`, `LOLO_BUDS_FULL_READ_API_KEY`, `LOLO_BUDS_EXPENSE_DRAFT_KEY`, `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`, `SUPABASE_PROJECT_REF`, `TEP_REPORTING_FULL_KEY`
- Active Render service: `garrett-telegram-bot` (srv-dakn8k0u01pc73foa530). The duplicate `garrett-telegram` (srv-dakngk942hec73cfqnb0) was suspended — do NOT re-enable.
- Render's Python runtime includes `curl` — the subprocess approach works
- Only one bot instance can poll Telegram at a time — kill old instances before starting (`pkill -f bot.py`)
- No `render.yaml` needed for a simple worker; connect GitHub repo and configure in dashboard

### 5. Wire into pipeline

In `~/projects/oracle/agents/orchestrator/pipeline.py`:

- Add `JSON_PATH = DASHBOARD_DIR / "<name>.json"`
- Add `run_<name>()` function (subprocess, 300s timeout)
- Call in `run_pipeline()` between gap and summary
- Pass result to `generate_summary()` and `log_run()`
- Add section to summary builder

### 6. Test full pipeline

```bash
cd ~/projects/oracle/agents/orchestrator
~/projects/oracle/agents/expense-bot/venv/bin/python3 pipeline.py --no-notify
```

Exit 0 with all steps green before wiring to cron.

- **Pagination is mandatory for large datasets.** `sales` and `sales_items` can exceed 5,000 rows in 30 days. Always paginate with `offset`. Failing to paginate silently drops the newest/smallest branches, making it look like they have zero sales.
- **`/api/branches` status field is unreliable.** Branches marked `opening_soon` may actually be open and selling. Don't filter branches by `status` — use dispatch/sales data to determine which branches are active.
- **Commissary portal caches branch status.** After changing a branch's status in the admin panel (e.g. `opening_soon` → `open`), the dispatch portal may still block dispatches with "branch is not available" until the user hard-refreshes (`Cmd+Shift+R`) or logs out/in. The API reflects the change immediately; the portal frontend does not.
- **Branch inventory reconciliation formula:** `System balance = Opening stock + Dispatched - Sales - Waste`. Current system inventory IS the expected physical count. If physical < system, product left without POS sale or waste tag.

### 7. Cash & Collection analysis

Combine POS sales with dispatch manifests to compute cash position:

```python
# POS sales (what customers paid)
sales = fetch_all("sales_items", from_date, to_date)
# Group by branch, sum total_amount, count by payment_method

# Dispatch manifests (what branches owe commissary)
dispatches = fetch_all("commissary_dispatches", from_date, to_date)
# Group by destination_branch, sum(total_cost)
# Status: ar_paid (collected), cod (cash on delivery), ar_pending_approval (outstanding)
```

Key metrics: revenue by branch, AR collection rate, outstanding receivables,
payment method split (cash vs GCash vs card).

### 8. Stock levels via `finished_stock`

Current commissary inventory (finished goods ready for dispatch):

```python
stock = fetch_all("finished_stock", None, None)
# Fields: product, current_finished_stock, average_daily_dispatch, days_of_cover
# Flag anything with days_of_cover < 1.0 as urgent
```

### 9. Commissary cost & margin calculation

Compute commissary earnings from a production batch:

1. **Get recipe costs** from `~/Desktop/Garrett/01-companies/lolo-buds/lolobuds-master.md` (search for `marinade`/`baste`/`stuffing`). Current per-chicken add-ons: marinade ₱9.75, baste/glaze ₱5.96, stuffing ₱4.52.
2. **COGS = raw cost + (quantity × add-on cost per unit)**. Always include marinade and baste — user explicitly requested this. Stuffing is optional (ask user).
3. **Revenue = quantity × transfer price** (₱175/chicken, ₱140/liempo as of 2026-09-20). Confirm current price with user if uncertain.
4. **Gross profit = revenue − COGS; margin = profit ÷ revenue × 100**.

User frames this as "will we earn" — means commissary-level cost-to-produce vs transfer price, not branch menu P&L.

## Pitfalls

- **Envelope key is not always `data`.** `commissary_production` returns its
  rows under **`rows`**, not `data`. Read `total_count` and assert your row
  count matches it — a silent `d.get("data", [])` returns `[]` while
  `total_count` says 33, and you will report zero instead of erroring.
- **Production line field names differ from dispatches:** inputs/outputs use
  `quantity_used` / `quantity_produced` and `base_unit` (NOT `quantity` /
  `unit`). Wrong keys yield silent 0.00 totals, not an exception.
- **Liempo trim has no waste line.** Unusable cuts are absorbed into
  `quantity_used` on `RAW-LIEMPO-KG`. Yield = raw kg in ÷ slabs out
  (449.9 g/slab measured over 11 batches). Never look for a scrap output line.
- **Shell invocation:** do NOT write `cd ~/dir && ~/path/venv/bin/python3 x.py`
  — the chained + tilde-expanded form trips the security scanner as an
  unresolvable nested command and blocks on approval. Pass the directory via
  the tool's `workdir` and run the interpreter as the sole command.

See `references/commissary-dispatch-pricing.md` for stock names, transfer prices, and COGS breakdowns.
See `references/branch-reconciliation.md` for the inventory gap analysis procedure.
See `references/franchisee-presentation-pattern.md` for building stakeholder presentation decks from API data.

- **Double `/api/` URL**: `BASE_URL = "https://lolobuds.vip/api"` + paths starting with `/api/query` = `https://lolobuds.vip/api/api/query`. Set `BASE_URL` to `https://lolobuds.vip` only.
- **WAF 403 on urllib — custom User-Agent does NOT fix it.** The WAF blocks `Python-urllib` even with a custom `User-Agent` header. Use `subprocess.run(["curl", ...])` for all Lolo Buds API calls. `curl` works with the same key and URL. `httpx` also gets 403. This applies to scripts, bot.py, and any Python code calling lolobuds.vip.
- **`X-API-Key` 401s**: Use `Authorization: Bearer $KEY`, not `X-API-Key`.
- **Packaging bags match protein keywords**: `Big Bag w/ Sticker (Chicken)` and `Small Bag w/ Sticker (Liempo)` are packaging lines. When filtering by product name for protein counts, use exact-name sets (`CHICKEN_STOCK`, `LIEMPO_STOCK`), never substring/keyword matching.
- **Field names differ per resource**: `commissary_dispatches` uses `stock_name`; `commissary_forecast` response uses `product`/`current_finished_stock`/`days_of_cover`/`average_daily_dispatch`; `sales_items` uses `product_name`. Always query a sample and check `data["rows"][0].keys()` before coding field references.
- **Cron may not actually be installed**: Previous reports of "cron live" can be wrong. Always verify with `crontab -l` after writing a crontab file.
- **Telegram bot single-instance**: Only one bot process can poll Telegram at a time. Kill old instances (`pkill -f bot.py`) before starting new — a second instance silently fails to receive updates.
- **Collection statuses**: `ar_paid` (receivables paid), `cod` (cash on delivery collected at door), `ar_pending_approval` (awaiting Bren's approval — this is the outstanding AR).
- **Sauce and bag income is in dispatches, not sales_items.** `sales_items` captures POS retail sales to end customers. Commissary income from sauce (₱4/pack), bags (₱5/bag), and baste bottles is in `commissary_dispatches` — those are commissary-to-branch transfers.
- **`transfer_price_per_unit` may not match the actual selling price.** The dispatch system recorded ₱616.25 for 1-gallon baste, but the actual selling price is ₱850. Always confirm prices with the user when doing financial analysis — don't trust the dispatch field blindly.
- **`transfer_price_per_unit` in dispatches is the actual price, not necessarily the listed price.** Always read it from the data; do not assume a price from docs or memory is still current.
- **API returns JSON with control characters.** `json.loads` fails on responses containing `\x00`–`\x1f` control chars. Save raw response to a temp file, strip control characters with `re.sub(r'[\x00-\x1f\x7f-\x9f]', ' ', raw)`, then parse. The `json_parse` helper does NOT reliably fix this.
- **SPA-served sites return HTTP 200 for every path.** When probing for API endpoints on a site with a frontend SPA (React, Next.js, etc.), all routes — real and nonexistent — return HTTP 200 with the HTML app shell. Don't trust status codes. Check `Content-Type: application/json` in the response header, or check if the body starts with `{` (JSON) vs `<` (HTML). If every path returns HTML, the server-side API routes haven't been built yet — the SPA catch-all is serving everything.
- **B1T1 Combo = 1 chicken + 1 liempo.** When counting total protein sold, add B1T1 Combo quantities to BOTH chicken and liempo totals. B1T1 Whole Chicken counts only as chicken. B1T1 Liempo counts only as liempo. Failing to account for combos undercounts both proteins.
- **`/api/query` pagination: check `has_more`, not row count.** The response includes `total_count`, `returned_count`, and `has_more`. Paginate while `has_more` is true, incrementing `offset += limit`. Do not assume `len(rows) < limit` means done — the API may return exactly `limit` rows with more available.
- **Sales API uses `from`/`to`, NOT `start_date`/`end_date`.** The old parameter names return HTTP 403. Always use `?branch_id={id}&from=YYYY-MM-DD&to=YYYY-MM-DD`.
- **Sales API max 90-day range.** Requesting more returns `DATE_RANGE_TOO_LARGE`. Query month-by-month and aggregate in code.
- **Sales API returns aggregates only.** It does not return per-day breakdowns. To compute operating days, calculate from branch schedule (days/week) × calendar days in period — do not try to extract daily data from the API.
- **Sauce allocation: 1 per ORDER, not per unit.** One chicken, one liempo, or one B1T1 combo each get exactly 1 sauce. A combo counts as 1 order (1 sauce), not 2. Use total orders (not total units) for sauce cost.
- **Charcoal cost tiers by daily revenue.** ₱300/day if avg daily revenue <₱10K; ₱400/day if ≥₱10K; ₱600/day if ≥₱20K. Compute avg daily revenue = branch revenue ÷ operating days, then multiply tier rate × operating days for total charcoal cost. See `references/branch-pl-cost-rules.md`.
See `references/branch-ids.md` for the current branch mapping and commissary status.
See `references/meta-graph-api.md` for Facebook/Instagram posting via Meta Graph API.

### 10. Content generation from API data

Generate social media content using real sales data:

```python
# Pull daily sales summary
sales = fetch_all("sales", from_date, to_date)
branches = {r['id']: r for r in fetch_all("branches", None, None)}

# Aggregate by branch
from collections import defaultdict
branch_totals = defaultdict(lambda: {'count': 0, 'total': 0, 'chicken': 0, 'liempo': 0})
for s in sales:
    bid = s['branch_id']
    branch_totals[bid]['count'] += 1
    branch_totals[bid]['total'] += s['total_amount']
    branch_totals[bid]['chicken'] += s.get('big_bags_used', 0)
    branch_totals[bid]['liempo'] += s.get('small_bags_used', 0)

# Generate post with real numbers
post = f"""🍗 Lolo Bud's Daily Update!
💰 ₱{sum(b['total'] for b in branch_totals.values()):,} total sales
📍 {len(branch_totals)} branches
🍗 {sum(b['chicken'] for b in branch_totals.values())} chicken + {sum(b['liempo'] for b in branch_totals.values())} liempo"""
```

**Key fields for content:**
- `sales`: `total_amount`, `big_bags_used` (chicken), `small_bags_used` (liempo), `payment_method`
- `branches`: `id`, `name`, `status`
- `sale_items`: `product_name`, `quantity`, `total_amount` (per-item detail)

**Content types:**
- Daily sales highlights (revenue, transactions, top branch)
- Franchise pitches (avg daily sales, margin, branch count)
- Product highlights (menu items, prices)
- Milestone celebrations (cumulative metrics)

**Always use real data** — never fabricate numbers. Pull from API, aggregate, format.

### 11. Intent classification for auto-response

Classify incoming messages (comments/DMs) by keyword matching:

```python
FRANCHISE_KEYWORDS = ['franchise', 'invest', 'business opportunity', 'how to open']
PRODUCT_KEYWORDS = ['order', 'menu', 'price', 'deliver', 'chicken', 'liempo']

def classify_intent(message):
    msg = message.lower()
    for kw in FRANCHISE_KEYWORDS:
        if kw in msg:
            return {'intent': 'franchise', 'confidence': 'high'}
    for kw in PRODUCT_KEYWORDS:
        if kw in msg:
            return {'intent': 'product', 'confidence': 'high'}
    return {'intent': 'general', 'confidence': 'low'}
```

**Response templates per intent:**
- Franchise: share business stats, offer presentation scheduling
- Product: show menu, branch locations, ordering options
- General: help menu with options

Log all interactions to `~/projects/oracle/agents/sales/leads.json` for follow-up.
- **Commissary is NOT a branch.** The `expenses` resource requires `branch_id`. The 7 branch IDs are Anadels=1, Concepcion=2, Estrella=3, Calapan=4, Ayala=5, Mabini=6, Tiaong=7. Querying expenses with `scope=commissary` or without a `branch_id` returns 403 Forbidden. Commissary payroll data is not accessible through the public API.
- **Payroll and attendance are 'excluded by design' from the public API.** Salary expense entries exist under branch expenses with `category: 'salaries'` (e.g. Concepcion has entries like 'shanangaba', 'trisha'), but only for branch-scoped expenses. Commissary payroll is not in the system. The attendance/timesheet endpoints (`/api/attendance`, `/api/timesheets`, `/api/shifts`, `/api/dtr`, `/api/staff`, `/api/schedule`, `/api/roster`) all exist server-side — they return 403, not 404 — but are blocked on ALL three API keys. Do not attempt these endpoints; they will always fail. Ask the user where attendance is tracked.
- **Supabase `lolo_buds_expenses` may be empty.** The expense data lives in the API backend, not Supabase directly. Always verify with a count query before assuming Supabase has data. If empty, fall back to `/api/query?resource=expenses&branch_id=X&from=...&to=...`.