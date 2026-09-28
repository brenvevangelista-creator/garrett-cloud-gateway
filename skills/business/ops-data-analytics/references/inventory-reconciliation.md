# Inventory Variance Reconciliation — Branch Level

Use when Bren asks why there's a variance, missing items, or inventory difference at a branch. Pull data from all three legs (dispatched, sold, on-hand) and reconcile.

## API Resources (Lolo Buds)

| Resource | What it gives | Latency | Use for |
|---|---|---|---|
| `comm_dispatches` | Commissary → branch shipments (date, items, qty) | Real-time | Dispatched leg |
| `sale_items` | Individual POS line items (product, qty, price, date) | Near real-time (through today) | Sold leg |
| `sales` | Daily aggregated sales (totalAmount, cashAmount, gcashAmount) | 2-3 days behind | Cash vs GCASH split |
| `inventory` | Current on-hand by location (freezer, rotisserie) | Real-time | On-hand leg |
| `stock_movements` | Full inventory movement history | Real-time | Deep audit trail |

**Critical**: `sale_items` is more current than `sales`. For a same-day audit, use `sale_items` for the sold count and only use `sales` for the payment-method breakdown.

## Procedure

1. **Pull dispatches** via `comm_dispatches` resource, filtered by `destination_branch_id`. Confirm each batch was received in full (check `received` or `status` fields). Sum dispatched qty per product type.

2. **Pull sale_items** (paginated, offset loop until short page). Filter by branch and date range. Group by product_id and date. 

3. **Pull current inventory** via `inventory` resource. Sum freezer + rotisserie for each product type.

4. **Compute the gap:**
   ```
   gap = dispatched − sold − on_hand
   ```
   Report as units AND percentage of dispatched. Low single-digit % = ordinary shrinkage (thawing, drip loss, minor spoilage). Flag > 5% for investigation.

5. **Check payment methods** from `sales` endpoint (if data is current enough). Flag anomalies like 100% cash on a day that normally has GCASH — may indicate a terminal or shift issue.

6. **Identify root causes** — see Variance Decision Tree below.

## B1T1 Physical Item Counting

B1T1 (Buy 1 Take 1) promos sell **2 physical items per POS transaction**:

| POS Product | Physical items per sale |
|---|---|
| 1pc Chicken | 1 chicken |
| 1pc Liempo | 1 liempo |
| B1T1 Combo (₱498) | 1 chicken + 1 liempo = **2 items** |
| B1T1 Whole Chicken | 2 chicken = **2 items** |
| B1T1 Liempo | 2 liempo = **2 items** |

When computing sold count from `sale_items`, each B1T1 row contributes 2 to the physical item count, not 1. A raw count that ignores this produces an artificially large "missing" gap.

Product ID mapping:
- 60001 = 1pc Chicken (×1)
- 60002 = 1pc Liempo (×1)
- 30001 = B1T1 Whole Chicken (×2 chicken)
- 30002 = B1T1 Liempo (×2 liempo)
- 30003 = B1T1 Combo (×1 chicken + ×1 liempo)

## Variance Decision Tree

```
Gap > 0 (more dispatched than accounted for)?
├─ B1T1 counted as 1 instead of 2? → Recount with physical multiplier
├─ On-hand not subtracted? → Add freezer + rotisserie to accounting
├─ Gap 1-5% after corrections? → Normal shrinkage (thawing, drip, spoilage)
├─ Gap > 5% concentrated in one period? → Investigate: theft, unreported waste, receiving error
└─ Gap > 5% spread evenly? → Likely systematic (prep waste, portioning variance)

Gap < 0 (more sold than dispatched)?
├─ Opening stock not counted? → Check if branch had pre-existing inventory
├─ Dispatch data incomplete? → Check date range, pagination
└─ Receiving lag? → Dispatch recorded but delivery not yet confirmed
```

## PDF Report Output

When the user wants a PDF of the variance report, build a JSON spec with these elements:
1. Title + author metadata
2. Section: Dispatches table (date, chicken, liempo, total)
3. Section: Items sold table (by product type, by date)
4. Section: Cash vs GCASH table (by date, with totals and %)
5. Section: Daily reconciliation (dispatched vs sold vs cumulative surplus)
6. Section: Problem statement (raw gap numbers)
7. Section: Analysis (B1T1 correction, root cause)
8. Section: Recommendations

Save spec to `/tmp/`, run `python3 scripts/pdf_create.py spec.json -o ~/Desktop/filename.pdf`. Use `python3` explicitly — `python` may resolve to a different interpreter that lacks reportlab.

Verify with `python3 scripts/pdf_read.py output.pdf --meta` — confirm page count and metadata.

## Pitfalls

- **B1T1 is 2 items, not 1.** The single most common source of phantom variance. A branch with 188 B1T1 Combo sales has 376 physical items consumed, not 188.
- **`sales` endpoint lags `sale_items` by 2-3 days.** Never use `sales` for same-day item counts; use it only for cash/GCASH breakdown.
- **Negative gap ≠ error.** It means uncounted opening stock or a receiving lag. Surface it; don't drop it.
- **Subtract on-hand before alarming.** Dispatch-minus-sales alone treats freezer stock as shrinkage.
- **Paginate sale_items.** Default page size is 500 rows. A busy branch in a 2-week window easily exceeds one page. Loop offset until a short page returns.
- **Cash/GCASH anomalies**: a day showing 100% cash when the branch normally runs 80/20 may indicate a GCASH terminal outage or shift-level reporting gap — flag for ops follow-up, not inventory.
