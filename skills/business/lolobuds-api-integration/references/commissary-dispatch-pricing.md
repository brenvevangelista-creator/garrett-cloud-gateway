# Commissary Dispatch Stock Names & Transfer Prices

Actual values from `commissary_dispatches.transfer_price_per_unit` as of 2026-09-14.
Always read from data; prices may change.

## Protein

| Stock Name | Transfer Price | COGS | Margin |
|---|---|---|---|
| Whole Chicken (Marinated) | ₱175 | ₱148.95–151.09 | 13.7–14.9% |
| Liempo (Marinated) | ₱140 | ₱95.54–119.18 | 14.9–31.8% |

Transfer prices re-verified from the API 2026-09-18: only ₱175 and ₱140 appear,
no variants.

**Verified volume (API, 30 days to 2026-09-18):** 310.5 chicken heads/day and
186.2 liempo slabs/day; September run rate 354.4 and 222.6. Do NOT use
`operations.md`'s "~56 slabs/day" or the old 237.08 model figure — both wrong.
Annualise at 113,333 heads and 67,963 slabs.

## Add-ons

| Stock Name | Transfer Price | Notes |
|---|---|---|
| Lolo Special Sauce (Pack) | ₱4 | Per cup/pack |
| Big Bag w/ Sticker (Chicken) | ₱5 | Per bag |
| Small Bag w/ Sticker (Liempo) | ₱5 | Per bag |
| Baste — 750 ml Bottle | ₱180 | Margin ~₱5 (2.8%) |
| Baste — 1 Gallon Bottle | ₱850 | Actual selling price (dispatch system may record ₱616.25 — confirm with user) |
| Atchara | Price varies | Check data |

## COGS breakdown (from recipe.json v3.1)

**Chicken** (₱150.94 total, system basis):
- Raw chicken: ₱131.18 — receipts show ₱129.19–131.33/head at ₱138–150/kg
- Marinade: ₱9.03
- Stuffing: ₱4.38
- Baste: ₱6.35
- Add-ons total: **₱19.76/head**

**Liempo** (₱97.88 at the 0.375 kg system slab; ₱107.12 at the 410 g midpoint):
- Raw liempo: ₱228–240/kg. Slab spec is **370 g minimum – 450 g maximum**
  (NOT 400 g flat) → raw ₱84.36–108.00
- Marinade: ₱4.83
- Baste: ₱6.35
- Add-ons total: **₱11.18/slab**

> The old ₱151.41/head (@ ~1.1 kg) and ₱107.64/slab (@ 400 g) figures were
> computed, never paid. Do not reintroduce them.

**Baste per piece** (₱5.96):
- Butter 21g: ₱3.92 (66%)
- Honey 7ml: ₱1.12
- Soy 3ml: ₱0.14
- Ketchup 7ml: ₱0.46
- Atsuete 2g: ₱0.32

## Key insight

Sauce, bags, and baste bottles are **separate income streams** from protein transfer income. They live in `commissary_dispatches`, NOT in `sales_items` (which is POS retail). When computing total commissary income, include all stock names from dispatches, not just chicken and liempo.
