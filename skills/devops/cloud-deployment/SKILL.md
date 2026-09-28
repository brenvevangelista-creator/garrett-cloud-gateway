---
name: cloud-deployment
description: "Deploy static sites, APIs, and bots to Vercel and Render."
tags: ["deployment", "vercel", "render", "paas", "hosting"]
---

# Cloud Deployment

Deploy static sites, APIs, and bots to Vercel, Render, and similar PaaS platforms.

## Procedure

### Vercel (static sites, Next.js, dashboards)

1. **Push to GitHub.** Vercel auto-detects from repo root or a subdirectory.
2. **Connect repo in Vercel dashboard.** New Project → Import → select repo → configure root directory if needed → Deploy.
3. **Disable auth protection.** Vercel Authentication → toggle off "Require Log In". Without this, the deployment returns 401/redirect even though it succeeded. Verify with `curl -sL -o /dev/null -w "%{http_code}" <url>` — must be 200.
4. **Set production alias.** Vercel auto-assigns `<project>-<hash>.vercel.app`. The production URL (`<project>.vercel.app`) aliases to latest deployment.

### Render (background services, bots, cron workers)

1. **Create account manually.** hCaptcha blocks automated signup — no CLI or API bypass exists. Guide user through browser signup.
2. **Use Blueprint deploy.** Add `render.yaml` to repo root:
   ```yaml
   services:
     - type: web
       name: <service-name>
       runtime: python
       buildCommand: pip install -r requirements.txt
       startCommand: python bot.py
       plan: free
   ```
   **Always use `type: web` on free tier** — `type: worker` requires a paid plan and will fail with "service type is not available for this plan".
3. **Add a health check HTTP server for non-web processes.** Telegram bots, cron workers, and other long-running processes that don't bind to a port must start a dummy HTTP server on `$PORT` or Render kills the service. Pattern:
   ```python
   import threading
   from http.server import HTTPServer, BaseHTTPRequestHandler

   class HealthHandler(BaseHTTPRequestHandler):
       def do_GET(self):
           self.send_response(200)
           self.send_header('Content-type', 'text/plain')
           self.end_headers()
           self.wfile.write(b'OK')
       def log_message(self, format, *args):
           pass

   def start_health_server():
       port = int(os.environ.get('PORT', 10000))
       server = HTTPServer(('0.0.0.0', port), HealthHandler)
       server.serve_forever()

   # In main(), before run_polling():
   threading.Thread(target=start_health_server, daemon=True).start()
   ```
4. **Handle missing local config on cloud.** Any `load_env()` or config loader that reads from a local file (e.g. `~/.config/bren-os/env`) must return `{}` when the file is missing — cloud hosts only have `os.environ`. Never raise `FileNotFoundError` for config files that only exist locally.
5. **Connect GitHub repo.** Dashboard → New + → Blueprint → authorize GitHub → select repo → Render reads `render.yaml`.
6. **Approve the Blueprint.** After sync, Render shows an "Approve" button for new/changed services. The deploy does NOT start until the user clicks Approve.
7. **Set environment variables.** Dashboard → Environment tab → add each key. Never put secrets in `render.yaml`. For bulk entry (5+ vars), use two methods in priority order:

   **Primary: Render REST API via API key (most reliable).** Ask user to create an API key at Account → API Keys, then use `curl` + `jq` (not Python — subprocesses get killed on macOS, exit 137). The only reliable write method is **bulk PUT** — PATCH and POST on individual env vars return HTTP 405.
   ```bash
   # 1. Read current vars
   curl -s -H "Authorization: Bearer $API_KEY" \
     "$BASE/services/$SERVICE_ID/env-vars" > /tmp/current_env.json

   # 2. Build complete list with jq (safe for JWT/API key special chars)
   jq --arg val "$NEW_VALUE" \
     '[.[] | {(.envVar.key): .envVar.value}] | add | .NEW_KEY = $val | to_entries | map({key: .key, value: .value})' \
     /tmp/current_env.json > /tmp/env_body.json

   # 3. Bulk PUT (flat array of {key, value} — NOT wrapped in {envVar: {...}})
   curl -s -X PUT \
     -H "Authorization: Bearer $API_KEY" \
     -H "Content-Type: application/json" \
     -d @/tmp/env_body.json \
     "$BASE/services/$SERVICE_ID/env-vars"

   # 4. Verify
   curl -s -H "Authorization: Bearer $API_KEY" \
     "$BASE/services/$SERVICE_ID/env-vars" | \
     jq '[.[] | {key: .envVar.key, len: (.envVar.value | length)}]'
   ```
   **After any bulk env var set, verify values by reading them back.** Compare value lengths or prefixes against the source file — swapped values (correct key, wrong value) are a common failure mode that silently breaks the service.

   **Fallback: browser automation via local=True.** Navigate to the Environment page, click "Add variable", and use CDP `Input.insertText` (not `fill_input` which types char-by-char and times out on values >20 chars). For React-controlled textareas, set value via native property setter + dispatch `input`/`change` events:
   ```python
   js('''(() => {
       const el = document.getElementById('textarea_id');
       const setter = Object.getOwnPropertyDescriptor(window.HTMLTextAreaElement.prototype, 'value').set;
       setter.call(el, 'the value');
       el.dispatchEvent(new Event('input', {bubbles: true}));
   })()''')
   ```
8. **Deploy.** Manual Deploy → Deploy latest commit. Watch logs for startup.

## Pitfalls

- **Vercel auth protection is on by default for new projects.** Always check after first deploy. A 401/redirect response means the toggle is still on, not that the deploy failed.
- **`render` CLI does not exist as a pip package.** The official Render CLI is available from Homebrew (`brew install render`) or direct binary download. pip packages claiming to be Render CLI are unrelated.
- **Render uses hCaptcha on signup.** No API or CLI bypass. Account creation must be done manually in browser.
- **GitHub OAuth authorize buttons may be disabled by default.** Remove the `disabled` attribute via JS (`btn.removeAttribute('disabled')`) before clicking, or the click silently fails.
- **Render Blueprint `render.yaml` must be in repo root.** Subdirectory placement causes "no blueprint found" error.
- **Free tier does NOT support `type: worker`.** Always use `type: web` with a health check HTTP server (see step 3). The deploy fails silently with a red X in Blueprint syncs if you try `type: worker`.
- **Free tier Render services spin down after inactivity.** First request after idle takes 30-60s cold start. Not suitable for latency-sensitive endpoints.
- **Render env vars are the only config mechanism on cloud.** Bot code that loads from local files (`.env`, custom config paths) must fall back to `os.environ` when the file is absent. Hardcoded `raise FileNotFoundError` kills the deploy.
- **Never use shell heredocs for JWT/API key values in JSON payloads.** Special characters in JWTs and API keys corrupt inside heredocs. Always use `jq --arg` or `jq --rawfile` to safely construct JSON bodies.
- **PATCH and POST on individual Render env vars return HTTP 405.** Use bulk PUT on the collection endpoint instead (flat JSON array of `{key, value}` objects). PUT on a single env var by cursor creates duplicates with the cursor string as the key name — never do this.
- **DELETE env vars by key name, not cursor.** `DELETE /services/{id}/env-vars/{KEY_NAME}` returns 204. Using the cursor as the identifier returns 404.
- **Detect duplicate services before fixing.** When a repo has been deployed multiple times (e.g. via Blueprint + manual), Render creates separate services with different IDs. List all services first (`GET /v1/services`), compare env var counts, and suspend the empty/stale duplicate before updating the active one. A stale service with the same bot token causes duplicate message delivery.
- **Suspend returns 204 (empty body).** `POST /v1/services/{id}/suspend` with no request body returns HTTP 204 on success. Don't expect JSON — empty response means it worked. Verify with `GET /v1/services/{id}` and check `suspended: true`.

## References

- `references/render-api-env-vars.md` — Render REST API endpoints, bulk set pattern, and pitfalls for environment variable management via API key.

## Testing

After deploy:
```bash
curl -sL -o /dev/null -w "%{http_code}" <url>
```
Must return 200. Check logs for startup errors.