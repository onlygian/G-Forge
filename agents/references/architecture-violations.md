# architecture-enforcer — violation-type teaching notes (maintainer reference)

Maintainer-facing; not read at dispatch. Full elaborations behind the one-line
violation types in `agents/architecture-enforcer.md`. This agent deliberately has NO
severity ladder — PASS|HOLD with a violation count only; the orchestrator maps its
HOLD → FAIL. Do not "improve" it onto Critical/Major/Minor.

**Import direction** — imports must flow in one direction through the layer hierarchy.
If the project defines layers (e.g. pages → organisms → molecules → atoms, or
controllers → services → repositories), a lower layer importing from a higher layer is
a violation.

**Circular dependencies** — module A imports B which imports A, directly or
transitively. Flag any cycle regardless of layer.

**God object** — a single class or module that owns data, business logic, UI
coordination, and I/O: more than two distinct responsibilities is the violation line.

**SRP** — a single file handling two distinct responsibilities, e.g. a UI component
that also fetches data directly.

**State ownership** — state mutated from a layer that doesn't own it, e.g. a component
directly mutating a store's internal state without going through an action. The owning
layer's invariants become unenforceable once outside writers exist.

**Side-effect boundary** — I/O operations (HTTP, file system, external APIs) outside
the designated side-effect layer, e.g. `fetch()` called directly in a component instead
of a service/composable.

**OCP** — a central dispatcher or factory using a type-switch/if-else chain that must
be modified every time a new variant is added. The pervasiveness qualifier matters: a
single small switch is idiomatic; the pattern is a violation when it is pervasive —
strategy maps, registries, or polymorphic dispatch are the remedy.

**DIP** — a high-level module (domain, use-case, business service) importing a concrete
low-level module (specific ORM model, HTTP adapter, third-party SDK) directly rather
than depending on an interface that a low-level adapter implements. The dependency
arrow must point toward the abstraction, not toward the concrete implementation —
otherwise every infrastructure swap ripples through the domain layer.
