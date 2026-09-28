---
name: lgu-procedures
description: Local government unit permit procedures, contacts, and quirks per city. Use when filing renewals, preparing for inspections, or answering compliance questions.
tier: 2
tools: bren-os CLI, supabase, web search
---

# LGU Procedures — Per City Reference

## Purpose
Each city/municipality has different offices, processes, and quirks.
This skill captures what we've learned from actual renewals so the
compliance agent doesn't start from zero each time.

## General renewal sequence (all cities)

```
1. Barangay Clearance        ← needed before step 2
2. Mayor's Business Permit   ← needs barangay clearance
3. BIR Registration display  ← independent, but check annually
4. Sanitary Permit           ← needs health cards for food handlers
5. Fire Safety Certificate   ← BFP inspects, may require fire drill
6. Other permits as needed   ← signage, environmental, etc.
```

## Marikina City

**Mayor's Permit Office:** Business Permit and Licensing Office (BPLO),
Marikina City Hall, J.P. Rizal St.
**Processing time:** 3-5 business days (if complete documents)
**Requirements:**
- Barangay Clearance (from the barangay where branch is located)
- Previous year's Mayor's Permit (renewal)
- Lease contract or property ownership docs
- Community Tax Certificate (CEDULA)
- Fire Safety Certificate (BFP Marikina)
- Sanitary Permit (City Health Office)
- Sketch/plan of establishment
**Fees:** Based on gross receipts. ₱2,000–₱10,000 typical for food businesses.
**Penalty for late renewal:** 25% surcharge + 2% monthly interest
**Tips:**
- File early December to avoid January rush
- BPLO hours: 8AM-5PM, Mon-Fri
- Bring extra photocopies of everything
- Online pre-registration available at marikina.gov.ph (check if still active)

**BFP Marikina:** Separate application. May require inspection visit.
Fire Safety Certificate fee: ~₱500-2,000 depending on establishment size.

**Sanitary Permit (City Health Office):**
- Requires valid health cards for all food-handling staff
- Health card = annual medical exam + food safety seminar
- Fee: ~₱200-500 per health card

## Taytay

**Mayor's Permit Office:** BPLO, Taytay Municipal Hall
**Processing time:** 5-7 business days (can be longer during January)
**Notes:**
- Taytay can be crowded during renewal season
- Online system may not be available — confirm with municipal hall
- BIR RDO 54A covers Taytay

## San Mateo

**Mayor's Permit Office:** BPLO, San Mateo Municipal Hall
**Processing time:** 3-5 business days
**Notes:**
- Smaller municipality, generally faster processing
- BIR RDO 53 covers San Mateo

## Antipolo

**Mayor's Permit Office:** BPLO, Antipolo City Hall
**Processing time:** 5-10 business days (larger city, more volume)
**Notes:**
- Antipolo is a city (since 1998) — more offices, more steps
- Can be crowded. File early.
- BIR RDO 54A covers Antipolo

## Cainta

**Mayor's Permit Office:** BPLO, Cainta Municipal Hall
**Processing time:** 3-5 business days
**Notes:**
- BIR RDO 54A covers Cainta
- Municipal, not city — slightly simpler process

## Inspection preparation

When an LGU inspection is scheduled:
1. Verify all permits are current and displayed at the branch
2. Ensure health cards are valid for all food handlers
3. Check fire extinguisher expiry dates
4. Ensure proper waste segregation is visible
5. Ensure food handling areas are clean and organized
6. Have a copy of the menu with prices visible
7. Ensure the branch has a visible suggestion box/complaint mechanism

## Contacts
*(To be filled by James as we build relationships with each LGU office)*

| City | Office | Contact person | Phone | Notes |
|---|---|---|---|---|
| Marikina | BPLO | TBD | TBD | |
| Taytay | BPLO | TBD | TBD | |
| San Mateo | BPLO | TBD | TBD | |
| Antipolo | BPLO | TBD | TBD | |
| Cainta | BPLO | TBD | TBD | |

## How this improves over time
Every LGU interaction gets logged to spine_events. The compliance agent learns:
- "Marikina health inspector visits every March" → proactive reminder in February
- "Taytay BPLO closes for lunch 12-1PM" → schedule around it
- "San Mateo needs 3 copies of lease contract" → note for next renewal
