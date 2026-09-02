#!/bin/bash
# detect-stack.sh — deterministic implementation of /g-specialize Step 1
# (dependency scan + combo detection + supplementary trigger) and Step 5
# (profile file location: current working directory first, then plugin cache).
#
# Run from the project root. Prints KEY: value lines for the skill to
# interpret; always exits 0 — every outcome is in the output, never the exit
# code. The dependency→stack mapping, combo table, and stack→file derivation
# that used to live as prose tables in SKILL.md live here now (one owner).
# Rationale for the edge cases (xamarin EOL, React Router v7 ≡ remix, the
# no-sources interview, the code-lead consult) lives in
# ../references/detection-edge-cases.md; combo emergent-pattern rationale in
# ../references/combo-rationale.md.
#
# Usage: detect-stack.sh [candidate-stack ...]
#   Candidate args are stack names the model extracted from prose (an explicit
#   /g-specialize argument, or brief/roadmap wording the grep cannot catch).
#   Each is validated against the supported closed set: valid → STACK line
#   (source=arg), invalid → UNSUPPORTED line.
#
# Output contract:
#   STACK: <name> source=<arg|brief|deps|roadmap>
#                            detected stack; <name> is from the supported
#                            closed set, byte-identical to the frontmatter
#                            description list; first source wins on duplicates
#                            (priority: arg > brief > deps > roadmap)
#   UNSUPPORTED: <name>      candidate arg not in the supported closed set
#   CONFLICT: <text>         ambiguity the skill must resolve (code-lead
#                            consult or developer question per the core) —
#                            includes the no-brief/no-deps case
#   COMBO: <combo-key>       every combo whose required stacks are fully
#                            covered by the detected set (rules only, no agent)
#   SUPPLEMENTARY: frontend-data-flow
#                            printed when any component-framework stack was
#                            detected (react, vue-pinia, nuxt, next-js,
#                            sveltekit, angular, remix, astro)
#   AGENT_FILE: <path>       per confirmed stack (glob agents/*-architect.md —
#                            irregular basenames like go-gin → go-architect.md
#                            fall out of the glob); absent for combos
#   RULES_FILE: <path>       per confirmed stack and combo
#   MISSING: <stack>         profile files not found locally or in the plugin
#                            cache (highest cache version is used when several
#                            are present)
#   NOTE: <text>             0+ human-readable notes (e.g. the xamarin EOL flag)
set -u
LC_ALL=C

out() { printf '%s\n' "$*"; }

SUPPORTED="angular asp-net-core astro bun c-embedded capacitor cpp-cmake django electron express fastapi flask flutter go-fiber go-gin godot-csharp godot-gdscript hono kotlin-android kotlin-ktor laravel maui nest-js next-js node-ts nuxt phoenix-liveview pygame python-cli python-data python-ml python-textual rails react react-native remix rust-axum rust-cli spring-boot sveltekit swift-ios tauri unity unreal vue-pinia wpf-csharp xamarin claude-plugin"

is_supported() {
    case " $SUPPORTED " in *" $1 "*) return 0 ;; *) return 1 ;; esac
}

EMITTED=" "
emitted() {
    case "$EMITTED" in *" $1 "*) return 0 ;; *) return 1 ;; esac
}
emit_stack() { # <name> <source>
    emitted "$1" && return 0
    EMITTED="$EMITTED$1 "
    out "STACK: $1 source=$2"
}

# word-ish grep: hyphen counts as a name character so `react` never matches
# inside `react-native` and `astro` never matches inside `astro-react`
name_in_file() { # <name> <file>
    grep -qiE "(^|[^a-zA-Z0-9-])$1([^a-zA-Z0-9-]|$)" "$2" 2>/dev/null
}

# ── candidate args (explicit /g-specialize argument or model-extracted names) ─
ARG_STACKS=""
for cand in "$@"; do
    if is_supported "$cand"; then
        ARG_STACKS="$ARG_STACKS $cand"
    else
        out "UNSUPPORTED: $cand"
    fi
done

# ── Source 1 — g-docs/project_brief.md (highest confidence) ──────────────────
BRIEF=g-docs/project_brief.md
BRIEF_SET=""
if [ -f "$BRIEF" ]; then
    for s in $SUPPORTED; do
        name_in_file "$s" "$BRIEF" && BRIEF_SET="$BRIEF_SET $s"
    done
fi

# ── Source 3 — dependency files ──────────────────────────────────────────────
DEPS_SET=""
DEP_FILES_FOUND=0
dep_add() {
    case " $DEPS_SET " in *" $1 "*) : ;; *) DEPS_SET="$DEPS_SET $1" ;; esac
}
in_deps() {
    case " $DEPS_SET " in *" $1 "*) return 0 ;; *) return 1 ;; esac
}

# package.json — dependencies and devDependencies (key-position match)
if [ -f package.json ]; then
    DEP_FILES_FOUND=1
    hd() { grep -qE "\"$1\"[[:space:]]*:" package.json; }
    # key present inside the devDependencies block specifically
    hdd() {
        sed -n '/"devDependencies"[[:space:]]*:/,/}/p' package.json \
            | grep -qE "\"$1\"[[:space:]]*:"
    }
    PKG_MATCHED=0
    pkg_add() { dep_add "$1"; PKG_MATCHED=1; }
    hd vue && hd pinia                      && pkg_add vue-pinia
    hd next                                 && pkg_add next-js
    hd nuxt                                 && pkg_add nuxt
    hd "@sveltejs/kit"                      && pkg_add sveltekit
    hd "@angular/core"                      && pkg_add angular
    hd astro                                && pkg_add astro
    hd "@remix-run/react"                   && pkg_add remix
    # React Router v7 framework mode — same architecture as Remix v2
    # (@react-router/dev must be in devDependencies, per the detection rule)
    if hd react-router && { hdd "@react-router/dev" || [ -f react-router.config.ts ]; }; then
        pkg_add remix
    fi
    { hd react-native || hd expo; }         && pkg_add react-native
    if hd react && ! in_deps next-js && ! in_deps remix && ! in_deps react-native; then
        pkg_add react
    fi
    hd express                              && pkg_add express
    hd "@nestjs/core"                       && pkg_add nest-js
    hd hono                                 && pkg_add hono
    hd elysia                               && pkg_add bun
    hd electron                             && pkg_add electron
    hd "@tauri-apps/api"                    && pkg_add tauri
    hd "@capacitor/core"                    && pkg_add capacitor
    if [ "$PKG_MATCHED" -eq 0 ] && hd typescript && { hd express || hd fastify || hd koa; }; then
        pkg_add node-ts
    fi
fi

# requirements.txt / pyproject.toml
PYFILE=""
[ -f requirements.txt ] && PYFILE=requirements.txt
[ -f pyproject.toml ] && { [ -n "$PYFILE" ] || PYFILE=pyproject.toml; }
if [ -f requirements.txt ] || [ -f pyproject.toml ]; then
    DEP_FILES_FOUND=1
    hp() {
        { cat requirements.txt 2>/dev/null; cat pyproject.toml 2>/dev/null; } \
            | grep -qiE "(^|[^a-zA-Z0-9_])$1([^a-zA-Z0-9_]|$)"
    }
    PY_WEB=0
    hp fastapi                              && { dep_add fastapi; PY_WEB=1; }
    { hp django || hp djangorestframework; } && { dep_add django; PY_WEB=1; }
    hp flask                                && { dep_add flask; PY_WEB=1; }
    hp pygame                               && dep_add pygame
    hp textual                              && dep_add python-textual
    { hp click || hp typer; }               && dep_add python-cli
    { hp torch || hp tensorflow || hp scikit-learn; } && dep_add python-ml
    if [ "$PY_WEB" -eq 0 ] && { hp pandas || hp polars || hp sqlalchemy; }; then
        dep_add python-data
    fi
fi

# Cargo.toml
if [ -f Cargo.toml ]; then
    DEP_FILES_FOUND=1
    hc() { grep -qE "(^|[^a-zA-Z0-9_-])$1([^a-zA-Z0-9_-]|$)" Cargo.toml; }
    hc axum && dep_add rust-axum
    if ! hc axum && { hc clap || hc indicatif || hc dialoguer; }; then
        dep_add rust-cli
    fi
    hc tauri && dep_add tauri
fi

# build.gradle / build.gradle.kts / pom.xml
if [ -f build.gradle ] || [ -f build.gradle.kts ] || [ -f pom.xml ]; then
    DEP_FILES_FOUND=1
    hg() {
        { cat build.gradle 2>/dev/null; cat build.gradle.kts 2>/dev/null; cat pom.xml 2>/dev/null; } \
            | grep -qE "$1"
    }
    { hg "spring-boot" || hg "org\.springframework\.boot"; } && dep_add spring-boot
    hg "ktor"                                                && dep_add kotlin-ktor
    hg "androidx\.compose"                                   && dep_add kotlin-android
fi

# *.csproj / *.sln
CSPROJ=$(find . -maxdepth 3 \( -name "*.csproj" -o -name "*.sln" \) -not -path "*/node_modules/*" 2>/dev/null | head -20)
if [ -n "$CSPROJ" ]; then
    DEP_FILES_FOUND=1
    hcs() { printf '%s\n' "$CSPROJ" | tr '\n' '\0' | xargs -0 cat 2>/dev/null | grep -q "$1"; }
    hcs "Microsoft.AspNetCore"     && dep_add asp-net-core
    hcs "PresentationFramework"    && dep_add wpf-csharp
    hcs "Microsoft.Maui"           && dep_add maui
    if hcs "Xamarin.Forms" && ! hcs "Microsoft.Maui"; then
        dep_add xamarin
        out "NOTE: Xamarin.Forms reached end-of-support May 2024 — flag with a migration-to-MAUI note (see references/detection-edge-cases.md)"
    fi
fi

# pubspec.yaml
if [ -f pubspec.yaml ]; then
    DEP_FILES_FOUND=1
    grep -qE "^[[:space:]]*flutter:" pubspec.yaml && dep_add flutter
fi

# CMakeLists.txt — presence suggests cpp-cmake
[ -f CMakeLists.txt ] && { DEP_FILES_FOUND=1; dep_add cpp-cmake; }

# Godot: *.gd files or project.godot
GD_FILES=$(find . -maxdepth 3 -name "*.gd" -not -path "*/node_modules/*" 2>/dev/null | head -1)
if [ -n "$GD_FILES" ]; then
    DEP_FILES_FOUND=1
    dep_add godot-gdscript
fi
if [ -f project.godot ]; then
    DEP_FILES_FOUND=1
    if [ -z "$GD_FILES" ] && [ -n "$(find . -maxdepth 3 -name "*.cs" -not -path "*/node_modules/*" 2>/dev/null | head -1)" ]; then
        dep_add godot-csharp
    fi
fi

# Unity: *.unity or Assets/ with *.cs
if [ ! -f project.godot ]; then
    if [ -n "$(find . -maxdepth 3 -name "*.unity" 2>/dev/null | head -1)" ] \
        || { [ -d Assets ] && [ -n "$(find Assets -maxdepth 3 -name "*.cs" 2>/dev/null | head -1)" ]; }; then
        DEP_FILES_FOUND=1
        dep_add unity
    fi
fi

# Unreal: *.uproject
if [ -n "$(find . -maxdepth 2 -name "*.uproject" 2>/dev/null | head -1)" ]; then
    DEP_FILES_FOUND=1
    dep_add unreal
fi

# Package.swift with iOS targets
if [ -f Package.swift ] && grep -q "iOS" Package.swift; then
    DEP_FILES_FOUND=1
    dep_add swift-ios
fi

# Claude Code plugin project
if [ -f .claude-plugin/plugin.json ]; then
    DEP_FILES_FOUND=1
    dep_add claude-plugin
elif [ -f plugin.json ] && grep -q '"\$schema".*claude-code-plugin' plugin.json; then
    DEP_FILES_FOUND=1
    dep_add claude-plugin
fi

# ── Source 2 — g-docs/ROADMAP.md ─────────────────────────────────────────────
ROADMAP=g-docs/ROADMAP.md
ROADMAP_SET=""
if [ -f "$ROADMAP" ]; then
    for s in $SUPPORTED; do
        name_in_file "$s" "$ROADMAP" && ROADMAP_SET="$ROADMAP_SET $s"
    done
fi

# ── emit STACK lines (first source wins: arg > brief > deps > roadmap) ───────
for s in $ARG_STACKS;   do emit_stack "$s" arg; done
for s in $BRIEF_SET;    do emit_stack "$s" brief; done
for s in $DEPS_SET;     do emit_stack "$s" deps; done
for s in $ROADMAP_SET;  do emit_stack "$s" roadmap; done

# ── conflicts ────────────────────────────────────────────────────────────────
if [ "$DEP_FILES_FOUND" -eq 1 ]; then
    for s in $BRIEF_SET; do
        in_deps "$s" || out "CONFLICT: $s named in brief but not confirmed by dependency files"
    done
fi
if [ ! -f "$BRIEF" ] && [ "$DEP_FILES_FOUND" -eq 0 ] && [ -z "$ARG_STACKS" ]; then
    out "CONFLICT: no brief and no dependency files found — ask the developer which profiles to apply"
fi

# ── combo detection (rules only, no agent) ───────────────────────────────────
COMBOS=""
combo() { # <combo-key> <stack-a> <stack-b>
    if emitted "$2" && emitted "$3"; then
        out "COMBO: $1"
        COMBOS="$COMBOS $1"
    fi
}
combo electron-react     electron react
combo electron-vue-pinia electron vue-pinia
combo react-tauri        react tauri
combo tauri-vue-pinia    tauri vue-pinia
combo astro-react        astro react
combo astro-vue          astro vue-pinia
combo astro-svelte       astro sveltekit

# ── supplementary profile auto-detection — frontend-data-flow ────────────────
SUPP=0
for s in react vue-pinia nuxt next-js sveltekit angular remix astro; do
    if emitted "$s"; then SUPP=1; break; fi
done
[ "$SUPP" -eq 1 ] && out "SUPPLEMENTARY: frontend-data-flow"

# ── file location: cwd first, then plugin cache (highest version) ────────────
CACHE_ROOT=""
for c in "$HOME"/.claude/plugins/cache/g-forge/g-forge/*/skills/g-init/SKILL.md; do
    [ -f "$c" ] && CACHE_ROOT="${c%/skills/g-init/SKILL.md}"
done

profile_root() { # <name> — echoes the profile dir or nothing
    if [ -d "profiles/$1" ]; then
        printf '%s\n' "profiles/$1"
    elif [ -n "$CACHE_ROOT" ] && [ -d "$CACHE_ROOT/profiles/$1" ]; then
        printf '%s\n' "$CACHE_ROOT/profiles/$1"
    fi
}

locate_profile() { # <name> <want-agent: yes|no>
    local root agent rules
    root=$(profile_root "$1")
    if [ -z "$root" ]; then out "MISSING: $1"; return 0; fi
    rules="$root/rules/architecture.md"
    if [ ! -f "$rules" ]; then out "MISSING: $1"; return 0; fi
    if [ "$2" = yes ]; then
        agent=""
        for a in "$root"/agents/*-architect.md; do
            [ -f "$a" ] && agent="$a"
        done
        if [ -z "$agent" ]; then out "MISSING: $1"; return 0; fi
        out "AGENT_FILE: $agent"
    fi
    out "RULES_FILE: $rules"
}

for s in $EMITTED;                       do locate_profile "$s" yes; done
for c in $COMBOS;                        do locate_profile "$c" no; done
[ "$SUPP" -eq 1 ]                        && locate_profile frontend-data-flow yes

exit 0
