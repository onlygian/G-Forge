# Detection edge cases — Step 3 playbook

Load trigger: read this when Step 3 fires — an explicit stack argument, `UNSUPPORTED:` or `CONFLICT:` lines from `scripts/detect-stack.sh`, no brief and no dependency files, an ambiguous picture, a risk-flagged stack, or xamarin detected.

The supported closed set (48 stacks): angular, asp-net-core, astro, bun, c-embedded, capacitor, cpp-cmake, django, electron, express, fastapi, flask, flutter, go-fiber, go-gin, godot-csharp, godot-gdscript, hono, kotlin-android, kotlin-ktor, laravel, maui, nest-js, next-js, node-ts, nuxt, phoenix-liveview, pygame, python-cli, python-data, python-ml, python-textual, rails, react, react-native, remix, rust-axum, rust-cli, spring-boot, sveltekit, swift-ios, tauri, unity, unreal, vue-pinia, wpf-csharp, xamarin, claude-plugin. Supplementary: frontend-data-flow (auto-installed alongside component frameworks).

## Explicit stack argument (e.g. `/g-specialize vue-pinia`)

- Validate it is one of the supported stacks (pass it to `scripts/detect-stack.sh` as a candidate arg — an `UNSUPPORTED:` line means it failed). If unsupported, say: "Unknown stack '[arg]'. Run `/g-specialize` with no argument to auto-detect, or pick from the supported list." and stop.
- If valid, use it as the confirmed profile list, skipping further detection — go straight to Step 2 (research) then Step 4 (confirm).

## No brief and no dependency files

Ask the developer: "I couldn't find a g-docs/project_brief.md or any dependency files. Which profile(s) should I apply? Supported stacks: angular, asp-net-core, astro, bun, c-embedded, capacitor, cpp-cmake, django, electron, express, fastapi, flask, flutter, go-fiber, go-gin, godot-csharp, godot-gdscript, hono, kotlin-android, kotlin-ktor, laravel, maui, nest-js, next-js, node-ts, nuxt, phoenix-liveview, pygame, python-cli, python-data, python-ml, python-textual, rails, react, react-native, remix, rust-axum, rust-cli, spring-boot, sveltekit, swift-ios, tauri, unity, unreal, vue-pinia, wpf-csharp, xamarin."

Wait for answer. Use it as the confirmed profile list.

## Unsupported stacks detected

Note them in the confirmation: "I detected [stack] which doesn't have a G-Forge profile yet. I'll skip that one."

## Ambiguous picture or conflicts — the code-lead consult

Ambiguous means: stacks detected from different sources that don't agree, or a brief that mentions a stack with no corresponding deps and no clear explanation (the script's `CONFLICT:` lines name these).

Before asking the user, dispatch `code-lead` with:
- The synthesised picture from Step 1
- The relevant excerpt from g-docs/project_brief.md (tech decisions table if present)
- The dependency file contents

Ask code-lead:
> "Based on this project's brief and dependencies, which G-Forge stack profiles should be applied? The supported profiles are: angular, asp-net-core, astro, bun, c-embedded, capacitor, cpp-cmake, django, electron, express, fastapi, flask, flutter, go-fiber, go-gin, godot-csharp, godot-gdscript, hono, kotlin-android, kotlin-ktor, laravel, maui, nest-js, next-js, node-ts, nuxt, phoenix-liveview, pygame, python-cli, python-data, python-ml, python-textual, rails, react, react-native, remix, rust-axum, rust-cli, spring-boot, sveltekit, swift-ios, tauri, unity, unreal, vue-pinia, wpf-csharp, xamarin. If the project is multi-stack, list all that apply. Flag anything that looks like a mismatch or a risky stack choice. Note that frontend-data-flow is a supplementary profile that I auto-install alongside any component framework — do not list it as a primary stack."

Present code-lead's response to the developer: "Here is code-lead's stack read — does this match what you're building?"

## Brief stack with a code-lead risk flag (Medium or High)

Surface it to the developer before proceeding: "code-lead flagged [stack choice] as [risk level]: [reason]. Do you want to proceed with this profile, or reconsider the stack first?"

Wait for answer. Proceed only after confirmation.

## Xamarin — end-of-support

`Xamarin.Forms` (without `Microsoft.Maui`) maps to **xamarin**, but the stack is legacy: Xamarin.Forms reached end-of-support May 2024. Flag this to the developer with a migration-to-MAUI note. The profile applies to existing maintained projects only; for new mobile development, recommend the `maui` profile instead.

## React Router v7 — remix profile

`react-router` AND (`@react-router/dev` in devDependencies OR `react-router.config.ts` exists) maps to **remix**: React Router v7 framework mode has the same architecture as Remix v2 (loaders/actions, route modules, framework-mode conventions), so the remix profile's layer map and rules apply unchanged. Library-mode `react-router` (no @react-router/dev, no config file) stays under the plain **react** profile.
