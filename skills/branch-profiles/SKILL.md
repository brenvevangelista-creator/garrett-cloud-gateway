---
name: branch-profiles
description: Reference for all branch locations, details, and operational context. Use when routing tasks, planning deliveries, or answering branch-specific questions.
tier: 1
tools: bren-os CLI, supabase
---

# Branch Profiles

## Purpose
Every agent that touches a branch — compliance, production, logistics, sales,
accounting — needs to know: where is it, who runs it, what's its status.
This skill is the reference.

## How to get the current branch list

```
bren-os branches       # lists all active branches with details
```

Or query the entities table: entities where role_title in ('branch', 'production site')

## Lolo Bud's Manok — Active Branches

| Branch | Address | Type | Notes |
|---|---|---|---|
| Anadels Parang (flagship) | 101 M. Tuazon St., Parang, Marikina City | branch | Operating. Hours: 10AM–9PM daily. This is the reference branch. |
| Cuatro Cantos, Taytay | 49 Rizal Avenue Cuatro Cantos, Taytay, Rizal | branch | Operating. Opened Aug 2026. |
| Banaba, San Mateo | 4 Liamzon St., Banaba, San Mateo, Rizal | branch | Operating. |
| Ayala Malls Marikina Heights | Marikina Heights, Marikina City | branch | Operating. Inside a mall — different permit requirements (mall handles some). |
| Concepcion 1, Marikina | EF Building, Flores St. cor. 702 Shoe Ave Ext., Concepcion Uno, Marikina City | branch | Operating. |
| Commissary (HQ) | Marikina City | production site | Not customer-facing. Production + distribution hub. |

## Pre-Launch Branches

| Branch | Address | Target | Status |
|---|---|---|---|
| Provident Tanong, Marikina | 248 A. Bonifacio Ave, Marikina | TBD | Pre-launch |
| L. Sumulong Circle, Antipolo | Antipolo City | TBD | Pre-launch |

## The Espresso Playground

| Branch | Address | Type | Notes |
|---|---|---|---|
| Cainta | Serra Monte Mansions, Filinvest East, Cainta, Rizal | branch | Operating. GrabFood + Foodpanda. |

*(Additional TEP branches: Bren to confirm)*

## Branch data points per location

Each branch in the spine has:
- `id` (uuid) — used in all database references
- `name` — display name
- `kind` — 'branch' or 'production site'
- `business_id` — links to the parent business
- `contact` (jsonb) — address, phone, social media
- `tags` — ['active','pre-launch','flagship','not-customer-facing']
- `notes` — operational context

## How compliance links to branches
The `compliance_items` table links via `entity_id` → branch id.
Each branch has multiple compliance items (mayor's permit, sanitary, fire, etc.)

## How production links to branches
The `production_runs` and `deliveries` tables link via `entity_id` → branch id.
Each branch has a delivery schedule and par levels for inventory.

## Operational notes by city

| City | Mayor's Permit office | BIR RDO | BFP station | Notes |
|---|---|---|---|---|
| Marikina | Marikina City Hall | RDO 53 | BFP Marikina | Processing: 3-5 days. Walk-in. |
| Taytay | Taytay Municipal Hall | RDO 54A | BFP Taytay | Processing: 5-7 days. Can be crowded. |
| San Mateo | San Mateo Municipal Hall | RDO 53 | BFP San Mateo | Processing: 3-5 days. |
| Antipolo | Antipolo City Hall | RDO 54A | BFP Antipolo | Larger city, longer queues. |
| Cainta | Cainta Municipal Hall | RDO 54A | BFP Cainta | Processing: 3-5 days. |

## How to update
When a new branch opens:
1. `bren-os` inserts into entities table
2. Add to this skill file
3. Compliance agent auto-asks: "What permits does this branch need?"
4. Delivery routes updated in logistics skill
