# Dossier Format Specification

Each dossier is a markdown file with YAML frontmatter. The dossier parser (`dossier_parser.py`) validates structure on load.

## YAML Frontmatter

```yaml
---
seat: "Offer Engineer"
domain: "pricing, offers, value stacks, guarantees"
person: "Alex Hormozi"
voice: "Direct, data-driven, zero fluff. Speaks in frameworks and numbers."
characteristic_objection: "I need more leads" → the real problem is usually the offer, not traffic.
blind_spots:
  - "Commodity markets where differentiation is structurally hard"
  - "Regulated industries with pricing constraints"
  - "Businesses with < $10K monthly revenue (pre-offer stage)"
domains:
  - offers
  - pricing
  - value
  - guarantees
  - monetization
verification: sourced
---
```

### Required Fields

| Field | Type | Purpose |
| ---| --- | --- |
| `seat` | string | Role title in the advisory board |
| `domain` | string | Comma-separated expertise areas |
| `person` | string | Named expert the seat represents |
| `voice` | string | How this seat communicates |
| `characteristic_objection` | string | The reframing this seat is known for |
| `blind_spots` | list[string] | What this seat's doctrine doesn't cover |
| `domains` | list[string] | Keywords for router matching |
| `verification` | string | `sourced` after adversarial fact-check |

## Doctrine Entries

After the frontmatter, each doctrine entry is a level-3 heading with a `D-n` ID:

```markdown
### D1 — [Title]

[2-4 paragraph explanation of the doctrine, specific enough to act on]

**Source:** *Book Title* (Year) Ch. X
```

### Entry Rules

1. **IDs are unique per dossier.** D1 appears once. The parser rejects duplicate IDs.
2. **IDs use `D` + integer.** D1, D2, D10 — not D01, not d1, not #1.
3. **Every entry needs a source.** Book + chapter, talk + year, interview + publication. Vague sources ("Hormozi has said...") are rejected. **Chapter numbers must come from the actual book's table of contents**, not from blog summaries, reading notes, or AI-generated estimates. Third-party chapter titles often don't match the real book.
4. **6-10 entries per seat.** Fewer lacks depth; more dilutes.
5. **Entries must be actionable doctrine**, not biography or trivia.

## Citation in Model Output

When a seat responds in a meeting, it cites doctrine entries inline:

> "The value equation [D3] suggests the outcome and speed of implementation matter more than the effort required [D1]."

The citation gate extracts `[D1]`, `[D3]` etc. and strips any ID not in the dossier's valid set.

## Blind Spots Section

```markdown
## Blind Spots

- [What this expert's framework doesn't address]
- [Industry or stage they have no doctrine for]
```

The router uses blind spots to avoid routing questions to seats that can't help.

## File Naming

`<lastname>.md` in lowercase: `hormozi.md`, `cardone.md`, `godin.md`