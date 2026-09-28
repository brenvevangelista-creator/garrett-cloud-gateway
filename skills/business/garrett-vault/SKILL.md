---
name: garrett-vault
description: Use when documenting Bren's businesses in the Garrett vault.
---

# Garrett Vault

Bren's single source of truth: an Obsidian vault at `~/Desktop/Garrett`.
Goal in his words: "document everything, build everything, and stop repeating myself."

Load this skill when building processes, playbooks, SOPs, decision rules, or
process maps for any of his businesses, or when merging legacy files into the vault.

## Structure

```
~/Desktop/Garrett/
  00-start-here.md          entry point / map of content
  00-inbox/                 unfiled captures (Obsidian default new-note folder)
  01-companies/<slug>/
    _company.md             index note
    playbooks/ numbers/ people/ branches/
    _files/                 GITIGNORED heavy binaries (PDFs, photos)
  02-departments/
    _ARCHITECTURE.md        three-layer model, autonomy tiers, build order
    _job-library.md         every job x function x tier (canonical)
    <slug>/
      _department.md        jobs, lead agent, human owner
      playbooks/ sops/ checklists/   one playbook per FUNCTION, not per job
  03-people/ 04-decisions/ 05-daily/
  99-meta/templates/        company.md department.md playbook.md
  99-meta/automation/STATUS.md
  _archive-merged/          GITIGNORED originals of merged legacy files
```

**Company slugs (15):** lolo-buds, espresso-playground, growth-architect-studio,
cocana, enchanted-getaways, fci, kahit-saan, kingdom-capital, manjari-cove,
manjari-residences, pagmaya, phoebren-inc, satori-real-estate,
tropic-haven-resorts, usana

Parked ventures nest under their parent as
`01-companies/<parent>/future-projects/<slug>/` rather than being archived —
they keep their playbooks and stay searchable without inflating the active
company count.

**Departments (8)** — each has one human owner and one lead agent:
sales, marketing, deals, operations, customer, back-office,
production-commissary, intelligence.

`intelligence` is a **shared service floor**, not a department: it sharpens the
other seven and has no owner-facing output of its own. Do not give it a
business-facing mandate.

Department definitions live in `02-departments/_job-library.md` (every job,
with function and autonomy tier) and `02-departments/_ARCHITECTURE.md` (the
three-layer model). Read both before adding a department or a job.

## The anti-duplication rule

Write the process ONCE in `02-departments/`. Businesses link to it and store
only their overrides. `_company.md` frontmatter declares `departments: [...]`.
If you are about to state a fact that already exists in another note, link it
instead. Never restate numbers across notes.

## Markdown-only git (critical)

The vault is 31GB on disk but git must track only markdown (~1.1MB).
GitHub caps 100MB/file and chokes past ~1GB/repo. `.gitignore` must exclude
`_files/`, `_archive-merged/`, and binary extensions. Verify before pushing:

```bash
cd ~/Desktop/Garrett && git ls-files | wc -l
```

Sum tracked bytes in Python, not `xargs`+`stat` — that gets OOM-killed on this
vault. Heavy files stay local, referenced by path; back them up with Time
Machine/iCloud, never git.

## Frontmatter on every note

```yaml
title: "..."
type: company | department | playbook | sop | reference | person | decision-rules | process-map | index
company: <slug>          # if applicable
department: <slug>       # if applicable
source: <original path>  # if merged from a legacy file
updated: YYYY-MM-DD
tags: [...]
```

The planned vector brain chunks notes at `##` headings and carries
`company`/`department`/`type` onto every chunk, so filtered search works.
Target pipeline: Obsidian -> private GitHub -> n8n 15min cron -> Supabase
pgvector (`brain_chunks`) -> agents. Status in `99-meta/automation/STATUS.md`.

## How to interview Bren

He explicitly asked for **one real question at a time**, with answers filed
automatically. Rules learned:

- Ask ONE question per turn. Never batch a questionnaire at him.
- Ask about what he *repeats*, not what sounds important. "Which business costs
  you the most repeated explaining?" beats "tell me about your business."
- When a note needs many unknowns (e.g. 17 authority thresholds), ask for ONE
  anchor number and derive the rest for him to correct. Filling blanks cold is
  a chore; correcting a draft is easy.
- Build one business deep as the template, then replicate the pattern outward.
  Others get skeletons marked `status: needs-interview`.
- File his answer into the vault immediately; do not let it sit in chat.

## Handling his legacy files

He had three competing knowledge layers. Quality order found:
`central-intelligence/` (best: per-company, recent) > new vault >
`legacy-system-os/` (111 files but 14 of 26 folders empty).

- **Never delete content without asking.** He explicitly praised not deleting.
  Move originals to `_archive-merged/<original-path>`, then report what is safe
  to delete and let him confirm. Empty directories may be removed outright after
  verifying `find <dir> -type f | wc -l` is 0.
- Merge duplicates into one note; on conflict the newer/better layer wins and the
  discrepancy goes in a `## Conflicts found` section rather than vanishing.
- Never copy secrets into a note. Replace with `[REDACTED]` and point to
  `~/.config/bren-os/env` instead. SEC/permit registration numbers are fine.
- **Scan the staged diff, not the working tree, before every commit** — merged
  legacy folders have had dirty history, and only staged content is about to be
  immortalised:

  ```bash
  cd ~/Desktop/Garrett && git add <paths> && git diff --cached > /tmp/staged.diff
  wc -l < /tmp/staged.diff
  /usr/bin/python3 ~/.hermes/skills/business/garrett-vault/scripts/secret_scan.py /tmp/staged.diff
  ```

  `SCAN_RESULT=CLEAN` is the pass condition, and the script prints how many
  added lines it scanned so the check is visible rather than merely claimed.
  Use `scripts/secret_scan.py`, not an inline `grep -E` one-liner: a long
  alternation pattern full of quotes, `$`, backticks and braces gets mangled or
  refused by the shell/command layer, and a bare grep over the diff also matches
  CONTEXT lines — flagging content that already existed and is not being added.
  The script tests only `+` lines and whitelists `[REDACTED]` and env-file
  pointers.
- Watch for LLM-generated overlapping PDFs ("Complete System Documentation",
  "Complete Engine Documentation", ...) — extract the unique content once.

## Correcting a number Bren supplies

"What I gave you is our actual number" — **figures he supplies outrank anything
derived, back-solved, or read out of the system.** When he corrects one, the job
is not to patch the note he mentioned; it is to make the vault consistent again.

1. **Back-solve the implied unit rate of every derived per-unit cost and check it
   against the quoted range.** A cost per head or per slab that implies a price
   outside the supplier band is fiction, not a rounding difference, and every
   margin built on it is wrong. Inputs are bought by weight and sold by unit, so
   the two only reconcile through an explicit weight — state that weight.
2. **Grep the whole company folder for the old figure before editing anything**,
   then fix every hit in one commit. Search the *derived* numbers too, not just
   the input: totals, COGS and margin lines carry the error forward under
   different values and survive a fix aimed only at the source.
3. **Check the note that calls itself canonical first, and hardest.** "Any
   document that contradicts this is wrong" is a claim, not a guarantee, and a
   wrong canonical note promotes one bad cell to vault-wide authority.
4. **Two copies of a table is how a bad number survives a correction.** When a
   stale duplicate exists, replace the duplicate with a pointer stub to the
   canonical note rather than updating both — updating both is what created it.
5. **Leave the correction visible.** Strike the old value inline beside the new
   one and the reason it failed, so nobody re-derives the error from an older
   note. Silent overwrites make the same question get asked again.
6. **Do not relabel arithmetic as "inferred".** A figure computed from a
   confirmed input is confirmed; marking it uncertain invites re-asking a
   question he has already answered — the exact repetition he wants to stop.
7. **Per-unit and annualized figures carry different confidence.** An annual
   number inherits the weakest denominator, so when daily volume is contradicted
   between notes, publish the per-unit result as solid and give the annual as a
   range that names the conflict. Never quietly pick the flattering volume.
8. **Say which lever the number actually moves.** Separate what he controls
   (portion weight, cut spec, yield) from what a supplier controls (price per
   kilo) and size them against each other — an in-house tolerance he sets
   usually outweighs a negotiation, and that comparison is the recommendation.
9. **Name what is still unmeasured.** Trim/yield loss and "has this unit ever
   been put on a scale?" decide whether a margin is real. An unverified spec
   range is a belief; label it as one instead of computing confidently from it.

## Process-map pattern (reusable across businesses)

The reason Bren repeats himself: a step lacking any ONE of **trigger, named
owner, defined output, decision rule** routes back to him. So every process-map
row carries all of: `# | Step | Trigger | Runs it | Output | Who reads it |
Decision they own`, marking agent vs human owners.

Then draw the **agent zone / human zone** handoff explicitly. Corollaries:

- Money and legal are never auto-executed; agents propose, humans dispose.
- **A report with no decision attached is noise.** If nobody acts on it, kill it.
- Automate the steps where *Bren himself* is the bottleneck before those where a
  staff member is — that reclaims his hours first.
- A decision rule without a number is an opinion. Leave explicit blanks and count
  them, so the remaining questions are visible.

## Derive thresholds from live data, never from plausible round numbers

A decision rule is only as good as the number in it, and a number invented to
look sensible can encode a rule that quietly breaks the business. Before
filling any threshold, compute the current actual value from real data and
stress it. Concretely:

- **Compute the baseline first, then set the trigger relative to it.** State the
  actual margin/volume/cost in the note next to the threshold, so the next
  reader can see the headroom rather than trusting the number.
- **Stress-test the gearing.** Walk the input cost up in +5% steps and record
  where the margin reaches zero. Set the re-quote/alert trigger at the step that
  still leaves room to act, not at a round 10% — on a thin margin, 10% can
  already have eaten most of it.
- **Check buffer stock before writing any "hold / stop / pause" rule.** With
  near-zero days of cover, holding production does not protect margin, it empties
  the outlets on the next cycle. When cover is under one day the correct rule is
  *proceed and escalate the pricing decision*, with hold available only above
  that. A produce-or-hold rule reads fine on paper and starves branches.
- **Check the existing footprint before writing any radius, quota, or territory
  rule.** Count what is already deployed per area first; a clean-looking radius
  frequently outlaws sites already operating. Split the rule by ownership
  (binding for sold/franchised units, discretionary for company-owned) — a
  franchisee harmed by a nearby company store has a real grievance, while
  self-cannibalisation is the owner's own call.
- **Anchor on a number the team already uses.** A threshold that matches an
  existing operational tier gets followed because staff already think in it.
- **Flag is not block.** State explicitly which thresholds notify and which
  actually stop work; an unlabelled threshold gets implemented as a block.
- **Amount-only authority ladders strangle high-frequency work.** Authorize
  recurring spend by approved plan and one-off spend by amount, or routine
  reorders queue behind the owner.

When the note is done, replace the blank-count line with a status line naming
the few thresholds that still need his judgment, and say why each is his call.

## Restructuring an existing folder set

When remapping directories and old and new names overlap, a direct move hits
`src == dst` and dies partway, leaving some folders moved and some not. Stage
every source into a temp directory first, create the new tree, then move
contents in — and make the script idempotent so a partial run can be re-run.

Generate per-department notes from ONE structured source (a dict of
department -> function -> jobs), never by hand-writing each note. Then verify
the derived counts against the published totals before committing; if your
per-job tier assignments do not reconcile exactly to the source's department
totals, your reading of the source is wrong, not the source.

## Merging: create the destination before archiving the source

A merge that archives originals first and writes destinations second leaves the
worst possible state if it dies midway — sources moved out of place, nothing
written, and the content invisible to git if the archive is gitignored. Always
write the destination note, verify it, then move the original to
`_archive-merged/`. Re-scan for secrets after any bulk restore: content pulled
out of a gitignored archive has never passed a commit-time check.

See `references/lolo-buds.md` for the worked example.
