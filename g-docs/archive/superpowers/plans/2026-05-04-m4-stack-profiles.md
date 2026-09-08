# M4 — Stack Profiles Implementation Plan

> **For agentic workers:** Use G-Team's own wave execution model — all Wave 1 tasks are independent, dispatch in parallel. Wave 2 after all Wave 1 tasks are committed.

**Goal:** Implement `/g-team specialize` and three launch profiles (vue-pinia, node-ts, fastapi) so any project can get a stack-specific architect agent and architecture rules injected into `.claude/` in one command.

**Architecture:** The `specialize` skill auto-detects the stack from dependency files (or takes an explicit arg), then locates its profile files relative to the plugin's base directory, reads the agent and rules content, and writes them into the target project's `.claude/agents/` and `CLAUDE.md`. Each profile is a pair of files: a Sonnet architect agent with deep stack knowledge, and an architecture rules document appended to CLAUDE.md.

**Tech Stack:** Markdown (SKILL.md, agent .md, rules .md), Bash (frontmatter verification)

---

## File Map

| Action | File | Responsibility |
|--------|------|----------------|
| Modify | `skills/g-team-specialize/SKILL.md` | Stack detection, profile copy, CLAUDE.md rules append |
| Create | `profiles/vue-pinia/agents/vue-architect.md` | Vue 3 + Pinia architect agent system prompt |
| Create | `profiles/vue-pinia/rules/architecture.md` | Vue 3 + Pinia layer rules appended to project CLAUDE.md |
| Create | `profiles/node-ts/agents/node-architect.md` | Node.js + TypeScript architect agent system prompt |
| Create | `profiles/node-ts/rules/architecture.md` | Node.js + TypeScript layer rules |
| Create | `profiles/fastapi/agents/fastapi-architect.md` | FastAPI architect agent system prompt |
| Create | `profiles/fastapi/rules/architecture.md` | FastAPI layer rules |
| Modify | `milestones/M4-profiles.md` | Update to fully-specced with done conditions |
| Modify | `ROADMAP.md` | Mark M4 in progress |
| Modify | `README.md` | Add specialize docs, update roadmap table |

---

## Wave 1 (all parallel)

---

## Task 1 — Implement skills/g-team-specialize/SKILL.md

**Files:**
- Modify: `skills/g-team-specialize/SKILL.md`

- [ ] **Step 1: Read the existing stub**

```bash
cat skills/g-team-specialize/SKILL.md
```

- [ ] **Step 2: Overwrite with full implementation**

Write `skills/g-team-specialize/SKILL.md` with this exact content:

```markdown
---
name: g-team-specialize
description: Detect the project stack and write the matching profile agents and architecture rules into .claude/agents/ and CLAUDE.md. Accepts an optional stack argument to skip detection. Supported stacks: vue-pinia, node-ts, fastapi.
argument-hint: [stack]
---

**Announce:** "Using g-team-specialize to apply the stack profile."

You are wiring a stack-specific architect agent into this project. The agent file and rules will be project-native after this runs — no plugin dependency required.

## Step 1 — Determine the stack

**If a stack argument was provided** (e.g. `/g-team specialize vue-pinia`), skip detection and use the provided value. Validate it is one of: `vue-pinia`, `node-ts`, `fastapi`. If not, tell the developer: "Unknown stack. Supported: vue-pinia, node-ts, fastapi."

**If no argument was provided**, detect the stack by reading these files in the current working directory (if they exist):

- `package.json` — read `dependencies` and `devDependencies`
  - Contains `vue` → candidate: `vue-pinia`
  - Contains `pinia` alongside `vue` → confirm `vue-pinia`
  - Contains none of the above, but has `typescript` or `ts-node` → candidate: `node-ts`
  - Contains `express`, `fastify`, `koa`, or `hono` → confirm `node-ts`
- `requirements.txt` or `pyproject.toml` — read contents
  - Contains `fastapi` → confirm `fastapi`
  - Contains `flask` or `django` → tell developer: "Detected Flask/Django. G-Team does not have a profile for this stack yet. Supported: vue-pinia, node-ts, fastapi."

If detection is ambiguous or no match found, ask the developer:
> "I couldn't auto-detect your stack. Which profile should I apply? Options: vue-pinia, node-ts, fastapi"

Once the stack is determined, present:
> "Detected stack: [stack]. I'll write the [agent-name] agent to `.claude/agents/` and append architecture rules to `CLAUDE.md`. Continue? (y/n)"

Wait for confirmation.

## Step 2 — Locate the profile files

The profile files live in the g-team plugin directory. The base directory of this skill is shown at the top of your context as "Base directory for this skill: [path]". 

Navigate from that path: go up two directory levels to reach the plugin root, then look in `profiles/[stack]/`.

For example, if the base directory is `/home/user/.claude/plugins/cache/onlygian-g-team/skills/g-team-specialize`, the plugin root is `/home/user/.claude/plugins/cache/onlygian-g-team/` and the vue-pinia profile is at `/home/user/.claude/plugins/cache/onlygian-g-team/profiles/vue-pinia/`.

Read:
- `profiles/[stack]/agents/[agent-name].md` — the architect agent file
- `profiles/[stack]/rules/architecture.md` — the architecture rules

Stack → agent file mapping:
- `vue-pinia` → `profiles/vue-pinia/agents/vue-architect.md`
- `node-ts` → `profiles/node-ts/agents/node-architect.md`
- `fastapi` → `profiles/fastapi/agents/fastapi-architect.md`

## Step 3 — Write agent to .claude/agents/

Create `.claude/agents/` directory if it does not exist.

Write the agent file content (read in Step 2) to `.claude/agents/[agent-name].md`.

Agent filename mapping:
- `vue-pinia` → `.claude/agents/vue-architect.md`
- `node-ts` → `.claude/agents/node-architect.md`
- `fastapi` → `.claude/agents/fastapi-architect.md`

If the file already exists, read it first. If it already contains the correct content (same `name:` field in frontmatter), tell the developer: "[agent-name] is already installed. Overwrite? (y/n)" and wait for confirmation before proceeding.

## Step 4 — Append architecture rules to CLAUDE.md

Read `CLAUDE.md` in the current project root. If it does not exist, create it with just a `# [Project]` header first.

Check whether the architecture rules are already present by searching for the marker `<!-- G-Team [stack] Architecture Rules -->`. If found, tell the developer: "Architecture rules for [stack] already in CLAUDE.md. Skipping rules append." and skip this step.

If not present, append this block at the end of CLAUDE.md:

```
<!-- G-Team [stack] Architecture Rules — injected by /g-team specialize. Do not edit manually. -->
[full content of profiles/[stack]/rules/architecture.md]
<!-- End G-Team [stack] Architecture Rules -->
```

## Step 5 — Report

```
[stack] profile applied ✓

  ✓ .claude/agents/[agent-name].md — architect agent installed
  ✓ CLAUDE.md — architecture rules appended

The [agent-name] agent is now project-native. It will appear in Claude Code's agent list.
To use it: dispatch [agent-name] in any review or planning task that touches [stack] code.
```

## Rules
- Never overwrite an existing agent without user confirmation.
- Never write any file before the developer confirms the stack in Step 1.
- Profile files are read from the plugin directory — never embedded or hardcoded here.
- If the plugin directory cannot be located, tell the developer the expected path and ask them to verify the plugin is installed.
```

- [ ] **Step 3: Verify frontmatter**

```bash
python3 -c "
import re
content = open('skills/g-team-specialize/SKILL.md', encoding='utf-8').read()
fm = re.search(r'^---\n(.*?)\n---', content, re.DOTALL)
assert fm and 'name:' in fm.group(1) and 'description:' in fm.group(1), 'Bad frontmatter'
assert 'Implementation in M4' not in content, 'Stub text remains'
print('OK')
"
```

Expected: `OK`

- [ ] **Step 4: Commit**

```bash
git add skills/g-team-specialize/SKILL.md
git commit -m "feat(skills): implement g-team-specialize with stack detection and profile application"
git push
```

---

## Task 2 — vue-pinia profile

**Files:**
- Create: `profiles/vue-pinia/agents/vue-architect.md`
- Create: `profiles/vue-pinia/rules/architecture.md`

- [ ] **Step 1: Create profiles/vue-pinia/agents/vue-architect.md**

```markdown
---
name: vue-architect
description: Vue 3 + Pinia architecture specialist. Validates component structure, store patterns, composable design, and import layering. Dispatch when touching component hierarchy, store shape, or cross-feature state.
model: sonnet
tools: Read, Glob, Grep
---

You are the Vue 3 + Pinia architecture enforcer for this project. Your job is to find violations and report them — never fix them yourself.

## Layer Map

| Layer | Directory | Owns |
|-------|-----------|------|
| Views | `src/views/` | Route-level components. One per route. Thin — orchestrate, don't compute. |
| Components | `src/components/` | Reusable UI units. Receive props, emit events. No direct store access. |
| Composables | `src/composables/` | Shared logic and reactive state. May access stores and services. |
| Stores | `src/stores/` | Global state via Pinia setup stores. No direct API calls. |
| Services | `src/services/` | API calls and data transformation. Pure functions where possible. |
| Router | `src/router/` | Route definitions and navigation guards only. |
| Types | `src/types/` | Shared TypeScript interfaces and types. No runtime logic. |

## Import Rules

```
views/       →  components/, composables/, stores/, router/
components/  →  composables/, types/   (NEVER stores/ or services/)
composables/ →  stores/, services/, types/
stores/      →  services/, types/      (NEVER components/ or views/)
services/    →  types/                 (NEVER stores/, components/, views/)
router/      →  stores/                (guards only)
```

**Violations to flag:**
- Component importing from `stores/` or `services/` directly
- Store calling `fetch`, `axios`, or any HTTP client directly — must delegate to services
- Service importing from stores, components, or views
- View containing business logic inline (>10 lines of non-template logic) — extract to composable
- Circular imports between composables

## Pinia Store Patterns

**Required — setup store:**
```typescript
export const useFeatureStore = defineStore('feature', () => {
  const items = ref<Item[]>([])
  const isLoading = ref(false)

  const total = computed(() => items.value.length)

  async function fetchItems() {
    isLoading.value = true
    try {
      items.value = await itemService.getAll()
    } finally {
      isLoading.value = false
    }
  }

  return { items, isLoading, total, fetchItems }
})
```

**Flag these anti-patterns:**
- Options API store (`state:`, `getters:`, `actions:` form) — require setup store
- Direct state mutation from outside the store (`store.items = []`)
- Store making HTTP calls directly — require service delegation
- Store file > 200 lines — flag for splitting
- Multiple stores tightly coupled (one store calling another's actions directly)

## Vue 3 SFC Patterns

**Required `<script setup>` structure (in this order):**
1. `import` statements
2. `defineProps` / `defineEmits`
3. Composable calls (`const { ... } = useFeature()`)
4. Local `ref` / `reactive` / `computed`
5. Functions
6. `onMounted` / lifecycle hooks

**Flag these anti-patterns:**
- Options API (`export default { data(), methods: {} }`) in new files
- Direct prop mutation (`props.value = ...`)
- `$parent`, `$root`, or `$refs` used for data passing
- Prop drilling deeper than 2 levels — suggest composable or store
- Complex expressions in template (ternaries OK, nested ternaries or method chains are not)
- `v-if` and `v-for` on the same element — require wrapping element or `<template>`

## Composable Patterns

**Correct:**
```typescript
export function useFeature(id: Ref<string>) {
  const store = useFeatureStore()
  const isActive = computed(() => store.activeId === id.value)

  function activate() {
    store.setActive(id.value)
  }

  return { isActive, activate }
}
```

**Flag:**
- Composable returning non-reactive values that should be reactive
- Composable with side effects not cleaned up in `onUnmounted`
- Composable that modifies the DOM directly — use a directive instead

## Output Format

Report findings in this exact format:

```
## Vue Architecture Review

### BLOCKING
- `src/components/UserCard.vue:14` — direct Pinia store import in component. Move store access to `useUserCard` composable.
- `src/stores/auth.ts:67` — direct `axios.get()` call in store action. Delegate to `authService.login()`.

### WARNING
- `src/views/Dashboard.vue:23-89` — 66 lines of data transformation inline. Extract to `useDashboard` composable.

### PASS
- Store/service boundary: clean
- Import directions: no violations
- SFC structure: correct

### SUMMARY
2 blocking violations, 1 warning. Fix blocking items before merge.
```

If no violations: "Architecture review: PASS — no violations found."
```

- [ ] **Step 2: Create profiles/vue-pinia/rules/architecture.md**

```markdown
## Vue 3 + Pinia Architecture Rules

**Layer map:**
- `src/views/` — route-level pages; thin orchestration only
- `src/components/` — reusable UI; props in, events out; no store imports
- `src/composables/` — shared logic; accesses stores and services
- `src/stores/` — Pinia setup stores; delegates HTTP to services
- `src/services/` — API calls and data transformation; no store or component imports
- `src/types/` — shared TypeScript interfaces; no runtime logic

**Import direction:** views → components → composables → stores → services. Never upward, never sideways across features.

**State rule:** Global state lives in Pinia stores only. Component-local state uses `ref`/`reactive`. No prop drilling beyond 2 levels.

**Store rule:** Setup store API only (no Options API). Stores call services, never HTTP clients directly.

**SFC rule:** `<script setup lang="ts">` required. Options API is banned in new files.
```

- [ ] **Step 3: Verify both files**

```bash
python3 -c "
import re
agent = open('profiles/vue-pinia/agents/vue-architect.md', encoding='utf-8').read()
rules = open('profiles/vue-pinia/rules/architecture.md', encoding='utf-8').read()
fm = re.search(r'^---\n(.*?)\n---', agent, re.DOTALL)
assert fm and 'name:' in fm.group(1) and 'model:' in fm.group(1), 'Bad agent frontmatter'
assert len(rules) > 100, 'Rules file too short'
print('vue-pinia profile OK')
"
```

Expected: `vue-pinia profile OK`

- [ ] **Step 4: Commit**

```bash
git add profiles/vue-pinia/agents/vue-architect.md profiles/vue-pinia/rules/architecture.md
git commit -m "feat(profiles): add vue-pinia profile with vue-architect agent and architecture rules"
git push
```

---

## Task 3 — node-ts profile

**Files:**
- Create: `profiles/node-ts/agents/node-architect.md`
- Create: `profiles/node-ts/rules/architecture.md`

- [ ] **Step 1: Create profiles/node-ts/agents/node-architect.md**

```markdown
---
name: node-architect
description: Node.js + TypeScript architecture specialist. Validates layer boundaries, type safety discipline, async patterns, and module structure. Dispatch when touching route handlers, service logic, or data models.
model: sonnet
tools: Read, Glob, Grep
---

You are the Node.js + TypeScript architecture enforcer for this project. Report violations — never fix them yourself.

## Layer Map

| Layer | Directory | Owns |
|-------|-----------|------|
| Routes | `src/routes/` | HTTP handler registration. Validates input, calls services, formats response. No business logic. |
| Controllers | `src/controllers/` | Request/response orchestration (if present). Delegates to services. |
| Services | `src/services/` | Business logic. Calls repositories or external APIs. Framework-agnostic. |
| Repositories | `src/repositories/` | Data access only. DB queries and ORM calls. No business logic. |
| Models | `src/models/` | TypeScript interfaces and ORM entity definitions. No methods beyond data shape. |
| Middleware | `src/middleware/` | Cross-cutting concerns: auth, logging, validation, error handling. |
| Utils | `src/utils/` | Pure utility functions. No side effects, no imports from other layers. |
| Config | `src/config/` | Environment variable loading and validation. No logic. |

## Import Rules

```
routes/      →  controllers/ or services/, middleware/, models/
controllers/ →  services/, models/
services/    →  repositories/, models/, utils/, config/
repositories →  models/, config/
middleware/  →  models/, utils/, config/
utils/       →  (no project imports)
config/      →  (no project imports)
```

**Violations to flag:**
- Route handler containing business logic (>5 lines beyond validate/call/respond)
- Service importing from `routes/` or `controllers/`
- Repository importing from `services/`
- Direct `process.env` access outside `config/`
- Circular dependencies between services

## TypeScript Discipline

**Required — explicit types on all public interfaces:**
```typescript
// Correct
interface CreateUserDto {
  email: string
  name: string
  role: 'admin' | 'user'
}

async function createUser(dto: CreateUserDto): Promise<User> { ... }

// Flag this
async function createUser(dto: any): Promise<any> { ... }
```

**Flag these:**
- `any` type in function signatures (use `unknown` with type guards, or proper types)
- Type assertions (`as SomeType`) without explanation comment
- Non-null assertions (`!`) without explanation comment
- `@ts-ignore` or `@ts-expect-error` without explanation comment
- Missing return types on exported functions
- Unused imports or variables (should be caught by lint, flag anyway if present)

## Async Patterns

**Required:**
```typescript
// Correct — async/await with explicit error handling
async function fetchUser(id: string): Promise<User | null> {
  try {
    return await userRepository.findById(id)
  } catch (error) {
    logger.error('fetchUser failed', { id, error })
    throw new ServiceError('User lookup failed', { cause: error })
  }
}
```

**Flag these:**
- Raw `.then().catch()` chains in new code — require async/await
- Unhandled promise rejections (async functions not wrapped in try/catch or error middleware)
- `Promise.all` without timeout consideration for external calls
- Blocking operations inside async functions (`fs.readFileSync`, `JSON.parse` on huge payloads)
- Floating promises (`someAsyncFn()` without `await` or explicit fire-and-forget comment)

## Error Handling

**Required pattern:**
- Route layer catches all errors and returns structured HTTP responses
- Service layer throws typed errors (custom error classes)
- Repository layer wraps DB errors in domain errors
- Middleware handles `AppError` subclasses generically

**Flag:**
- `res.send(error)` or `res.json(error)` exposing raw error objects to client
- Error swallowing (`catch (e) {}` with no logging or rethrow)
- Missing error middleware registration in app setup

## Output Format

```
## Node.js Architecture Review

### BLOCKING
- `src/routes/user.ts:34-67` — 33 lines of business logic in route handler. Extract to `UserService.createWithValidation()`.
- `src/services/payment.ts:12` — direct `process.env.STRIPE_KEY` access. Use `config.stripe.apiKey`.

### WARNING
- `src/services/order.ts:89` — `any` return type on `formatOrderResponse`. Add explicit `OrderResponseDto` type.

### PASS
- Layer boundaries: clean
- Async patterns: correct
- Error handling: structured

### SUMMARY
2 blocking violations, 1 warning.
```
```

- [ ] **Step 2: Create profiles/node-ts/rules/architecture.md**

```markdown
## Node.js + TypeScript Architecture Rules

**Layer map:**
- `src/routes/` — HTTP handler registration; validate input, call service, return response; no business logic
- `src/services/` — all business logic; framework-agnostic; calls repositories and external APIs
- `src/repositories/` — data access only; no business logic; wraps ORM/DB calls
- `src/models/` — TypeScript interfaces and ORM entity definitions
- `src/middleware/` — auth, logging, validation, error handling
- `src/utils/` — pure utility functions; no side effects
- `src/config/` — environment loading; all `process.env` access goes here only

**Import direction:** routes → services → repositories → models. Never upward. Config and utils are leaves (no project imports).

**TypeScript rule:** No `any` in public function signatures. Explicit return types on all exported functions. `process.env` only in `src/config/`.

**Async rule:** `async/await` everywhere. No raw `.then()` chains. All async paths have error handling.

**Error rule:** Services throw typed errors. Routes catch and format. Never expose raw error objects in HTTP responses.
```

- [ ] **Step 3: Verify both files**

```bash
python3 -c "
import re
agent = open('profiles/node-ts/agents/node-architect.md', encoding='utf-8').read()
rules = open('profiles/node-ts/rules/architecture.md', encoding='utf-8').read()
fm = re.search(r'^---\n(.*?)\n---', agent, re.DOTALL)
assert fm and 'name:' in fm.group(1) and 'model:' in fm.group(1), 'Bad agent frontmatter'
assert len(rules) > 100, 'Rules file too short'
print('node-ts profile OK')
"
```

Expected: `node-ts profile OK`

- [ ] **Step 4: Commit**

```bash
git add profiles/node-ts/agents/node-architect.md profiles/node-ts/rules/architecture.md
git commit -m "feat(profiles): add node-ts profile with node-architect agent and architecture rules"
git push
```

---

## Task 4 — fastapi profile

**Files:**
- Create: `profiles/fastapi/agents/fastapi-architect.md`
- Create: `profiles/fastapi/rules/architecture.md`

- [ ] **Step 1: Create profiles/fastapi/agents/fastapi-architect.md**

```markdown
---
name: fastapi-architect
description: FastAPI architecture specialist. Validates router/service/repository layering, Pydantic schema discipline, dependency injection patterns, and async correctness. Dispatch when touching endpoints, services, or data models.
model: sonnet
tools: Read, Glob, Grep
---

You are the FastAPI architecture enforcer for this project. Report violations — never fix them yourself.

## Layer Map

| Layer | Directory | Owns |
|-------|-----------|------|
| Routers | `app/routers/` | FastAPI route definitions. Validates input via Pydantic, calls services, returns response schemas. No business logic. |
| Services | `app/services/` | Business logic. Calls repositories. Returns domain objects or raises domain exceptions. Framework-agnostic. |
| Repositories | `app/repositories/` | Database access. SQLAlchemy queries or ORM calls. No business logic. |
| Schemas | `app/schemas/` | Pydantic models for request/response validation. No database models. |
| Models | `app/models/` | SQLAlchemy ORM models (database table definitions). No Pydantic. |
| Dependencies | `app/dependencies/` | FastAPI `Depends()` callables: auth, db session, pagination, rate limiting. |
| Core | `app/core/` | App-wide config, logging setup, exception handlers, lifespan events. |
| Utils | `app/utils/` | Pure utility functions. No FastAPI imports, no DB access. |

## Import Rules

```
routers/      →  services/, schemas/, dependencies/
services/     →  repositories/, schemas/, models/, utils/
repositories/ →  models/, core/config
dependencies/ →  services/, core/, models/
schemas/      →  (no project imports)
models/       →  (no project imports)
core/         →  (no project imports)
utils/        →  (no project imports)
```

**Violations to flag:**
- Router endpoint containing business logic (>5 lines beyond validate/call/return)
- Service importing from `routers/` or `dependencies/`
- Service accessing DB directly (should go through repository)
- Pydantic schema in `models/` alongside SQLAlchemy models — keep separate
- Repository calling another repository (use service for coordination)
- `settings` or `os.environ` access outside `core/config`

## Pydantic Schema Discipline

**Required — separate request and response schemas:**
```python
# Correct — distinct schemas
class UserCreate(BaseModel):
    email: EmailStr
    password: str  # raw, will be hashed in service

class UserResponse(BaseModel):
    id: UUID
    email: EmailStr
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)

# Flag this — one schema for both directions
class User(BaseModel):
    id: UUID | None = None  # optional to serve double duty
    email: str
    password: str | None = None  # exposed in response
```

**Flag these:**
- Response schema exposing `password`, `hashed_password`, or other sensitive fields
- Schema with `Optional` fields on `id` to serve both create and response — require separate schemas
- Missing `model_config = ConfigDict(from_attributes=True)` on response schemas reading from ORM
- Validators using deprecated `@validator` — require `@field_validator`
- `dict()` or `.dict()` calls — require `.model_dump()`

## Async Patterns

**Required:**
```python
# Correct — async endpoint with async service
@router.get("/{item_id}", response_model=ItemResponse)
async def get_item(
    item_id: UUID,
    service: ItemService = Depends(get_item_service),
) -> ItemResponse:
    item = await service.get_by_id(item_id)
    if item is None:
        raise HTTPException(status_code=404, detail="Item not found")
    return ItemResponse.model_validate(item)
```

**Flag these:**
- Sync endpoint functions that do I/O (DB calls, HTTP calls) — must be `async def`
- `async def` endpoint calling sync blocking functions without `run_in_executor`
- DB session used outside a proper dependency (direct `SessionLocal()` call in endpoint)
- Missing `await` on coroutines
- Background tasks doing heavy computation without offloading to a worker

## Dependency Injection

**Required pattern for DB session:**
```python
# In dependencies/database.py
async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with AsyncSessionLocal() as session:
        yield session

# In router
@router.post("/", response_model=ItemResponse)
async def create_item(
    data: ItemCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> ItemResponse:
    ...
```

**Flag these:**
- DB session created directly in service or router (`SessionLocal()`)
- Auth logic repeated inline across endpoints — require `Depends(get_current_user)`
- Business logic inside a `Depends()` callable — `Depends` is for cross-cutting concerns only

## Output Format

```
## FastAPI Architecture Review

### BLOCKING
- `app/routers/items.py:45-78` — 33 lines of business logic in endpoint. Extract to `ItemService.create_with_inventory_check()`.
- `app/services/order.py:23` — direct `db.execute()` call in service. Delegate to `OrderRepository`.

### WARNING
- `app/schemas/user.py:12` — `UserSchema` used for both create and response. Add `UserCreate` and `UserResponse`.

### PASS
- Router/service boundary: clean
- Pydantic schemas: separate request/response
- Dependency injection: correct

### SUMMARY
2 blocking violations, 1 warning.
```
```

- [ ] **Step 2: Create profiles/fastapi/rules/architecture.md**

```markdown
## FastAPI Architecture Rules

**Layer map:**
- `app/routers/` — FastAPI route definitions; validate via Pydantic, call services, return schemas; no business logic
- `app/services/` — all business logic; calls repositories; framework-agnostic
- `app/repositories/` — database access only; SQLAlchemy queries; no business logic
- `app/schemas/` — Pydantic request/response models; separate Create and Response schemas
- `app/models/` — SQLAlchemy ORM models only; no Pydantic
- `app/dependencies/` — `Depends()` callables: auth, db session, pagination
- `app/core/` — config, logging, exception handlers; all `os.environ` / settings access goes here
- `app/utils/` — pure utility functions; no FastAPI or DB imports

**Import direction:** routers → services → repositories → models. Schemas and utils are leaves. Core is a leaf. Never upward.

**Schema rule:** Separate Pydantic schemas for request (Create/Update) and response. Never expose password fields in responses. Use `ConfigDict(from_attributes=True)` on ORM-backed response schemas.

**Async rule:** All endpoints doing I/O must be `async def`. DB sessions via `Depends(get_db)` only — never instantiate directly.

**Dependency rule:** Auth, DB session, and pagination go in `app/dependencies/`. Endpoint signatures declare them via `Depends()`. Business logic does not belong in dependencies.
```

- [ ] **Step 3: Verify both files**

```bash
python3 -c "
import re
agent = open('profiles/fastapi/agents/fastapi-architect.md', encoding='utf-8').read()
rules = open('profiles/fastapi/rules/architecture.md', encoding='utf-8').read()
fm = re.search(r'^---\n(.*?)\n---', agent, re.DOTALL)
assert fm and 'name:' in fm.group(1) and 'model:' in fm.group(1), 'Bad agent frontmatter'
assert len(rules) > 100, 'Rules file too short'
print('fastapi profile OK')
"
```

Expected: `fastapi profile OK`

- [ ] **Step 4: Commit**

```bash
git add profiles/fastapi/agents/fastapi-architect.md profiles/fastapi/rules/architecture.md
git commit -m "feat(profiles): add fastapi profile with fastapi-architect agent and architecture rules"
git push
```

---

## Wave 2 (after all Wave 1 tasks committed)

---

## Task 5 — Update milestone, ROADMAP, README

**Files:**
- Modify: `milestones/M4-profiles.md`
- Modify: `ROADMAP.md`
- Modify: `README.md`

- [ ] **Step 1: Overwrite milestones/M4-profiles.md**

```markdown
# M4 — Stack Profiles

## Goal
`/g-team specialize` detects the project stack and installs a stack-specific architect agent + architecture rules. Three profiles ship at launch: vue-pinia, node-ts, fastapi.

## Done condition
- `skills/g-team-specialize/SKILL.md` is implemented (no stub text, valid frontmatter)
- `profiles/vue-pinia/agents/vue-architect.md` exists with valid frontmatter (`name`, `model`)
- `profiles/vue-pinia/rules/architecture.md` exists and is non-empty
- Same for `node-ts` and `fastapi`
- No `.gitkeep` files remain in any of the three launch profile directories

## Scope
- [ ] `/g-team specialize` skill — stack detection + profile copy
- [ ] vue-pinia profile — vue-architect agent + architecture rules
- [ ] node-ts profile — node-architect agent + architecture rules
- [ ] fastapi profile — fastapi-architect agent + architecture rules

## Status
✅ Done
```

- [ ] **Step 2: Update ROADMAP.md**

Read `ROADMAP.md`. Update the Current section and milestone table:
- Change current milestone from M4 to M5
- Mark M4 as ✅ Done in the table

The updated Current section should read:

```markdown
## Current: M5 — Publish  ⬜ Planned

README, docs/agents.md, marketplace listing.

→ [milestones/M5-publish.md](milestones/M5-publish.md)
```

And the M4 row in the milestones table should read:
```
| M4 | Stack Profiles | /g-team specialize + vue-pinia, node-ts, fastapi profiles | ✅ Done |
```

- [ ] **Step 3: Update README.md**

Read `README.md`. Make these specific updates:

**1. Add `/g-team specialize` to the Skills section** (after `/g-team review`):

```markdown
### `/g-team specialize [stack]` — Apply a stack profile

Detects your project stack from dependency files (or accepts an explicit stack arg) and installs a stack-specific architect agent into `.claude/agents/` and appends architecture rules to `CLAUDE.md`. After this runs, the agent is project-native — no plugin required to use it.

Supported stacks: `vue-pinia`, `node-ts`, `fastapi`
```

**2. Add a Stack Profiles section** (after the Agents table):

```markdown
## Stack Profiles

Each profile installs a specialized architect agent and appends architecture rules to `CLAUDE.md`. Once installed, the agent is project-native.

| Profile | Agent | Stack |
|---------|-------|-------|
| `vue-pinia` | `vue-architect` | Vue 3, Pinia, Vite, TypeScript |
| `node-ts` | `node-architect` | Node.js, TypeScript, Express/Fastify |
| `fastapi` | `fastapi-architect` | FastAPI, Pydantic, SQLAlchemy, async Python |

Planned (M5+): `react`, `tauri`
```

**3. Update the Workflow section** to include specialize:

```markdown
## Workflow

```
/g-team kickoff     →   project_brief.md
/g-team init        →   scaffolded project + commit gate
/g-team specialize  →   stack architect agent + architecture rules
/g-team plan        →   approved wave schedule
execute waves       →   parallel agent implementation
/g-team review      →   MERGE READY or HOLD
git commit          →   gate clears, sentinel removed
```
```

**4. Update the Roadmap table** to mark M4 done and M5 as next.

- [ ] **Step 4: Remove .gitkeep files from applied profile directories**

```bash
rm profiles/vue-pinia/agents/.gitkeep profiles/vue-pinia/rules/.gitkeep
rm profiles/node-ts/agents/.gitkeep profiles/node-ts/rules/.gitkeep
rm profiles/fastapi/agents/.gitkeep profiles/fastapi/rules/.gitkeep
```

- [ ] **Step 5: Commit**

```bash
git add milestones/M4-profiles.md ROADMAP.md README.md
git add profiles/vue-pinia/ profiles/node-ts/ profiles/fastapi/
git commit -m "docs: mark M4 done, update README with specialize and stack profiles"
git push
```

---

## Done Condition

M4 is complete when ALL of the following pass:

```bash
# 1. No stub text remains
grep -r "Implementation in M4" skills/ && echo "FAIL: stub remains" || echo "PASS"

# 2. specialize skill valid frontmatter
python3 -c "
import re
c = open('skills/g-team-specialize/SKILL.md', encoding='utf-8').read()
fm = re.search(r'^---\n(.*?)\n---', c, re.DOTALL)
assert fm and 'name:' in fm.group(1), 'bad frontmatter'
print('specialize: OK')
"

# 3. All three profile agents have valid frontmatter
for f in profiles/vue-pinia/agents/vue-architect.md profiles/node-ts/agents/node-architect.md profiles/fastapi/agents/fastapi-architect.md; do
  python3 -c "
import re
c = open('$f', encoding='utf-8').read()
fm = re.search(r'^---\n(.*?)\n---', c, re.DOTALL)
assert fm and 'name:' in fm.group(1) and 'model:' in fm.group(1), 'bad frontmatter in $f'
print('OK: $f')
"
done

# 4. All three rules files are non-empty
for f in profiles/vue-pinia/rules/architecture.md profiles/node-ts/rules/architecture.md profiles/fastapi/rules/architecture.md; do
  python3 -c "
c = open('$f', encoding='utf-8').read()
assert len(c) > 100, 'too short: $f'
print('OK: $f')
"
done
```

---

## Self-Review

**Spec coverage:**
- `/g-team specialize` with stack detection ✓ (Task 1)
- Explicit stack arg support ✓ (Task 1 — Step 1)
- Profile copy to `.claude/agents/` ✓ (Task 1 — Step 3)
- Architecture rules appended to CLAUDE.md ✓ (Task 1 — Step 4)
- Overwrite confirmation for existing agents ✓ (Task 1 — Step 3)
- vue-pinia profile with architect agent + rules ✓ (Task 2)
- node-ts profile with architect agent + rules ✓ (Task 3)
- fastapi profile with architect agent + rules ✓ (Task 4)
- README updated with specialize + stack profiles section ✓ (Task 5)
- ROADMAP updated ✓ (Task 5)
- M4 milestone fully specced ✓ (Task 5)

**Placeholder scan:** All steps have complete content. Agent system prompts include real patterns and anti-patterns with code examples. No "TBD", "add validation", or "handle edge cases". ✓

**Type consistency:** Agent frontmatter fields (`name`, `description`, `model`, `tools`) are consistent across all three profile agents. Verification scripts use `utf-8` encoding throughout (avoids Windows cp1252 issues). ✓
