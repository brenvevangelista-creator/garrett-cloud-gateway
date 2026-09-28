# Pipeline Orchestrator Pattern

Chain multiple bots/scripts into a single daily automated run with Telegram notification.

## Architecture

```
Forecast Bot → Commissary Bot → Summary Generator → Telegram Notifier
     ↓               ↓                ↓                    ↓
 forecast.json  production.json   markdown report    bot group message
```

## Implementation Checklist

1. **Create orchestrator directory** — `~/projects/<name>/agents/orchestrator/`
2. **Write pipeline.py** — chains subprocess calls, reads JSON outputs, generates summary
3. **Write refresh.sh** — shell wrapper for easy CLI execution
4. **Set correct Python** — use project venv, NOT system Python
5. **Test pipeline** — run end-to-end, verify JSON parsing
6. **Create cron job** — `cronjob_manage` with script in `~/.hermes/scripts/`
7. **Add Telegram commands** — extend existing bot with pipeline triggers

## JSON Parsing Rules

- Always `json.load(open('file.json'))` — never parse subprocess stdout
- Check actual key names in the JSON file before writing parsers
- Don't assume `summary`, `daily_forecast`, or other common names — read the file first

## Cron Job Setup

```bash
# Copy script to standard location
cp ~/projects/<name>/agents/orchestrator/refresh.sh ~/.hermes/scripts/<name>-pipeline.sh
chmod +x ~/.hermes/scripts/<name>-pipeline.sh
```

Then create cron job via `cronjob_manage` with `schedule` (cron expression) and `script` path.

## Telegram Bot Extension

To add commands to an existing python-telegram-bot bot:

1. Read bot.py — find handler functions and registration block
2. Add new handler functions before `help_command`
3. Add `CommandHandler` registrations in `main()`
4. Restart bot: kill old PID, start new, verify

### Token Loading Pitfall

Custom env file parsers return a dict but don't set `os.environ`. Always:
```python
BOT_TOKEN = os.environ.get("TELEGRAM_BOT_TOKEN", "") or env.get("TELEGRAM_BOT_TOKEN", "")
```

## Bot Restart Procedure

```bash
# Find and kill old process
ps aux | grep bot.py | grep -v grep
kill <PID>
sleep 2

# Start new (background)
cd ~/projects/<name>/agents/<bot-dir>
venv/bin/python3 bot.py &

# Verify
sleep 3
ps aux | grep bot.py
```

If bot crashes immediately, run in foreground to see errors:
```bash
venv/bin/python3 bot.py 2>&1
```