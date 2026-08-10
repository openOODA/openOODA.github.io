# RP-2.3: Intent-driven compilation (telepathic AST)

| Field | Value |
|-------|--------|
| **Paper ID** | `RP-2.3` |
| **DESIGN.md** | §2 AI tooling — Intent-Driven Compilation (Telepathic AST) |
| **Status** | `draft` |
| **PM.md row** | `2.3` |
| **Product mapping** | **not-started** — contracts + blank body → LLM synthesis is vision only |

## 1. Why this is in DESIGN.md

DESIGN.md §2 states:

> **Intent-Driven Compilation (Telepathic AST):** You write the `requires` and `ensures` contracts. You leave the function body blank (`...`). During compilation, the compiler starts an embedded LLM. The LLM creates the optimal algorithm. The compiler formally verifies the algorithm. Then, the compiler lowers the algorithm to assembly code.

This is the primary AI claim in §2: **specification-as-source**. Humans or agents write the intent. The toolchain creates and checks the implementation. This changes mathematical contracts (RP-1.2) from a runtime oracle to a synthesis goal. It connects to formal verification, program synthesis, and LLM code generation.

This paper explains why we put this idea in DESIGN. It shows the danger of a naive implementation. It lists the pipeline risks. It explains why the **product status is not-started**. We must use a staged path to protect pure deterministic builds.

## 2. Problem statement

### 2.1 The implementation bottleneck

Writing correct systems code has a high cost. Writing precise contracts is also hard. But contracts are usually shorter and easier to review than implementations. The toolchain must do these steps:

1. Read `requires` and `ensures` (with types and capabilities).
2. Create a function body.
3. Verify the code with tests, fuzzing, or SMT.
4. Lower the verified code to machine code.

If the toolchain does these steps, developers can focus on intent and review. They do not write boilerplate code.

### 2.2 The blank-body user story

```text
fn clamp(x: Int, lo: Int, hi: Int) -> Int
  requires lo <= hi
  ensures result >= lo && result <= hi
  ensures result == x || result == lo || result == hi
{
  ...
}
```

Design intent: The compiler or LLM replaces `...` with a verified algorithm.

### 2.3 Users and adversaries

| Actor | Interest |
|-------|----------|
| Application developer | Speed. Correct helpers. |
| Agent author | Write contracts only. The toolchain completes the code. |
| Safety auditor | Require machine-checkable evidence. Do not trust vibes. |
| Adversary | Prompt-inject synthesis. Ship unverified code. Use non-reproducible builds as a supply-chain attack. |

### 2.4 Core hardness

Program synthesis is hard. LLMs create possible programs, but they do not prove correctness. If you do not use a verifier, "telepathic AST" is only a marketing term for unchecked code generation. This is worse than agent-written code that a human reviews in a pull request.

## 3. Related work

### 3.1 Classical program synthesis

- **Deductive synthesis** from formal specifications (early Dijkstra/Manna–Waldinger).
- **Inductive synthesis** from examples (FlashFill, SyGuS).
- **Sketching** (Solar-Lezama): Humans write partial programs. A synthesizer fills the holes.

The `...` in openOODA operates as a sketch hole. The contracts act as constraints.

### 3.2 LLM code generation

Models like Codex and Copilot generate code from natural language or signatures. Empirical studies show these problems:

- The generated code has many subtle bugs and vulnerabilities.
- The models are sensitive to prompt phrasing.
- The code lacks algorithmic correctness if you do not use tests.

### 3.3 LLM + formal verification pipelines

An emerging pattern is **generate, verify, and repair**.

- Combine LLM code generation with formal specifications. Use feedback from model checking.
- Tools like Frama-C with LLM loops send proof failures back to the model.
- Smart-contract synthesis uses formal verification.
- The synthesis community agrees: The LLM proposes the code. A classical verifier accepts or rejects it.

### 3.4 Verified compilers and proof-carrying code

- CompCert: A verified compiler for human code. It does not synthesize code.
- Proof-carrying code: You must ship verification evidence with the software artifacts.

Telepathic AST must emit a certificate (a proof, an SMT log, or a fuzz corpus hash). It must not emit only an AST.

### 3.5 Industrial “AI compile” features

Mainstream systems compilers do not use a general LLM for code generation. Current practices include:

- Generation in the IDE (like Copilot) before compilation.
- Build plugins that call cloud models. These are not reproducible.
- Research prototypes that run offline.

The DESIGN document requires an embedded LLM at compile time. This is a radical idea. It conflicts with deterministic builds (see RP-4.3.2 and §6).

## 4. Design rationale for openOODA

### 4.1 Why contracts are the right interface

openOODA already invests in `requires`/`ensures` (RP-1.2) and contract fuzzing (RP-3.6). Intent-driven compilation **reuses** that surface:

| Input | Role |
|-------|------|
| Types | Shape |
| Caps | Effect boundary |
| `requires`/`ensures` | Functional intent |
| `...` hole | Synthesis obligation |
| Tests / `verify` | Executable oracle |
| Future SMT | Proof oracle |

### 4.2 Recommended pipeline (research architecture)

```
parse → typecheck hole
     → synthesize candidates (LLM and/or enumerative)
     → filter: typecheck + cap check
     → filter: contract tests / fuzz (RP-3.6)
     → filter: optional SMT proof
     → commit body to AST or .oo sidecar
     → lower (C/LLVM/… backends)
```

Never lower a hole if you do not have an explicit policy. You must use one of these:

- The `--allow-synthesize` flag.
- A pre-synthesized body saved in the source code.
- A cache key (spec hash, model id, temperature, seed).

### 4.3 Embedding vs sidecar (critical)

| Mode | Pros | Cons |
|------|------|------|
| **Embedded in `oodac`** | Great user experience | Breaks determinism. Increases binary size. Needs network access. Violates pure floor. |
| **Sidecar `ooda synthesize`** | Clean trust boundary. Optional. | Requires an extra step. |
| **Agent-loop only** | Path exists today. | Not "compile-time telepathy". |

**Alpha recommendation:** Make telepathic AST a sidecar and verifier, not a core compiler feature. Product agents give a weaker version of this today (see RP-2.1, 2.2, 2.2b).

### 4.4 “Optimal algorithm” claim

The DESIGN document says "optimal." For research honesty, we must state:

- You must optimize for verified correctness first.
- Performance optimality is secondary. Do not block version 1 for performance.
- You must prefer readable code for human audits.

### 4.5 Capability purity

Synthesized code must not get capabilities for free:

- If a signature does not have `&NetCap`, the synthesizer must not emit network calls.
- The capability inference works backwards: The signature is the maximum effect envelope. The synthesizer must stay in that envelope (this connects to RP-3.1).

## 5. Threat / failure model

### 5.1 Pipeline risks (primary contribution of this paper)

| Risk | Severity | Mitigation |
|------|----------|------------|
| **Unverified accept** | Critical | Fail closed if there are no tests or proofs. |
| **False "verified" label** | Critical | Use certificates. Separate a fuzz-pass from a proof. |
| **Non-reproducible builds** | High | Cache the synthesized source. Pin the model. Use an offline mode. |
| **Supply-chain model poisoning** | High | Use local weights. Use hash pins. Do not use silent cloud connections. |
| **Prompt injection via comments/specs** | High | Sandbox the specifications. Do not let the synthesizer read ambient files. |
| **Spec gaming** | Medium | Weak `ensures` cause trivial code. Use linters to find vacuous contracts. |
| **Resource exhaustion** | Medium | Set time and token budgets. Set `MaxCycles` on the fuzz harness. |
| **IP / licensing of model output** | Medium | Create a policy. Use local models. |
| **Capability laundering** | High | Do a static cap check on the candidate AST. |
| **Secret leakage into model context** | High | Never send `#[Secret]` sources to the cloud (RP-3.5). |

### 5.2 What success would prevent

- Boilerplate bugs in small pure functions.
- Drift between comments and code. The specification becomes the code.
- Agents writing code that fails the contracts.

### 5.3 What it will not prevent

- Incorrect specifications (garbage-in).
- Incomplete specifications (the code passes `ensures` but fails unstated intent).
- Side-channel or constant-time requirements, if they are not explicit.
- The need for human systems engineers to write novel algorithms.

## 6. Alternatives considered

| Alternative | Role |
|-------------|------|
| **Human writes body, contracts check only** | The current path (RP-1.2 and RP-3.6). Ship this first. |
| **Agent synthesizes via patch tools** | The current alpha telepathy. It has no compiler magic. |
| **Example-guided synthesis only** | Uses easier oracles, but is weaker than contracts. |
| **SMT-only synthesis (no LLM)** | Strong for narrow domains. Incomplete for general code. |
| **Natural language comments as intent** | Ambiguous. We prefer structured contracts. |
| **Always-on cloud LLM in CI** | Reject this as the default to protect reproducibility and privacy. |

## 7. Product reality (alpha honesty)

**PM.md `2.3`: not-started.**

| Piece | Reality |
|-------|---------|
| Blank body `...` syntax as synthesis hole | Not-started (or not in product). |
| Embedded LLM in compiler | Not-started (correctly delayed). |
| Formal verification pipeline for synthesized code | Not-started (SMT is not a product yet). |
| Related building blocks | Partial elsewhere: contract syntax exists. Integer-domain fuzz is partial (RP-3.6). The agent loop (RP-2.1, 2.2, 2.2b) is mostly done. |

**Honest summary:** Telepathic AST is a research goal. Alpha provides a manual or agent-based synthesis loop. This loop runs outside the compiler using `patch` and `check` or `fuzz`. Do not say that compile-time LLM generation is complete.

## 8. Open research questions

1. What is the minimal certificate for "verified synthesis" in openOODA (fuzz corpus, SMT proof, or both)?
2. How should we design hole syntax for partial sketches (some human lines, some `...`)?
3. How do we do model selection (local small models vs. large cloud models)? How do we balance quality and purity?
4. What is the cache topology? Can we use a global content-addressed synthesis cache without breaking privacy?
5. How can we do vacuous contract detection before we waste time on synthesis?
6. How does synthesis interact with type-state (RP-1.5) and SoA (RP-1.3)? What is the synthesizable subset?
7. Can we build a benchmark suite of contract-only tasks with hidden reference implementations?

## 9. Acceptance criteria (for PM status promotion)

### not-started → smoke

- [ ] Document the `ooda synthesize` sidecar filling one pure `Int` function from contracts.
- [ ] The compiler must fail closed if you do not use `--allow-synthesize`.
- [ ] Re-check and contract tests must pass, or the tool must discard the candidate.
- [ ] The tool must output a written body or a rejected error. It must not skip silently.

### smoke → partial

- [ ] Enforce the capability envelope on candidates.
- [ ] Ensure a deterministic cache. The same specification hash must produce the same body when the cache hits.
- [ ] Ensure the CI process runs offline. It must use cached fixtures and require no live network.

### partial → done (aggressive)

- [ ] Support multi-type synthesis, not just `Int`.
- [ ] Provide an optional SMT path for a documented fragment.
- [ ] Write an explicit non-claim: The tool does not guarantee performance "optimality".

## 10. References

1. DESIGN.md §2 — Intent-Driven Compilation (Telepathic AST); §1 Mathematical Contracts.  
2. openOODA `PM.md` 2.3; RP-1.2, RP-3.6, RP-2.1/2.2/2.2b sibling papers.  
3. Solar-Lezama, A. — Program sketching.  
4. SyGuS / syntax-guided synthesis competition literature.  
5. Chen et al. — Evaluating large language models trained on code (Codex / HumanEval line).  
6. Fan et al. — Automated repair of LLM-generated programs (ICSE 2023).  
7. Works combining LLM codegen with formal verification / Frama-C-style feedback loops (e.g. Vecogen and related 2024–2025 studies).  
8. Surveys on verified code generation and multi-agent LLM + verifier pipelines.  
9. CompCert — verified compilation (contrast class).  
10. GitHub Copilot / commercial NL-to-code — non-verified synthesis baseline.  
11. RP-4.3.2 / DESIGN §6 — deterministic reproducible builds (tension).

---

## Conflicts with other DESIGN items

| Tension | Conflict | Resolution direction |
|---------|----------|----------------------|
| **Telepathic AST vs deterministic builds (§4.3.2, §6)** | LLM sampling breaks byte-identical builds. | Synthesize to source in a cached, pinned step. Pure compilation hashes only committed bodies. |
| **Embedded LLM vs self-hosted pure floor (§5.1, §5.1a)** | Model runtimes are not pure `.oo`. | Use a sidecar or optional feature. Never block `oodac check` on the model. |
| **Synthesis vs capability purity (§3.1)** | The model can emit I/O. | Use a hard capability envelope from the signature. Reject bad candidates statically. |
| **"Formally verifies" vs fuzz-only reality (§3.6)** | This is a marketing overclaim. | Label the stages clearly: `fuzz-closed` is not `proof-closed`. |
| **§2.3 vs agent loop §2.1–2.2b** | This creates duplicate synthesis paths. | Agents are a temporary solution. The compiler hole will eventually use the same verifiers. |
| **Blank body vs narrative diagnostics (§5.5)** | Failure "could not synthesize" requires useful stories. | Use structured codes for classes of synthesis failure. |
| **Global hive fuzz (§2.4) and synthesis** | An overnight search can fill holes. | Require user opt-in. Never change main without a human review (HITL §5.6). |

---

*Series: [Research papers index](./README.md). Template: [TEMPLATE.md](./TEMPLATE.md).*
