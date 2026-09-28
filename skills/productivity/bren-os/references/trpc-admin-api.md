# tRPC Admin API Reference — LB & EP

Both lolobuds.vip and espressoplayground.vip use **tRPC** (not REST). All endpoints are at `/api/trpc/<procedure>`. Authentication is cookie-based (not Bearer token).

## Auth Flow

### LB (lolobuds.vip) — curl works
```
curl -s -D /tmp/lb_headers.txt -X POST "https://lolobuds.vip/api/trpc/auth.login" \
  -H "Content-Type: application/json" \
  -d '{"json":{"email":"***","password":"***"}}'
# Parse staff_session cookie from Set-Cookie header in /tmp/lb_headers.txt
# Cookie: staff_session=eyJhbG... (JWT, 30-day rolling expiry, auto-refreshes on use)
```

Auth check: `GET /api/trpc/auth.me` with cookie → user profile (name, email, role, accessRole).

### EP (espressoplayground.vip) — curl returns 500

EP's auth endpoint rejects curl requests (likely CSRF or UA filtering). Two workarounds:
1. **Browser CDP:** Log in via `browser_exec(local=True)`, extract cookie via `cdp('Network.getCookies', urls=[...])`
2. **Stored cookie:** Save `app_session_id` to env file (~1 year expiry). When expired, re-login via browser.

## LB Admin Endpoints

All require `staff_session` cookie. Use `?batch=1&input={"0":{"json":null}}` format.

| Procedure | Data returned |
|-----------|--------------|
| `admin.dashboard` | Today's revenue, order count, total customers |
| `admin.branches` | Full branch list with coordinates, hours, production targets |
| `admin.branchPerformanceReport` | Revenue per branch, order counts, averages |
| `admin.dailyBreakevenOverview` | Per-branch daily breakeven status (needs date input) |
| `admin.expensesByCategory` | Expense breakdown: ingredients, COGS, salaries, etc. |
| `admin.customers` | Customer list with loyalty points, QR codes, contact info |
| `admin.commissaryExecutiveSummary` | Stock levels, manifests, production batches |
| `admin.bankAccounts` | Bank account details |
| `admin.branchAccounts` | Per-branch financial accounts |
| `admin.attendance` | Staff attendance records |
| `admin.enrollments` | Franchise enrollment pipeline |
| `admin.pendingExpenses` | Expenses awaiting approval |
| `admin.expensesReport` | Full expense report |
| `admin.expensesByDay` | Daily expense aggregation |
| `admin.listExpenses` | Filtered expense list |

Also available: `staff.list`, `staff.schedule`, `expenses.csv`, `inventory.csv`, `transactions.csv`.

### LB Expense Mutations (WRITE-CAPABLE)

| Procedure | Purpose | Namespace |
|-----------|---------|----------|
| `finance.logExpense` | **Create new expense** | `finance` (not `admin`) |
| `admin.updateExpense` | Edit existing expense | `admin` |
| `admin.approveExpense` | Approve pending expenses | `admin` |
| `admin.rejectExpense` | Reject expenses | `admin` |
| `admin.deleteExpense` | Remove expenses | `admin` |
| `admin.recordExpense` | Franchise accounting expense | `admin` (under `franchiseAccounting` namespace in JS) |

`finance.logExpense` input shape:
```json
{
  "scope": "branch" | "hq",
  "branchId": 1,
  "bankAccountId": 5,
  "category": "Ingredients",
  "amount": 1500,
  "description": "Chicken delivery",
  "receiptUrl": "https://...",
  "expenseDate": "2026-09-08",
  "dateOverrideReason": ""
}
```
- `branchId` required only when `scope === "branch"`
- `bankAccountId`, `description`, `receiptUrl`, `dateOverrideReason` are all optional
- `receiptUrl` comes from a separate upload mutation first
- Response includes `status` field — can be `"draft"` if receipt is still required

## EP Admin Endpoints

All require `app_session_id` cookie.

| Procedure | Data returned |
|-----------|--------------|
| `admin.dashboard` | Today's orders, branch counts |
| `admin.getFranchiseDashboard` | Per-branch revenue vs targets (Marikina, Cainta) |
| `admin.getFranchiseInsights` | Full sales history, top products, daily breakdowns (~240KB) |
| `admin.getTerritories` | Territory map: 104 cities, 131 franchise slots |
| `admin.analytics` | Aggregated analytics |
| `admin.customers` | Customer list |
| `admin.menu` | Menu items and pricing |

**EP has NO expense write endpoints.** All EP expense management must go through Manus API tasks.

## Key Patterns

1. **tRPC batch format:** `?batch=1&input={"0":{"json":<payload>}}` — even null payloads need the wrapper.
2. **Cookie auth only** — both sites reject Authorization headers; sessions are cookie-bound.
3. **Admin JS chunks** contain procedure names — fetch the chunk URL from the SPA HTML `<script>` tags, download it, grep for `/api/trpc/` to enumerate all endpoints.
4. **Rate limits:** None observed, but large responses (EP insights = 240KB) may need increased timeout (120s recommended).
5. **Mutation vs query detection:** In minified JS, `.useMutation(` marks write endpoints, `.useQuery(` marks read endpoints. The namespace prefix before the dot (e.g., `finance.`, `admin.`, `franchiseAccounting.`) indicates the tRPC router.
6. **Shell quoting for curl POST:** Always write JSON payloads to a temp file and use `curl -d @/tmp/file.json` — inline JSON with embedded quotes breaks `execSync` shell parsing.