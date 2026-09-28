---
name: advisory-board
description: Build a named-expert advisory board with citation gates.
metadata:
  origin: built-in
---

# Advisory Board

A standing council of named domain experts, each backed by a persistent dossier of sourced doctrine. Every seat runs as an isolated model call — no seat sees another seat's reasoning. A chair synthesizes after all seats respond.

This is NOT `council` (generic voices, single session, no memory), NOT `dev-team` (preset PM/Arch/Dev/QA roles), and NOT `santa-method` (dual reviewers for verification). Advisory board seats have **persistent domain knowledge**, **named doctrines with citations**, and **adversarial research pipelines**.

## Core Anti-Patterns the Architecture Defeats

1. **Consensus theater** — when one model role-plays five people, they converge toward the same middle. Fix: one isolated call per seat, no cross-awareness.
2. **Confident fabrication** — a model speaking as "Hormozi" invents plausible-sounding doctrine that doesn't exist in any book. Fix: citation gate strips any claimed source that doesn't exist in the seat's dossier.

## When to Use

- User wants strategic advice from named experts, not generic role-play
- Decisions benefit from multiple domain perspectives (offer design, sales, positioning, distribution, etc.)
- User wants persistent advisors that accumulate and refine knowledge over time
- The question has enough complexity that 1-2 expert lenses aren't sufficient

## When NOT to Use

| Instead | Use |
| --- | --- |
| Quick go/no-go with generic skepticism | `council` |
| Feature design across PM/Arch/Dev/QA | `dev-team` |
| Verify a single output's accuracy | `santa-method` |
| Simple factual question | answer directly |

## Architecture

```
Question → Router → [Seat 1] [Seat 2] ... [Seat N] → Chair → Presentation
                         ↓              ↓
                    (isolated)    (isolated)
                    citation gate  citation gate
```

### Tier 0: Interview

Before building, interview the user:
1. Who are the advisors? (named people, domains, or auto-discover)
2. How many seats?
3. Decline gate? (can a seat say "this isn't my domain")
4. Abstention? ("I have no doctrine on this" as first-class answer)
5. Cost ceiling per meeting?
6. Model to use?

### Tier 1: Dossier Parser

Build a parser that loads dossiers and validates them on startup. The parser is the foundation — if it doesn't enforce structure, everything downstream breaks.

**Dossier format** (see `references/dossier-format.md` for the full spec):
- YAML frontmatter: seat name, domain, voice, characteristic objection
- Doctrine entries with `D-n` IDs (e.g. D1, D2, D3)
- Each entry has a source citation (book + chapter, talk + year, etc.)
- Blind spots section
- Domains list for routing

**Parser responsibilities:**
- Load and validate YAML frontmatter
- Extract doctrine entries, rejecting duplicate IDs
- Build `extract_citations()` to pull `[D1]`, `[D3]` from raw model output
- Build `citation_gate(cited_ids, valid_ids)` that strips non-existent IDs
- Expose `.doctrine`, `.blind_spots`, `.voice`, `.domains` for downstream use

> PITFALL: `citation_gate` expects a pre-extracted list of IDs, NOT raw text. Always call `extract_citations(text)` first, then pass the list to `citation_gate()`. Passing raw text causes character-by-character comparison that strips everything.

### Tier 2: Research (Two-Stage)

**Stage 1: Generate dossiers.** For each seat, dispatch a research subagent to:
- Research the person's actual published doctrine (books, talks, interviews)
- Write 6-10 numbered doctrine entries with specific source citations
- Identify blind spots and domains
- Output a valid dossier in the Tier 1 format

Use `delegate_task` with one subagent per seat — parallel dispatch.

**Stage 2: Adversarial fact-check.** Dispatch a second wave of subagents, each tasked with:
- Reading the dossier
- Attempting to disprove or find errors in each doctrine entry
- Flagging vague citations, anachronisms, or unsupported claims
- Producing a verification report

This is NOT optional. The citation gate proves a citation EXISTS in the dossier; adversarial research proves the dossier itself is CORRECT.

> PITFALL: Don't skip Stage 2 because Stage 1 "looked good." The whole point is that generated dossiers are plausible but unchecked. The two stages serve different gates.
>
> PITFALL: AI-generated dossiers have **high citation error rates** — expect 30–80% of entries to have wrong chapter numbers, blog-sourced references, or fabricated section titles. Common failure patterns:
> - **Blog-sourced citations** — chapter titles pulled from third-party reading notes (e.g. a blog's summary headers) instead of the actual book's table of contents. The titles look plausible but don't match any real chapter.
> - **Chapter numbering off-by-one** — the principle is real but the chapter number is wrong (Ch. 1 instead of Ch. 2). Systematic error from models counting from the wrong starting point.
> - **Fabricated structural details** — invented section names, step counts, or framework labels (e.g. "10-step email sequence" that doesn't exist in the cited book).
>
> **Fix strategy after verification:** For ≤3 errors per dossier, fix inline (patch chapter numbers directly). For >5 errors, dispatch a correction agent with the verifier report as context — it needs to re-research the book's actual structure.

### Tier 3: Router

Given a question:
1. Load all dossiers
2. Extract domains from the question
3. Match question domains to each seat's `.domains`
4. Select relevant seats (or all seats if the question is broad enough)
5. Build a business context brief for each seat

**Context distribution:**
- Seats get a SHORT business brief (branch count, revenue trend, key metrics)
- The chair gets FULL database/system access
- This asymmetry is intentional: seats reason from doctrine, the chair synthesizes with ground truth

### Tier 4: Meeting Fan-Out

For each selected seat, build a prompt containing:
- The question
- The business brief
- The seat's full dossier (doctrine entries, voice, blind spots)
- Instructions to cite doctrine entries as `[D1]`, `[D3]`, etc.
- Decline/abstention instructions if enabled

Launch all seat calls in parallel (subagents or concurrent model calls).

After all seats respond, run the citation gate on each response:
1. `extract_citations(response_text)` → list of cited IDs
2. `citation_gate(cited_ids, valid_ids)` → valid list + stripped list
3. Log any stripped citations (fabrication signal)
4. Strip invalid citations from the response before passing to chair

### Tier 5: Chair Synthesis

The chair receives:
- All gated seat responses
- Full business context (DB access, metrics, etc.)
- Instructions to synthesize, identify agreements and tensions, and produce a recommendation

The chair does NOT have a dossier — it synthesizes, it doesn't advocate.

### Tier 6: Presentation

Format the meeting output:
- Question asked
- Each seat's response (with citations visible)
- Chair's synthesis
- Consensus points
- Key tensions/disagreements
- Recommended action
- Any stripped citations (transparency)

### Tier 7: Standing Review

Quarterly unprompted meeting:
- Cron triggers on first day of quarter, 8 AM
- Each seat writes a ~500-word silent table review
- Chair convenes after all reviews are in
- No user question needed — the board reviews the business proactively

## Implementation Checklist

```
[ ] Tier 0: Interview (who, how many, gates, model)
[ ] Tier 1: Dossier parser + citation gate + extract_citations
[ ] Tier 2 Stage 1: Research subagents → dossiers on disk
[ ] Tier 2 Stage 2: Adversarial fact-check subagents → verification reports
[ ] Tier 3: Router (domain matching + context builder)
[ ] Tier 4: Meeting fan-out (parallel seat calls + citation gate)
[ ] Tier 5: Chair synthesis
[ ] Tier 6: Presentation format
[ ] Tier 7: Quarterly cron
```

Verify each tier before proceeding to the next.

## Cost Model

For local models (Ollama), cost is $0 per meeting. The cost ceiling ($0.50/meeting default) is a discipline gate — it caps token usage, not dollars.

Meeting cost: 1 router call + N seat calls + 1 chair call = N+2 calls max.

## Dossier Directory Structure

```
dossiers/
  <name>.md              # One dossier per seat
  verification/          # Adversarial fact-check reports (verify-*.md)
  references/            # Supporting source materials
  versions/              # Dossier version history
```

> PITFALL: Keep verification reports in `dossiers/verification/`, NOT in `dossiers/` root. The parser loads all `*.md` files in the dossiers directory as dossiers — verification reports without YAML frontmatter cause FATAL warnings on every load.

## Related Skills

- `council` — quick generic-voice decision-making (no persistent knowledge)
- `santa-method` — dual-reviewer verification (subset of the adversarial pipeline)
- `dev-team` — preset PM/Arch/Dev/QA review (no domain expertise)
- `delegate_task` tool — parallel subagent dispatch for research and fan-out