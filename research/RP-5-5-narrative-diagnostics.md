# RP-5.5: Narrative diagnostics

| Field | Value |
|-------|--------|
| **Paper ID** | `RP-5.5` |
| **DESIGN.md** | Section 5 Ecosystem |
| **Status** | `draft` |
| **PM.md row** | `5.5` |
| **Product mapping** | **not-started** (Stable codes and JSON exist. Causal narratives do not exist.) |

## 1. Why this is in DESIGN.md

DESIGN.md Section 5:

> When a violation of a contract or capability occurs, the compiler does not only send a stack trace. It makes a causal story. This story traces the data flow from its origin to the violation. This makes complex system bugs easy to read and understand.

openOODA uses artificial intelligence (AI). Humans and AI agents must understand failures quickly to complete the OODA loop. Capability and contract bugs are not local. The missing `&FsCap` can be three frames higher in the call stack. A contract breach can start at a bad data source. A short error message without data history wastes tokens and human attention.

Narrative diagnostics help the developer experience. They work with syntax tree patching (RP-2.1) and token-minimized application programming interfaces (APIs) (RP-2.2). Together they make a closed loop: explain, fix, and verify.

## 2. Problem statement

### 2.1 Failure of classical diagnostics

| Style | Example | Failure |
|-------|---------|---------|
| Opaque codes | `error: E0308` without a story | Novices and agents fail to fix the error |
| Local only | "Type mismatch here" | Does not explain why the value is wrong |
| Stack dump | Runtime panic backtrace | Gives no data history. Does not work for static capabilities |
| Flood | 200 template errors | Gives too much information to the user |

### 2.2 openOODA-specific diagnostics

1. **Capability violations**: Authority is missing, moved, or decreased.
2. **Contract violations**: Static or dynamic `requires` and `ensures` fail.
3. **Taint and secret flow** (RP-3.5): Data moves from a secret to a public sink.
4. **Concurrency moves** (RP-5.3): The program uses a capability after it sends the capability.
5. **Package trust** (RP-5.2): The package manifest does not match the package body.

### 2.3 Dual audience

| Audience | Needs |
|----------|-------|
| Human | A short and readable causal story that tells them what to do |
| Agent | A stable `code`, code spans, a structured flow graph, and a `fix_hint` |
| CI | Exit codes and stable hashes of diagnostic data |

## 3. Related work

### 3.1 University research

- **Compiler error message research**: Research shows that error messages use too much jargon. They do not give the next steps. They do not find the true cause of the error.
- **Explanation and slicing**: Program slicing and dependence graphs give a causal structure. They explain why a value is wrong.
- **Counterexample-guided explanations**: Research compilers use these in model checking and type error slicing.
- **Provenance and taint analysis**: Security tools use this to track data flow.

### 3.2 Industrial exemplars

| System | Contribution |
|--------|--------------|
| **Elm** | Explains errors, shows code, and gives fixes. This is a very high standard. |
| **Rustc** | Uses multi-span labels, structured suggestions, and JSON diagnostics. |
| **TypeScript** | Gives actionable errors and integrates with language services. |
| **Clang and GCC** | Uses notes and carets. Does not tell semantic stories well. |
| **Flow and Pyre** | Gives type error traces across multiple steps. |
| **Sentry** | Shows runtime error chains. Does not operate at compile-time. |

**Elm lesson:** Make the user experience of errors a primary product feature.
**Rust lesson:** Multi-span labels and primary or secondary labels make a short narrative. Machine-readable JSON lets other tools operate.
**Research lesson:** Causality requires dependence data, not only better text strings.

### 3.3 openOODA today

The file `bootstrap/DIAG_CODES.md` defines stable error codes (`E_CAP`, `E_TC`), the JSON format, and `fix_hint`. This helps route the agent. It does not give a causal story of data flow from the origin to the violation.

## 4. Design rationale for openOODA

### 4.1 The definition of a narrative diagnostic

A narrative diagnostic contains these items:

1. **Primary span**: The location where the compiler finds the violation.
2. **Origin span**: The location where the bad value or authority starts.
3. **Path**: The ordered sequence of steps between the origin and the violation.
4. **Rule**: The rule that fails.
5. **Remediation**: Text for humans and a `fix_hint` for agents.
6. **Stable code**: A code to branch logic (for example, `E_CAP_FLOW`).

Human rendering example (illustrative):

```text
capability error [E_CAP]: `read_file` requires `&FsCap`

  --> src/main.oo:42:11
   |
42 |     read_file(path)
   |     ^^^^^^^^^ call needs FsCap

origin: `main` does not have FsCap
  --> src/main.oo:10:1
   |
10 | fn main() {
   |    ^^^^ missing capability parameter

story: call chain main → load_config → read_file
hint: add `fs: &FsCap` to `main` and pass it through `load_config`
```

### 4.2 Agent output format

The JSON output must add these optional fields:

```json
{
  "code": "E_CAP",
  "msg": "…",
  "path": "src/main.oo",
  "line": 42,
  "col": 11,
  "fix_hint": "…",
  "story": {
    "rule": "cap_required",
    "hops": [
      {"path": "src/main.oo", "line": 10, "role": "origin"},
      {"path": "src/main.oo", "line": 30, "role": "forward"},
      {"path": "src/main.oo", "line": 42, "role": "sink"}
    ]
  }
}
```

Agents use data hops more easily than text. Humans use text made from data hops more easily.

### 4.3 Implementation strategy

| Phase | Mechanism |
|-------|-----------|
| A | Improve multi-span messages for capabilities. |
| B | Make simple definition-use chains for capability values and contract values. |
| C | Make data provenance for `#[Secret]` and contract predicates. |
| D | Make runtime contract narratives with a recorded trail. |

Do not wait for full provenance graphs before you release Phase A and Phase B.

### 4.4 Operation speed

Narratives must operate very fast for interactive checks. Full program slicing on every error takes too much time. You must calculate data chains on demand for the reported errors only.

## 5. Threat / failure model

### Events that this design prevents

- Agents make bad repairs because they only see the error location.
- Humans do not understand capability parameters.
- Many secondary errors show without a root cause.

### Events that this design does not prevent

- The compiler makes incorrect narratives because of bugs. This gives false confidence.
- Malicious diagnostic strings cause social engineering. You must treat the message string as data.
- The compiler cannot explain all errors fully.

### Failure modes

| Mode | Mitigation |
|------|------------|
| Text is too long | Use a maximum number of data hops. Remove extra hops and write "plus more". |
| Text changes too often | Use stable codes and data hops. The text is only a display view. |
| The origin is incorrect | It is better to write "unknown origin" than to give incorrect data. |
| Secret data leaks in stories | Remove secret values from the output. Show only the data shapes (RP-3.5). |

## 6. Alternatives considered

| Alternative | Verdict |
|-------------|---------|
| **Codes only** | This is not enough for humans. Agents also need data hops. |
| **LLM-generated explanations** | These are useful as a secondary tool. Do not use them as the source of truth because they can hallucinate. |
| **Always do a full program slice** | This takes too much time for our speed goals. |
| **IDE-only visualizations** | The design must operate in the command line interface first so that agents can use it. |
| **Stack traces alone** | These only operate at runtime. They do not find static capabilities. |

## 7. Product status

Refer to the monorepo file **PM.md**, row `5.5`. The status is **not-started**.

| Capability | State |
|------------|-------|
| Human text output | Available |
| JSON diagnostics and codes | Available (`DIAG_CODES.md`) |
| `fix_hint` | Available, but limited |
| Multi-span causal stories | **Not started** |
| Data-flow provenance | **Not started** |
| Contract violation narratives | Available only with the contracts |

Do **not** say that you have narrative diagnostics if you only have JSON errors.

## 8. Open research questions

1. What maximum number of data hops keeps the check time below one second for large packages?
2. How can we share the intermediate representation for narratives between the compiler and the language server?
3. How can we explain proof failures without showing raw solver data?
4. Can we make stories differential (for example, "this passed until you made this edit")?
5. Should we translate narratives for humans into different languages, but keep agent codes stable in English?
6. How do we evaluate this feature? We can use human studies and measure the agent repair success rate.

## 9. Acceptance criteria

### Move from not-started to smoke

- [ ] Minimum one `E_CAP` path shows two or more code spans in the text and JSON outputs.
- [ ] You document the `story.hops` JSON schema.

### Move from smoke to partial

- [ ] Capability chains move across two or more function calls.
- [ ] Contract `requires` failures point to the predicate and the call site.
- [ ] You write snapshot tests for narrative data.

### Move from partial to done

- [ ] You build data provenance for capabilities, contracts, and secrets. You remove actual secret values.
- [ ] You document the performance budget. Continuous integration tests check the budget.
- [ ] The agent repair success rate improves when you compare it to the single-span baseline.
- [ ] You write documentation with examples to prove the causal story claim.

## 10. References

1. B. A. Becker et al., "Compiler Error Messages Considered Unhelpful," ITiCSE 2019.
2. Elm, "Compiler Errors for Humans," elm-lang.org, 2015.
3. Rustc error API and diagnostic structures.
4. M. Weiser, program slicing. Horwitz et al., dependence graphs.
5. CHI papers on programming error messages for novices.
6. openOODA `DIAG_CODES.md`, RP-2.1, RP-2.2, RP-3.1, RP-3.5, RP-5.7.

---

*Series: [Research papers index](./README.md). Template: [TEMPLATE.md](./TEMPLATE.md).*
