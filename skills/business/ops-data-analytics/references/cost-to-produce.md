# Cost-to-Produce Profitability Analysis

Use when Bren asks "will we earn from X" or "is this batch profitable" — forward-looking COGS vs revenue, not historical sales P&L.

## Data Sources
- **recipe.json** (`~/projects/garrett-deploy/recipe.json`): per-unit ingredient costs for marinade, stuffing, basting glaze, sawsawan, packaging. Version-controlled, last updated field at top.\- **User-provided purchase prices**: raw chicken/liempo buy prices for the batch in question. These change daily; never use recipe.json's `raw_chicken.cost_per_pc` when the user gives actual prices.
- **Lolo Buds API** (`/api/reports/daily`, `/api/reports/today`): actual sales volumes and revenue when doing historical P&L.

## Procedure

1. **Get batch quantity and purchase price from user.** They'll say something like "330 pcs at 140.067 and 300 at 148.90". Compute weighted average cost per unit.

2. **Read recipe.json** for the product type (chicken or liempo). Extract:
   - `marinade.cost_per_pc` — always include
   - `stuffing.cost_per_pc` (chicken only)
   - `basting_glaze.cost_per_pc`
   - Do NOT include `raw_chicken.cost_per_pc` or `raw_liempo.cost_per_pc` — the user gives actual purchase prices

3. **Compute COGS per unit:**
   ```
   COGS = actual_raw_cost + marinade + stuffing + basting_glaze
   ```

4. **Get selling price.** If not specified, use `transfer_pricing` from recipe.json (₱175 chicken, ₱140 liempo). Bren means transfer price (commissary → branches) when he asks about earning from production.

5. **Compute profit:**
   ```
   revenue = qty × selling_price
   total_cogs = qty × cogs_per_unit
   profit = revenue - total_cogs
   margin_pct = profit / revenue × 100
   ```

6. **Flag if margin < 10%.** Bren considers <10% tight. Note the delta vs recipe-standard raw cost to show how much purchase price is eating margin.

## Output format
- Use `cat << 'EOF'` in terminal for aligned tables (Bren likes the box-drawing style)
- Lead with verdict (profitable/not), then show the math
- Include per-unit breakdown so he sees WHERE the cost sits
- Include comparison to recipe-standard cost when actual price is higher
- Keep it to one screen — no scrolling

## Pitfall
- **Don't confuse transfer price with menu price.** Transfer = ₱175 (commissary sells to branch). Menu = ₱260-498 (branch sells to customer). Bren asks about commissary profitability, not branch-level.
- **recipe.json `raw_chicken.cost_per_pc` is a STANDARD cost, not actual.** Always use user-provided prices for the batch being analyzed.