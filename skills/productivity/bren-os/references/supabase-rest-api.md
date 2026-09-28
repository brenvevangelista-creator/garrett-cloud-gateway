# Supabase REST API — Direct usage from scripts

When writing TypeScript/Node scripts that talk to Supabase without the JS client library.

## Environment

The Bren OS env file (`~/.config/bren-os/env`) exports:
- `SUPABASE_PROJECT_REF` (NOT `SUPABASE_URL` — construct URL as `https://${ref}.supabase.co`)
- `SUPABASE_SERVICE_ROLE_KEY`

Lines may have `export` prefix or not. Parse with: `/^(?:export\s+)?(\w+)=(.+)$/` and trim values.

## Reading env from scripts

```typescript
import { readFileSync } from 'fs';
const envPath = `${process.env.HOME}/.config/bren-os/env`;
for (const line of readFileSync(envPath, 'utf-8').split('\n')) {
  const m = line.match(/^(?:export\s+)?(\w+)=(.+)$/);
  if (m) process.env[m[1]] = m[2].trim();
}
const SUPABASE_URL = `https://${process.env.SUPABASE_PROJECT_REF}.supabase.co`;
const SERVICE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY!;
```

## Upsert (INSERT ... ON CONFLICT UPDATE)

```typescript
async function supabaseUpsert(
  table: string, rows: Record<string, unknown>[], conflictColumns: string[]
): Promise<void> {
  const url = `${SUPABASE_URL}/rest/v1/${table}?on_conflict=${conflictColumns.join(',')}`;
  const res = await fetch(url, {
    method: 'POST',
    headers: {
      'apikey': SERVICE_KEY,
      'Authorization': `Bearer ${SERVICE_KEY}`,
      'Content-Type': 'application/json',
      'Prefer': 'resolution=merge-duplicates,return=minimal',
    },
    body: JSON.stringify(rows),
  });
  if (!res.ok) throw new Error(`Supabase upsert ${table} failed: ${res.status} ${await res.text()}`);
}
```

## Query (SELECT)

```typescript
async function supabaseQuery<T>(table: string, select = '*'): Promise<T[]> {
  const url = `${SUPABASE_URL}/rest/v1/${table}?select=${select}`;
  const res = await fetch(url, {
    headers: {
      'apikey': SERVICE_KEY,
      'Authorization': `Bearer ${SERVICE_KEY}`,
    },
  });
  if (!res.ok) throw new Error(`Supabase query ${table} failed: ${res.status}`);
  return res.json();
}
```

## Pitfalls
- The env file uses `SUPABASE_PROJECT_REF`, not `SUPABASE_URL`. Scripts that assume `SUPABASE_URL` will get undefined.
- Lines may or may not have `export` prefix — regex must handle both.
- Upsert requires `on_conflict` query param AND `Prefer: resolution=merge-duplicates` header. Missing either causes silent failure.
- Always include both `apikey` and `Authorization: Bearer` headers (the service role key goes in both).
- Use `return=minimal` in Prefer header to avoid getting full rows back (saves bandwidth).
