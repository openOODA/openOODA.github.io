# RP-4.1.2: Production LLVM backend

| Field | Value |
|-------|--------|
| **Paper ID** | `RP-4.1.2` |
| **DESIGN.md** | Section 4 Targets — Production LLVM (`ooda build --emit-llvm`) |
| **Status** | `draft` |
| **PM.md row** | `4.1.2` (**smoke test**) |
| **Product mapping** | Textual LLVM IR output. Optional execution smoke test when `clang` or `llc` is available. This is not the production floor. |

## 1. Reason for inclusion in DESIGN.md

Section 4 of DESIGN.md states:

> **Production LLVM (`ooda build --emit-llvm`):** Compiles directly to native LLVM IR (`.ll`) to maximize CPU performance.

LLVM is an industry standard intermediate representation (IR) for systems programming languages. It provides portable optimization and code generation for multiple architectures. It removes the need to write code generators for each instruction set architecture (ISA).

In openOODA, LLVM is the primary path for production CPU targets. This path is different from the development bytecode path (Section 4.1.1) and the alpha product floor (Backend-C with `gcc`, Section 4.x).

This document explains the role of LLVM in the design. It reviews related technologies (IR, `clang`, MLIR). It also ensures that claims about alpha versions are accurate.

## 2. Problem statement

If openOODA does not include a native optimization path, these problems occur:

1. **Performance limits:** Backend-C with `gcc` is sufficient to compile the compiler itself. But the design requires CPU performance equal to C and Rust for systems software.
2. **Cross-language optimization:** Cross-language Link Time Optimization (LTO, Section 4.3.1) requires a shared LLVM IR environment with C++ and Rust.
3. **Target diversity:** A single frontend must compile to many CPUs and Operating System (OS) Application Binary Interfaces (ABIs). LLVM backends make this possible.
4. **GPU and NPU support:** Multi-Level IR (MLIR) and Graphics Processing Unit (GPU) operations usually translate into LLVM IR. A C-only foundation prevents clean integration with these tools (Section 4.1.3).

The compiler can output C code permanently. But openOODA must support multiple target architectures. It must also interact smoothly with standard native tools.

## 3. Related work

### 3.1 LLVM IR pipeline

The standard pipeline is:

```text
Frontend → LLVM IR → Optimizer (passes) → Codegen (SelectionDAG/GlobalISel) → object/asm
```

Many languages use LLVM as a primary backend. Examples include Clang (C++), Rust (`rustc`), Swift, and Julia.

LLVM IR uses Static Single Assignment (SSA). It has strong typing. It includes metadata for debugging, annotations for alias analysis, and attributes for interprocedural optimization.

### 3.2 Risks of LLVM adoption

Language developers report these common problems:

- **Host complexity:** Linking to LLVM or `clang` adds a large C++ dependency. If the compiler includes `libLLVM`, it contradicts the goal of a pure self-hosted compiler.
- **Version incompatibility:** Compatibility of IR and bitcode between major LLVM versions is difficult to maintain.
- **Abstraction loss:** LLVM IR operates at a lower level than many language IRs. You must carefully encode high-level properties (like capabilities and ownership). Otherwise, the compiler loses them.
- **Compile-time cost:** Optimization pipelines are slow. They can exceed the sub-second compile time limit if you use them for every run.

Alternative options include Cranelift, libFIRM, QBE, custom code generation, and C code generation (the alpha choice for openOODA).

### 3.3 MLIR as layered IR

Multi-Level IR (MLIR) is part of the LLVM project. It provides intermediate layers based on dialects. Projects create domain-specific dialects. Then, they translate these dialects into the `llvm` dialect (LLVM IR).

MLIR is useful because the design includes support for GPUs and NPUs (Section 4.1.3). The `gpu` dialect translates heterogeneous code cleanly. It avoids the use of custom PTX code strings.

ClangIR (CIR) uses MLIR to create a higher-level C/C++ IR. This IR sits between the Abstract Syntax Tree (AST) and LLVM IR. This shows that C-family compilers require more structure before they reach LLVM IR.

### 3.4 C code generation as an alternative backend

Many programming languages generate C code to achieve portability. The Backend-C of openOODA follows this method. It uses `.c` files as the IR and uses `gcc` or `clang` to optimize the code. This is a valid strategy.

The LLVM backend is the alternative option. You use the LLVM backend when C code generation cannot provide necessary optimization, LTO, or support for non-C targets.

## 4. Design rationale for openOODA

### 4.1 Production and development paths

| Path | Goal | Latency | Optimization |
|------|------|---------|--------------|
| Development bytecode or native run | Fast feedback | Low | Minimal |
| Backend-C product | Self-hosting, code purity | Medium | `gcc -O2` |
| **LLVM production** | Maximum CPU performance, LTO, multiple architectures | Higher compile time | Full mid-end |

LLVM must not be the only engine for the `ooda run` command. If it is, the compile time violates the fast OODA loop. Use LLVM for `build --release`, `--emit-llvm`, and profile-guided production builds.

### 4.2 Frontend neutrality (FLOOR.md)

The file `bootstrap/FLOOR.md` defines a backend as a combination of three parts: **Emit**, **Runtime ABI**, and **Link recipe**.

Backend-LLVM contains these parts:

- **Emit:** Translates checked CHS/AST into `.ll` files or bitcode.
- **Runtime:** Uses the standard Runtime ABI v0 symbols or LLVM-native equivalents.
- **Link:** Uses `llc`, `clang`, or `lld` commands to link the files.

The frontend (lexer, parser, and checker) must not use LLVM Application Programming Interfaces (APIs). This separation keeps Backend-C as pure `.oo` code and `gcc`.

### 4.3 Capability and contract translation

LLVM does not understand capability types like `&FsCap`. We have three options for translation:

1. **Remove and replace with runtime checks:** Use the same magic-token seals as Backend-C.
2. **Use annotations:** Add address-space or metadata annotations for analysis passes (currently in research).
3. **Use a separate IR:** Verify an intermediate representation before you send it to LLVM. Discharge or keep the contracts.

Do not claim that the alpha version of LLVM preserves capability mathematics.

### 4.4 Pure self-hosting vs LLVM

Product purity rules prohibit a Rust product host. They require pure `.oo` code.

A production LLVM backend can call the system tools `clang` or `llc` as external commands. This method is similar to how the system calls `gcc`. This keeps the compiler source pure, even if it relies on a C++ foundation.

The "Production LLVM" design does not require the inclusion of `libLLVM` inside `oodac` in the first version.

## 5. Threat and failure model

### Benefits

The LLVM backend prevents these problems:

- Slow execution on security-critical paths (which causes Denial of Service by latency).
- ABI fragmentation. This occurs when you mix C++ and Rust objects without a common IR for LTO.
- Dependency on `gcc` for all compilation.

### Limitations

The LLVM backend does not provide these features by itself:

- Memory safety. This requires Automatic Reference Counting (ARC), Resource Acquisition Is Initialization (RAII), and language rules.
- Capability safety. The compiler must translate the capability checks.
- Reproducible builds. This requires deterministic compilation flags (Section 4.3.2).
- Security of the `clang` supply chain.

### Failure modes

| Failure | Mitigation |
|---------|------------|
| Users confuse the smoke test with the production floor | Ensure accurate documentation in `P4_DROPS`. Maintain the PM smoke test status. |
| The `--release` flag produces an incorrect soft-pass | Use a fail-closed residual process until the real pipeline is ready. |
| Too many supported LLVM versions | Fix the tool environment in Continuous Integration (CI). Document the minimum required version. |
| The compiler loses its pure self-hosting status | Ensure the Backend-C `fixed_point` tests always pass. |

## 6. Alternatives

| Alternative | Notes | Decision |
|-------------|-------|---------|
| **Stay on Backend-C forever** | This is simple and pure. | Accept this as the product floor. It does not complete the full design. |
| **Cranelift** | This compiles faster and has a smaller size. | Consider this as a strong candidate for Phase F3. |
| **QBE or custom codegen** | This is very small. | Reject. It has limited targets and optimizations. |
| **Embed libLLVM in oodac** | This gives maximum control. | Reject. It is too large and causes problems for self-hosting. |
| **External clang only** | This operates like the `gcc` floor. | **Accept.** This is the preferred shape for the first LLVM product. |
| **MLIR-first** | This is excellent for GPU support. | Reject for now. It is too complex before the CPU Minimum Viable Product (MVP) is ready. |

## 7. Alpha product status

**PM.md task 4.1.2 is a smoke test.** The Milestone 5 (M5) LLVM status requires tests to pass and a correct tool environment.

| Claim | Actual status |
|-------|---------|
| The production LLVM backend is the optimization floor. | **False.** Backend-C is the self-hosted product floor. |
| The compiler supports `oodac emit-llvm`, `ooda build --target llvm`, and `--emit-llvm`. | **Smoke test only.** The compiler outputs textual IR. It executes a smoke test if `clang` or `llc` is available in the system PATH. |
| The `--release` flag optimizes the code. | **False.** This results in a fail-closed error on the pure CLI. |
| The compiler supports full LTO with C++ and Rust. | **Not started** (Section 4.3.1). |

Refer to these documents for authoritative project status: `ooda/bootstrap/P4_DROPS.md`, `ooda/README.md`, `FLOOR.md`, and `BACKEND_F3_PREP.md` (candidate L).

**Relationship to DESIGN "JIT" (Section 4.1.1):** LLVM Ahead-of-Time (AOT) compilation is not a development Just-In-Time (JIT) compiler. Do not describe `emit-llvm` as the development path.

## 8. Open research questions

1. Should the compiler use bitcode or textual `.ll` files to improve reproducibility and caching?
2. Which parts of the Runtime ABI translate to LLVM intrinsics, and which parts translate to `libc` calls?
3. Should the default LTO for openOODA and the C runtime be ThinLTO or full LTO?
4. What is the correct debug information strategy to support narrative diagnostics (Section 5.5)?
5. When should the compiler use MLIR instead of raw LLVM IR output?
6. How should we tier the backends? (For example, use Backend-C for the `fixed_point` compiler build, and use LLVM for user application releases).

## 9. Acceptance criteria

### From smoke test to partial status

- [ ] Document the link recipe. Show how to convert a CHS smoke test to a native executable with `clang` or `llc`.
- [ ] Create a parity test suite. Compare LLVM output against Backend-C output on a fixed set of test fixtures.
- [ ] Add a Continuous Integration (CI) job for the tool environment. (This is optional if `clang` is present in the base image).
- [ ] Add explicit documentation to state that LLVM is not the self-hosted product floor.

### From partial to done (production path)

- [ ] Users can compile applications with `ooda build --target llvm` (or an equivalent command). The project supports this profile.
- [ ] Map the optimization levels. Document the deterministic compiler flags.
- [ ] Complete the Runtime ABI coverage for the supported CHS language features.
- [ ] Update the `DESIGN.md` and `README.md` documents. Ensure they state that the LLVM backend is a production feature, not a test.

Self-hosting with LLVM is **optional**. It must not break the Backend-C `fixed_point` build.

## 10. References

1. The LLVM Compiler Infrastructure: https://llvm.org/
2. "LLVM IR Explained" and educational surveys of IR pipelines: https://www.compilersutra.com/docs/llvm/llvm_ir/intro_to_llvm_ir/
3. MLIR users and dialects: https://mlir.llvm.org/users/ and GPU dialect: https://mlir.llvm.org/docs/Dialects/GPU/
4. LangDev discussion on the risks of LLVM as infrastructure: https://langdev.stackexchange.com/questions/1824/what-are-the-pitfalls-of-using-an-existing-ir-compiler-infrastructure-like-llvm
5. openOODA documents: `DESIGN.md` Section 4; `PM.md` item 4.1.2 / M5; `bootstrap/P4_DROPS.md`; `bootstrap/FLOOR.md`; `bootstrap/BACKEND_F3_PREP.md`.

---

*Series: [Research papers index](./README.md). Related documents: [RP-4.3.1 Cross-language LTO](./RP-4-3-1-cross-language-lto.md), [RP-4.x Backend-C](./RP-4-x-backend-c-product-floor.md).*
