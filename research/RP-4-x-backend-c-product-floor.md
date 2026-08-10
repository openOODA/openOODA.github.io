# RP-4.x: Backend-C product floor

| Field | Value |
|-------|--------|
| **Paper ID** | `RP-4.x` |
| **DESIGN.md** | Section 4 Targets (This is the current product foundation. It is not a future multi-target item) |
| **Status** | `draft` |
| **PM.md row** | `4.x` (**done** at alpha) |
| **Product mapping** | `emit-c` + `runtime/chs_rt*` + **gcc** + trusted **seed** bootstrap. This is the permanent path for `ooda run`. |

## 1. Purpose of this document

Section 4 of DESIGN.md lists multiple targets: Development JIT, Production LLVM, GPU/NPU, Wasm, and bare metal. **These targets are not the current foundation for the alpha product.**

The current alpha product (version 0.183.x) uses this structure:

```text
.oo ──► oodac (lex/parse/check) ──► emit-c
                                      │
                                      ▼
                              generated .c text
                                      │
                         gcc + runtime/chs_rt*.c
                                      │
                                      ▼
                               native binary
```

This document explains why we use this C-based foundation. It shows that this choice is an engineering decision. It also shows how FLOOR.md makes sure that C remains a backend and not the final goal.

## 2. Problem statement

### 2.1 The requirement to bootstrap

A self-hosting systems language requires these items:

1. Low-level code to communicate with the operating system (syscalls, libc, or similar).
2. A compiler binary (the seed) to compile the initial stage.
3. A linker or driver that is available on most developer systems.

If openOODA does not use a basic C foundation, it must use an obsolete Rust/Cargo host or incomplete LLVM/Wasm engines. The project rules forbid the Rust/Cargo host.

### 2.2 The risk of incorrect claims about LLVM/JIT

If we say that LLVM or JIT is the foundation, these problems occur:

| Incorrect claim | Actual result |
|-----------------|---------------|
| `ooda run` uses the JIT from DESIGN | Users expect a VM but receive a gcc link |
| Production uses LLVM | The fixed_point build and the releases use Backend-C |
| There is no C in the Trusted Computing Base (TCB) | It is not possible to build native software without a basic C foundation |

Accurate documentation is a requirement. We use `PROBE`, residual documentation, and fail-closed flags to keep claims accurate.

## 3. Related work

### 3.1 Emit-C as an Intermediate Representation (IR)

Many compilers use C as a portable assembler. Examples include early language versions, academic compilers, and bootstrap stages.
* **Advantages:** Uses gcc/clang optimizers, debuggers, and sanitizers. C is available everywhere.
* **Disadvantages:** C has undefined behavior. Compilation is slower than direct assembly for small programs. It creates a risk of relying on one toolchain.

### 3.2 The use of gcc as the system compiler

The **gcc** compiler is the default C compiler on many Linux distributions. The build scripts use a simple command (`-O2 -Iruntime … -lm`). You can often use clang instead of gcc, but clang is not a requirement for Backend-C.

### 3.3 Seed bootstrap procedures

Self-hosting languages supply a seed binary. Examples include the Go bootstrap, rustc stages, and Scheme/C bootstraps. openOODA uses `bootstrap/seed`, `BOOTSTRAP_PIN`, and a release archive. The procedure is: you trust a clean product binary one time. After that, you rebuild the software with gcc. You do not use Cargo.

### 3.4 Support for multiple backends

The phases F0 through F5 in FLOOR.md are similar to industry standard pluggable backends (like LLVM targets, Cranelift, or QBE). The initial Wasm and LLVM implementations are tests. They are not the foundation.

## 4. Design rules for openOODA

### 4.1 Project constraints

These rules are from FLOOR.md and README:

* User software must use **`.oo`**.
* A small layer of C code (`chs_rt`) is permitted to connect to the OS.
* **You must not use the Rust host.**
* The seed binary must be a clean product. It must never use the Cargo-built host.

Backend-C meets these rules and makes releases possible.

### 4.2 The three parts of the backend

| Component | Current Backend-C implementation |
|-----------|----------------------------------|
| **Emit** | `oodac/c_emit_*.oo` creates C text |
| **Runtime** | `runtime/chs_rt*.c` provides Runtime ABI v0 |
| **Link** | `scripts/oodac_pure_build.sh` and the product build use **gcc** |

The frontend code must not import emit modules that belong to other backends.

### 4.3 Reasons to not wait for the target engines

| Engine | Alpha status | Reason it is not the foundation |
|--------|--------------|---------------------------------|
| Bytecode VM | Partially tested | It does not support product `run`. It is not a JIT. |
| LLVM | Initial tests | It does not support optimization or self-hosting yet. |
| Wasm | Initial tests | It requires a runtime pin. It does not support self-hosting. |
| GPU / embedded | Not started | Not applicable |

Releasing software is more important than the goal of removing all C code.

### 4.4 Relation to DESIGN Section 4

Backend-C is the default method for native execution until phase F3 is complete. The multi-target plan in DESIGN is the future roadmap. The item `4.x` in PM.md shows the actual implementation status. This prevents the research documents from making incorrect claims.

### 4.5 Limits on the C foundation

The system uses static capability checking. It also uses a process-local magic-token check in the runtime (`STATIC_CAPS.md`). It does not use cryptographic object capabilities. The interface to standard C code remains a risk (see Section 6.3). The `chs_rt` component is part of the Trusted Computing Base (TCB).

## 5. Threat and failure analysis

### 5.1 Capabilities of Backend-C

Backend-C gives you these features:

* It creates native binaries for users and for Continuous Integration (CI).
* It lets you debug the C code with gdb.
* It provides a way to build a self-hosting fixed_point release without LLVM in the compiler build.

### 5.2 Limitations of Backend-C

Backend-C does not give you these features:

* It does not provide memory safety for bugs in `chs_rt` (because it is C code).
* It does not remove the dependency on the gcc toolchain.
* It does not provide the JIT or hot-reload features from the DESIGN document.
* It does not provide cross-language Link Time Optimization (LTO) with Rust.

### 5.3 Possible failures and solutions

| Failure | Solution |
|---------|----------|
| The project relies only on C permanently | Use FLOOR F1–F3 phases and build a second minimum viable backend |
| The parser receives data about the emit phase | Enforce strict package boundaries |
| Unwanted symbols from the host remain | Use the ABI table and fail-closed tests |
| Documentation falsely claims the product has a JIT | Use this document and RP-4.1.1 Section 7 to state facts |

## 6. Alternatives considered

| Alternative | Reason for rejection at this time |
|-------------|-----------------------------------|
| **Use only LLVM** | The toolchain is large. The emit phase is incomplete. It affects the project goals. |
| **Use only Wasm** | It requires an engine. It is not good for self-hosting a native CLI. |
| **Return to the Rust host** | It breaks the B0/B1 purity rules. |
| **Write custom x86 code generation** | It requires too much work. It is not portable. |
| **Use an interpreter only** | Self-hosting is too slow. It fails to meet the DESIGN native goals. |
| **Use Backend-C as the documented foundation** | **This is the accepted alternative.** |

## 7. Current product status

**The PM.md item `4.x` is complete for the alpha phase.**

| Item | Status |
|------|--------|
| `emit-c` and multi-module pure build | **Complete** |
| `chs_rt` Runtime ABI v0 | **Complete** (residual items are in the documentation) |
| `ooda run` or `build --target c\|native` | Uses **Native Backend-C** |
| fixed_point self-host | Uses **Backend-C** |
| `--backend c` | Uses an allowlist. Other backends fail safely. |
| Seed bootstrap | **Required** for a cold start. Includes checksums. |
| Second backend | Only in preparation (`BACKEND_F3_PREP.md`) |

### 7.1 The build and execution procedure

A user installs an approved pure seed. The user runs `bootstrap_no_cargo.sh` with bash and **gcc**. This creates `oodac` and `bin/ooda`. The user then rebuilds the software from `.oo` source files. To run a program, the system compiles to C, uses gcc to compile the C code, and then runs the binary. The LLVM, Wasm, and bytecode options are only initial tests. They are not the core self-hosting mechanism. The DESIGN document describes a "Development JIT", but this feature does not exist yet. Please read RP-4.1.1 for more data.

### 7.2 References to related documents

| Document Path | Purpose |
|---------------|---------|
| `ooda/bootstrap/FLOOR.md` | Policy and phases F0 through F5 |
| `ooda/bootstrap/RUNTIME_ABI_v0.md` | Application Binary Interface |
| `ooda/bootstrap/BACKEND_F3_PREP.md` | Preparation for a second backend |
| `ooda/bootstrap/P4_DROPS.md` | Status of LLVM and Wasm |
| `ooda/bootstrap/seed/README.md` | Rules for the seed |
| `ooda/README.md` | Table of product features |

## 8. Open research questions

1. When should we upgrade Wasm or LLVM from an initial test to an optional product feature? We must do this without breaking the fixed_point build.
2. Should freestanding and embedded targets use `chs_rt`, or should they use a different ABI?
3. How can we decrease the number of lines in the C TCB while we keep the leak-safe ARC policy?
4. What are the correct deterministic gcc flags for Section 4.3.2?
5. How do we formalize the link command as data (as specified in FLOOR Section 3.4)?

## 9. Acceptance criteria

The alpha phase is **complete**. This means:

- [x] The system can self-host on Backend-C with a documented seed.
- [x] The commands `run` and `build` use a native path.
- [x] FLOOR separates Backend-C from the frontend.
- [x] Backends other than `c` stop safely if they fail.

### 9.1 Rules to keep the status as complete

- [ ] New language features must add to the **ABI table**. They must not add random C code.
- [ ] The fixed_point build must succeed on every release.
- [ ] The LLVM, Wasm, and bytecode tests must never change the behavior of the `run` command.
- [ ] The phase F3 second backend must not damage the C foundation.

### 9.2 Triggers that cancel the complete status

If these events occur, we must reopen task 4.x:

- The project uses the Cargo or Rust host again.
- The seed-to-gcc bootstrap process stops working and has no replacement.
- The README claims a different foundation, but C is still the only path to a fixed_point build.

## 10. References

1. openOODA `ooda/bootstrap/FLOOR.md` — primary policy.
2. openOODA `ooda/bootstrap/RUNTIME_ABI_v0.md`, `BACKEND_F3_PREP.md`, `P4_DROPS.md`, `seed/README.md`.
3. openOODA `ooda/README.md`, `PM.md` task `4.x`, M4/M5/M6 notes.
4. `spec/DESIGN.md` Section 4 (for contrast).
5. Historical emit-C and bootstrap procedures in programming languages.

---

## Appendix A — Text corrections for the DESIGN document

For personnel who update DESIGN, PM, or README documents:

| Text in DESIGN Section 4 | Problem | Recommended change |
|--------------------------|---------|--------------------|
| **Development JIT (`ooda run`)** | The command `ooda run` uses **native Backend-C**, not a JIT. The bytecode is an **interpreter** test. | Change to "Development bytecode interpreter (optional)". State that the product `run` is native. Move the JIT to a future release. |
| **Instant sub-millisecond … bytecode VM** | This is not applicable to self-hosting. The VM does not do the product run. | Apply this only to interactive small programs or daemon mode. |
| **Production LLVM** | This is an initial test only. | Keep the plan, but add the label "not the alpha foundation". |
| **Hot-Code Reloading via JIT VM** | This cannot happen without a product VM. | Rely on the RP-4.1.1 engine. Alternatively, specify native dlopen separately. |
| **std::os runs on LLVM/JIT** (Section 5) | The product uses Backend-C. | Change to "hosted backends (C/LLVM/JIT/…)". |
| **Section 6.1 JIT phase metamorphism** | There is no product JIT phase. | Change to "load/runtime phase". |

**Section 7 global rule for all Section 4 documents:** The product run uses Backend-C. The BC, WASM, and LLVM are initial tests. The DESIGN "JIT" is a future goal until we build it and connect it to the CLI.

---

*Series: [Research papers index](./README.md). Related documents: [RP-4.1.1](./RP-4-1-1-development-bytecode-vm.md), [RP-4.1.2](./RP-4-1-2-production-llvm.md), [RP-4.1.4](./RP-4-1-4-direct-webassembly.md).*
