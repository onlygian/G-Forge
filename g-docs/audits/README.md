# Audits

Audit reports, triage tables, and findings promoted here because they outlive the milestone that produced them (G-RULES §I: `g-docs/audits/` is committed; `g-docs/agent-output/` is gitignored and regenerable). Three classes are held here.

## 2026-07 modernization cycle

Modernization / optimization audit reports and their triage tables, in reading order: the external report (received-input record, see its banner) → per-finding triage (incl. coverage-sweep rows GF-70…78) → rebuild map (component verdicts) → rebuild report (v2, authoritative for planning) → triage review (developer decisions, incl. the confirmed GF-46 full rebuild).

- `2026-07-modernization-report.md`
- `2026-07-modernization-triage.md`
- `2026-07-rebuild-map.md`
- `2026-07-rebuild-report.md`
- `2026-07-triage-review.md`

## 2026-08-30 — the M52 Fable audit cycles (F1–F3)

Three audit-and-fix cycles inserted before the v2.5 release session (`g-docs/ROADMAP.md` M52, scope amended 2026-08-30). **Fable is the auditing model, not the subject:** in each cycle HQ ran on the session model and read one slice of source *directly*, writing the findings itself with no reviewer agents — a deliberate §A1 override, on the reasoning that the gap being hunted is the class the cheaper reviewers had already passed. Findings earned a fix only if they sat on a component the rebuild map marks **SURVIVES** (`2026-07-rebuild-map.md`: no native equivalent — a G-Forge opinion) or were adopter-facing. One slice, one wave, one gate per cycle.

- `2026-08-30-fable-f1-commit-gate.md` — F1: the commit-gate path (`check-commit.sh`, native `pre-commit`, `post-commit-cleanup.sh` and the libs they source), the git-hooks-dir install steps, and CI.
- `2026-08-30-fable-f2-survives-agents-record-seam.md` — F2: the SURVIVES agents and the record seam (`g-resume`, `g-retro`, `g-adr`, `g-doc-review`).
- `2026-08-30-fable-f2-redo-survives-agents-record-seam.md` — F2 REDO: the same slice audited a second time on a fresh session at developer direction, diffed against the F2 record finding by finding. Read the pair together; this one is not an independent slice.
- `2026-08-30-fable-f3-survives-skills-ledger.md` — F3: the remaining SURVIVES skills plus the open ledger, including the carries minted by F2.

## 2026-09 promoted records

Written originally to gitignored `g-docs/agent-output/` and promoted here on 2026-09-05, before the working copy that held them was deleted. Each carries a provenance header stating its original path and how to read it; bodies are verbatim.

- `2026-09-02-m54-doc-review-verdict.md` — the `/g-doc-review` verdict that put M54 (Wiki & README Currency) into DOCS HOLD: 16 blocking, 7 warning. The basis for M54's outstanding fix round. Read as of its own date — v2.6.2 has since changed some surfaces it discusses.
- `2026-09-03-voice-profile-diagnosis.md` — the read-only diagnosis behind M53.1 defect 4 (`.claude/voice-profile` written but not honoured), whose fix is deferred pending a developer decision on the contract. Re-derive its enumeration of read sites from source rather than trusting the list.
