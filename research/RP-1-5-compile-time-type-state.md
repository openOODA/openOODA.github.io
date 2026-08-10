# RP-1.5: Compile-time type-state machines

| Field | Value |
|-------|--------|
| **Paper ID** | `RP-1.5` |
| **DESIGN.md** | §1 Language |
| **Status** | `draft` |
| **PM.md row** | `1.5` |
| **Product mapping** | **not-started** — no typestate/session-type machine in the typechecker; ordinary nominal types only |

## 1. Why this is in DESIGN.md

DESIGN.md §1:

> **Compile-Time Type-State Machines:** Objects can transition through explicit lifecycles (e.g., `Unopened` -> `Opened` -> `Closed`). The compiler statically proves that `.read()` can never be called on an `Unopened` file, eliminating entire classes of logic bugs.

Types that track **lifecycle** show the state of an object. For example, a type shows that a `File` is `Opened`. The compiler finds illegal sequences. These sequences include reading before you open a file, or using a file after you close it. These are **type errors**. They are not runtime exceptions. This is critical for an AI-native language. Agents can change the order of calls. Typestate stops agents from making illegal changes.

This paper explains typestate as a DESIGN pillar. It surveys classical typestate, session types, and Rust typestate patterns. It also lists conflicts with ownership, capabilities, and product reality (`not-started`).

## 2. Problem statement

### 2.1 Class of bugs

Protocol and resource APIs have **stateful interfaces**:

- Files: open → read/write → close,
- Sockets: bind → listen → accept → connected I/O,
- Locks: unlocked → locked → unlocked,
- Builders: empty → configured → sealed,
- Crypto: key uninit → loaded → consumed.

Type systems with only nominal types allow:

```text
f.read()  // f never opened — typechecks if read: (File) -> ...
```

### 2.2 Why compile-time

Programmers can easily forget runtime checks. These checks are hard for agents to maintain. Runtime checks also occur late in the OODA loop. Static typestate moves the failure to the **Orient** phase. This happens before the **Act** phase.

### 2.3 Users

| Actor | Benefit |
|-------|---------|
| Human | API misuse caught at compile time |
| AI agent | Invalid tool sequences rejected without execution |
| Caps system | Complements authority: may have `&FsCap` yet still wrong file state |
| Fuzzer | Fewer shallow state bugs; deeper semantic search |

### 2.4 What breaks if omitted

- The DESIGN file claims to "eliminate entire classes of logic bugs". Without typestate, this claim has no mechanism.
- Capabilities alone do not encode protocols.
- Contracts can express some state. But, they usually act as **runtime** checks unless the compiler proves them. Typestate aims to make methods **statically** unavailable.

## 3. Related work

### 3.1 Classical typestate

- **Strom, R. E., & Yemini, S.** “Typestate: A Programming Language Concept for Enhancing Software Reliability.” *IEEE Transactions on Software Engineering*, SE-12(1), 1986, pp. 157–171. This is the canonical definition. It associates abstract states with types. It enables operations per state. It tracks states at compile time. PDF links: https://www.cs.cmu.edu/~aldrich/papers/classic/tse12-typestate.pdf and https://research.ibm.com/publications/typestate-a-programming-language-concept-for-enhancing-software-reliability

### 3.2 Session types

- **Honda, K.** Foundational work on session types. This work defines types as **communication protocols**.
- Toolchains such as **Mungo** and **StMungo**. These integrate session types with typestate checking for Java.
- Session types generalize "file open/close" to concurrent message protocols. This is relevant if openOODA grows channels.

### 3.3 Rust typestate pattern (industrial)

Rust lacks first-class typestate but encodes it with:

- Generics: `File<Unopened>` / `File<Opened>`,
- Ownership + move: consume `Unopened` to produce `Opened`,
- Sealed traits / zero-sized state markers,
- Occasionally typestate crates / research (e.g. session-type embeddings, “Retrofitting Typestates into Rust” theses).

Strength: This works today. The language does not need new type theory. Weakness: The code is long. You can easily bypass it with `unsafe` code or shared mutability. It is not as declarative as DESIGN’s lifecycle machines.

### 3.4 Other language / research systems

- **Plaid**, **Typestate-oriented programming**.
- **Fugue**, **Vault**, **Clay**: These are resource and typestate-inspired systems languages.
- **Coconut** and embedded typestate work.
- **Ada/SPARK** models state with types and contracts.
- Recent work on typestate via capabilities. This aligns with openOODA capabilities.

### 3.5 Relation to contracts

Design by Contract is expressive. But, it is often dynamic. Typestate makes `.read` **not a member** of `File<Unopened>`. The best design uses typestate for discrete protocols. It uses contracts for value checks within a state.

## 4. Design rationale for openOODA

### 4.1 DESIGN example

The compiler proves that `.read()` is impossible on `Unopened`. The state machine goes `Unopened → Opened → Closed`. This implies:

- States are part of the type.
- Transition functions **consume** the old state and return a new state.
- The state controls the available methods.

### 4.2 Fit with capabilities

Example split:

- `&FsCap` — authority to touch filesystem,
- `File<Opened>` — protocol state of a particular handle.

You need both capabilities to `read`. This double check stops "capability present but API misused" failures.

### 4.3 Fit with AI agents

The compiler gives an **immediate** static rejection when agents propose bad call sequences. The compiler uses JSON diagnostics. The compiler can suggest legal transitions to the agent.

### 4.4 Possible surface sketches (not product)

1. **Generic state params:** `File[Opened]`. This is Rust-like. The team can implement this sooner.
2. **Explicit machine block:** Declare states and transitions. The compiler creates the types.
3. **Session-typed channels:** Add these later for concurrency.

MVP recommendation: Use option 1 with move semantics. Test this on standard file and network types.

### 4.5 Aliasability

Classic typestate is hard to use with unrestricted aliasing. openOODA must pick one option:

- Affine handles for stateful resources, or
- Refinement that invalidates aliases, or
- Runtime checks when static analysis fails.

The ownership design is a hard requirement for sound typestate.

## 5. Threat / failure model

### 5.1 Prevents (when sound)

- The compiler finds use-before-ready, use-after-done, and illegal double transitions.
- The compiler finds entire API misuse classes without executing code.
- The compiler stops agent “shotgun” call ordering.

### 5.2 Does not prevent

- Logic bugs **within** a legal state.
- Security without caps (opened file still needs authority model).
- Concurrent protocol violations without session types / send bounds.
- Malicious `unsafe`/FFI escape hatches (6.3).
- Spec bugs (wrong state machine encoded).

### 5.3 Failure modes

| Mode | Risk |
|------|------|
| Escape hatches | `transmute`-like cast between states |
| Shared `Rc` of stateful object | Divergent views of state |
| Drop glue | `Opened` dropped without `Closed`—need drop obligations or end states |
| Incomplete std adoption | Feature exists but APIs ignore it |
| Compile-time cost | Complex DFAs slow typecheck (vs 1.1) |

## 6. Alternatives considered

| Alternative | Assessment |
|-------------|------------|
| **Runtime-only state flags** | Simple; fails DESIGN “statically proves”; weak for agents |
| **Contracts only** | Complementary; not identical to method absence |
| **Rust-pattern in library without language help** | Good prototype path; DESIGN still wants first-class story |
| **Full multiparty session types in v0** | Research-heavy; defer past MVP file/socket machines |
| **Dependent types encoding all protocols** | Powerful; steep; not required for lifecycle MVP |
| **Only linters** | Non-compositional; not type-system enforced |

## 7. Product reality (alpha honesty)

**PM.md `1.5` status: `not-started`.**

| Feature | Reality |
|---------|---------|
| State-indexed types / typestate checker | **No** |
| Consuming transitions enforced | **No** (no linear type system) |
| File/socket APIs as state machines | **No** DESIGN-level typestate |
| Related partial pieces | Caps on I/O (**partial**, 3.1); contracts **partial** (1.2) — neither is typestate |
| Rust-like manual encoding in user code | Possible only insofar as generics exist; openOODA generics/type system still product-evolving |

Do not describe Result/error handling or caps as “typestate shipped.”

## 8. Open research questions

1. What is the **minimal type feature set** for MVP lifecycle machines?
2. How does typestate interact with **ARC** and shared ownership?
3. **Drop obligations:** Must `close` consume `Opened`? How does the compiler check this?
4. Can capabilities themselves use typestate?
5. Are session types for **fearless concurrency** on the roadmap? Or are they out of scope?
6. Error UX: Explain illegal transitions with legal successors.
7. What is the annotation burden for agents and humans?

## 9. Acceptance criteria (for PM status promotion)

### not-started → smoke

- [ ] RFC: state parameters, transition rules, aliasing rules, drop policy.
- [ ] Prototype: `File[Unopened|Opened|Closed]`-style API in a fixture; illegal call fails typecheck.
- [ ] Document intentional non-goals (full session types).

### smoke → partial

- [ ] Enforced in product typechecker on a supported fragment.
- [ ] At least one std or fixture resource API uses typestate.
- [ ] Diagnostics name expected states; corpus pass/fail rails.
- [ ] Interaction note with caps published.

### partial → done (MVP)

- [ ] Stable syntax/semantics for lifecycle machines on owned resources.
- [ ] No silent bypass without explicit unsafe/FFI cap path.
- [ ] QA rails; DESIGN example (`read` on `Unopened`) holds in product.
- [ ] Written limits (aliasing, concurrency) so users don’t over-trust.

## 10. References

1. Strom, R. E., Yemini, S. “Typestate: A Programming Language Concept for Enhancing Software Reliability.” *IEEE TSE*, 12(1):157–171, 1986. https://www.cs.cmu.edu/~aldrich/papers/classic/tse12-typestate.pdf
2. IBM Research publication record: https://research.ibm.com/publications/typestate-a-programming-language-concept-for-enhancing-software-reliability
3. Honda, K. “Types for Dyadic Interaction.” CONCUR 1993 (foundational session types). Subsequent multiparty session-type literature.
4. Kouzapas, D., et al. “Typechecking protocols with Mungo and StMungo.” *Science of Computer Programming*, 2018. https://www.sciencedirect.com/science/article/pii/S0167642317302186
5. Aldrich, J., et al. Typestate-oriented programming / Plaid project papers (CMU).
6. Rust typestate pattern — community documentation and blog corpus; research on embedding session/typestate in Rust (e.g. Duarte, “Retrofitting Typestates into Rust,” 2021 thesis lineage).
7. Alsubhi, A. H., et al. “Coconut: Typestates for Embedded Systems” (embedded typestate case study). https://eprints.gla.ac.uk/325787/1/325787.pdf
8. openOODA `spec/DESIGN.md` §1, §3.1, §5.3; monorepo `PM.md` row `1.5`.

## Conflicts with other DESIGN items

| Conflict | Description | Resolution direction |
|----------|-------------|----------------------|
| **1.5 vs 3.7 ARC/RAII** | Shared ownership vs unique state | Stateful protocols on owned/affine handles; share only immutable or end states |
| **1.5 vs 3.8 temporal memory** | Rollback may revive dead states | Rollback restores consistent typestate snapshots or forbids typestate across rewind barriers |
| **1.5 vs 3.1 caps** | Overlapping but distinct | Document matrix: cap = authority, typestate = protocol |
| **1.5 vs 1.2 contracts** | Duplicate enforcement | Typestate for discrete states; contracts for predicates inside state |
| **1.5 vs 1.1 speed** | Heavier typechecking | Keep MVP state machines small; cache; avoid full dependent types |
| **1.5 vs 5.3 concurrency** | Parallel aliases | Session types or exclusive borrows later; MVP single-threaded owned |
| **1.5 vs 6.3 FFI** | C returns untyped handles | Wrap immediately into typestate newtypes; require UnsafeFFICap |
| **1.5 vs 1.3 SoA** | Entity component presence as state | Optional components / sparse columns as parallel to typestate |
| **1.5 vs 2.3 LLM synthesis** | Generated code must respect transitions | Typecheck after synthesis; reject illegal sequences |

---

*Series: [Research papers index](./README.md). Template: [TEMPLATE.md](./TEMPLATE.md).*
