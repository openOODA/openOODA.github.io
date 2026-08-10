# RP-2.2b: Surgical `patch replace_fn` (safe agent edits)

| Field | Value |
|-------|--------|
| **Paper ID** | `RP-2.2b` |
| **DESIGN.md** | §2 AI tooling (product elaboration of surgical edit Act) |
| **Status** | `draft` |
| **PM.md row** | `2.2b` |
| **Product mapping** | **done** — `replace_fn` only; line-range / node_id residual |

## 1. Why this is in DESIGN.md

Section 2 of DESIGN explains **surgical AST patching** and automatic fixes by agents. The product divides this process into two parts:

- **RP-2.1** — Observe: You use `--json-errors`, codes, and hints.
- **RP-2.2b** — Act: Agents use a **fail-closed** tool to rewrite source code at the function level. This tool does not use shell evaluation or overwrite the whole file.

`ooda patch … --replace-fn` is the safe command for agents to make changes. It replaces one function body (or the signature and body) atomically. It can do an optional check. It rejects unknown operations.

This document explains why we use **structured, narrow edit operations** instead of free-form file writes. It examines commercial edit formats. It also records remaining work (line-range, AST node_id).

## 2. Problem statement

### 2.1 Why whole-file agent writes fail systems languages

| Failure | Consequence in openOODA |
|---------|-------------------------|
| Drift of unrelated functions | Silent capability/contract damage |
| Partial writes / crash mid-edit | Corrupt sources |
| Shell-based `sed` from model | Injection; non-portable |
| Search/replace mismatch | Duplicated anchors; wrong overload |
| No revalidation | “Fixed” code still fails `check` |

Agents need an **API-shaped editor**. This editor must have a small command vocabulary, safe paths, atomic replacement, and explicit failure messages.

### 2.2 Users

| Actor | Need |
|-------|------|
| Autonomous repair loop | `replace_fn` from JSON stdin or CLI |
| HITL developer | Reviewable diffs; optional `--check` |
| CI | Deterministic patch apply from fixtures |
| Adversary | Path escape (`..`), op smuggling, code execution via patch engine |

### 2.3 Design thesis

**Least privilege for edits:** The default tool for agents can change only **one named function** per call. It cannot change the whole file system.

## 3. Related work

### 3.1 Commercial / OSS agent edit formats

| System | Edit style | Notes |
|--------|------------|-------|
| **Aider** | SEARCH/REPLACE, whole-file, unified diff | Chooses format per model reliability |
| **Claude Code** | Dedicated Edit/Write tools (old_string → new_string) | Exact match replace |
| **OpenAI apply_patch** | Structured create/update/delete diffs | Tool-native; harness applies |
| **Cursor** | Often larger rewrites / diff UX | Editor-integrated |
| **Codex / OpenCode** | Patch-centric mutation | Single write channel in some designs |

Reports from developers (2024–2025) show that **AI models fail at different rates depending on the format**. You must validate (compile and test) the code after you apply a patch.

### 3.2 AST-level editing research

- Classical Automated Program Repair (APR) changes ASTs (inserts or replaces statements).
- Refactoring engines (such as jscodeshift, go fmt AST, and Rust rustc_ast) show that structural edits are reliable.
- The idea that "AST edits are better than text diffs" for agents is not yet common in real products. Most production agents still use **text** operations with some structural limits.

### 3.3 Safe tool use / agent sandboxing

This adds safety at the **tool-level**. This is separate from language capabilities (RP-3.1). The tool uses the principle of least privilege (it only permits `replace_fn` and rejects unknown operations). If a malicious AI model tries to use `run_shell` in the JSON schema, the tool rejects it safely.

### 3.4 Gap

Few languages ship a **first-party** `patch` CLI with:

1. Named function granularity.
2. JSON operation protocol.
3. Path sandbox (relative to current directory, no `..`).
4. Atomic write.
5. Optional compile check.
6. **No** execution of the new body at patch time.

This is the product goal of openOODA for 2.2b.

## 4. Design rationale for openOODA

### 4.1 Product interface (shipped shape)

```text
ooda patch <file.oo> --replace-fn <name> --with <body_file> [--check]
```

Or JSON stdin:

```json
{"op":"replace_fn","name":"add","body":"…"}
```

- **Unknown `op` → fail-closed.**  
- **No shell-eval of body.**  
- **Path rules:** reject `..`; relative under cwd; atomic write.  
- Engine historically: `scripts/ooda_patch.py` + shell rail; pure-path direction tracked in bootstrap docs.  
- Rails: `scripts/patch_smoke.sh`; fixtures `fixtures/patch_add.oo`.

### 4.2 Why `replace_fn` first

| Op | Risk | Priority |
|----|------|----------|
| `replace_fn` | Medium; localized | **MVP** |
| Line-range replace | Easy to use incorrectly | Residual |
| AST `node_id` replace | Best precision; needs stable IDs | Residual |
| `insert_fn` / `delete_fn` | API surface changes | Later |
| `replace_file` | High risk of damage | Discouraged for agents |

Function-level changes match how agents work (for example, “fix `parse_config`”). It also matches how the `outline` command shows symbols.

### 4.3 Coupling to Observe / Orient

1. `outline` → pick name.  
2. `reflect name` → contracts/caps to preserve.  
3. Model proposes body.  
4. `patch replace_fn`.  
5. `check --json-errors` → iterate.

It is a **policy** choice to keep `requires` and `ensures` text during a replacement. We prefer to replace **only the body** when possible. This keeps the contracts checked by humans.

### 4.4 Optional `--check`

You can patch and check types in one command. This stops race conditions between tools. It also shows the correct OODA Act-to-Observe loop.

## 5. Threat / failure model

### 5.1 Mitigations (design / product)

| Threat | Control |
|--------|---------|
| Path traversal | Reject `..`; cwd confinement |
| Op smuggling | Allowlist `replace_fn` only |
| Partial write | Atomic replace |
| Accidental execution | Never run patched code in patch tool |
| Silent multi-fn damage | Single-name replace |
| Model inserts `unsafe` FFI | Not patch’s job — `check` + caps (RP-3.1, RP-6.3) |

### 5.2 Residual failures

| Failure | Notes |
|---------|-------|
| **Wrong function same name** (overloads) | Language can lack overloading; if added, it needs disambiguation |
| **Brace-balance false structure** | Textual engines can break nested forms |
| **Contract deletion** | Occurs if replacement includes signature block carelessly |
| **TOCTOU** | File changes between outline and patch |
| **Malicious body content** | The tool writes it; you must validate later with a check, test, or fuzz |

### 5.3 Explicit non-goals

`ooda patch` is **not** a general refactoring engine. It is **not** a security boundary for multi-tenant SaaS. It does **not** replace the sandbox for *running* code.

## 6. Alternatives considered

| Alternative | Why we do not use it |
|-------------|----------------------|
| **Unified diff only** | Models often make diffs that fail; we keep this for future use |
| **Whole-file write tool** | Too broad for standard agent rules |
| **Editor LSP workspace/edit** | Good for humans; not good for headless CI |
| **In-place sed from shell** | High risk of command injection |
| **Immediate full AST IR patch** | Correct for the long-term; blocked until we have stable node IDs and a pure engine |

## 7. Product reality (alpha honesty)

**PM.md `2.2b`: done** (with residuals).

| Piece | Reality |
|-------|---------|
| `replace_fn` CLI + JSON stdin | **Done** |
| Unknown op fail-closed | **Done** |
| Path safety + atomic write | **Done** (as documented) |
| Smoke rails / fixtures | **Done** |
| Line-range op | **Residual** (fail-closed / not shipped) |
| AST `node_id` path | **Residual** |
| Pure self-hosted patch engine (no Python) | Track toward pure floor; honesty per bootstrap |

**Summary:** The surgical **function** patch works. We recommend it for agent actions. We have **not** combined the full AST patching from the RP-2.1 plan into one tool yet.

## 8. Open research questions

1. Can we have **stable node IDs** across re-parses that only change whitespace?
2. **Body-only vs signature-inclusive** replacement — which keeps contracts better in real use?
3. Can we have **multi-hunk transactions** (replace two functions atomically) without whole-file writes?
4. **Patch attestation:** should we sign the agent identity and operation for audit logs?
5. **Diff user experience for humans:** should we automatically create a unified diff file for review?
6. **Interaction with macros and generated regions** (RP-1.4): should we have forbidden zones?

## 9. Acceptance criteria (for PM status promotion)

### Maintain `done`

- [x] `replace_fn` only allowlist; smokes for happy path + rejects.  
- [x] Documented security properties (no shell-eval; path rules).

### Residuals → partial/done upgrades

- [ ] Line-range op **or** explicit forever-rejected with agent guidance.  
- [ ] `node_id` replace gated on AST ID RFC.  
- [ ] Pure `.oo` implementation of patch engine on product path.  
- [ ] Corpus: N agent-repair traces with patch + json-errors loop in CI.

## 10. References

1. DESIGN.md §2; openOODA `BUILD_OUT.md` P2 (`ooda patch`), `BETA.md`, `PM.md` 2.2b.  
2. OpenAI — *Apply Patch* tool documentation (structured diffs for agents).  
3. Aider — multi-format edit system (SEARCH/REPLACE, whole-file, unified diff).  
4. Practitioner analyses: “How Agent Harnesses Edit Files”; “How AI Assistants Make Precise Edits” (Cursor, Codex, OpenHands, Claude Code comparisons).  
5. Classical APR AST mutation operators (GenProg et al.) — structural edit lineage.  
6. jscodeshift / language refactoring engines — industrial AST rewrites.  
7. RP-2.1 (Observe), RP-2.2 (Orient) — sibling papers in this series.

---

## Conflicts with other DESIGN items

| Tension | Conflict | Resolution direction |
|---------|----------|----------------------|
| **§2.2b vs §2.1 “AST patching” naming** | Product is source `replace_fn`, not AST IR | Keep IDs separate; converge only with node_id RFC |
| **Broad agent autonomy vs least-privilege tools** | Power users want `replace_file` | Default allowlist narrow; escape hatches explicit and logged |
| **Atomic patch vs hot reload (§4.2)** | Live processes may hold old AST | Patch is source-level; reload is runtime concern |
| **Patch body may call FFI** | Widens §6.3 caps-vs-FFI tension | `check` must demand `&UnsafeFFICap` etc.; patch doesn’t pre-clear |
| **Self-host purity** | Python patch engine vs pure `.oo` | Accept transitional engine; track pure rewrite |

---

*Series: [Research papers index](./README.md). Template: [TEMPLATE.md](./TEMPLATE.md). Siblings: [RP-2.1](./RP-2-1-surgical-ast-patching.md), [RP-2.2](./RP-2-2-token-minimized-apis.md).*
