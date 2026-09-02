# Code quality — expanded SOLID guidance (G-RULES §D companion)

Load trigger: read this when judging a borderline SOLID call — the compact rules in `.claude/rules/g-rules-D-code-quality.md` name each principle and its primary symptom; this file holds the fuller walkthroughs moved out of them (v2.6 token diet).

- **SRP** — a unit that handles data access *and* business logic needs splitting. The test is "one reason to change": if two different stakeholders or concerns could each force an edit, the unit has two responsibilities.
- **OCP** — extend behaviour by adding new code, not by modifying existing code. The canonical violation is a switch/if-else chain that must be edited every time a new type is added.
- **LSP** — an override that throws where the base returns a value, accepts a narrower input type, or silently ignores part of the supertype's behaviour is a violation. Prefer composition over inheritance to sidestep LSP traps entirely.
- **ISP** — a function that receives a large object and reads two fields out of ten should accept a narrower type or destructured params. A class that implements an interface but leaves half the methods as `throw new Error('not implemented')` needs the interface split.
- **DIP** — high-level modules depend on abstractions, not concrete implementations. Business logic must not `new` its own services — receive them via constructor/function injection. An import of a concrete adapter (database driver, HTTP client, third-party SDK) inside a domain or business-logic module is a DIP violation.
