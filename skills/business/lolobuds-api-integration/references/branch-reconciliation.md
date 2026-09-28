# Branch Inventory Reconciliation

## Procedure

Compare dispatches → sales → system inventory → physical count to find shrinkage.

### 1. Fetch all data (paginate!)

```python
# Dispatches (commissary → branch)
dispatches = fetch_all("commissary_dispatches", from_date, to_date)
# Filter: destination_branch_name, stock_name exact match
# "Whole Chicken (Marinated)" or "Liempo (Marinated)" only
# Exclude: Big Bag, Small Bag, Baste, Sauce, Atchara

# Sales (branch POS)
sales = fetch_all("sales_items", from_date, to_date)
# Must paginate — 30 days can exceed 8,000 rows
# Map products: "b1t1 combo" = 1 chicken + 1 liempo

# System inventory
inv = fetch_all("inventory", from_date=None, to_date=None)
# Filter: "Whole Chicken (Marinated)" / "Liempo (Marinated)"
# Sum freezer + thawing + cooking + rotisserie + storage
```

### 2. Compute per branch

```
Dispatched = sum(quantity_dispatched) per stock_name per branch
Sold = sum(quantity) per product mapped to chicken/liempo per branch
System = total_quantity per stock_name per branch (current snapshot)
Net = Dispatched - Sold  (positive = should still be in system)
```

### 3. Interpret

- **Sold > Dispatched** → branch had opening stock (normal)
- **System > Dispatched** → impossible without opening stock (check data)
- **Physical < System** → shrinkage: product left without POS or waste tag
- **System ≈ 0, Dispatched > 0** → branch is selling through (normal for high-volume)

### 4. Product name mapping (POS → protein)

| POS product name | Chicken | Liempo |
|---|---|---|
| b1t1 combo | +1 | +1 |
| b1t1 whole chicken | +1 | — |
| 1 pc chicken | +1 | — |
| b1t1 liempo | — | +1 |
| 1 pc liempo | — | +1 |

### Shrinkage investigation checklist

1. Check voided sales — were items served then voided to pocket cash?
2. Check edited sales — were items downgraded after the fact?
3. Check waste entries — zero waste + missing product = unreported spoilage or theft
4. Check receiving discrepancies — did the branch flag any dispatch disparities?
5. Physical count at highest-volume branches first
