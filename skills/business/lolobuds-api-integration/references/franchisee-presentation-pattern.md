# Franchisee Presentation Pattern

Standard slide structure and data procedure for Lolo Buds stakeholder presentations.

## Data Procedure

### 1. Pull sales data

Query API month-by-month (max 90-day range) or use cached JSON in `/tmp/lolobuds_sales/`.

Product name mappings:
- "1 pc Chicken" → chicken
- "1 pc Liempo" → liempo
- "B1T1 Combo" → count as 1 chicken + 1 liempo (see also SKILL.md pitfall)

### 2. Calculate operating days

API returns aggregates only. Use branch schedule:
```
operating_days = calendar_days ÷ 7 × days_per_week
```

### 3. Build P&L per branch

Follow `branch-pl-cost-rules.md` for all 8 line items. Transfer chicken and liempo as SEPARATE columns.

### 4. Aggregate network totals

Sum all branches. Include total operating days across network.

## Slide Structure (11 slides)

| # | Slide | Content |
|---|-------|--------|
| 1 | Title | Network name, date, tagline |
| 2 | Network at a Glance | 3-4 metric cards: total revenue, branches, units sold, network net |
| 3 | Monthly Revenue Growth | Bar chart or table, month-over-month |
| 4 | Branch Rankings | Table: operating days, revenue, net. Green for profit, red for loss |
| 5 | Unit Economics | Transfer prices, COGS breakdown, margins per protein |
| 6 | Network P&L | Aggregated table, all 8 line items, split transfer columns |
| 7 | Top Performers | Highlight best branches with key metrics |
| 8 | Challenges & Action Items | Problem branches, specific corrective actions |
| 9 | Growth Story | Trajectory, milestones, franchise pipeline status |
| 10 | Franchise Opportunity | Investment, ROI, support structure |
| 11 | Next Steps | Action items, timeline, owners |

## Visual Style

Bren's preference: aggressive, cinematic, dark-themed — NOT clean corporate.

- Background: dark navy (#1a1a2e or #16213e)
- Accent: green (#00d4aa) for positive, red (#ff6b6b) for negative
- Metric cards: rounded rectangles with large value text
- Tables: alternating row colors, bold headers
- Use python-pptx directly for custom layouts (powerpoint skill's JSON spec supports basics but not custom shapes)

## Output

Save to `~/Desktop/<Name>_MonYYYY.pptx`. Open with `open` command.
