# Vault operations

## Secret scan (run before EVERY commit)

Merging legacy folders drags in live credentials. Scan staged markdown only:

```bash
cd <vault>
git add -A
git diff --cached --name-only -- '*.md' > /tmp/staged.txt
while read f; do
  [ -f "$f" ] && grep -nIEo '(sk-[A-Za-z0-9]{16,}|eyJ[A-Za-z0-9_-]{20,}|postgres(ql)?://[^ ]+:[^ ]+@|service_role|AIza[0-9A-Za-z_-]{30,})' "$f" | sed "s|^|$f:|"
done < /tmp/staged.txt
```

Empty output = clean. Redact in place, keep a pointer note in the vault, and
leave the real `credentials.md` in the archive (outside git).

**Avoid `while read` piped directly from `git ls-files` in one shell line** —
security scanners block unresolvable nested bodies. Write the file list first,
as above.

## Gitignored content is invisible

A folder matched by `.gitignore` is invisible to git **and** to any future vector
sync. After a merge, always confirm the restored notes are actually tracked:

```bash
git ls-files | wc -l
git check-ignore -v <path>   # why is this ignored?
```

Big PDF/binary sets stay excluded, but their **index note must be tracked**.

## Do mechanical merges locally

Do not delegate vault merges to subagents. Observed failure: two parallel
subagents archived the source folders, then both died on `HTTP 402 insufficient
credits` after ~910s, having written almost nothing. The originals survived only
because they were archived rather than deleted.

Split the work instead:
- **Mechanical** (indexing, moving, frontmatter, tables, arithmetic) → do it
  locally in `execute_code`.
- **Judgment** (which of 6 conflicting master docs is current) → flag for the owner.

## Restructuring script pitfalls

- **Self-move**: `git mv operations operations` errors. Stage through a temp dir
  when a source and destination name collide.
- **Heredocs in `terminal` get killed.** Use `execute_code` for any multi-line
  Python.
- Preserve superseded notes under `_inherited/` with a `> ⚠️ SUPERSEDED <date>`
  banner plus `superseded: true` frontmatter. Never rewrite history silently.
- Generate every department note from **one** Python dict so the job library and
  the per-department pages cannot drift.

## Verify counts against the source

After generating a job library, assert totals match the blueprint's published
numbers (jobs, and each autonomy tier). A mismatch means a typo in the dict.
Count with Python, never by eye.

## Skill frontmatter

Descriptions must be ≤60 chars **and contain no colon** (unquoted YAML treats
`word: word` as a nested mapping and the create fails). Put the "use when"
trigger in the body instead.
