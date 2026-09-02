# Abstraction contract — every write to `g-docs/patterns/latest.md`

Load this before EVERY write to the saved report — the first write in Step 7 and every later status update (Step 8's triage updates in MINE, every status update in RESOLVE's Step 14). `g-docs/patterns/latest.md` leaves the project — every mutation to it is an outbound write, not just its first.

## The contract

This file leaves the local environment — it is read by external third-party models — so it must contain **NO file paths, NO code fragments, NO function/variable/agent/skill identifiers, and NO repo or project names**. Each entry contains only:

- Pattern label, generalized (not the repo-specific label from Step 3)
- Failure-class description in plain, principle-level language
- Frequency bucket (Isolated / Emerging / Systemic)
- Weighted count
- Source counts (e.g. "3 retrospectives, 1 forecast")
- Proposed-fix INTENT in one abstract sentence (e.g. "strengthen the planning rule that forbids splitting serial work")
- Status

Every Emerging or Systemic (≥2-frequency) pattern gets `**Status:** PENDING`. Isolated and Reinforced patterns are listed compactly with `**Status:** —`.

## Mandatory self-check — do not skip

Before writing the file, re-read the drafted report end-to-end and strip anything matching the forbidden list above (file paths, code fragments, identifiers, repo/project names) plus the secrets class below. This report is the only artifact that crosses outside the project; the self-check is what keeps it inside the abstraction contract.

## Mechanical scan — after the self-check, before writing

This scan runs **in-model, against the drafted text held in context** — nothing has been written to disk yet at this point, so this is a mechanical *discipline* (a fixed, exhaustive token-class pass over the draft), **never a shell grep against a file** — no future edit may convert it to a script; the draft is in-context, not on disk. Scan the drafted report text for: path-like tokens (a `/` or `\` appearing inside backticks or inside a word-token), file-extension tokens matching `\.(sh|md|js|ts|py|json|yaml)\b`, the repo/project name, and a **secrets class** — anything resembling a credential, API key, or token; an env-var name; a URL, hostname, or IP address; or an email address. Any hit means the self-check missed something — fix the draft and re-scan until clean, then write. (This converges with M38's planned outbound-leak check for the same class of problem — a mechanical scan on a document leaving the project, rather than a model self-check alone.)

## Report skeleton

```
# Pattern Report — YYYY-MM-DD

## Systemic (≥3)
- **Label:** ... | **Weighted count:** N | **Sources:** X retrospectives, Y forecasts
  **Failure class:** ...
  **Proposed fix intent:** ...
  **Status:** PENDING

## Emerging (2)
[same shape]

## Isolated (1)
- **Label:** ... | **Sources:** N | **Status:** —

## Reinforced
- **Label:** ... | **Sources:** N | **Status:** —
```
