# code-reviewer SOLID checks — teaching rationale

Maintainer-facing rationale. NOT read by dispatched agents — the
trigger + severity mappings stay in `agents/code-reviewer.md` (they drive
verdicts); the teaching essays live here.

- **SRP (Major):** a function or class mixing two distinct concerns (e.g.
  fetches data AND formats it AND handles UI state) couples unrelated change
  reasons. Suggest splitting at the responsibility boundary.
- **OCP (Major):** a switch/if-else chain dispatching on a type discriminant
  must be edited for each new variant — every extension is a modification.
  Suggest a strategy map or polymorphic dispatch.
- **LSP (Critical):** a subtype method that throws where the base always
  returns, narrows accepted input types, or skips part of the supertype's
  contract breaks callers **silently** — code written against the base type is
  correct and still fails at runtime. This is why LSP alone maps to Critical.
- **ISP (Minor):** a parameter that is a large object where the function uses
  ≤2 fields, or an interface with stub/`throw` implementations because the
  class doesn't need those methods. Suggest narrowing the type or splitting the
  interface.
- **DIP (Major):** `new ConcreteService()` inside business logic, or a direct
  import of a concrete infrastructure module (ORM model, HTTP client,
  third-party SDK) in a service or use-case layer, welds policy to mechanism.
  Suggest constructor/function injection with an interface type.
