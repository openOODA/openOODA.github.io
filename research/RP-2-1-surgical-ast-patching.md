# RP-2.1: Surgical AST patching & JSON diagnostics

| Field | Value |
|-------|--------|
| **Paper ID** | `RP-2.1` |
| **DESIGN.md** | §2 AI tooling — Surgical AST Patching |
| **Status** | `draft` |
| **PM.md row** | `2.1` |
| **Product mapping** | **partial** — JSON diagnostics and `fix_hint` shipped. Full AST auto-fix is residual. |

## 1. Why this is in DESIGN.md

DESIGN.md §2 states:

> **Surgical AST Patching:** `--json-errors` gives machine-readable diagnostics. It includes surgical AST diff-fix suggestions. This lets AI agents automatically fix code in one step.

The OODA loop (Observe → Orient → Decide → Act) fails when agents read human-oriented error text. Agents cannot easily find file locations or change large text buffers. Machine-readable diagnostics give stable codes and optional fix instructions. These diagnostics close the Observe and Orient gap. Then, an agent can Act (use `ooda patch` or an AST rewrite) and test the code in one step.

This paper explains the design. It shows the agent-repair problem, previous work in automated program repair (APR), and commercial copilots. It explains why JSON and AST-oriented fixes are better than free-text. It also shows what we released and what remains to build.

## 2. Problem statement

### 2.1 What breaks without this feature

1. **Multi-turn thrashing.** Agents only see `ERR\ttype\tundefined variable foo`. They read full files again. They create incorrect patches and use many context tokens. Each compilation failure increases the OODA cycle time.
2. **Unstable routing.** Free-text messages change. Agents cannot correctly branch their logic (for example, `if E_CAP then add capability param`).
3. **Unsafe auto-apply.** Diagnostics need structured locations (path, line, col, code) and safe patch tools. Without them, an "auto-fix" changes the full file. This causes high risk for capability-sensitive code.
4. **Human/agent mismatch.** Humans want narrative diagnostics (DESIGN §5.5). Agents want codes, spans, and suggested edits. One product must give both without software bloat.

### 2.2 Users

| Actor | Need |
|-------|------|
| **AI coding agent** (CLI, Cursor, Copilot Workspace, custom loops) | Deterministic JSON. Stable `code`. Optional `fix_hint`. Re-check loop. |
| **Human developer** | Same pipeline. Human mode by default. |
| **Adversary / buggy agent** | Must not use `msg` as a path to open. Must not increase privileges through patch side channels. Must not execute user code while it fixes a problem. |

### 2.3 Success criteria (design intent)

An agent receives only `--json-errors` output and `ooda outline`/`reflect` metadata. For common failures (`E_CAP`, `E_TC`, simple parse), the agent must make a **local** edit. The `ooda check` tool must accept this edit. The agent must not send the full source code to the model two times.

## 3. Related work

### 3.1 Classical automated program repair (APR)

- **Search-based repair (GenProg and similar).** This uses genetic search across program versions with test suites. Patches are usually AST-level mutations. Correctness is weak (passing tests do not mean a semantic fix). This shows that **AST-scoped edits** are easier to process than free-form text.
- **Semantics-based repair (Angelix, SemFix, and similar).** Symbolic execution and constraint solving create expressions at fault locations. This gives stronger guarantees when specifications exist. But, it uses many resources and is specific to a language.
- **Template / learning-based APR.** This uses learned edit patterns (for example, fix templates from past commits). It predicts the *type* of patch. It still needs localization and validation.

**Takeaway for openOODA:** Classical APR uses the AST as the edit domain. openOODA does not invent APR. It gives **language-native agent I/O**. Diagnostics point to the AST surface that the agent (or `ooda patch`) changes. It uses contracts and capabilities as oracles.

### 3.2 LLM-based APR and agentic repair

Recent surveys (for example, LLM-based APR taxonomies, 2022–2025) put systems into these groups: fine-tuning, prompting, procedural pipelines, and **agentic frameworks**. The common themes are:

- **Retrieval- and analysis-augmented generation (RAG/AAG):** Error traces, code coverage, and static facts improve patch quality better than raw source code.
- **Compiler-in-the-loop:** Generate → compile/test → repair. (Fan et al., ICSE 2023 *Automated Repair of Programs from Large Language Models*; Xia et al. on pre-trained models for APR).
- **Autonomous agents:** RepairAgent (ICSE 2025) and similar systems use the LLM as an agent with tools (run tests, read files, apply edits). They do not use it as a one-shot patch generator.
- **Patch correctness assessment:** LLM-as-judge and hybrid filters decrease overfit patches (LLM4PatchCorrect and related APCA work).

Commercial systems (GitHub Copilot, Copilot Workspace, Cursor Agent, Claude Code, Aider, OpenAI `apply_patch`) use the same loop: **diagnostics → structured edit → revalidate**. They are different in their edit format (search and replace, unified diff, full file rewrite) and editor lock-in.

### 3.3 Compiler diagnostics for tools

- **SARIF** (Static Analysis Results Interchange Format): The industry standard for static-analysis results. It gives rich data but is too heavy for a fast CLI agent loop.
- **Language Server Protocol (LSP) diagnostics:** Structured severity, range, and code data. Editors use them. The `--json-errors` feature in openOODA is the **batch CLI equivalent** of LSP diagnostics for headless agents.
- **Rust / Swift / TypeScript** machine-readable modes (`--error-format=json`, etc.): Stable codes and spans prove the pattern is good. But, few output *surgical AST rewrite suggestions* that connect to a primary patch tool.

### 3.4 Gap

| Prior art | Strength | Gap vs DESIGN §2.1 |
|-----------|----------|---------------------|
| GenProg-style AST mutation | Local edits | No agent-facing JSON. Not capability-aware. |
| LLM APR / RepairAgent | High fix rates on benchmarks | External to the language. Fragile scrape of compiler text. |
| SARIF / LSP | Standard schemas | Not optimized for a single-turn agent and `replace_fn`. |
| Copilot / Cursor | Excellent UX | Editor-centric. No openOODA contracts or capabilities in the oracle. |

openOODA targets **language-owned** Observe (JSON diagnostics) and Act (`patch` or future AST apply). It uses **contracts and capabilities** as validation, not only unit tests.

## 4. Design rationale for openOODA

### 4.1 Dual surface: human narrative + agent JSON

- Default human mode: Tab-separated `ERR` lines (and later narrative diagnostics, RP-5.5).
- `--json-errors` / `-json`: Array of objects:

```json
{
  "code": "E_CAP",
  "line": 2,
  "col": 13,
  "msg": "…",
  "path": "fixtures/example.oo",
  "fix_hint": "Add matching &FsCap/… capability param."
}
```

Agents **branch on `code`**, not free-text `msg`. We document codes in `bootstrap/DIAG_CODES.md` (`E_CAP`, `E_TC`, `E_PARSE`, `E_LEX`, `E_CHECK`, `E_LOAD`, …).

### 4.2 Fix suggestions without host LLM bloat

We can build the "surgical AST diff-fix suggestions" from DESIGN in stages:

| Stage | Mechanism | Status intent |
|-------|-----------|---------------|
| A | `fix_hint` string keyed by diagnostic code | Shipped (alpha) |
| B | Structured suggestion: `{op, name, body_span}` consumed by `ooda patch` | Partial / residual |
| C | True AST edit list (node_id, replace/insert/delete) + verifier | Vision |

Stage A is intentionally **not** an embedded model call. Hints are deterministic tables. This keeps the compiler pure and self-hosted (RP-5.1). Stage C is the full "surgical AST patching" vision.

### 4.3 Interaction with the agent stack (§2 family)

```
ooda outline / reflect   → Orient (cheap context)
ooda check --json-errors → Observe (codes + spans + hints)
agent decides edit       → Decide
ooda patch replace_fn    → Act (fail-closed write)
ooda check / test        → Observe again
```

JSON diagnostics alone are incomplete without a **safe Act** function (RP-2.2b). Together, they form the product agent loop. You can read about this loop in `bootstrap/BETA.md` and `BUILD_OUT.md`.

### 4.4 Capability and contract awareness

- `E_CAP` must be a primary code. Agents learn that a missing `&FsCap` is not a type typo.
- Contract failures must emit codes that point to `requires` and `ensures` locations. This helps the repair keep mathematical bounds instead of deleting them.

### 4.5 Security properties of the diagnostic payload

- Payloads are **data**, not open APIs. The `path` and `msg` are JSON-escaped strings.
- Agents must not use `msg` as a file path to open (this is written in DIAG_CODES).
- Diagnostics must never execute user code. (The check path is pure relative to the run.)

## 5. Threat / failure model

### 5.1 What this prevents (when working)

| Failure | Mitigation |
|---------|------------|
| Agent mis-parses human errors | Stable JSON schema and codes |
| Wrong-file edits | Explicit `path` and line/col |
| Infinite regenerate loops | Deterministic re-check. Exit codes. |
| Accidental capability widening via silent rewrite | Codes like `E_CAP` and human review rails. Patch fail-closed. |

### 5.2 What this does **not** prevent

| Residual risk | Notes |
|---------------|-------|
| **Semantically incorrect "fixes"** | The `fix_hint` is guidance, not a proven patch. |
| **Overfitting to tests** | A classical APR problem. Contracts and fuzzing decrease this risk but do not stop it. |
| **Prompt injection in diagnostics** | Malicious code comments or strings in `msg` can influence simple agents. |
| **Supply-chain agent compromise** | Structured diagnostics help honest agents. Hostile agents ignore them. |
| **Incomplete localization** | A parse-only or partial type check can report the wrong primary span. |

### 5.3 Adversary model

Assume an agent is compromised or hallucinates. The agent has write access through `patch` or editor tools. JSON diagnostics decrease *accidental* damage. They do not put the agent in a sandbox. Sandboxing is RP-3.x (capabilities on generated code), not RP-2.1.

## 6. Alternatives considered

| Alternative | Why considered | Why insufficient / deferred |
|-------------|----------------|-----------------------------|
| **Human text only** | Zero schema work | Breaks agent routing. It has a high token cost. |
| **Full SARIF emission** | Industry standard | Heavy data. It is a poor fit for a fast CLI loop. We can adopt it later as an export. |
| **LSP-only diagnostics** | Already structured | Headless CI and agents need a batch CLI. Dual-emit is acceptable. |
| **Embedded LLM "heal" in compiler** | Matches ooda-future `ooda heal` | Breaks the pure and self-hosted rule. It makes builds non-deterministic (see RP-2.3). |
| **Whole-file rewrite suggestions** | Easy for models | High damage risk. Worse for capabilities and contracts. |
| **Binary AST patch protocol only** | Maximum precision | Difficult for external agents. Text JSON and `replace_fn` are better first steps. |

## 7. Product reality (alpha honesty)

**PM.md `2.1`: partial.**

| Piece | Reality | Evidence |
|-------|---------|----------|
| `ooda`/`oodac check --json-errors` | **Done** | JSON array. Clean gives `[]`. Smoke test in `scripts/json_errors_smoke.sh`. |
| Stable codes | **Done** | `bootstrap/DIAG_CODES.md` |
| `fix_hint` | **Done** (code-keyed strings) | Not an AST rewrite. No host AiDiagnostic bloat. |
| Suggested AST diff / auto-apply from diag | **Residual** | Explicit residual in `BUILD_OUT.md` |
| Full surgical AST patch engine from diagnostics | **Not done** | Design vision. Edits today use `ooda patch` (2.2b). |

**Honest summary:** The Observe step is real for agents. We did **not** ship "surgical AST patching" as auto-generated AST diffs. The product path is JSON diagnostics and a separate `replace_fn` patch. It is not a one-step AST magic tool.

Cross-links: `bootstrap/BUILD_OUT.md` (P2 AI-native), `BETA.md` (JSON diags row), RP-2.2b (Act side).

## 8. Open research questions

1. **Schema versioning:** How can we change the diagnostic JSON and not break agents (semver field, capability flags)?
2. **Primary and related spans:** Multi-span diagnostics (definition and use). What is the minimum useful set for a single-turn fix?
3. **Source of `fix_hint`:** Static tables, a mined corpus, or a model? How do we keep the pure compiler free of network and LLM calls?
4. **Patch correctness without full tests:** Can contracts and type checks reject ≥X% of bad agent patches on a held-out test set?
5. **SARIF bridge:** Is a lossy SARIF export useful for GitHub Code Scanning?
6. **Prompt-injection hardening:** Should we limit the length of `msg` or make it structure-only for agent mode?

## 9. Acceptance criteria (for PM status promotion)

### partial → done (minimum)

- [ ] Diagnostics have sufficient structure for the top N failure classes to be auto-routed (`code`, path, and span are always present).
- [ ] Documented agent loop: check → patch → check with golden smoke tests in CI (no cargo on the pure path).
- [ ] At least one **structured** fix suggestion path (not only a free-text `fix_hint`) that `ooda patch` or an AST apply tool can read, for ≥1 code (for example, `E_CAP`).
- [ ] Security review notes: There is no execution of user code on the check/json path. The injection guidance is published.

### done → aspirational “DESIGN complete”

- [ ] AST-level edit list (node identity is stable across a re-parse, or there is an explicit source-map).
- [ ] Optional `ooda heal` **outside** the pure compiler core (as a side process) with contract revalidation.
- [ ] Measured single-turn fix rate on a public test suite.

## 10. References

1. DESIGN.md §2 — Surgical AST Patching; §1 Philosophy of Speed (OODA loop).  
2. openOODA `bootstrap/DIAG_CODES.md`, `BUILD_OUT.md`, `BETA.md`, monorepo `PM.md` row 2.1.  
3. Le Goues, C. et al. — GenProg / search-based automated program repair (ICSE and follow-ons).  
4. Mechtaev, S. et al. — Angelix / semantics-based repair.  
5. Fan, Z. et al. — *Automated Repair of Programs from Large Language Models* (ICSE 2023).  
6. Xia, C.S. et al. — APR with large pre-trained language models (ICSE 2023 lineage).  
7. Bouzenia, I. et al. — *RepairAgent: An Autonomous, LLM-Based Agent for Program Repair* (ICSE 2025).  
8. Survey: *A Survey of LLM-based Automated Program Repair* (arXiv:2506.23749) — taxonomies, RAG/AAG, agentic paradigms.  
9. Zhou et al. — LLM4PatchCorrect / automatic patch correctness assessment (Defects4J, BEARS).  
10. OASIS — SARIF specification.  
11. Microsoft — Language Server Protocol (diagnostics).  
12. GitHub Copilot / Copilot Workspace — commercial agent-repair loops (product docs).  
13. Cursor, Aider, OpenAI `apply_patch` tool — structured edit formats for coding agents.  
14. Rustc `--error-format=json` — prior art for machine-readable compiler diagnostics.

---

## Conflicts with other DESIGN items

| Tension | Conflict | Resolution direction |
|---------|----------|----------------------|
| **§2.1 auto-fix vs §3 capability purity** | Automatically applied patches can insert or remove `&Cap` parameters. | Never automatically apply capability-widening patches without an explicit agent or user flag. `E_CAP` fixes that *add* required capabilities are safer than removing checks. |
| **§2.1 vs §5.5 narrative diagnostics** | Agents want codes. Humans want stories. | Dual emit: JSON codes and human narrative. Do not overload one string. |
| **§2.1 heal-in-compiler vs §4.3.2 deterministic builds** | LLM suggestions are non-deterministic. | Keep the heal function **out** of the pure compile hash path. Suggestions are advisory or use a side-tool. |
| **§2.1 vs §2.2b** | Overlap: "Who applies the fix?" | 2.1 is Observe and suggest. 2.2b is Act (`replace_fn`). Do not merge them into one unsafe tool. |
| **§2.1 full AST rewrite vs §1.4 AST macros** | Two AST mutation engines. | Macros run at compile-time and are trusted. Agent patches are source-level and untrusted until the re-check. |

---

*Series: [Research papers index](./README.md). Template: [TEMPLATE.md](./TEMPLATE.md). Sibling: [RP-2.2b](./RP-2-2b-surgical-patch-replace-fn.md).*
