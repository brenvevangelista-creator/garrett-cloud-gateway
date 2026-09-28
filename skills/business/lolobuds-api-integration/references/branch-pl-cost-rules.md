# Branch P&L Cost Rules

Cost allocation rules for building per-branch profit & loss reports from Lolo Buds API data.

## Operating days

Calculate from branch schedule, NOT from API (API returns aggregates only).

```
operating_days = calendar_days_in_period ÷ 7 × days_per_week_per_person
```

Use each branch's actual start date and days/week. Round to nearest integer.

## Charcoal tiers

Based on average daily revenue:

| Avg Daily Revenue | Charcoal/Day |
|---|---|
| < ₱10,000 | ₱300 |
| ≥ ₱10,000 | ₱400 |
| ≥ ₱20,000 | ₱600 |

```
avg_daily_rev = branch_revenue ÷ operating_days
total_charcoal = charcoal_tier × operating_days
```

## Sauce allocation

- ₱4 per ORDER, not per unit
- 1 chicken = 1 order = 1 sauce
- 1 liempo = 1 order = 1 sauce
- 1 B1T1 combo = 1 order = 1 sauce (NOT 2)
- Use total orders count from API for sauce cost

## Packaging

- ₱5 per chicken unit
- ₱5 per liempo unit
- Applies to every individual unit, including units inside B1T1 combos

## Transfer prices

| Item | Transfer Price | COGS |
|---|---|---|
| Whole Chicken | ₱175 | ₱151.41 |
| Liempo | ₱140 | ₱107.64 |

## P&L line items (user-standard order)

1. Revenue
2. Transfer chicken (units × ₱175)
3. Transfer liempo (units × ₱140)
4. Packaging (total units × ₱5)
5. Sauce (total orders × ₱4)
6. Charcoal (tier × operating days)
7. Salary
8. Rent (flat per month, NOT prorated)

All 8 items as SEPARATE line items. Transfer chicken and liempo are SEPARATE columns. Always include operating days in the branch header.

## Rent rule

Rent is flat per month regardless of operating days or sales. Do not prorate.

## Master file scope

When saving to `LOLOBUDS_MASTER.md`, save ONLY expenses, manpower, and rent — not the full transfer-breakdown P&L columns.