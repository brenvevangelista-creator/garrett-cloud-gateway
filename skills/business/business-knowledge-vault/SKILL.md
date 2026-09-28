---
name: business-knowledge-vault
description: Build business vaults with departments, agents, rules.
---

# Business Knowledge Vault

**Use when** building or extending an Obsidian markdown vault as the single
source of truth for a multi-company operation — department structure, agent org
charts, decision rules with real thresholds, playbooks, and per-company job
allocation. Target stack: Obsidian → private GitHub → cron → vector store →
chat/voice agents that answer by meaning.

**Core promise to the owner: write it once, never repeat it.** Every design
choice below serves that. If a change would make the owner explain something
twice, it is wrong.

## Non-negotiables

1. **Never guess a number.** Compute every threshold from live data (API dumps,
   exports, recipe files). A guessed threshold is worse than a blank — it looks
   authoritative and gets acted on.
2. **Verify the arithmetic AND the units in source docs.** Stated totals are
   often wrong, and stated weights/specs often contradict what the business
   actually buys. Re-add every cost breakdown and confirm every unit spec with
   the owner. See `references/unit-economics.md`.
3. **Secret-scan before every commit.** Merging legacy folders routinely drags
   in live API keys and connection strings. See `references/vault-ops.md`.
4. **Archive, never delete.** Move originals to `_archive-merged/` and let the
   owner confirm before removal.
5. **Flag, don't decide.** Judgment calls (pricing, equity, territory, which of
   6 conflicting master docs wins) get a `⬜ needs decision` block with stakes
   quantified. Mechanical work you do yourself.

## Structure

```
00-inbox/  01-companies/  02-departments/  03-people/
04-decisions/  05-daily/  99-meta/  _archive-merged/
```

**The one rule that stops repetition:**

> A department defines a job **once**. A company only declares whether it
> **needs** that job.

So `02-departments/` holds the canonical job library and playbooks;
`01-companies/<co>/job-allocation.md` is just a needed/not-needed list with
P1–P3 priority. Never restate a process inside a company folder.

## Department & agent architecture

Three layers, never four:

```
Human owner  →  Lead agent  →  Worker agents
  (decides)     (routes,        (execute one job)
                 filters)
```

The lead agent exists to **absorb volume and forward only decisions**. It is a
filter, not a manager. Without it every worker reports to a human. Workers
cannot spawn workers.

### Four autonomy tiers

Most published blueprints assume pure knowledge work and ship three tiers. Any
business with physical operations needs a fourth:

| Tier | Meaning |
|---|---|
| 🟢 solo | Agent completes it end to end |
| 🟡 assisted | Agent drafts, human approves |
| 🔴 human | Human decides, agent prepares |
| ⬛ **physical** | Human hands do it; agent only **instruments** — logs time, yield, temperature, cost |

Omitting ⬛ is how a plan claims 69% autonomy while someone still stands in a
commissary at 4am. Recompute autonomy per department with ⬛ excluded.

### Adapting a generic blueprint

Agency-shaped blueprints map onto a franchisor with one substitution:

> **A franchisor *is* an agency. The franchisee *is* the client.**

Client onboarding → franchisee onboarding; project scaffolding → branch
build-out; health scoring → branch health; deal rooms → franchise agreements.
What such blueprints always lack is **physical production** — author that
department from the owner's own process map.

Mark clearly which job tiers are your assignment versus published fact, and
reconcile your per-job tiers to the source's department totals as a checksum.

### Who may own a department

**Only an internal person.** An external commission-based party must never hold
an owner seat — they would read the daily digest (standing access to business
data), optimise for commission over brand, hold the playbooks, and speak as the
brand with no employment remedy. Model them as a **channel governed by
contract**, sitting between two internal departments, receiving briefs and
returning leads. Equity in one venture does not make someone internal to
another.

## Decision rules

One file per company. Each rule: condition → decision → owner → escalation.
Fill every blank with a computed number. Two patterns that recur:

- **A rule that contradicts existing reality is the wrong rule.** Test each
  threshold against current operations before proposing it (a 1.5 km territory
  radius would have blocked 3 branches the owner already ran; the real rule was
  500 m).
- **Check whether the rule's action is even available.** A produce-or-hold rule
  is meaningless at 0 days of inventory cover — holding empties the branches.
  Rewrite as produce-and-escalate.

Different brands need different rule *shapes*: a neighbourhood takeaway uses a
radius, a destination/dwell brand uses jurisdiction exclusivity (1 per city, 2
per major city, 1 per mall). Jurisdiction rules need two definitions written
down — what counts as "major", and whether a mall slot consumes the city slot —
or they cannot be sold.

Surface fragility, not just the level: show what a ±5/10/15% input shock does to
margin. A 13.4% margin that a 15% cost move erases is the finding, not the 13.4%.

## Detailed procedures

- `references/vault-ops.md` — secret scanning, merges, restructuring scripts, git hygiene
- `references/unit-economics.md` — unit specs, transfer pricing, food cost, ceilings, capex gates
