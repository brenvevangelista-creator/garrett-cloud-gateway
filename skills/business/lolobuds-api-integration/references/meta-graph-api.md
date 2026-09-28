# Meta Graph API — Facebook & Instagram Posting

Post content to Facebook Pages and Instagram Business accounts via Meta Graph API.

## Current Status (2026-09-24)

**BLOCKED.** App "Lolo Buds Marketing" (ID: `1085496040850678`) is in **development mode**. The `pages_manage_posts` permission is NOT available in development mode — it requires **App Review** (submit for review at `https://developers.facebook.com/apps/{APP_ID}/app-review/permissions/`).

All standard approaches were exhausted:
- User token → only `pages_read_engagement` granted
- Page-specific token via `/me/accounts` → same
- `fb_exchange_token` flow with App Secret → extended token still missing permission
- Graph API Explorer → `pages_manage_posts` not listed in dropdown
- OAuth redirect flow → permission not grantable in development mode

**Instagram NOT connected** — `instagram_business_account` field is empty on the FB Page.

## Working Alternatives (not yet implemented)

1. **Buffer** (https://buffer.com) — fastest to set up, supports FB + IG scheduling
2. **Meta Business Suite** (https://business.facebook.com) — free, built-in scheduling, no API needed
3. **App Review** — submit for `pages_manage_posts` review (1-2 weeks turnaround)

## Prerequisites (for when App Review passes)

1. Meta App at https://developers.facebook.com/
2. Page Access Token with permissions:
   - `pages_manage_posts`
   - `pages_read_engagement`
   - `instagram_basic`
   - `instagram_content_publish`
3. Store credentials in `~/projects/oracle/agents/marketing/config.json`

## Facebook Page Post

```bash
curl -s -X POST "https://graph.facebook.com/v26.0/{PAGE_ID}/feed" \
  -d "message=Hello from Lolo Buds!" \
  -d "access_token={PAGE_TOKEN}"
```

Response: `{"id": "PAGE_POST_ID"}`

## Facebook Photo Post

```bash
curl -s -X POST "https://graph.facebook.com/v26.0/{PAGE_ID}/photos" \
  -d "url={IMAGE_URL}" \
  -d "message=Caption text" \
  -d "access_token={PAGE_TOKEN}"
```

## Instagram Photo Post

Instagram requires a two-step process:

### Step 1: Create media container

```bash
curl -s -X POST "https://graph.facebook.com/v26.0/{IG_ACCOUNT_ID}/media" \
  -d "image_url={IMAGE_URL}" \
  -d "message=Caption text" \
  -d "access_token={IG_TOKEN}"
```

### Step 2: Publish container

```bash
curl -s -X POST "https://graph.facebook.com/v26.0/{IG_ACCOUNT_ID}/media_publish" \
  -d "creation_id={CONTAINER_ID}" \
  -d "access_token={IG_TOKEN}"
```

## Pitfalls

- **`pages_manage_posts` requires App Review.** Cannot be obtained in development mode. Do not attempt OAuth flows, token exchanges, or Graph API Explorer — all fail. Submit for App Review or use an alternative (Buffer, Business Suite).
- **Facebook Login + Marketing API conflict.** Meta does not allow combining these use cases in one app. Choose one.
- **Instagram requires image or video** — text-only posts are not supported.
- **Instagram containers expire** — publish within 24 hours of creation.
- **Rate limits** — 25 posts per 24 hours per Instagram account.
- **Token expiration** — Page tokens can expire. Use long-lived tokens or refresh.
- **Image URL must be publicly accessible** — Meta's servers need to fetch the image.
- **API version**: Use `v26.0` (current as of 2026-09). Older versions may be deprecated.
