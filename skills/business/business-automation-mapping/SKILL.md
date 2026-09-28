---
name: business-automation-mapping
description: Map business ops and design agent teams for automation.
---

# Business Automation Mapping

Interview-driven methodology for mapping a business's operations and designing agent teams to automate them. Goal: replace manual oversight with systems so the owner directs agents instead of doing everything.

## When To Use

- User wants to automate business operations with AI agents
- Mapping workflows, departments, or team responsibilities
- Designing agent architectures for a business
- Scaling a business by replacing manual processes with systems

## Procedure

### Phase 1: Structured Interview

Collect data in focused blocks. Don't ask everything at once — each block builds on the previous.

**Block 1 — Business Entities**
For each business entity:
- What it does, current status (active/paused/halting)
- How many locations/branches/units
- Revenue model (direct sales, franchise, subscription)
- Key products/services
- Website/system that serves as operating system

**Block 2 — Owner's Daily Reality**
- What does the owner DO every day? (specific tasks, not titles)
- What do they APPROVE?
- What falls through the cracks when they're busy?
- "The operation collapses when I'm not available" = single point of failure

**Block 3 — Team**
For each team member:
- Name, role, allocation %
- What they SHOULD do vs. what they ACTUALLY do
- Underperformance root cause (usually: no system telling them what to do)

**Block 4 — Operational Workflows**
Walk through each major workflow step by step:
- **Supply chain:** How are materials ordered? Who decides quantities? Based on what data?
- **Production:** What's produced, in what volume, with what inputs?
- **Distribution:** How does product get from production to point of sale?
- **Sales:** How is each sale recorded? Payment methods?
- **Cash flow:** How is cash collected, reconciled, deposited?
- **HR:** How are staff scheduled, attendance tracked, payroll processed?
- **Growth:** How are new locations/units/franchisees onboarded?

**Block 5 — Automation Status Matrix**
Build a table:
| Task | System or Manual? |
|------|-------------------|

Categorize every recurring task. This reveals the automation opportunity at a glance.

**Block 6 — Bottleneck Ranking**
Ask: "What are the top 5 things that eat your time or fall through the cracks?"
This sets the build priority.

### Phase 2: Workflow Map

Synthesize interview data into:
1. **Current state diagram** — who does what, where data flows, where it breaks
2. **Automation status table** — system vs. manual for every task
3. **Bottleneck list** — ranked by owner impact
4. **Single points of failure** — where does the operation break if one person is unavailable?

### Phase 3: Agent Architecture

Design agents based on natural department boundaries:

For the reusable department set, the four autonomy tiers, and the
define-once/allocate-per-business mechanism, see
`references/workforce-job-library.md`.

Use exactly three layers: **human owner decides -> lead agent routes -> worker
agents execute.** One lead agent per department exists to absorb volume and
forward only decisions; without it every agent reports to a human and the owner
is the bottleneck again. Workers never spawn workers — a fourth layer means
nobody can say who decided.

**Playbook before agent, always.** An agent pointed at an unwritten process
automates chaos. The count of written function playbooks is the real backlog,
not the count of agents. Write one playbook per FUNCTION, not per job — jobs in
a function share a procedure.

1. **Identify departments** — group related workflows (e.g., production, sales, finance, marketing, HR)
2. **Map data sources** — what systems/databases/APIs does each agent need to read/write?
3. **Define boundaries** — what can each agent decide autonomously vs. escalate to human?
4. **Set authority levels** — read-only agents, agents that create drafts, agents that execute with approval, agents that execute autonomously

**Agent authority tiers:**
| Tier | Authority | Examples |
|------|-----------|----------|
| Scout | Read-only, report | Monitor inventory, scan sales trends |
| Drafter | Create proposals/orders | Draft production plan, create social media posts |
| Executor | Act with approval | Place supplier orders after approval, dispatch deliveries |
| Autonomous | Act independently | Send payment reminders, update dashboards |
| Physical | Instrument only — agent records, human does | Marinating, sanitation, loading, selling |

Report autonomy per department, not just overall. A production department caps
well below a knowledge department, and a single blended percentage hides that.

### Phase 4: Build Priority

Rank agents by:
1. **Impact** — how much owner time does it free?
2. **Data readiness** — is the data already in a system?
3. **Risk** — what happens if the agent makes a mistake?
4. **Dependency** — does another agent need this one's output?

Build order: high impact + low risk + data-ready first.

### Phase 5: Visual Agent Map

After the architecture is designed, build an interactive HTML visualization that serves as the agent workspace — not a static diagram, but a living interface where the owner can see all agents, their status, and communicate with them directly.

**Structure (SkillTree pattern):**
1. Knowledge Base ("Second Brain") at center — every agent reads from and writes to it
2. Departments radiating outward as clusters
3. Agents as nodes within their department
4. Connection lines showing data flow between agents and the KB
5. Status indicators: not started / in development / live
6. Click-to-inspect sidebar with agent details (role, tools, authority tier, status)

**Implementation:**
- Single self-contained HTML file with inline CSS/JS
- Use HTML/CSS, NOT canvas — emojis render correctly, text is selectable, works in preview panes
- Emojis as agent identifiers (🏭 Production, 📊 Expense, 💰 Finance) — faster recognition than icons
- Dark theme requires HIGH contrast: backgrounds `rgba(255,255,255,0.08)` minimum, connection lines `rgba(255,255,255,0.15)` minimum
- Clickable nodes open a sidebar with full agent details
- Show deployment progress (X/17 agents live)
- Department headers show agent count and live count

**Verification:** Open in `desktop_preview` tool and call `read` to confirm text content renders. If text extraction returns the expected agent names and descriptions, the visual is working.

**Save location:** Project dashboard directory (e.g., `~/projects/<name>/dashboard/skill-tree.html`)

### Phase 6: Autonomous Pipeline

After agents are built, chain them into automated daily runs. See `references/pipeline-orchestrator.md` for implementation details.

**Pattern:** Forecast → Production → Report → Telegram notification
**Schedule:** Morning pipeline (6:30 AM) + Evening summary (9:00 PM)
**Key rule:** Read JSON outputs from disk, never parse subprocess stdout.

### Phase 7: Multi-Business Scaling (Template → Instance → Oracle)

When the owner has multiple businesses with similar department structures,
don't rebuild agents per business. Build department **templates** once, deploy
per business by wiring different data configs.

**Vault architecture** — the physical layout that makes multi-business scaling
work: `core/` for shared connectors and schemas, `templates/` for reusable
SOPs and scripts, `businesses/<id>/` for per-business context, directives,
execution scripts, and scratch. See `references/vault-architecture.md` for the
full directory structure, directive format, and self-annealing loop.

**Architecture:**
```
Oracle (Chief of Staff, digital self — knows everything about the owner)
  ├── Operations Bot (planning tier — Opus)
  ├── Branch Monitor Bot (execution tier — Sonnet)
  ├── Franchise Bot (execution tier — Sonnet)
  ├── Production Bot (execution tier — Sonnet)
  ├── Sales & Marketing Bot (execution tier — Sonnet)
  ├── Accounting Bot (planning tier — Opus)
  └── Capture Bots (capture tier — Haiku, e.g. expense bot)
```

**Model tiers:**
| Tier | Model | Use |
|------|-------|----|
| Planning | Opus | Ops, Accounting — complex reasoning, strategy |
| Execution | Sonnet | Branch, Franchise, Production, Sales — action-oriented |
| Capture | Haiku | Expense, intake — simple transforms, fast |

**Department identity pattern (SOUL.md):**
Each department gets a `SOUL.md` file defining:
- Codename and model tier
- Mission and authority scope
- Data sources (read/write boundaries)
- Escalation rules (when to alert the owner)
- Interaction style (how it communicates)

**Compliance registry pattern:**
A single `COMPLIANCE_REGISTRY.md` tracks all entity-level registrations
(SEC, BIR COR, DTI, Mayor's Permit, FDA, etc.) with:
- Entity registered name vs. trade name
- Document number, issue date, expiry date
- Issuing agency
- Renewal calendar (which months trigger alerts)
- Link to scanned copy in the entity's `legal/` folder

This is complementary to branch-level compliance (permits per location).
Entity registration = the company exists legally. Branch compliance = each
outlet operates legally.

**File consolidation pattern:**
When consolidating scattered business files:
1. Create a single root folder (e.g. `~/Desktop/Oracle/`)
2. Subfolders: `business-units/<EntityName>/`, `oracle/` (system), `personal/`
3. Each business unit gets: `legal/`, operational docs, scanned permits
4. Use symlinks for code that lives elsewhere (no duplicates)
5. Scan entire computer for business documents and move to correct entity
6. Remove temp files (`~$*.docx`), duplicates, and dead entities

## Pitfalls

- **Don't build before mapping.** User will ask to start coding immediately. Resist — the map IS the deliverable. Building without a map produces agents that automate the wrong things.
- **"Manual" doesn't mean "automate it first."** Some manual tasks are manual because they require human judgment. Focus automation on data-heavy, repetitive, predictable tasks.
- **Underperforming team members are usually a systems problem, not a people problem.** If someone "does nothing," check whether they have clear instructions, dashboards, and checklists before assuming they can't do the job.
- **The owner IS the bottleneck.** Design agents to replace the owner's role as single point of failure, not to add another layer of tools the owner must manage.
- **One workflow at a time.** Don't design 10 agents at once. Build one, verify it works, then move to the next.
- **Separate agent boundaries from business entity boundaries.** A commissary agent and a branch agent may serve the same business. Don't create agents per business — create them per function.
- **Agent writes need human approval at first.** Start with Scout + Drafter authority. Only promote to Executor after the agent's output is verified correct over multiple cycles.
- **Existing systems are data sources, not enemies.** If the business already has a POS, ERP, or website with APIs, the agent reads from it — don't rebuild the system.
- **Agents are coworkers, not dashboard tiles.** The visual map must be interactive — clickable agents, direct communication, status that changes. A passive grid of cards that just shows names is a waste. The user explicitly wants to TALK to agents directly, not just see them.
- **Dark-themed canvas with ultra-low alpha is invisible.** `rgba(255,255,255,0.04)` backgrounds and `rgba(255,255,255,0.03)` connection lines vanish on dark backgrounds. Use HTML/CSS with `rgba` at 0.08+ for fills, 0.15+ for lines. Canvas-based rendering also breaks emoji display and text selection.
- **Map generic blueprints by substituting the customer noun, not by discarding departments.** An agency/SaaS job framework looks irrelevant to a franchise until you ask who the client is: for a franchisor the franchisee IS the client, and then client onboarding becomes franchisee onboarding, project scaffolding becomes branch build-out, health scoring becomes branch health, and deal rooms become franchise agreements. Sales and Deals transfer fully, because a franchisor's core business is selling and servicing franchisees. Find the one substitution that unlocks the mapping before writing anything off.
- **Knowledge-work blueprints contain no physical jobs.** For any business with production, the core department is simply absent from the reference model and must be authored from the owner's own process map. Check for the missing department before adopting a framework, or the plan will look complete while the real bottleneck stays undocumented.
- **Switch irrelevant jobs off explicitly rather than deleting them.** Keep them in the shared library for the businesses that do need them, and record them as off for this one, so nobody rebuilds them later.
- **Never present a job as automated when a human's hands do the work.** Physical steps get an instrumentation-only tier: the agent logs time, yield, temperature, and cost, and never executes. Counting physical work as automated is how these plans look finished while someone still stands in the commissary at 4am.
- **Cron scripts must live in `~/.hermes/scripts/`.** Absolute paths to project directories don't persist across sessions. Copy the script to the standard location before creating a cron job.
- **Read JSON data files from disk, not subprocess stdout.** When chaining bots into a pipeline, `json.load(open('file.json'))` is more reliable than parsing subprocess output. Stdout may contain log lines, warnings, or partial output that breaks JSON parsing.
- **Check for existing processes before starting bots.** `ps aux | grep <process> | grep -v grep` to find running instances. Kill old PID before starting new — duplicate bots cause conflicts.
- **Bot token loading from custom env files.** `os.environ.get()` reads OS environment, not a custom env parser's returned dict. Always fall back to the parsed dict: `os.environ.get(key) or env.get(key)`.

## User Preferences

- Bren wants to direct the army, humans do physical labor, agents handle departments
- Bren approves agent work; agents don't auto-execute money/legal actions
- Map before build — always get the full picture first
- One agent at a time, one workflow at a time
- Use existing systems as data sources (lolobuds.vip, espressoplayground.vip, Supabase spine DB)
- Free/open-source tools only
- Agents must be interactive coworkers, not passive status displays — user wants to communicate with each agent directly
