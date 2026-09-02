# Project tracking — incident history and Roundtable design (G-RULES §I companion)

Load trigger: read this when deciding whether a record is worth committing, when binding or editing the Roundtable, or when editing §I. The normative rules live in `.claude/rules/g-rules-I-project-tracking.md`; this file holds the incident history and design detail moved out of them (v2.6 token diet).

## Roundtable design detail (M33)

Spec: `g-docs/milestones/M33-the-roundtable.md`. **Surface-agnostic** per ADR-001: the skill talks to a four-op adapter (`bind`/`read_section`/`append_feed`/`write_living_state`), never an MCP directly. Link-restricted, never public; no secrets on the Roundtable. Opt-in, triggerable, never autonomous.

## Why audits and archives are committed

An audit finding whose only durable copy is a `g-docs/todo.md` row pointing at gitignored `g-docs/agent-output/` is not recorded, it is scheduled to be lost — demonstrated 2026-08-17: one 2026-08-11 finding is already unrecoverable.

## Why field reports are committed verbatim

A field report is the evidence base a scope amendment cites (e.g. M52 Task 23), so it must survive with the record — committed verbatim, never rewritten at intake. The reproduction against source, not the report itself, is what earns a task.
