# Combo and supplementary profiles — what each one covers and why

Load trigger: read this when `scripts/detect-stack.sh` prints `COMBO:` or `SUPPLEMENTARY:` lines and you need to explain the install to the developer, or when editing combo detection.

## Combo profiles — emergent cross-stack patterns

A combo profile exists because two stacks composed together produce architectural patterns that neither stack's own rules cover — the emergent seams (IPC bridges, island hydration boundaries, typed invoke layers). Combo profiles install rules only — no architect agent (each member stack's architect already reviews its side; the combo card covers the seam).

| Combo key            | Required stacks             | Emergent patterns covered                                                         |
|----------------------|-----------------------------|-----------------------------------------------------------------------------------|
| `electron-react`     | electron + react            | contextBridge API layer, IPC channel constants, cross-window state                |
| `electron-vue-pinia` | electron + vue-pinia        | contextBridge + Pinia IPC integration, cross-window state                         |
| `react-tauri`        | react + tauri               | `invoke()` typed API layer, Tauri event hooks in React, capability scoping        |
| `tauri-vue-pinia`    | tauri + vue-pinia           | `invoke()` typed API layer, Pinia + Tauri event subscriptions, capability scoping |
| `astro-react`        | astro + react               | Island isolation, serializable prop contract, cross-island state via nanostores, React hydration directives |
| `astro-vue`          | astro + vue-pinia           | Island isolation, serializable prop contract, cross-island state via nanostores, Vue hydration directives  |
| `astro-svelte`       | astro + sveltekit           | Island isolation, serializable prop contract, native Svelte store sharing across islands, hydration directives |

If any detected stacks fully cover a combo's required stacks, that combo applies (the script checks this — alphabetical sort of detected names, subset match).

## Supplementary profile — frontend-data-flow

If the apply list contains any component-framework stack — `react`, `vue-pinia`, `nuxt`, `next-js`, `sveltekit`, `angular`, `remix`, `astro`, or any astro-* combo — `frontend-data-flow` is auto-added. This is a **supplementary** profile: it ships its own architect agent (`frontend-data-flow-architect`) and rules file (`profiles/frontend-data-flow/rules/architecture.md`), and it covers the universal two-network frontend data-flow model (read network + write network) plus the four canonical violations (HTTP in components, shadow-state ref sync, watch-as-dispatch, caller-follows-truck). It complements the per-framework architect — never replaces it. Surface it in confirmation as `+ frontend-data-flow (supplementary, auto-installed alongside component frameworks)`.
