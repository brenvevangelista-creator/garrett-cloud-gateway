---
name: bren-os-lolobuds
description: Lolo Buds tasks — branches, POS, loyalty, commissary ops.
---

# Lolo Buds Operational Model

## Business Structure

### Team (5 people)
| Name | Role | Scope |
|------|------|-------|
| Bren Evangelista | CEO | Strategy, capital, baste home production |
| James Notarte | Operations Manager | Branch operations, LGU compliance |
| Kevin Evangelista | Franchise Sales & Onboarding | Deal pipeline, new franchisee setup |
| Kenneth Evangelista | Area Manager | Branch efficiency, field oversight |
| Bryan Evangelista | Commissary/Production Manager | Commissary ops, production, dispatch |

### Capital
- Started with **₱300,000** initial capital
- Record all capex for corporate branches
- Track every expense to put up new branches

### Franchise Pipeline
1. Inquiry → 2. Reservation (₱50K) → 3. Deal closed (₱250K-350K) → 4. Onboarding → 5. Opening
- Each franchise branch costs **₱120K-₱150K** in capex from the deal
- **Standard inclusions:** rotisserie, 15cu freezer, tablet, 58mm thermal printer, 16-channel timer, digital food thermometer, lighted signage, tarpaulins, 100pcs chicken, 100pcs liempo, 100pcs chicken packaging, 100pcs liempo packaging, 100pcs sauce, 1 gallon baste

### Ambassador Program
- Ambassadors sell franchises at **₱399,000**
- Commission: **₱49,000** per franchisee onboarded
- Milestone: **10 franchisees = free branch**

### Commissary (Supply Chain Hub)
- **Produces:** marinated chicken, marinated liempo, chiligarlic, atchara, chicken packaging, liempo packaging, sauce
- **Role:** Separate entity collecting payments from branches, acquiring own expenses (ingredients, rent, manpower)
- **Monitors:** branch payables, inventory, production, commissary expenses

### Baste Production (2-Stage)
1. Home baste station (Bren's home): commissary sends ingredients → home produces baste → returns to commissary
2. Distribution: 200pcs chicken/liempo/mix = 1 free gallon of baste
- **Extra baste sales:** ₱180/750ml bottle, ₱850/1 gallon bottle

### Branches (14 total, 5 open)
- Sell roasted chicken, liempo, atchara, chiligarlic
- Order from commissary → commissary dispatches → branch receives and counts
- Storage: **freezer** (chicken, liempo) + **dry** (atchara, chiligarlic, sauce, packaging)
- Lechoneros pull frozen items before shift → POS won't allow sale without pull
- POS auto-deducts inventory on sale
- Branches monitor: payroll, cash advances, sales, inventory, shifts, production

### Customer Loyalty
- Chicken/liempo only: 50php = 1 point
- Rewards: 30pts = free atchara, 80pts = free chiligarlic, 200pts = free chicken OR liempo

## tRPC API (lolobuds.vip/api/trpc/)

### Auth
- `auth.login` → `staff_session` cookie (30 days, auto-refreshes)
- `auth.me` → current user info

### Commissary
- `commissary.authorityManifestReceivables` — branch payables
- `commissary.authorityReplenishmentInvoice` — invoicing
- `admin.commissaryExecutiveSummary` — overview
- `admin.supplyChainOperations` — supply chain
- `admin.createPayable` / `admin.updatePayable` / `admin.deletePayable`
- `admin.recordPayablePayment` / `admin.approveManifestArPayment`

### Branch Operations
- `admin.branches` / `admin.updateBranch`
- `admin.branchPerformanceReport`
- `admin.shifts` / `admin.shiftCashCounts`
- `admin.attendance`
- `admin.allStaff` / `admin.assignStaff` / `admin.createStaffMember`
- `admin.createCashAdvance` / `admin.listCashAdvances` / `admin.settleCashAdvance`
- `admin.saveBranchBreakevenPlan` / `admin.dailyBreakevenOverview`

### Inventory & Production
- `admin.inventoryReport`
- `admin.forwardBranchDeliveries` / `admin.forwardForwardInventory`
- `admin.submitForwardPhysicalReconciliation`
- `production.report` / `production.setWasteAlertThreshold`
- `admin.productionPosTruthTable`
- `inventory.csv` — CSV export

### Sales & POS
- `admin.salesReport` / `admin.salesByDay` / `admin.salesByPaymentMethod`
- `admin.salesHeatmap` / `admin.salesWithItems` / `admin.topItems`
- `admin.menuItems` / `admin.createMenuItem` / `admin.updateMenuItem`

### Customer & Loyalty
- `admin.customers` / `admin.customersWithRoles`
- `admin.promoteCustomer` / `admin.demoteCustomer`
- `admin.rewardSettings` / `admin.updateRewardSettings`
- `admin.listAmbassadors` / `admin.createAmbassadorPayout`

### Finance (HQ)
- `finance.logExpense` — CREATE expense
- `finance.expenses` / `finance.needsReceipt`
- `finance.bankAccounts` / `finance.bankOverview`
- `finance.recordCheque` / `finance.clearCheque`
- `finance.createTransfer` / `finance.recordClosingBalance`

### Franchise Pipeline
- `admin.createFranchiseApplication` / `admin.listFranchiseApplications`
- `admin.updateFranchiseApplicationStage`
- `admin.createFranchiseGroup` / `admin.listFranchiseGroups`

## Spine DB Tables

### 0017 — Core Operations
- `commissary_products` — what commissary produces (7 categories)
- `commissary_expenses` — commissary costs (ingredients, rent, manpower)
- `branch_payables` — what branches owe commissary
- `branch_inventory` — per-branch stock (freezer vs dry)
- `deliveries` / `delivery_items` — dispatch → receive → count pipeline
- `branch_shifts` — lechonero pulls and sales per shift
- `pos_sales` — transactions with loyalty points
- `loyalty_customers` — customer accounts with points
- `loyalty_rewards` — reward tiers (30/80/200 pts)
- `employee_cash_advances` — cash advance tracking
- `daily_metrics` — pre-computed analytics from tRPC

### 0018 — Franchise, Capital & Baste
- `corporate_team` — 5 people (Bren CEO, James Ops, Kevin Franchise, Kenneth Area, Bryan Commissary)
- `capital_accounts` — initial₱300K capital + revenue streams
- `capex_records` — every setup expense (corporate + franchise branches)
- `franchise_deals` — full pipeline (inquiry → reservation → deal → onboarding → open)
- `franchise_payments` — reservations + installments per deal
- `franchise_inclusions` — what each franchisee gets (14 items)
- `franchise_inclusion_template` — standard template auto-copied per new deal
- `ambassadors` — sell at₱399K, earn₱49K/sale, free branch at 10 sales
- `ambassador_commissions` — per-sale commission tracking
- `baste_products` — 750ml=₱180, 1 gallon=₱850
- `baste_production` — home station flow (commissary→home→commissary)
- `baste_distribution` — per-branch delivery + free gallon rules
- `commissary_metrics` — daily: expenses, cost of product, income, stock

## Agent Boundaries
| Agent | Reads | Writes | Never |
|-------|-------|--------|-------|
| scan-admin.ts | LB tRPC | admin_snapshots | Website UI |
| scan-websites.ts | Public pages | website_metrics | Auth data |
| bren-os-cli | Spine DB | Spine DB | Websites |
| manus-cli | Manus API | Website changes | Spine DB |
| secretary cron | Spine DB | Reports | Websites |

## Key Rule
Only `manus-cli` writes to lolobuds.vip. Scanners read-only. Spine DB is source of truth.