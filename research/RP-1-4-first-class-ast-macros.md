# RP-1.4: First-class AST macros

| Field | Value |
|-------|--------|
| **Paper ID** | `RP-1.4` |
| **DESIGN.md** | §1 Language |
| **Status** | `draft` |
| **PM.md row** | `1.4` |
| **Product mapping** | **not-started** — no compile-time AST macro system; ordinary functions and backends only |

## 1. Why this is in DESIGN.md

DESIGN.md §1:

> **First-Class AST Macros:** The compiler lets you write standard openOODA functions that execute at compile-time. These functions rewrite the Abstract Syntax Tree (AST). They give you the power of Rust macros but keep native readability.

openOODA needs metaprogramming without a second language. It does not use a `macro_rules!` pattern DSL. It does not use a separate API for procedural macros. Instead, ordinary openOODA functions run at compile time to return or change the AST. Procedural macros are powerful but difficult to use and bad for tools. Classic Lisp macros are powerful but their hygiene changes often. The openOODA design solves this industry problem.

This paper explains why openOODA needs compile-time AST rewriting. It looks at Rust, Racket, Template Haskell, and Metalua. It also shows the current status (`not-started`) and conflicts with speed, capabilities, and determinism.

## 2. Problem statement

### 2.1 Why metaprogramming

Systems languages need:

- Derive-like boilerplate (encoders, caps wrappers, FFI shims),
- Domain-specific checks embedded in syntax,
- Compile-time configuration and code generation,
- Agent-friendly mechanical edits that are still **typed and reviewed** as code.

Without macros, users must use external code generators. External generators break self-host purity and the capability model. Users might also copy and paste code. This action breaks OODA and correctness.

### 2.2 Why “ordinary functions on AST”

| Approach | Problem |
|----------|---------|
| String codegen | Unhygienic, untyped, injection hell |
| Token-only macros | Hard to do structured rewrites |
| Separate macro language | Dual cognitive load; agents weaker |
| Import-time side effects | Non-determinism; supply-chain risk |

The design uses the same syntax. It has an explicit compile-time phase. It treats AST values as data.

### 2.3 Users

| Actor | Use |
|-------|-----|
| Stdlib / compiler | Generate repetitive safe wrappers |
| Human | DSLs, derives, embedded checks |
| AI agent | Prefer expanding readable macros over inventing new codegen tools |
| Adversary | Compile-time code execution as attack surface (must sandbox) |

### 2.4 What breaks if omitted

- Design items that need code generation do not have a unified mechanism. These include compile-time FFI, contract derives, and narrative helpers.
- The self-host ecosystem gets external Python or shell generators. This causes tension during bootstrap.
- The AI-native design depends too much on runtime agents editing text. It needs structured compile-time transforms instead.

## 3. Related work

### 3.1 Rust macros

- **`macro_rules!`**: This uses pattern-based macros. It has limited structured transformation.
- **Procedural macros**: These operate on `TokenStream`. Ecosystem crates like `syn` and `quote` approximate the AST. They are very successful in industry. But users complain about slow compile times, difficult debugging, lag in IDEs, and friction across crate boundaries.
- References: See the Rust reference and Rust Book chapters on macros. See community discussions on procedural macros.

Lesson: Power is necessary. Token-level APIs decrease readability. The openOODA design tries to avoid this dual world.

### 3.2 Racket (Scheme lineage) — macros done seriously

- Racket has **hygiene**, **phase separation**, and modules-as-languages (`#lang`).
- Matthew Flatt wrote about compile-time versus run-time phases. This work is foundational.
- Flatt and others researched macros, modules, and language towers.
- For education, see *Fear of Macros* by Greg Hendershott and the Racket documentation on `syntax-parse`.

Lesson: Phases and hygiene are necessary for first-class macros. Racket is the best example for macro-extensible language design.

### 3.3 Template Haskell

- Sheard and Peyton Jones wrote about compile-time functions that produce ASTs. They also discussed quasi-quotation.
- Critics talk about stage restrictions, recompilation, and tooling problems.

Lesson: Staged metaprogramming works in production Haskell. But ergonomics and IDE support are difficult. The phase model is important.

### 3.4 Metalua (Lua)

- Metalua is a full Lua dialect. It has compile-time meta-programming over ASTs. It uses concrete syntax quasi-quotes. People use it for DSLs and language extensions on the simple Lua AST.
- It shows AST macros on a small imperative language. This is closer to systems scripting than Haskell.

### 3.5 Other

- **Lisp and Clojure** use macros. **Scala** uses macros and inline functions. **Zig comptime** evaluates ordinary code at compile time. **Nim** has macros and templates. **C++** uses templates and constexpr.
- **Terra** and multi-stage programming research embed high-performance code generation.

## 4. Design rationale for openOODA

### 4.1 Target properties

1. **Readable:** macro authors write openOODA-looking code.
2. **Structured:** operate on AST nodes (spans, kinds, children), not raw strings.
3. **Hygienic or explicitly unhygienic:** default safe binding; escape hatches documented.
4. **Phased:** compile-time host environment ≠ runtime target env.
5. **Capability-aware:** comptime cannot silently gain `&FsCap` / network (supply chain).
6. **Deterministic:** same sources → same expansion (ties to §4.3.2 reproducible builds).
7. **Budgeted:** expansion cost bounded for OODA tempo (§1.1).

### 4.2 Relation to surgical patching (product §2)

The product already has **source-level** `patch replace_fn` for agents. This operates at **edit-time**, not during **compile-time macro expansion**. Macros generate code inside the compiler pipeline. Patches change user files. Both rewrite ASTs, but they have different trust and phase models.

### 4.3 Relation to intent-driven compilation (§2.3)

LLM body synthesis is another compile-time generator. Macros must be **deterministic pure transforms**. LLM synthesis is probabilistic. You must explicitly gate LLM synthesis. Do not mix them.

### 4.4 Suggested architecture (research direction, not shipped)

- Use `comptime fn` or `macro fn` that take `Ast` or `Syntax` values.
- Use quasi-quote syntax to produce nodes. Propagate spans for diagnostics.
- Trace expansion in JSON diagnostics for agents. Use the `expanded_from` field.
- Use a sandboxed interpreter or staged subset for comptime. Do not allow ambient OS access.

## 5. Threat / failure model

### 5.1 What macros enable (positive)

- They control code generation under type and capability review.
- They remove external generator scripts from the pure product path.
- They let libraries extend syntax without forking the compiler.

### 5.2 Threats

| Threat | Detail |
|--------|--------|
| **Comptime RCE** | Macros that read env, network, or write files during build → supply-chain attack |
| **Non-determinism** | Time/rand in expansion breaks reproducible builds and hash integrity (§3.9, §4.3.2) |
| **Exponential expansion** | Compile-time DoS; destroys OODA |
| **Unhygienic capture** | Silent name capture bugs |
| **Opaque errors** | Errors in generated code without mapping to macro source |
| **Cap laundering** | Generated code inserts privileged calls the user didn’t audit |

### 5.3 What macros do not provide

- Macros do not provide runtime memory safety. OpenOODA still needs ARC, RAII, and bounds checks.
- Macros do not prove contracts unless they insert checks.
- Macros do not replace the capability system. They must generate **visible** capability parameters.

## 6. Alternatives considered

| Alternative | Why insufficient alone |
|-------------|------------------------|
| **External codegen only** | Breaks self-host and pure build ethics |
| **Rust-style proc-macro crates** | Powerful but dual-language API; DESIGN rejects as end state |
| **C preprocessor** | Non-structured; toxic for tools/agents |
| **Zig-style comptime only (no AST)** | Great for values/types; weaker for syntax DSLs unless reflection is rich |
| **Agent-only rewriting** | Non-deterministic; not package-expandable at publish time |
| **No metaprogramming** | Boilerplate and FFI wrappers explode |

## 7. Product reality (alpha honesty)

**PM.md `1.4` status: `not-started`.**

| Piece | Reality |
|-------|---------|
| Comptime/macro functions | **No** |
| AST as user-manipulable value | **No** (internal compiler AST only) |
| Derive/attribute macros | **No** |
| Quasi-quotes | **No** |
| Related product features | `patch replace_fn`, outline/reflect — **edit-time** tools, not macros |
| Compile-time FFI generation (4.3.3) | Separate DESIGN item; also not a full macro system |

A bootstrap script that rewrites sources is only **engineering scaffolding**. It is not the actual design feature.

## 8. Open research questions

1. **AST API stability:** how to expose nodes without freezing compiler internals forever?
2. **Phase model:** Racket-like towers vs single comptime interpreter?
3. **Cap model for comptime:** which caps exist at compile time, and are they ambient for the build driver only?
4. **Expansion tracing** for narrative diagnostics and agents?
5. **Interaction with incremental compilation:** invalidation units for macro-heavy crates?
6. Can macros emit **requires/ensures** and typestate transitions safely?
7. Should openOODA forbid macros from expanding to `&UnsafeFFICap` calls without explicit user annotation?

## 9. Acceptance criteria (for PM status promotion)

### not-started → smoke

- [ ] RFC: syntax, phase rules, hygiene, cap rules, determinism.
- [ ] Prototype: one comptime function rewriting a trivial AST form; expand-and-typecheck rail.
- [ ] Error mapping smoke: failure points at macro invocation span.

### smoke → partial

- [ ] Documented AST API subset; quasi-quote or builder MVP.
- [ ] Sandbox: no ambient filesystem/network in comptime without explicit build caps.
- [ ] Determinism test: two expands byte-identical IR/source fingerprint.
- [ ] Cost meter or depth limit preventing trivial exponential blowup.

### partial → done (MVP)

- [ ] Usable by stdlib for at least one real derive (e.g. simple codec or wrapper gen).
- [ ] Agent-visible expansion metadata optional but recommended.
- [ ] Conformance tests; security notes in docs; PM/DESIGN wording aligned (no “Rust parity” overclaim).

## 10. References

1. Rust Reference — Macros: https://doc.rust-lang.org/reference/macros.html ; procedural macros: https://doc.rust-lang.org/reference/procedural-macros.html
2. Flatt, M. “Composable and Compilable Macros: You Want It When?” ICFP 2002 (Utah PLT). Related PLT publications index: https://www.cs.utah.edu/plt/publications/
3. Flatt, M., et al. “Macros that Work Together” / Racket macro system papers (JFP line). Draft example: https://www-old.cs.utah.edu/plt/publications/jfp12-draft-fcdf.pdf
4. Sheard, T., Peyton Jones, S. “Template Meta-programming for Haskell.” Haskell Workshop 2002.
5. Yang, E. Z. “What Template Haskell gets wrong and Racket gets right.” 2016. https://blog.ezyang.com/2016/07/what-template-haskell-gets-wrong-and-racket-gets-right/
6. Hendershott, G. *Fear of Macros*. https://www.greghendershott.com/fear-of-macros/
7. Metalua documentation / historical project pages (Lua AST meta-programming).
8. openOODA `spec/DESIGN.md` §1, §2.1–2.3, §4.3.3; monorepo `PM.md` row `1.4`.

## Conflicts with other DESIGN items

| Conflict | Description | Resolution direction |
|----------|-------------|----------------------|
| **1.4 vs 1.1 OODA speed** | Macro expansion can dominate compile | Budgets, caching, incremental invalidation; ban pathological recursion |
| **1.4 vs 3.1 caps** | Generated privileged calls | Expand to explicit cap params; audit/lint expansions |
| **1.4 vs 4.3.2 reproducible builds** | Non-deterministic comptime | Forbid time/rand/host-fingerprint unless opt-in impure mode (not default) |
| **1.4 vs 3.9 call-graph integrity** | Expansion changes graph | Hash **post-expansion** graph; record macro provenance |
| **1.4 vs 6.1 metamorphic vs deterministic** | Related purity tension | Macros in deterministic lane; metamorphic is runtime binary concern |
| **1.4 vs 2.3 LLM synthesis** | Both generate bodies | Separate: macros pure/deterministic; LLM explicitly impure/tool-gated |
| **1.4 vs 2.1/2.2b patch** | Competing rewrite paths | Patches edit source; macros expand in compiler—don’t unify APIs carelessly |
| **1.4 vs 5.1 self-host** | Comptime interpreter must be in pure ooda eventually | Stage: host comptime in existing compiler; reimplement later |
| **1.4 vs 6.3 FFI** | Macros auto-wrapping C | Still require `&UnsafeFFICap` in generated signatures |

---

*Series: [Research papers index](./README.md). Template: [TEMPLATE.md](./TEMPLATE.md).*
