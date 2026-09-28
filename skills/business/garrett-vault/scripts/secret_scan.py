#!/usr/bin/env python3
"""Scan a staged git diff for secrets before committing to the Garrett vault.

Usage:
    cd ~/Desktop/Garrett && git add <paths> && git diff --cached > /tmp/staged.diff
    /usr/bin/python3 scripts/secret_scan.py /tmp/staged.diff

Exits 0 and prints SCAN_RESULT=CLEAN when nothing is found, 1 otherwise.

Only ADDED lines ('+' prefixed) are tested. Context lines in a diff are content
that already exists in the file and is not being introduced by this commit;
matching them produces false alarms that train you to ignore the check.
"""
import re
import sys

PATTERNS = {
    "openai_key":   r"sk-[A-Za-z0-9]{16,}",
    "jwt":          r"eyJ[A-Za-z0-9_-]{12,}",
    "aws_key":      r"AKIA[0-9A-Z]{12,}",
    "private_key":  r"-----BEGIN [A-Z ]*PRIVATE KEY",
    "pg_url":       r"postgres(?:ql)?://[^\s]*:[^\s]*@",
    "supabase":     r"service_role|anon[_-]?key",
    "telegram_tok": r"[0-9]{9,10}:AA[A-Za-z0-9_-]{30,}",
    "generic_cred": r"(?:api[_-]?key|password|secret|token)\s*[:=]\s*[\"']?[A-Za-z0-9_\-./+]{12,}",
}

# [REDACTED] placeholders and env-file POINTERS are the documented safe pattern.
ALLOW = re.compile(r"\[REDACTED\]|~/\.config/bren-os/env|<[a-z_]+>", re.I)


def main() -> int:
    path = sys.argv[1] if len(sys.argv) > 1 else "/tmp/staged.diff"
    with open(path, encoding="utf-8", errors="replace") as fh:
        lines = fh.readlines()

    added = [l for l in lines if l.startswith("+") and not l.startswith("+++")]
    hits = []
    for i, line in enumerate(added, 1):
        if ALLOW.search(line):
            continue
        for name, pat in PATTERNS.items():
            if re.search(pat, line, re.I):
                hits.append((i, name, line.rstrip()[:160]))

    print(f"added_lines_scanned={len(added)}")
    if hits:
        for i, name, text in hits:
            print(f"  HIT[{name}] added-line {i}: {text}")
        print(f"SCAN_RESULT=DIRTY ({len(hits)} hit(s)) - DO NOT COMMIT")
        return 1
    print("SCAN_RESULT=CLEAN")
    return 0


if __name__ == "__main__":
    sys.exit(main())
