---
name: compliance-tracker
description: Track permits, licenses, and compliance items per branch. Use when logging, checking, or alerting on compliance status.
tier: 1-2
tools: bren-os CLI, supabase
---

# Compliance Tracker

## Purpose
Every branch has permits and licenses that expire. This skill tracks them all
and alerts the responsible person before expiry. No branch gets shut down because
someone forgot a renewal.

## Permit types (Philippine context)

| Permit | Issuing agency | Renewal | Who needs it |
|---|---|---|---|
| Mayor's Business Permit | City/Municipal Hall | Annual (January) | Every branch |
| BIR Registration (COR) | Bureau of Internal Revenue | One-time (update on changes) | Every branch |
| Sanitary Permit | City Health Office | Annual | Food businesses |
| Fire Safety Certificate | Bureau of Fire Protection (BFP) | Annual | Every branch |
| DTI Business Name Registration | Dept of Trade and Industry | Every 5 years | Per business name |
| DOT Accreditation | Dept of Tourism | Annual | Resorts/hotels |
| Environmental Compliance | DENR/EMB | As required | Resorts, commissary |
| Barangay Clearance | Barangay Hall | Annual | Every branch |
| Occupancy Permit | City Engineering | One-time (new construction) | New builds |
| Signage Permit | City Planning | Annual | Branches with external signage |
| PHILHEALTH/SSS/Pag-IBIG Registration | Gov agencies | One-time (employer) | Per business |
| FDA License to Operate | Food and Drug Administration | Every 2 years | Food manufacturers (commissary) |

## How to log a compliance item

```
bren-os compliance-add "<permit type>" --branch "<name fragment>" --biz <slug> \
  --agency "<issuing agency>" --expiry YYYY-MM-DD [--doc-no "<number>"] \
  [--issued YYYY-MM-DD] [--responsible "<person>"] [--notes "<details>"]
```

## How to check status

```
bren-os compliance [--biz <slug>] [--branch "<name>"] [--status ACTIVE|EXPIRING_SOON|EXPIRED]
```

## Alert logic

The daily cron job runs this check:
1. Update status: items past expiry → EXPIRED, items within 30 days → EXPIRING_SOON
2. EXPIRING_SOON items:
   - 30 days out: note in weekly ops report
   - 14 days out: alert responsible person + James
   - 7 days out: alert responsible + James + Bren
   - Day of: urgent alert to everyone
3. EXPIRED items: urgent alert, flagged as "shutdown risk"

## Escalation

- Single permit expiring → James handles
- Multiple permits expiring same week → Bren notified
- Any permit EXPIRED + no renewal in progress → Tier 3 escalation to Bren
- LGU inspection scheduled → James preps, alerts branch manager

## Philippine-specific knowledge

- Mayor's Permit renewal deadline is January 20 each year (most cities).
  Late renewal = penalty (usually 25% surcharge + 2% monthly interest).
- BIR: annual registration display required at branch. Failure = ₱1,000 fine.
- Sanitary Permit: requires health cards for all food handlers (annual medical exam).
- BFP: Fire Safety Certificate requires fire drill (usually annual).
- Barangay Clearance: needed before Mayor's Permit can be renewed.
- Processing times vary: Marikina ~3-5 business days, Taytay ~5-7, San Mateo ~3-5.
- During renewal season (January), lines are long — file early (December).

## Data source
Compliance items live in the `compliance_items` table. The `entity_id` links to
the branch (from the `entities` table where role_title = 'branch' or 'production site').
