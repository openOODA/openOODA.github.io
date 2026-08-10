# RP-ES.4: Sub-second development feedback

| Field | Value |
|-------|--------|
| **Paper ID** | `RP-ES.4` |
| **DESIGN.md** | Executive Summary |
| **Status** | `draft` |
| **PM.md row** | `ES.4` |
| **Product mapping** | **partial** — product loops operate correctly. The project does not claim sub-millisecond performance for marketing. |

## 1. Reason for this document

The Executive Summary designs OODA to give **sub-second development feedback**. Section 1 of the DESIGN document connects this to the project philosophy. The language gives fast feedback between human intent, AI generation, and compiler validation. It does this with sub-millisecond compile times and JSON metadata.

Section 4 of the DESIGN document specifies a **Development JIT or bytecode VM** (`ooda run`). This virtual machine gives fast edit and test loops. For production, the system uses LLVM for maximum performance. Section 5.7 specifies that the compiler operates as a background LSP daemon. This daemon gives sub-millisecond feedback in the IDE.

This paper gives the reason for the Executive Summary item. Feedback latency is the **period of the OODA control loop**. The AI-native tooling (ES.1) and self-testing (ES.3) must have sub-second feedback to operate at interactive speeds.

## 2. Problem statement

### 2.1 Latency stops iteration

Wait time decreases developer productivity. Long builds cause developers to do work in batches. AI agents increase the problem because they do many compile and test cycles in one minute.

If each agent fix takes 10 or more seconds:

- Humans stop their work or do tasks in batches.
- Agents fail or stop the task before it is complete.
- Self-testing fuzz only operates in continuous integration (CI). It cannot operate in the local development loop.

### 2.2 Conflicting goals

| Goal | Effect on latency |
|------|---------------------|
| Full program optimization (LTO) | Slow |
| Whole-crate monomorphization | Slow |
| Formal verification | Slow |
| Interactive diagnose and patch | Must be fast |
| Production native speed | Build time can be slow |

A systems language must have optimization for release builds. But if it only has this, AI tools cannot use it well. If a language only uses an interpreter, it is not a systems language. Because of this, the design uses a dual-engine architecture.

### 2.3 Users

| User | Latency target |
|-------|-------------------------|
| Human in editor (LSP) | The target is sub-second diagnostics. The design goal is sub-millisecond. |
| AI agent loop | Sub-second for each check and patch cycle. |
| CI release build | Minutes are acceptable if the build is reproducible. |
| Fuzz overnight | High throughput is more important than low latency. |

## 3. Related work

### 3.1 Incremental compilation and analysis

- **Incremental compilers** compile only changed parts. Almost all production toolchains use this method (examples: Java, Kotlin, Rust, .NET RyuJIT). 
- **Zig** has goals for incremental compilation. These goals make builds deterministic and consistent with full builds.
- **Rust compile times** are long. Developers often use `check` or `clippy` for faster development loops instead of a full `build`.

### 3.2 Multi-tier execution

- **JVM, V8, HHVM, and PyPy** interpret or compile code first. They optimize the frequently used code later.
- **SPEC dual-engine pattern** for OODA uses a development interpreter or JIT. It uses production LLVM for maximum performance.

### 3.3 Developer experience metrics

- Industry guidelines recommend that you optimize **incremental** and **check** builds differently than release builds.
- AI studies show that fast tools give better results because agents do many continuous compiles.

## 4. Design reasons for openOODA

### 4.1 Architecture with multiple engines

| Mode | Design intent | Role |
|------|---------------|------|
| `ooda run` or dev VM | Instant bytecode or JIT | Inner development loop |
| Backend-C product floor | Real alpha path that uses `emit-c` and GCC | What the software uses today |
| LLVM production | Maximum native performance | Outer release loop |
| WASM or embedded | Different targets | ES.6 scale |

Hot-code reloading and the LSP daemon give sub-second feedback. You can edit the code and you do not need to restart the program.

### 4.2 The meaning of "sub-second" for openOODA

The DESIGN document sometimes uses the word **sub-millisecond**. But Product Management (PM.md) does not claim sub-millisecond performance for the alpha version. The rules for this paper are:

- **Goal:** Interactive feedback must target **sub-second** speed for typical edits on the check and run paths.
- **Future design:** Sub-millisecond speed for incremental checks on small edits.
- **Excluded goals:** The project does not need to show that LLVM release builds are sub-second.

### 4.3 Interaction with other parts

- **ES.1:** Outline, reflect, and patch operations decrease work for each cycle. A fast check increases their value.
- **ES.3:** Fuzz testing operates in the outer loop. Verification must operate in the fast inner loop.
- **ES.2:** Capability checks must operate in the fast loop. They must not be a slow, optional tool.

## 5. Risks and failure models

### 5.1 Problems that the design prevents

- Developers do not lose their focus during compile times.
- Agents do not stop or abandon their tasks.
- Developers do not skip local tests.

### 5.2 Problems that the design does not prevent

- Algorithm errors that have no relation to tool speed.
- **Slow tests** that use too much time, even if the compile is fast.
- Distributed fuzz testing latency (this operates overnight).
- Network latency to remote LLM services.

### 5.3 Failure modes

- The project claims sub-millisecond performance, but does not use measurement tools.
- The fast path uses different language rules than the production path.
- The system skips capability checks on the fast path to increase speed. This causes security problems.

## 6. Alternative options

| Alternative | Reason it is not sufficient |
|-------------|------------------|
| **Single slow optimizing compiler** | It breaks AI and human interactive loops. |
| **Language that only uses an interpreter** | It fails the system and native goals. |
| **A system that only operates in an IDE** | CLI agents and CI are slow. It forces users to use one editor. |
| **Cache all data and ignore correctness** | Old incremental errors are worse than slow clean builds. |
| **Only use a remote build system** | The offline and embedded functions become worse. |

## 7. Product reality for the alpha version

**PM.md — Sub-second feedback is `partial`.** Note: Product loops operate correctly. The project does not claim sub-millisecond performance.

| Design component | Alpha status |
|--------------|-------|
| Product `ooda` check, build, and run loops | **Real** on the Backend-C floor |
| Development bytecode VM or JIT | **Partial** - The interpreter operates, but the product `run` is native Backend-C. |
| LLVM | **Smoke test only** if the toolchain is installed. |
| WASM | **Smoke test only** if wasmtime is installed. |
| Hot reload and universal LSP daemon | **Not started** |
| Sub-millisecond guarantee | **Not claimed**. Do not use for marketing. |

**Summary:** The alpha version gives **interactive product loops** with the compiler and the C backend. It does not use the JIT and LSP daemon from the DESIGN document. You must measure performance for each release. Do not copy performance claims from the DESIGN document.

## 8. Open research questions

1. What measurement tools will verify latency claims?
2. How does the **incremental AST** interact with pure self-host and seed reproducibility?
3. Can Backend-C stay as the product floor while a bytecode `run` is the default inner loop, without language rule differences?
4. How do **contract fuzz iterations** connect to sub-second targets?
5. What daemon architecture shares analysis between the CLI and the LSP to prevent double memory use?

## 9. Acceptance criteria

### Conditions to keep `partial` status

- [ ] Add documents for p50 and p95 latency for `check` and `run` on a static test corpus.
- [ ] Make a public statement: sub-millisecond is a design goal. It is not a product guarantee.

### Conditions to increase from `partial` status

- [ ] Make an incremental path or daemon path with a measured speed increase on multi-file edits.
- [ ] Add tests to make sure development rules and production rules are the same.

### Conditions for `done` status

- [ ] Measure sub-second p95 times for specified interactive workflows on standard hardware.
- [ ] Add approved text in the release notes.
- [ ] Put residual items (hot reload, full JIT) outside of the "done" category, or complete them.

## 10. References

1. openOODA, *DESIGN.md* Section 1 Philosophy of Speed; Section 4 Multi-Target Engine; Section 5.7 Universal Native LSP.
2. openOODA, *SPEC.md* — Dual-Engine Execution.
3. openOODA, *PM.md* — ES Sub-second feedback; rows 4.1.1–4.1.2, 4.x.
4. J. Smits, G. Konat, E. Visser, “Constructing Hybrid Incremental Compilers for Cross-Module Extensibility,” arXiv:2002.06183.
5. LangDev discussion: techniques for fine-grained incremental compilation.
6. Zig community: comptime and incremental compilation design threads.
7. S. Peng et al., Copilot productivity study — arXiv:2302.06590.
8. Related documents: RP-1.1, RP-4.1.1, RP-4.1.2, RP-4.2, RP-5.7, RP-ES.1.

---

## Conflicts with other DESIGN items

- **Section 2.3 Intent-driven embedded LLM compile:** Network communication or large-model synthesis stops interactive performance. This must be an asynchronous or optional process. It must not operate on the default check path.
- **Section 3.9–3.11 Heavy integrity procedures:** Cryptographic operations, shadow-state, and metamorphic mutation add process overhead. The system must turn them off during development. They are optional for release builds.
- **Section 4.3.1 Cross-language LTO:** Full LTO prevents fine-grained incremental builds. Use it in release profiles only.

---

*Series: [Research papers index](./README.md). Template: [TEMPLATE.md](./TEMPLATE.md).*
