# P&L Reporting — Lolo Buds Branches & Network

Use when Bren asks for a branch P&L, network comparison, or cost breakdown.

## Master document
Single source of truth: `~/projects/garrett-deploy/LOLOBUDS_MASTER.md`. Read it first, update it in place. Bren explicitly wants ONE living file — "i dont want to be repeating details."

## Line items (ALL must appear as SEPARATE rows)
Bren will flag any missing line item. Never bundle into a single COGS row.

1. **Revenue** — from sales API (`/api/sales`)
2. **Transfer chicken** — units × ₱175
3. **Transfer liempo** — units × ₱140
4. **Packaging** — units × ₱5
5. **Sauce** — orders × ₱4 (per ORDER, not per unit)
6. **Charcoal** — tiered by daily revenue (see below)
7. **Salary** — per-branch staffing (see `bren-os-lolobuds` skill for table)
8. **Rent** — flat monthly, never prorated

## Charcoal tiers
| Daily revenue | Daily cost |
|---|---|
| < ₱10,000 | ₱300/day |
| ≥ ₱10,000 | ₱400/day |
| ≥ ₱20,000 | ₱600/day |

## Sauce allocation rule
1 sauce per ORDER, not per unit. A B1T1 combo = 1 sauce. Individual chicken or liempo = 1 sauce each.

## Rent rule
Flat per month regardless of operating days. Never prorate by days open.

## Table format
Bren wants a **Calc column** showing the math, then an Amount column:

| Line Item | Calc | Amount |
|---|---|---:|
| Revenue | | ₱XXX |
| Transfer chicken | 2,082 × ₱175 | ₱364,350 |
| Packaging | 2,584 × ₱5 | ₱12,920 |
| Sauce | 1,452 × ₱4 | ₱5,808 |
| Charcoal | 62 days × ₱300 | ₱18,600 |
| Salary | 3 × ₱700 × 7d/wk × 4.33mo | ₱63,651 |
| Rent | | ₱15,000 |
| **NET** | | **₱XX,XXX** |

## Network total
After all individual branch P&Ls, add a NETWORK GRAND TOTAL table summing all branches + commissary.

## Rankings
Include a ranked table by monthly net with 🟢/🔴 indicators and margin %.

## Red/Green flags
After the tables, list:
- **Red flags**: branches losing money, at razor's edge, or trending down
- **Green flags**: top earners, high margins, volume trends

## Branch staffing (corrected 2026-09-17)
| Branch | Staff | Rate | Days/wk | Monthly Salary | Rent/mo |
|---|---|---|---|---:|---:|
| Commissary | 6 | ₱700 | 7 | ₱84,868 | ₱17,000 |
| Anadels | 3 | ₱700 | 6 | ₱54,558 | ₱12,000 |
| Ayala | 3 | ₱700 | 6 | ₱54,558 | ₱18,000 |
| Concepcion | 2 | ₱700 | 7 | ₱42,434 | ₱20,000 |
| Banaba | 4 | ₱600 | 5 | ₱51,960 | ₱20,000 |
| Taytay | 3 | ₱700 | 7 | ₱63,651 | ₱20,000 |
| Friendly | 3 | ₱700 | 7 | ₱63,651 | ₱15,000 |

Formula: `staff × rate × days_per_week × 4.33` (rounded to nearest peso).

## Sales API product IDs and B1T1 counting
The sales API (`/api/sales`) returns line items by product ID. B1T1 combos must be split:

| Product ID | Name | Count as |
|---|---|---|
| 60001 | 1 pc Chicken | 1 chicken |
| 60002 | 1 pc Liempo | 1 liempo |
| 30001 | B1T1 Whole Chicken | 2 chicken |
| 30002 | B1T1 Liempo | 2 liempo |
| 30003 | B1T1 Combo | 1 chicken + 1 liempo |

**Never count B1T1 Combo as chicken-only.** The old report counted combo units as all chicken, inflating chicken transfer and understating liempo. Total units stay the same but the split changes — and since liempo is cheaper (₱140 vs ₱175), the correct split lowers total transfer cost.

Sum per branch: `chicken = qty[60001] + qty[30001]*2 + qty[30003]`, `liempo = qty[60002] + qty[30002]*2 + qty[30003]`.

## Sales API parameters
Current: `?branch_id=X&from=YYYY-MM-DD&to=YYYY-MM-DD` with `Authorization: Bearer <key>`.
Previously used `start_date`/`end_date` — those now return 403.

## Pitfalls
- **Sales API max 90 days per request.** Query month-by-month for longer ranges.
- **Sauce is per ORDER, not per unit.** Counting per unit overstates sauce cost and makes branches look worse.
- **Rent is flat monthly.** Prorating by operating days understates cost and inflates net.
- **Banaba uses ₱600/day rate and 5 days/week** — different from all other branches. Never apply ₱700 or 7d/wk uniformly.
- **Packaging and sauce are branch costs**, not included in commissary transfer price. Report them separately.
- **Charcoal minimum is ₱300/day.** Even if revenue is ₱0, branches need charcoal to cook. Never show ₱0 charcoal.
- **B1T1 Combo = 1 chicken + 1 liempo.** Counting it as all chicken inflates chicken transfer by ₱35 per combo unit (₱175 − ₱140). This made Anadels look ₱78K more expensive than reality.
- **`execute_code` Python environment does not inherit shell `source`d env vars.** When calling APIs from execute_code, read the key file explicitly in Python (`open(os.path.expanduser('~/.config/bren-os/env'))`) or use `terminal` with curl.
- **`terminal` piped to `python3` exits 137.** For large API responses, curl to a temp file first, then process with Python separately.
