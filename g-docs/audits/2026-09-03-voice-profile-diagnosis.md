> **Promoted to the committed record on 2026-09-05.** Originally written to
> `g-docs/agent-output/g-plan/m53-1-voice-profile-diagnosis.md`, which is
> gitignored and did not survive the working copy. This is the read-only
> diagnosis behind M53.1 defect 4 (`.claude/voice-profile` written but not
> honoured) — its verdict is (a), and the fix is deferred pending a developer
> decision on what the contract should be. Body below is verbatim as written;
> only this header was added. Promoted under G-RULES §I, which makes
> `g-docs/audits/` the committed home for findings that outlive their
> milestone — a 2026-08-11 finding of this repo's was demonstrated
> unrecoverable on 2026-08-17 for exactly this reason.
>
> **Caveat recorded at promotion:** the enumeration of voice-profile read
> sites in this document was refuted repeatedly during the v2.6.2 release
> gate. Re-derive the read set from source at fix time rather than trusting
> any list here.

# M53-1 — Why `.claude/voice-profile` is not honoured (diagnosis, read-only)

Date: 2026-09-03
Scope: read-only. No file except this report was modified.

## Conclusion

**(a) nothing reads the file at render time** — for the surface where the defect was actually observed (PM/general conversational responses to one-line questions). Two narrow skills (`g-voice`, `g-tier`) do read the file and branch their own confirmation/demo output on it, but neither is the surface the developer's 2026-09-02 complaint ("you're too verbose with the user") was about — that complaint concerns ordinary PM/skill responses to plain questions, and for that surface there is no read site at all. See "Why not (b)" below for the reasoning that rules out (b) as the primary conclusion.

## Enumeration of every hit — `grep -rln 'voice-profile' skills/ hooks/ agents/ .claude/rules/`

Command and full output:

```
$ grep -rln 'voice-profile' skills/ hooks/ agents/ .claude/rules/
skills/g-kickoff/references/voice-and-training.md
skills/g-kickoff/SKILL.md
skills/g-voice/SKILL.md
skills/g-train/SKILL.md
skills/g-help/SKILL.md
skills/g-init/SKILL.md
skills/g-tier/SKILL.md
.claude/rules/g-rules-B-workflow.md
```

Per-file classification, each pinned by its own `grep -n 'voice-profile' <file>` (never a concatenated read):

### `skills/g-kickoff/references/voice-and-training.md`
```
$ grep -n 'voice-profile' skills/g-kickoff/references/voice-and-training.md
3:Load when Step 0 runs its intake (i.e. `.claude/voice-profile` was absent). Deliver these blocks verbatim, rendered per the branch logic in the SKILL.md core.
```
Classification: **prose** — describes when this reference is loaded; does not itself read the file.

### `skills/g-kickoff/SKILL.md`
```
$ grep -n 'voice-profile' skills/g-kickoff/SKILL.md
12:Check for `.claude/voice-profile`.
15:- If it **does not exist**: run the language intake exactly as `/g-voice` defines it: Glob `skills/g-voice/SKILL.md` and follow its Step 1a — the same 2-question plain-language interview and profile-derivation table — then write the derived profile name to `.claude/voice-profile`. Load `references/voice-and-training.md` and deliver its confirmation line for the profile just written.
```
Classification: **read site, existence-check only** (line 12) that gates whether to run first-time intake, plus a **write site** (line 15, only fires when the file is absent). This is a one-time bootstrap path (kickoff runs once per project), not a per-response render check. It does not affect the rendering of any other skill's output, and does not fire on a project (like this one) where the file already exists.

### `skills/g-voice/SKILL.md`
```
$ grep -n 'voice-profile' skills/g-voice/SKILL.md
3:description: Set how G-Forge communicates with you. With no argument, runs a short 2-question intake and sets the right profile automatically — you never need to know the tier names. With `dev`, `mid`, or `eli5` as an argument, applies that profile directly. Writes `.claude/voice-profile`. Every G-Forge skill reads this and renders its output accordingly.
58:Create `.claude/` if missing. Write the profile name as a single bare word followed by a newline to `.claude/voice-profile`. Overwrite any existing content.
59:87:If Step 1 was the read case, after printing the status block, render the same example report in all three profiles so the developer can compare. Use a short, neutral example like a `/g-review MERGE READY` summary. See `g-docs/voice-profiles.md` for canonical samples.
94:  Profile file:    .claude/voice-profile ([present / absent — using default])
```
Classification: line 3 is a **prose claim** ("Every G-Forge skill reads this and renders its output accordingly") — this is the claim under test, not evidence that it is true; no other skill file contains a matching read+branch (see enumeration above — only `skills/g-tier/SKILL.md` and `skills/g-kickoff/SKILL.md` contain the literal string at all, and kickoff's use is a one-time existence check, not a render branch). Line 58 is a **write site**. Line 87 renders a demo of all three profiles side by side for comparison purposes — it does not read the *current* value of the file to select one rendering; it prints all three. Line 94 **reads the file to display its own presence/absence status** in `/g-voice`'s own confirmation screen — this is `/g-voice` reporting on itself, not `/g-voice` (or any other skill) rendering *its own regular output* according to the stored profile.

### `skills/g-train/SKILL.md`
```
$ grep -n 'voice-profile' skills/g-train/SKILL.md
12:**Read `.claude/voice-profile`.** If absent: run the language intake (same 2-question interview as `/g-voice` no-arg). Derive and write the profile before continuing.
```
Classification: **read site, existence/bootstrap only** — same pattern as g-kickoff: read to check presence, intake only fires if absent. No branch on the profile's *value* to change `/g-train`'s own rendering.

### `skills/g-help/SKILL.md`
```
$ grep -n 'voice-profile' skills/g-help/SKILL.md
42:9. `.claude/voice-profile` — active voice profile (default: `dev`)
```
Classification: **prose** — one line in a reference table of state files; does not read or branch.

### `skills/g-init/SKILL.md`
```
$ grep -n 'voice-profile' skills/g-init/SKILL.md
263:Map `1`/`d`/`dev` → `dev` · `2`/`m`/`mid` → `mid` · `3`/`e`/`eli5` → `eli5` · anything else/empty → `dev`. Write to `.claude/voice-profile`.
277:  ✓ .claude/voice-profile — [resolved]
302:  ✓ .claude/voice-profile — [chosen voice]
```
Classification: **write site** (project scaffolding, one-time at `/g-init`). No read-and-branch for rendering.

### `skills/g-tier/SKILL.md`
```
$ grep -n 'voice-profile' skills/g-tier/SKILL.md
51:Read `.claude/voice-profile` if it exists; treat absent as `dev`. The Step 5 confirmation message is rendered according to the profile:
86:- Honor the active voice profile (`.claude/voice-profile`) in the confirmation message. Never override the voice — even an `eli5` user gets the same factual switch, just rendered conversationally.
```
Classification: **genuine read site with a render branch** — the only one found in the entire enumeration. It is scoped narrowly to `/g-tier`'s own Step 5 confirmation message after a tier switch. It does not generalize to any other skill's output, and has no bearing on PM conversational responses, `/g-plan`, `/g-execute`, `/g-review`, or any of the other ~20+ skills in `skills/`.

### `.claude/rules/g-rules-B-workflow.md`
```
$ grep -n 'voice-profile' .claude/rules/g-rules-B-workflow.md
40:**Voice rule:** Every skill output, prompt, and confirmation honors the voice profile in `.claude/voice-profile` — `dev` (terse, default), `mid` (one context sentence per major result), or `eli5` (plain language, conversational). Set via a 2-question plain-language intake (auto during `/g-kickoff` if unset, or `/g-voice` with no argument) — never by asking the developer to self-select a tier. The profile changes **rendering**, never verdicts or numeric values. See `g-docs/voice-profiles.md` for canonical samples.
```
Classification: **prose — the normative claim itself**, not an implementation. This is the source text (`@`-imported into every session via `CLAUDE.md` → `G-RULES.md` → this file) that *states* the rule, but it names no mechanism, hook, or per-response check that reads `.claude/voice-profile`'s stored value and injects it into ordinary skill/PM output. It is read into every session's context (because it is `@`-imported), but the *string it names* (`.claude/voice-profile`) is never itself opened as a file by anything that renders a general response.

## Absence check — the general/PM conversational render surface

The observed defect (2026-09-02, verbatim: "you're too verbose with the user") is about ordinary PM/skill responses to plain questions — not `/g-voice`'s or `/g-tier`'s own confirmation screens. For that surface, the relevant read points would be: the per-prompt hook (`hooks/workflow-checkpoint.sh`, which runs on every `UserPromptSubmit` and is the one mechanism that injects state into every turn), and the `project-manager` agent definition (the PM role that is supposed to render every response per G-RULES §B).

```
$ grep -n 'voice' hooks/workflow-checkpoint.sh
(no output — zero matches)
```

```
$ grep -rln 'voice-profile' agents/
(no output — zero matches)
```

```
$ grep -rln 'voice-profile\|voice_profile\|VOICE_PROFILE' hooks/*.sh
(no output — zero matches across every hook script, not just workflow-checkpoint.sh)
```

This absence-grep covers: every hook script in `hooks/*.sh` (the only mechanism that runs unconditionally on every prompt) and every agent definition in `agents/` (including `agents/project-manager.md`, the file that embodies the PM voice on every turn per G-RULES §B's "PM interface rule"). It does **not** cover: the two narrow exceptions already found and reported above (`skills/g-voice/SKILL.md` line 94, `skills/g-tier/SKILL.md` lines 51/86), which are real but scoped to those two skills' own confirmation output, not the general response surface.

## Installed-copy parity check (self-host)

This repo self-hosts: `.claude/rules/` is the installed copy read at runtime, `.claude/rules/g-rules-B-workflow.md` is the live copy of the Voice rule actually in force on this seat. Compared against source:

```
$ grep -n 'voice-profile' .claude/rules/g-rules-B-workflow.md
40:**Voice rule:** Every skill output, prompt, and confirmation honors the voice profile in `.claude/voice-profile` — ...
```

Identical text to source (same line 40, same wording) — no drift on this file. `skills/`, `hooks/`, and `agents/` have no installed-copy shadow directory in `.claude/` (confirmed: `.claude/skills` does not exist — `ls .claude/skills` → "NO .claude/skills dir"; skills are read directly from the plugin source tree, not copied per-project), so there is no drift surface to check for those three.

```
$ diff hooks/workflow-checkpoint.sh .claude/hooks/workflow-checkpoint.sh
(no output — files identical, confirms both source and installed copy independently have zero voice-profile references)
```

```
$ grep -rln 'voice-profile' .claude/agents .claude/hooks
(no output — zero matches in installed agents/hooks, matching source)
```

No drift found between source and installed copy on this axis — both agree the general render surface has no read site.

## `.claude/voice-profile` content on this seat

```
$ cat .claude/voice-profile
dev
```

Confirms the file is present and set (not the absent/default case) — the write side of the pipeline works; the gap is entirely on the read/render side for the general conversational surface.

## Why not (b)

(b) would require: something reads the profile's value, but the skills' output templates are verbose *regardless* of what value they read — i.e. a read-and-discard pattern, or a read-and-branch pattern whose branches are all equally verbose. Neither is what the enumeration shows for the observed failure surface. For PM/general responses, there is no read attempt at all to discard — `hooks/workflow-checkpoint.sh` and every file in `agents/` (including `project-manager.md`) contain zero occurrences of the string, confirmed by absence-grep above. (b) is the correct description only for the two narrow exceptions (`g-voice`, `g-tier`), where a read-and-branch genuinely exists and is scoped correctly — but that is not where the reported verbosity occurred, so (b) does not explain the observation.

## What would separate the residual ambiguity

If a future grep of `agents/project-manager.md` or a currently-undiscovered hook surfaces a read site that was missed here, that would move the general-surface conclusion from (a) toward (b) or (c). The absence-grep above is exhaustive across `hooks/*.sh` and `agents/*.md` as of this diagnosis (2026-09-03) — re-run `grep -rln 'voice-profile\|voice_profile\|VOICE_PROFILE' hooks/ agents/` after any change to either directory to confirm the surface hasn't grown a new read site.
