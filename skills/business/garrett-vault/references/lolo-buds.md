# Lolo Buds — worked example

Canonical notes: `01-companies/lolo-buds/process-map.md` and `decision-rules.md`.

## Value chain (11 steps)

```
(1)FORECAST -> (2)ORDER -> (3)PRODUCE -> (4)TRANSFER -> (5)SELL
                                                          |
(11)COMPLY (10)FRANCHISE <- (9)P&L <- (8)REVIEW <- (7)REPORT <- (6)CAPTURE
```

| # | Step | Runs it | Decision owner |
|---|---|---|---|
| 1 | Demand forecast | BOT Forecast Engine (6:30 AM cron) | Bryan: accept/override volume |
| 2 | Supplier ordering | Bryan (agent planned) | Bryan: supplier + qty |
| 3 | Commissary production | Bryan + BOT Commissary Controller | Bryan -> Bren: produce or hold |
| 4 | Transfer to branches | Bryan | Kenneth: allocation |
| 5 | Branch selling | 2 lechoneros + 1 cashier | none — execute to standard |
| 6 | Expense capture | BOT Expense Intel (Telegram) | Bren: approve each draft |
| 7 | Daily reporting | BOT Pipeline Orchestrator (6:30AM/9PM) | owners: flag abnormal |
| 8 | Branch performance review | Kenneth (agent planned) | Kenneth: visit/retrain/escalate |
| 9 | P&L close | Bren (agent planned) | Bren: keep/fix/close branch |
| 10 | Franchise pipeline | Kevin | Kevin qualifies; Bren signs |
| 11 | Compliance | James (agent planned) | James: file/renew/escalate |

5 of 11 steps have live agents. The manual ones (2, 8, 9, 11) are exactly where
Bren gets pulled back in. Recommended build order: **9 P&L Reporter first**
(only manual step where Bren is the bottleneck), then 8, then 2, then 11.

## Team

| Person | Role | Owns |
|---|---|---|
| Bren | CEO | strategy, finance, tech, AI oversight |
| James Notarte | Operations Manager | branch ops, LGU compliance, permits |
| Kenneth Evangelista | Area Manager | branch efficiency, field visits |
| Kevin Evangelista | Franchise Sales | leads, onboarding |
| Bryan Evangelista | Commissary & Production | production, sourcing, QC |

All 5 owners on Telegram. Owners submit expenses via Facebook group chat;
branch cashiers use the branch portal instead. Branches run 2 lechoneros +
1 cashier, **no branch managers**.

## 3 P&L centers (never mix)

Branch Operations (Kenneth) | Commissary Production (Bryan) | Franchise Sales (Kevin)

"Will we earn?" about a batch = **commissary** math: raw cost + recipe
marinade/stuffing/glaze -> COGS -> vs transfer price x qty. NOT branch menu P&L.

### Buy by weight, sell by unit

Both core inputs are purchased by weight and transferred as units, so every
commissary cost figure hides a weight assumption. That is where the errors live:

- **Chicken** is quoted per head, but *delivered* weight per bird sets the real
  cost. Receipts list bag weights against a fixed head count per bag (Kababayan
  20 pcs/bag, JV 15 pcs/bag) — divide to get kg/head. Costing a bird at a spec
  weight no supplier actually delivers overstates COGS badly, and that inflated
  per-head figure then spreads into every margin table.
- **Liempo** is purchased per kilo and cut in-house into slabs. Because Lolo Buds
  owns the knife, slab weight is Bren's decision rather than the supplier's, and
  it moves more money per slab than the whole price range does. Treat the cut
  spec as a tolerance, recommend a target inside it, and report slabs per kilo
  bought next to cost per slab.

Keep live prices, weights and margins in the vault notes
(`numbers/commissary-cogs-verified.md`, `input-specs.md`) and link to them —
never restate them here.

**Liempo volume is contradicted across notes** (daily production figure vs the
volume the COGS model annualizes, ~4x apart). Confirm slabs/day with Bryan
before publishing any annual liempo number.

## Cost constants (state once, in `_company.md`; link elsewhere)

- Transfer: chicken PHP 175/unit, liempo PHP 140/unit
- Packaging: PHP 5/unit chicken, PHP 5/unit liempo
- Sauce: PHP 4/portion, 1 per ORDER (not per unit)
- Charcoal/day: PHP 300 if daily sales <10K, PHP 400 if >=10K, PHP 600 if >=20K
- Rent: flat per month regardless of operating days
- B1T1 Combo = 1 chicken + 1 liempo

P&L must always show packaging, sauce, COGS, charcoal, salary, rent as SEPARATE
line items, transfer cost split into chicken and liempo columns, amounts based
on actual units sold.

## Operating reality (2026-09-12)

~485 chicken heads + ~56 liempo slabs/day; weekly 2,978 chicken + 352 liempo;
weekly commissary cost ~PHP 570,710; growth +62.7%; margins 15.1% transfer /
37.3% sawsawan / 24.1% packaging. Transfer is baste-only. Fresh chicken ordered
day-before from 4 suppliers; liempo frozen/imported, ordered ahead.
14 branches registered, 5 open; 3 franchisees active. API: https://lolobuds.vip
Taytay (Rizal Avenue, branch 210001) first sale 2026-08-13.

## Agent workforce

17 agents across 5 departments. Live: Forecast Engine, Production Intel,
Commissary Controller, Expense Intel, Pipeline Orchestrator.
Agents talk over a JSON message bus (`bus.py`).

Safety ceiling that does not bend: money/legal never auto-executed; expense
writes are draft-only; scanners only read; read before write; ask when unsure;
recall degrades rather than breaks. A child agent may drop capabilities but
never add tools, spend, network, or delegation depth.

## The 4 portals

Customer (ordering/menu/promos) | Branch (staff, cashier expense upload) |
Admin (management dashboard) | Commissary (production, recipes, inventory)
