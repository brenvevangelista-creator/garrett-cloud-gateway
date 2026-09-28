---
name: ops-data-analytics
description: Ops API data pulls, gap reconciliation, Telegram bots.
---

# Operational Data Analytics & Ops Bots

For turning a business's operational API (POS, inventory, commissary,
expenses) into numbers the owner acts on, and wiring those numbers into a
Telegram bot. Bren acts on these figures operationally — a wrong number
costs more than a slow one.

Venture-specific endpoints, keys, and product economics live in the
user-owned `bren-os-lolobuds` skill; load it too when the venture is Lolo
Buds.

## Procedure

1. **Discover before coding.** Hit the API's schema/discovery route and read
   the actual resource and field names. Never write a parser against field
   names you inferred from a docs snippet.
2. **Choose the untruncated endpoint.** Summary/report routes commonly return
   only the top N items per group. Use the row-level query endpoint for any
   volume figure.
3. **Paginate to exhaustion.** Loop `offset` until a short page returns.
4. **Classify by exact name**, never substring — see below.
5. **Run the sanity gate** before any peso/loss figure reaches the user.
6. **Reconcile against all three stocks** (sent, sold, on hand) for gap work.
7. **Render handler output offline** before restarting a live bot.
8. **Lead with the number, flag the correction.** If an earlier figure in the
   same session was wrong, say so plainly and give the mechanism before
   restating. Do not bury a retraction under a fresh table.

## Always-on rules

### Classifier: exact match only
Product catalogs embed category words inside unrelated SKUs — packaging named
`Big Bag w/ Sticker (Chicken)` matches a `"chicken" in name.lower()` filter and
gets counted as birds. Maintain explicit name sets (`{"marinated chicken"}`) and
assert that every row classified is in the set. A keyword filter inflated one
dispatch total by ~6,900 units.

### Sanity gate: divide by unit count
Before reporting any shortfall, divide the peso figure by the unit count and
compare it against the known unit/transfer price. A materially wrong implied
price means the classifier is broken, not the business. This check caught a
35x overstatement (a fake ₱9.8M/yr "leak") before it was reported.

### Gap formula must subtract on-hand
```
gap = dispatched - sold - on_hand
```
Dispatch-minus-sales alone treats every unit sitting in a branch freezer as
shrinkage. Raw ratios of 1.16x/1.35x collapsed to ~3%/~2% once branch
inventory was subtracted. Low single-digit % = ordinary shrinkage; report,
don't alarm. Concentration in one or two sites is the real signal. A
**negative** gap means uncounted opening stock or a receiving lag — surface
it, don't drop it.

### Never let a client silently degrade
If the full-access credential is missing, fail loudly. A fallback to a
truncated summary route produces plausible wrong numbers and hides its own
bug.

## Inventory variance reconciliation
When Bren asks about missing items, inventory gaps, or branch stock discrepancies, use `references/inventory-reconciliation.md` — it covers the three-leg reconciliation (dispatched − sold − on_hand), B1T1 physical item counting, and PDF report generation.

## Cost-to-produce analysis
When Bren asks "will we earn" from a batch of purchased raw materials, use `references/cost-to-produce.md` — it maps recipe.json ingredient costs to actual purchase prices and computes commissary-level gross profit.

## P&L reporting
When Bren asks for a branch or network P&L, use `references/pnl-reporting.md` — it defines the required line items, calculation format, and layout he expects.

## Pitfalls

- **Check `core/connectors/` before writing new API scripts.** Reusable API
  clients live in `~/Desktop/Garrett/core/connectors/`. Import and use them
  instead of inline curl or one-off Python. Business-specific scripts go in
  `businesses/<id>/execution/`. This prevents duplicate auth logic and keeps
  the self-annealing loop (fix connector once → all directives benefit).
- **Send an explicit `User-Agent` from Python HTTP clients.** WAFs return 403
  to the default `Python-urllib/3.x` agent even with a valid key, which reads
  exactly like an auth failure and burns a debugging cycle.
- **Confirm the auth header scheme.** `Authorization: Bearer` and `X-API-Key`
  are not interchangeable; the wrong one 401s on every key.
- **Detect undeployed routes by body size and MIME, not status.** SPA-backed
  APIs return HTTP 200 with the HTML shell for unmatched paths, so a missing
  route looks identical to a working one by status code alone. Check for
  `text/html` / `<!doctype html>`.
- **Re-probe before declaring a route dead.** Asynchronously deployed routes
  return the shell and then live JSON minutes later.
- **Verify response key names against a live call.** Guessing them yields
  empty collections that look like a successful request — a parser reading
  `items`/`stock_name` against a payload keyed `products`/`product` produced
  no error and no output.
- **Keep credentials isolated by scope.** Distinct keys for full-read,\n  summary-reporting, and write/draft operations; store in a chmod-600 env\n  file outside any repo and never substitute one for another.\n- **`execute_code` does not inherit shell `source`d env vars.** The Python kernel\n  runs in its own process — `source ~/.config/bren-os/env` in `terminal` does NOT\n  propagate. Either use `terminal` with curl + file redirect, or read the env file\n  explicitly in Python with `open(os.path.expanduser('~/.config/bren-os/env'))`.\n- **`terminal` piped to `python3` exits 137.** For large API JSON, curl to a temp\n  file first (`curl ... -o /tmp/data.json`), then process with a separate Python call.

## Ops bot handlers

- Exercise a new handler before restarting the live bot: load the module via
  `importlib`, pass a stub exposing `async reply_text`, print the rendered
  message. Wrong field names and missing imports surface in seconds instead
  of over a round-trip through the chat platform.
- Check imports and module-level objects the new code assumes exist
  (`urllib`, a `logger`) — a handler added to a file that only ever called
  `logging.error` inline will `NameError` at first use, not at import.
- Start bots with the terminal tool's `background=true`; shell-level
  `nohup`/`disown` is rejected and leaves the process untracked. Verify with
  a separate readiness check that reads the process log.
- Every commissary/stock output should check days-of-cover and flag anything
  under 1.0 day up front, above the detail tables.
- **Financial summaries truncate in terminal.** Multi-table reports with 30+
  daily rows get cut off mid-output. Redirect to a temp file, then `read_file`.
  Never assume the user saw the full numbers from terminal output alone — if
  the report has >20 lines, verify the totals row was included before quoting.
- **Dispatch ≠ receipt across organizational boundaries.** When commissary
  dispatches to a branch, the dispatched volume and the branch's accepted
  receipt volume can diverge significantly (e.g. 900 dispatched vs 650
  received). Always reconcile against the branch receipt count, not the
  commissary dispatch count. The dispatch count includes batches not yet
  received, returns, or accounting-period mismatches. Using dispatch volume
  as the numerator inflates the gap and produces false 28–42% "shortage"
  figures that are actually an accounting boundary problem, not missing
  inventory.
- **₱ renders as ■ in reportlab PDFs.** Replace all ₱ with "Php" in every PDF
  spec. reportlab's default Helvetica lacks the Philippine Peso glyph.
- **PDF table headers must be the first data row.** pdf_create.py has no
  separate header element. Embed column names as the first row of the `data`
  array; bold them with `<b>...</b>` markup. Without this, tables render
  numbers with no labels.
