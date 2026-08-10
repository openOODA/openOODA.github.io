# RP-5.4: Standard library philosophy (core vs os)

| Field | Value |
|-------|--------|
| **Paper ID** | `RP-5.4` |
| **DESIGN.md** | §5 Ecosystem |
| **Status** | `draft` |
| **PM.md row** | `5.4` |
| **Product mapping** | **partial** — direction exists; full split not closed |

## 1. Why this is in DESIGN.md

DESIGN.md §5:

> The standard library strictly divides into `std::core` (pure logic, needs zero capabilities, runs anywhere) and `std::os` (needs OS capabilities, runs on LLVM or JIT).

This division lets openOODA scale from bare-metal, WASM, and embedded environments to full OS agents. You do not need two different languages. This division also keeps capability security honest. Pure algorithms cannot hide network or file system access in standard library helpers.

If you do not make a hard split, every dependency can become a security risk. In this condition, `#![no_std]` targets (RP-4.1.5) will not operate.

## 2. Problem statement

### 2.1 Monolithic standard library failure

Classic large standard libraries (for example, Python, Go, and historical C) mix the items that follow:

- Pure algorithms (sort, JSON parse without I/O).
- OS services (files, sockets, processes).
- Ambient globals (`open`, `getenv`).

In a capability language, ambient OS access in the standard library is a design bug.

### 2.2 Portability failure

| Target | Needs pure logic | Needs OS |
|--------|------------------|----------|
| Bare metal MCU | Yes | No (or custom HAL) |
| WASM component | Yes | WASI-shaped caps |
| Native CLI agent | Yes | Fs/Net/Sys caps |
| Formal / fuzz pure domain | Yes | Must deny OS |

### 2.3 Users

- **Embedded and WASM authors** need `core` only.  
- **Agent authors** need gated `os`.  
- **Package verifiers** (RP-5.2) must classify dependencies as core-only or os-tainted.  
- **Adversaries** try to hide I/O operations in “pure” modules.

## 3. Related work

### 3.1 University and standards

- **Capability OS interfaces**: Hydra, KeyKOS, EROS, and Capsicum use authority as handles, not ambient system calls.  
- **WASI (WebAssembly System Interface)**: Capability-oriented APIs for files, clocks, and random data. It gives industrial standardization for “no ambient OS”.  
- **Proof-oriented and pure Prelude** designs in Haskell or ML: IO operates as a typed effect. It gives purity by construction.  
- **Effect systems** (research languages, Koka, Unison): These systems track IO in types. This is a related goal, but uses a different mechanism than capabilities.

### 3.2 Commercial and industrial language splits

| System | Split | Notes |
|--------|-------|-------|
| **Rust** | `core`, `alloc`, `std` | Gold standard industrial split. Has a `no_std` ecosystem. |
| **C++** | freestanding vs hosted | Has a weaker purity story. The freestanding model was historically underspecified. |
| **Zig** | std always available-ish; freestanding targets | Uses an explicit target model. |
| **Go** | single std | Gives portability through GOOS. Not capability-pure. |
| **Swift** | layered availability | OS frameworks dominate. |
| **Java** | SE modules | Not capability-based. |

**Rust’s lesson:** `libcore` has no allocator and no OS. `alloc` adds heaps without OS. `std` adds OS. openOODA maps to this as follows:

| Rust | openOODA DESIGN |
|------|-----------------|
| `core` | `std::core` (zero capabilities) |
| `alloc` | possibly `std::core` + explicit `&AllocCap` later (RP-3.3) |
| `std` | `std::os` (needs OS capabilities) |

**WASI’s lesson:** A “portable OS” must use **handles**, not ambient access. `std::os` APIs must take `&FsCap`, `&NetCap`, `&TimeCap`, and `&RandCap`.

### 3.3 Existing openOODA std sketch

The monorepo `std/` already trends toward capability-gated access:

- `std::net` — uses `NetCap`.
- `std::fs` — uses `FsCap`.
- `std::json`, `std::crypto` — these are closer to pure or core modules.

The philosophical split is partial in the product. Naming and enforcement (where `core` cannot import `os`) are not complete.

## 4. Design rationale for openOODA

### 4.1 Hard rules

1. **`std::core`**: You must not use ambient I/O, hidden system calls, or threads that need OS scheduler APIs (unless using pure schedulers later). This module can include collections (with an allocation policy), math, encoding, pure cryptography, JSON parsing to memory, error types, and iterators.  
2. **`std::os`**: Every entry point that causes an effect must take explicit capability parameters.  
3. **Import law**: `std::core` modules must not import `std::os`. `std::os` modules can import `std::core`.  
4. **Target law**: Bare-metal or pure WASM profiles link only to `core`.  
5. **Package law**: Packages with a `core`-safe label must not depend on `os` (RP-5.2).

### 4.2 Allocators as the gray zone

The DESIGN document states that `std::core` “runs anywhere.” Rust needed `alloc` as a middle crate. openOODA has these options:

| Option | Pros | Cons |
|--------|------|------|
| A. Provide heap access only through `&AllocCap`, even in core algorithms | Consistent capabilities | Verbose. Breaks the “zero capabilities” rule |
| B. Let core use a global allocator on some profiles | Ergonomic | Creates ambient authority for memory |
| C. Keep core without heap access. Put vectors in a `std::alloc` middle layer | Clean design | Makes a three-way split |

**Recommendation for the research draft:** Use the Rust-like three-layer naming scheme (`core`, `alloc`, and `os`) for the implementation. Let the DESIGN document keep the two-layer rule. Document `alloc` as a sublayer of portability, with optional capability quotas (RP-3.3).

### 4.3 Time and entropy

Clocks and random number generators (RNG) need an OS (RP-3.2). They must not operate in pure `core` as ambient `now()` or `random()` functions. A pure deterministic pseudorandom number generator (PRNG) that receives a seed from an argument is permitted in `core`.

### 4.4 Backend notes

The DESIGN document says that `std::os` “runs on LLVM/JIT.” The product alpha uses **Backend-C** (RP-4.x). The philosophy uses **capabilities and OS services**, but it does not mandate LLVM only. Read it correctly as follows: `os` needs a hosted runtime environment (C, LLVM, JIT, or WASI). `core` runs on any environment, which includes freestanding ones.

## 5. Threat and failure model

### 5.1 Prevents

- Libraries that look pure from performing network or file I/O.  
- Accidental non-portability of algorithmic packages.  
- Agent confusion about which modules need capabilities.  
- Bare-metal builds from downloading socket code.

### 5.2 Does not prevent

- Algorithmic Denial of Service (DoS) for CPU or memory in pure core. You must use quotas to prevent this.  
- Cryptography side channels.  
- Logic bugs in pure code.  
- `os` modules that request capabilities that are too broad.

### 5.3 Failure modes

| Mode | Mitigation |
|------|------------|
| Soft split (documentation only) | Use compiler crate-level isolation |
| A JSON “core” that fetches URLs | Do an API review. Do not permit network access in the module |
| Cryptography in core that links to an OS RNG ambiently | Use seed parameters only |
| Name is `std::os` but path is `std/fs.oo` | Do a naming pass and use a module map |

## 6. Alternatives considered

| Alternative | Decision |
|-------------|----------|
| **Single std with feature flags** | Rejected as the primary solution. Flags are not capability proofs. |
| **Effects instead of caps** | A research alternative. Capabilities are already in the DESIGN core. |
| **No std (only packages)** | Rejects included components for agents. Gives a worse developer experience. |
| **OS-only std (like early Go)** | Stops the embedded and WASM vision. |
| **Full POSIX in core** | Rejected. This creates ambient authority. |

## 7. Product reality (alpha status)

According to the monorepo **PM.md** row `5.4`, the status is **partial**.

| Item | State |
|------|-------|
| Capability-gated fs and net modules | Direction is present (`std/`, product trees) |
| Named `std::core` vs `std::os` enforcement | **Not complete** |
| Compiler forbids core-to-os imports | Residual |
| Bare-metal `no_std` profile | **Not started** (4.1.5) |
| Allocator middle layer policy | Residual |
| Full module coverage | Sparse alpha |

Status summary: **The project adopted the philosophy in spirit, but the product taxonomy is incomplete.**

## 8. Open research questions

1. How do we document the two-way DESIGN naming versus the three-way (`core`, `alloc`, `os`) implementation without contradiction?  
2. Can pure cryptography use platform AES-NI through a privileged intrinsic without `os`? (This relates to constant-time and side-channel policies.)  
3. Should we split `std::os` per capability (for example, `std::os::fs`, `net`) for finer package graphs?  
4. How do we classify holographic persistence (RP-4.4) and temporal memory (RP-3.8)? Are they core or os?  
5. What is the WASI preview2 component model mapping for `std::os`?

## 9. Acceptance criteria (for PM status promotion)

### Move from partial to done

- [ ] Documented module map: You must label every std module as `core`, `alloc`, or `os`.  
- [ ] The compiler or packager **rejects** core-to-os imports.  
- [ ] The CI profile builds a pure-core fixture with no OS runtime symbols (or a freestanding test).  
- [ ] Public APIs in `os` must take explicit capabilities (audit complete).  
- [ ] Package metadata can declare `core-only` and the system enforces this rule.  
- [ ] README and std documentation match the DESIGN terminology.

### Intermediate test

- [ ] Put `std::json` and pure cryptography behind the `core` path in documentation and imports.  
- [ ] Document `std::fs` and `std::net` as `os` with capabilities.

## 10. References

1. Rust Embedded Book — `no_std`, `libcore`, `alloc`.  
2. WASI specifications — Capability-oriented system interface.  
3. Capsicum and CloudABI papers and documentation.  
4. Haskell IO monads and effect systems surveys (for purity tracking contrast).  
5. Free-standing C++ and WG21 freestanding discussions.  
6. openOODA `std/README.md`; DESIGN §5; RP-3.1–3.4; RP-4.1.5; RP-5.2.

---

*Series: [Research papers index](./README.md). Template: [TEMPLATE.md](./TEMPLATE.md).*
