# RP-2.2: Token-minimized APIs (`outline` / `reflect`)

| Field | Value |
|-------|--------|
| **Paper ID** | `RP-2.2` |
| **DESIGN.md** | §2 AI tooling — Token-Minimized APIs |
| **Status** | `draft` |
| **PM.md row** | `2.2` |
| **Product mapping** | **done** (M1 pure path; parse-only; residual richness) |

## 1. Why this is in DESIGN.md

DESIGN.md §2 states:

> **Token-Minimized APIs:** `ooda outline` and `ooda reflect` export compressed symbol metadata. This gives an 85 to 90 percent token reduction when AI agents read the source code.

Large language models have context limits. Agents that read the repository with full source files hit these limits. They lose long-range structure and increase latency and cost. The openOODA AI-native design requires **language-first compression**. The compiler (or a pure parse path) exports the data that an agent needs to Orient. This data includes public APIs, contracts, and capabilities, without the function bodies.

This document gives the reasons for outline and reflect as product surfaces. It compares them to RAG and code summarization research. It also records the known residuals. (It does not record a full typed AST or import graph).

## 2. Problem statement

### 2.1 The context crisis

| Approach | Failure mode |
|----------|--------------|
| Paste entire files | Uses too many tokens. It hides contracts in noise. |
| Embedding RAG only | Retrieval misses rare capabilities and contracts. It is non-deterministic and has index lag. |
| Human README only | The data becomes obsolete. It is not machine-checked against the source code. |
| Full typecheck dump | It has a high cost. It can require a build graph. It is too large to find the API. |

Agents need different **levels of detail**:

1. **Outline** — the lowest cost public surface (names, parameters, returns, capabilities).
2. **Reflect** — contracts, verify hooks, and richer metadata (but no bodies).
3. **Source slice / patch target** — use this only after you decide *where* to do the work.
4. **Full check / test** — use this for validation, not orientation.

### 2.2 Users

| Actor | Use |
|-------|-----|
| Coding agent | Map modules before you edit them. Choose `replace_fn` targets. |
| Package consumer (future) | Use precomputed outlines in packages (ooda-future "context-optimized packages"). |
| Human | Read the API quickly without an IDE. |
| Adversary | Must not execute code through introspection. Must not leak secrets from bodies (the design omits bodies). |

### 2.3 Quantitative design goal

DESIGN claims an **85 to 90 percent token reduction**. Treat this as a **target range**, not a strict mathematical proof. Measure `tokens(outline+reflect) / tokens(full source)` on the stdlib and compiler source files. The Alpha version can claim a large decrease in orientation cost with published methods, even if it does not reach 85 percent on every file.

## 3. Related work

### 3.1 Context windows and agent practice

Modern agents (Cursor, Copilot, Claude Code, Aider) combine these items:

- **Repository maps / file trees** (names only).  
- **Grep / semantic search** (on-demand).  
- **Summaries** (model-generated, frequently obsolete).  
- **Editor open tabs** as implicit context.

Language-owned outline tools decrease the need for model-generated summaries. Model-generated summaries can **invent incorrect APIs**.

### 3.2 RAG for code

Retrieval-augmented generation (Lewis et al., 2020) improves data accuracy, but:

- Splitting APIs can separate signatures from their documentation.  
- Capability and contract clauses use few tokens. It is easy to miss them in the embedding space.  
- Private code cannot always use cloud services for embeddings.

**outline** and **reflect** are **deterministic extractors**. They work together with RAG. Use outline as the continuous structure. Use RAG for text documentation and examples.

### 3.3 Code summarization and documentation generation

Academic code summarization (function to natural language) and neural documentation tools compress *meaning*, but:

- They are probabilistic and have high cost.  
- They do not make sure to include `&FsCap` or `requires`.  
- They make errors frequently. This is dangerous for capability-sensitive APIs.

openOODA uses **lossy but accurate** structured compression instead of natural language summaries for agent Orient.

### 3.4 Existing language tooling

| Tool | Similarity | Difference |
|------|------------|------------|
| `go doc` / `rustdoc` JSON | API extract | They are doc-oriented and heavier. They do not use an NDJSON agent stream. |
| TypeScript `--declaration` | Public types | They emit artifacts. They are not an interactive agent CLI. |
| `ctags` / tree-sitter queries | Symbols | They have no contract or capability semantics. |
| LSP `documentSymbol` | Hierarchical symbols | It requires a running LSP. Outline is batch-friendly. |

### 3.5 Gap

No mainstream systems language includes CLI extractors that are **first-class, parse-only, capability-aware, contract-aware, and token-budgeted** as part of the *language* product for AI agents. This is the core idea of the DESIGN.

## 4. Design rationale for openOODA

### 4.1 Two commands, two budgets

Documented in `bootstrap/OUTLINE_REFLECT.md`:

```text
ooda outline <file.oo>
ooda reflect <file.oo> [symbol]
```

| Command | Fidelity | Token posture |
|---------|----------|---------------|
| `outline` | Public `fn` lines: parameters, return, `caps=` | Minimal |
| `reflect` | NDJSON: requires, ensures, capabilities, verify names, and an optional symbol filter. | Small to medium |

**Security:** parse-only. It **never executes** user `.oo` code. It fails closed on unreadable paths.

### 4.2 Outline format (product)

```text
pub fn NAME(param: Type, …) [-> Ret] [caps=Cap1,Cap2]
```

- It omits private `fn` (it shows the public API only).  
- It does **not** print bodies, requires/ensures, or verify (this saves tokens).  
- It detects capabilities from parameter types (`NetCap|FsCap|SysCap|EnvCap`).

### 4.3 Reflect format (product)

NDJSON objects, e.g.:

```json
{"kind":"fn","name":"add","pub":true,"params":[…],"ret":"Int","requires":["a >= 0"],"ensures":["result >= 0"],"caps":[]}
{"kind":"verify","name":"add"}
```

Agents filter by symbol when they focus. A full-file reflect also omits the function bodies.

### 4.4 Pipeline fit

```
outline  → “what can I call?”
reflect  → “what must hold / what caps?”
json-errors → “what broke?”
patch    → “change this fn only”
```

Package-manager future (ooda-future §2): supply outlines **with** packages. This prevents agents from downloading 100,000 lines of code to learn an API.

### 4.5 Why not only embeddings?

Determinism, offline pure bootstrap, auditability, and **capability and contract accuracy**. Embeddings are optional for natural language documentation.

## 5. Threat / failure model

### 5.1 Prevents

| Risk | Mitigation |
|------|------------|
| Agent executes code while it reads the API | The implementation only parses the code. |
| Token budget exhaustion on Orient | The design omits bodies and only outlines public data. |
| Stale model memory of APIs | Run outline again after every patch. |
| Accidental secret exfiltration from function bodies | The design does not emit bodies. |

### 5.2 Does not prevent

| Risk | Notes |
|------|-------|
| **Stale outline vs semantics** | A text/scan residual is not a full typecheck. It can disagree with `check`. |
| **Missing private helpers** | This is by design. Agents can need to read targeted source files. |
| **Import graph blindness** | Residual: there are no import lines in the MVP. |
| **Adversarial public signatures** | Malicious `pub fn` names or strings still go into the agent context. |
| **Over-trust** | Outline does not prove that the implementation is correct. |

### 5.3 Integrity

Agents must treat outline and reflect as **claims about source text**. Agents must validate these claims with `check` before they trust safety properties.

## 6. Alternatives considered

| Alternative | Rejection / deferral reason |
|-------------|----------------------------|
| **Model-summarize on the fly** | It is non-deterministic and has high cost. It invents capabilities. |
| **Always full-file context** | It fails the OODA cost goals. |
| **Binary symbol tables only** | It is not easy to use for external agents and humans. |
| **JSON-Schema mega dump of typed AST** | It uses many tokens and needs a full checker. The residual comes later as `reflect --full`. |
| **Documentation comments only** | They are not enforced and are frequently missing. |

## 7. Product reality (alpha honesty)

**PM.md `2.2`: done** (M1 pure path).

| Piece | Reality |
|-------|---------|
| Pure `oodac outline` / `reflect` via product CLI | **Done** (not Python helper as primary) |
| Parse-only / no execution | **Done** |
| Format docs + smoke rails | **Done** (`OUTLINE_REFLECT.md`, `outline_reflect_smoke.sh`) |
| Full typed AST outline | **Residual** |
| Import graph / type-alias lines | **Residual** |
| `--json` outline variant | **Residual** |
| Measured 85–90% token reduction published | **Not formalized** (design claim; measure in §9) |
| Package-shipped outlines | **Not-started** (ecosystem) |

**Honest summary:** outline and reflect are **real products and usable by agents**. They have an intentional residual depth. “Done” means they are an M1 pure path. It does not mean they have the maximum features from the DESIGN.

## 8. Open research questions

1. **Compression metrics:** What standard source files and tokenizer do we use for the 85 to 90 percent claim?  
2. **Incremental outline:** How do we do module-level cache invalidation for monorepos?  
3. **Cross-file outline:** How do we summarize `std` and the user tree without an import graph?  
4. **Privacy tiers:** Do we use `reflect --public-only`, or do we include non-public data for local agents?  
5. **Outline as package artifact:** How do we manage signing and freshness? (This connects to RP-5.2 web of code).  
6. **Hybrid RAG:** What is the best practice prompt? Do we use outline first, and then retrieve bodies only for named symbols?

## 9. Acceptance criteria (for PM status promotion)

### Maintain `done` (regression bar)

- [x] `ooda outline` / `reflect` on pure path; smoke pass/fail cases.  
- [x] Never execute user code.  
- [x] Fail-closed unreadable / missing symbol.

### `done` → richer (optional PM note, not status demotion)

- [ ] Put the import graph or `mod` lines in the outline.  
- [ ] Add a typed or checked reflect mode. (This can require check-class work).  
- [ ] Publish token-reduction numbers on the `std/` and `oodac/` source files.  
- [ ] Add an optional machine-wide `ooda outline --project` command.

## 10. References

1. DESIGN.md §2 — Token-Minimized APIs; ooda-future “Context-Optimized Package Ecosystem.”  
2. openOODA `bootstrap/OUTLINE_REFLECT.md`, `BUILD_OUT.md`, `PM.md` row 2.2.  
3. Lewis, P. et al. — Retrieval-Augmented Generation for Knowledge-Intensive NLP (NeurIPS 2020 lineage).  
4. Surveys on repository-level code generation and long-context agents (2023–2025 literature).  
5. Code summarization surveys (neural source code summarization, ASE/ICSE lines).  
6. GitHub Copilot, Cursor codebase indexing — commercial context selection (product documentation).  
7. rustdoc JSON, TypeScript declaration emit, Go doc — industrial API extraction prior art.  
8. LSP `textDocument/documentSymbol` — editor-oriented symbol compression.  
9. Tree-sitter / ctags — generic symbol extraction without semantic contracts.

---

## Conflicts with other DESIGN items

| Tension | Conflict | Resolution direction |
|---------|----------|----------------------|
| **Token compression vs narrative diagnostics (§5.5)** | Rich stories use many tokens. | Keep outline and reflect small. Use narratives only on failure paths. |
| **Outline pub-only vs self-host debugging** | Compiler developers need private symbols. | Allow a future `--all` option for local trusted use. The default is public for agents. |
| **Parse-only honesty vs “85–90%” marketing** | An incomplete parse can omit a real API. | Measure on parsable source files. Do not claim typechecked accuracy in the MVP. |
| **§2.2 vs §2.3 telepathic AST** | Synthesis needs contracts from reflect. | Reflect is the Orient input for the future intent compile. Keep the formats stable. |
| **Package outlines vs zero-trust (§5.2)** | A shipped outline can give false capability data. | Outline is a hint. The **check** command and capability minting are authoritative. |

---

*Series: [Research papers index](./README.md). Template: [TEMPLATE.md](./TEMPLATE.md). Sibling: [RP-2.1](./RP-2-1-surgical-ast-patching.md), [RP-2.2b](./RP-2-2b-surgical-patch-replace-fn.md).*
