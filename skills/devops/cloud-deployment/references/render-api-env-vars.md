# Render REST API — Environment Variables

API base: `https://api.render.com/v1`
Auth: `Authorization: Bearer <API_KEY>`

## Endpoints

| Action | Method | Path | Notes |
|--------|--------|------|-------|
| List env vars | GET | `/services/{id}/env-vars` | Returns array |
| Bulk replace | **PUT** | `/services/{id}/env-vars` | Flat JSON array `[{key, value}, ...]` |
| Delete env var | **DELETE** | `/services/{id}/env-vars/{KEY_NAME}` | Key name, not cursor |
| Trigger deploy | POST | `/services/{id}/deploys` | `{"clearCache": "clear"}` |

**PATCH and POST on individual env vars return HTTP 405.** These are not supported. Use bulk PUT instead.

## Response format

GET returns an array of objects:
```json
[
  {
    "envVar": {
      "key": "TELEGRAM_BOT_TOKEN",
      "value": "123:ABC...",
      "generatedValue": false,
      "generateWithStartCommand": null
    },
    "cursor": "abc123"
  }
]
```

The **cursor** appears in GET responses but is not needed for PUT or DELETE.

## Bulk replace (PUT)

PUT body is a **flat array** of `{key, value}` objects — NOT wrapped in `{envVar: {...}}`:
```json
[
  {"key": "VAR1", "value": "val1"},
  {"key": "VAR2", "value": "val2"}
]
```

This replaces ALL env vars. Include every var that should exist after the call.

### Workflow

1. GET existing vars → extract keys + values with `jq`
2. Modify the set using `jq --arg` (safe for JWTs, API keys, and special chars)
3. PUT the complete list
4. GET again to verify — compare value lengths and prefixes against source

## Pitfalls

- API keys are scoped to the account, not a single service. One key works for all services.
- The service ID in the URL changes when you delete and recreate a service — Blueprint re-sync may create a new service with a different ID.
- `clearCache: "clear"` in the deploy trigger forces a clean build. Use when env vars changed.
- Render's internal `/api/v1/` route (used in browser) has different auth than the public API — don't confuse them.
- **After any bulk set, verify values by GETting them back.** Compare value lengths or start-characters against the source. Swapped values (correct key, wrong value from a neighboring var) silently break the service and are hard to diagnose from logs alone.
- **PUT by individual cursor creates duplicates** with the cursor string as the key name. Only PUT to the collection endpoint with the full list.
- **DELETE uses key name, not cursor.** `DELETE /services/{id}/env-vars/VAR_NAME` returns 204. Using cursor returns 404.
- **Never use shell heredocs for JWT/API key values.** Special chars corrupt in heredocs. Use `jq --arg` or `jq --rawfile` instead.
- **macOS kills Python subprocesses (exit 137)** when run from certain tool contexts. Use `jq` + `curl` directly instead of Python `requests` scripts.
