# RP-5.1a: Pure product compiler + CLI

| Field | Value |
|-------|--------|
| **Paper ID** | `RP-5.1a` |
| **DESIGN.md** | §5 Ecosystem (product floor under 5.1) |
| **Status** | `draft` |
| **PM.md row** | `5.1a` |
| **Product mapping** | **done (alpha)** — seed + gcc; zero product `.rs` |

## 1. Why this is in DESIGN.md

DESIGN.md requires a self-hosted ecosystem. The software industry shows that compiler self-hosting is the best first step. Go, Rust, OCaml, and Chicken compile themselves after an initial bootstrap step. The product rules of openOODA (`FLOOR.md`) are more strict:

- All user software must be in `.oo`.
- You must not use a Rust product host.
- A thin OS layer (C runtime, gcc/clang link) is the only approved base. It is not a second language for the compiler frontend.

Item 5.1a lets the PM mark the pure product compiler and CLI as "done (alpha)". This does not incorrectly claim full ecosystem purity (5.1). This item shows that openOODA is not only a research tool on a Rust host.

## 2. Problem statement

### 2.1 Historical trap

Many language projects deliver these items:

1. A fast host compiler written in C++ or Rust.
2. A slow or incomplete self-host compiler for the future.
3. Tools that only use the host language.

This sequence breaks the capability model of openOODA. The commands that agents use (`ooda check|build|run|test|outline|reflect|patch`) would operate outside the `.oo` capability and diagnostic rules.

### 2.2 Bootstrap reality

You cannot have true purity from zero on a standard OS. Every self-hosting language uses a trusted seed:

| Language | Seed / bootstrap | Self-host form |
|----------|------------------|----------------|
| **Go** | Previous Go binary | Compiler in Go |
| **Rust** | Stage0 (was OCaml, now previous rustc). Tests: mrustc, Dozer (C) | rustc in Rust |
| **OCaml** | Binary bootstrap. Test source (camlboot) | Compiler in OCaml. Runtime in C |
| **Chicken** | Bootstrap chicken to C | Scheme compiler |

The model for openOODA is: a pinned pure seed `oodac`, Backend-C, and gcc. All product sources must be `.oo`.

### 2.3 What "pure product" means

| In scope | Out of scope (allowed residual) |
|----------|---------------------------------|
| `oodac/**/*.oo` | `runtime/chs_rt*.c` |
| `cli/main.oo`, product CLI | CI shell/Python scripts |
| Emitters in `.oo` that print C | External `gcc`/`clang` |
| No product Cargo / `.rs` files | Bootstrap seed binary data |

## 3. Related work

### 3.1 University and classic bootstrap theory

- **Bootstrapping** (Wirth, early Pascal/P-code stories, modern surveys): Write language L in language L after you build an initial compiler in language L₀.
- **Trusting Trust** (Thompson, 1984): A self-host design improves elegance but can hide bad code. Purity does not prove security. You must use reproducible builds, different compilers, and checksum pins.
- **Reproducible builds research** (Debian Reproducible Builds, academic papers): Bit-identical outputs stop the "which seed did you use?" problem (this connects to RP-4.3.2).

### 3.2 Commercial and open-source compilers

**Go.** After an initial C bootstrap, developers maintain the Go compiler and runtime in Go. The bootstrap process still uses a previous toolchain. Lesson: You must document the seed. Do not claim zero trust surface.

**Rust.** rustc is a self-hosted compiler but it uses LLVM (C++). The bootstrap process has multiple stages. Alternative frontends (mrustc, Dozer) exist because the goal is to release software, not to make the full stack pure. The openOODA equivalent to LLVM is Backend-C for the alpha phase (RP-4.x). It does not mean "no C code ever".

**OCaml.** It has a self-hosted compiler, a C runtime, and a bytecode VM for portability. Reproducibility discussions on discuss.ocaml.org show the differences between a binary bootstrap and a long source bootstrap. This is the same as the openOODA choice between seed pins and a full system rebuild.

**Chicken Scheme.** It compiles Scheme code to C code and self-hosts. This is very similar to the Backend-C base of openOODA: high-level language to C text to system C compiler.

### 3.3 Distilled lessons

1. You must self-host the frontend and the product CLI first.
2. You must keep a versioned runtime ABI (openOODA uses `RUNTIME_ABI_v0`).
3. You must pin seed hashes. Do not use an unapproved host as a seed (`seed/README.md` says: never use a Cargo-built host).
4. You must keep product purity separate from CI convenience scripts.

## 4. Design rules for openOODA

### 4.1 Constitution

From `ooda/bootstrap/FLOOR.md`:

> Constitution: User software stays `.oo`. A thin OS layer is approved. **A Rust product host is not approved.**

Item 5.1a is the test for this rule on the compiler and the CLI.

### 4.2 Architecture (alpha)

```text
.oo sources
   │
   ▼
seed oodac (pure binary pin)
   │  lex / parse / check / emit-c  (all .oo logic)
   ▼
generated .c + chs_rt*.c
   │
   ▼
gcc/clang → new oodac / ooda
```

The CLI (`cli/main.oo`) is pure `.oo`. Some subcommands use shell scripts to start tasks. This is a technical remainder. It is not a second product language.

### 4.3 Why Backend-C agrees with a "pure product"

Purity shows who writes the product logic. Purity does not mean that native code is absent. Chicken, Nim, and early many-to-C languages use this same sequence. Future FLOOR backends (LLVM, WASM) must not add a Rust product host again. They can still use C or LLVM as their base.

### 4.4 Fixed-point rule

Self-host approval usually needs these steps:

1. The seed builds the source tree to make `oodac₁`.
2. `oodac₁` builds the source tree to make `oodac₂`.
3. Use hash parity or behavior parity (`fixed_point` or `chs_parity` scripts).

The alpha phase provides working pure multi-stage product sequences. It does not provide cryptographic proof that the bootstrap is safe.

## 5. Threat / failure model

### 5.1 What this prevents

- A permanent change to a Rust/Cargo product compiler.
- Agents that use host CLIs (without capabilities) for core check, build, or run steps.
- Dual implementations that you cannot review (features only in the host).

### 5.2 What this does not prevent

- A bad or incorrect seed binary. Checksums stop accidental wrong seeds, but they do not remove the Trusted Computing Base (TCB).
- Errors in the C runtime or the system linker.
- Shell code in the CLI dispatch steps (`product_sh.oo` pattern).
- Missing language features (alpha is not equal to DESIGN complete).

### 5.3 Failure modes

| Failure | Solution |
|---------|----------|
| Seed comes from a Cargo host | Policy and `bootstrap_no_cargo` scripts |
| Python scripts change the pure C output | Technical debt (`DEBT_HANDOFF.md`) and a plan for a pure rewrite |
| Concurrent pure builds cause a race condition | Documented agent safety procedures in SPRINT/DEBT |
| False claims of "no C" | FLOOR honesty and RP-4.x |

## 6. Alternatives considered

| Alternative | Decision |
|-------------|----------|
| Use a Rust host permanently | **Rejected.** Disagrees with the constitution and capability model. |
| Use only a pure interpreter (no native code) | **Rejected** for the production sequence. The optional VM is separate (4.1.1). |
| Use an LLVM-only product without C | **Deferred.** A basic test exists, but C is the alpha base. |
| Do a full source bootstrap from Scheme/C (like camlboot) | **Research optional.** A pinned seed is the alpha strategy. |
| Keep a dual host and a pure host permanently | **Rejected.** This causes maintenance problems and security risks. |

## 7. Product reality (alpha honesty)

In the monorepo **PM.md** row `5.1a`, the status is: **done (alpha)**.

| Claim | Reality |
|-------|---------|
| Product compiler is in `.oo` | Yes (`oodac/`) |
| Product CLI is in `.oo` | Yes (`cli/main.oo` with v0.183.0-alpha strings) |
| Zero product `.rs` files | Yes (script `RS_COUNT=0` is active. No Cargo product sequence) |
| Uses Seed + gcc | Yes (`bootstrap/seed` and Backend-C) |
| Full DESIGN language available | **No** (Many DESIGN items are missing) |
| No shell code used anywhere | **No** (Uses CI scripts. Uses some CLI dispatch scripts) |
| Full ecosystem (pkg/LSP/registry) is ready | **No** (Read RP-5.1) |

You can change the document status from `draft` to `done` when engineering finishes. But do not use `accepted` until you write the shell dispatch policy and you remove Python scripts from the self-host sequence (or you put them in the TCB list).

## 8. Open research questions

1. When do you need a multi-stage binary hash fixed-point instead of behavior parity for alpha or beta releases?
2. Can you move the C output scripts fully into pure `.oo` without stopping the ARC memory release?
3. How small can you make the C runtime if you must keep the sealed I/O security tokens?
4. Must the seed support multiple architectures at the start of beta, or can you pin x86_64 first?
5. How do you add diverse double-compilation without a second language version?

## 9. Acceptance criteria (for PM status upgrade)

### 9.1 Current (done alpha) — already met

- [x] The `oodac` product sources are `.oo` (not Rust).
- [x] The `ooda` product CLI is `.oo`.
- [x] The team uses a documented seed selection and checksum procedure.
- [x] The CI scripts prove that there is no Cargo product host.

### 9.2 Upgrade to beta-ready

- [ ] The pure build sequence has no Python scripts. (Alternatively, list them in the TCB with a removal date).
- [ ] CLI subcommands for check, build, run, and test do not use shell scripts if a pure sequence exists.
- [ ] The `RELEASE_CHECKLIST` contains a published multi-stage parity procedure.
- [ ] All FLOOR backend tests pass.

## 10. References

1. K. Thompson, "Reflections on Trusting Trust", *CACM*, 1984.
2. N. Wirth, compiler construction texts on the bootstrap method.
3. Go bootstrap documents. Russ Cox texts on the Go toolchain.
4. Rust bootstrap guides. mrustc. Dozer (pure C Rust compiler tests).
5. OCaml compiler bootstrap. The camlboot project discussions.
6. Chicken Scheme User Manual. Compilation to C and self-host.
7. Debian Reproducible Builds project.
8. openOODA `FLOOR.md`, `seed/README.md`, `BUILD_OUT.md`, `PM.md` 5.1a, `cli/main.oo`.

---

*Series: [Research papers index](./README.md). Template: [TEMPLATE.md](./TEMPLATE.md).*
