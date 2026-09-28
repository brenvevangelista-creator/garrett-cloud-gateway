# Unit economics for commissary / franchise models

## Confirm the unit spec before costing anything

**Ask the owner what they actually buy, in weight, before trusting any cost
line.** Recipe docs drift from purchasing reality, and a wrong weight silently
corrupts every downstream number — per-kg rates, margin, and whether vertical
integration is worth anything.

For each input capture: **standard spec, fallback spec, and form**. Real example:
chicken standard 0.8 kg / fallback 0.9 kg when unavailable; pork liempo cut from
**frozen** slabs at 370–450 g. A doc claiming "~1.1 kg" against a real 0.8 kg
spec makes a ₱151 bird look like ₱138/kg when it is really ₱189/kg — a 37% error
in the per-kg rate that reverses the make-or-buy conclusion.

Always derive and state the **price per kg**, not just per head. Per-head hides
spec drift; per-kg is comparable to market and to a grower quote.

Where a spec is a range (370–450 g), cost at the **midpoint** and flag that a
range means variable portion cost and inconsistent customer value — tighten the
spec or price for the midpoint.

## Recompute every stated total

Components that don't sum to the stated total are common and expensive. When you
find a gap:

1. Compute both candidate answers and the **annual value of the difference**
   (`gap × units/day × 365`).
2. Independently re-cost the formulation from the recipe file at market prices.
3. Cross-check a sibling product — if pork's breakdown adds up and chicken's
   doesn't, the error is one cell, not the formulation.
4. Label your own prices as estimates and ask for **one real batch costed from
   receipts**. State that it blocks everything downstream.

## Transfer price as a ceiling

When the owner says a transfer price is the *maximum*:

| Rule | Owner |
|---|---|
| Exceed it | Forbidden — escalate the cost overrun, never reprice branches upward |
| Lower it | Owner only, after a **verified sustained** cost reduction |
| Sequencing | **Cost reduction leads, price reduction lags** |

Always quantify sensitivity: `₱1/unit × units/day × 365`. At ~350 units/day that
is ~₱127k/year per peso — which makes a proposed ₱35 cut visibly equal to the
entire annual margin.

## Food cost is an offer problem first

Get the **actual menu** from the owner before computing anything, and never infer
it from a cost document. Real failure: a master doc listed the transfer prices
(₱175 / ₱140) under a heading "Menu Prices (to customers)" — reading it that way
implies zero branch margin and corrupts every food cost figure downstream. Ask
explicitly: single price, bundle price, and **what the bundle contains**.

Compute `branch cost ÷ retail` per **menu item**, then bound the blended figure
between the all-singles and all-bundles cases. Without the sales mix you get a
range, not a number — say so instead of inventing a point estimate.

**The classic flaw is one price for two different costs.** Two products at the
same ₱260 whose transfer costs differ by 25% (₱175 vs ₱140) means one is at 53.8%
food cost and the other at 67.3%. The business does not have a menu-wide food
cost problem; it has a problem with one SKU. Isolate it before proposing
anything broad.

**Check what a bundle actually discounts.** Do not assume "buy one take one"
means free — compute `bundle price` vs `n × single price`. A ₱498 bundle against
two ₱260 singles is a 4.2% discount: too small to change behaviour, big enough to
cost margin on every transaction.

**Flat bundle pricing causes adverse selection.** When one bundle price covers
combinations whose costs span ₱280–₱350, the customer's best-value pick is the
worst-margin one — and it is usually the hero product. Mix drifts there by
itself and blended food cost decays with no operational change. Differentiated
pricing is normally the cheapest available margin action: no capex, no supplier
negotiation.

## Test whether the target is even reachable

Before accepting a food cost target, solve it from **both** sides and show the
owner which one is arithmetically possible:

1. **Cost side:** required transfer price = `retail × target`. Compare to
   commissary COGS. If it lands below COGS, the target is unreachable from
   operations — state that plainly rather than proposing capex against it.
2. **Price side:** required average retail = `transfer cost ÷ target`. Express as
   a % increase.

**Then check pricing power against the unit spec**, because portion size caps
price. A 0.8 kg bird at ₱260 is already ₱325/kg retail; ₱350 would be ₱438/kg,
against competitors selling a 1.0–1.2 kg bird for ₱400–500. So a third path
exists that cost-reduction thinking never surfaces: **upsize the unit.** Adding
₱30–35 of raw cost to make a 35% price rise defensible can beat every efficiency
project combined.

When a target needs a 12–15 point move, say which lever owns it and which lever
does not. Let the efficiency programme *protect* margin; do not let it carry a
target the arithmetic says it cannot deliver.

## Sizing vertical integration honestly

Derive the current **per-kg** input price first — the make-or-buy answer depends
entirely on it, so this is why the unit spec must be confirmed up front.

Build the buy-side comparison explicitly: `live weight needed = dressed spec ÷
dressing yield` (poultry ≈ 70–75%), then `live × grower ₱/kg + processing cost
per head`. Compare to the current dressed price. If the owner already buys at a
competitive per-kg rate, a plant will **not** deliver a large per-head cut.

The non-cost benefits are usually the real case:

- supply **control** and continuity at scale
- insulation from input shocks that erase thin margins
- consistent **size spec** (which downstream equipment and recipes require)
- captured processing margin, plus by-product revenue (offal, feet, necks)

State plainly what it will not do: close a 20-point food cost gap. Never let a
capex project carry a target that arithmetic says it cannot reach.

## Capex gates

Tie equipment and plants to a **volume trigger**, and show the distance to it:
current units/day, units per outlet, and projected volume at the trigger. Compute
payback as `saving/unit × units/day × 365` against machine cost.

Prefer the near-term process machine (consistency + waste reduction) over the
far-term plant. For a franchise system, **consistency is a system asset** — every
branch tasting identical is what is actually being sold to a franchisee, and hand
processes cannot deliver it at scale.
