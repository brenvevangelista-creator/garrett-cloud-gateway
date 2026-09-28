# Lolo Buds Branch IDs

Fetched from `/api/branches`. Update when new branches open.

| ID | Branch | Status | Active |
|----|--------|--------|--------|
| 1 | Anadels Parang | open | ✅ |
| 90001 | Concepcion 1 | open | ✅ |
| 150001 | Banaba, San Mateo | open | ✅ |
| 210001 | Rizal Avenue Taytay | open | ✅ |
| 270001 | Friendly Village | open | ✅ |
| 450001 | Batingan, Manila East - Binangonan | open | ✅ |
| 120002 | Ayala Malls Arvo Marikina Heights | opening_soon | ✅ |
| 150002 | Panorama Ext., Cupang | opening_soon | ✅ |
| 180001 | L. Sumulong Memorial Circle | closed | ❌ |
| 300001 | Lamuan, Malanday | opening_soon | ✅ |
| 300002 | Lilac, Concepcion | opening_soon | ✅ |
| 330001 | Panorama Ext., Cupang | opening_soon | ✅ |
| 360001 | Magdiwang Highway, Kawit | opening_soon | ✅ |
| 390001 | BoyNIta TayTay Arena | opening_soon | ❌ |
| (others TBD) | | | |

**Total: 16 branches (6 open, 9 opening_soon, 1 closed).**

**Commissary is NOT a branch.** It has no branch_id in the API. The `expenses` resource requires `branch_id`; querying with `scope=commissary` returns 403 Forbidden. Commissary payroll and expenses are not accessible through the public API.

### Payroll access
- Branch salary expenses: `/api/query?resource=expenses&branch_id=X&from=YYYY-MM-DD&to=YYYY-MM-DD` with `category: "salaries"`
- Commissary payroll: **not available** — "excluded by design" per API docs
- Supabase `lolo_buds_expenses` table: **empty** — data lives in API backend only

### Portal behavior
- Commissary portal caches branch status. After changing status (e.g. `opening_soon` → `open`), dispatch portal may still block with "branch is not available" until hard-refresh (`Cmd+Shift+R`) or logout/login.
