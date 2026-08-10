# RP-ES.6: Embedded to global verifiable network

| Field | Value |
|-------|--------|
| **Paper ID** | `RP-ES.6` |
| **DESIGN.md** | Executive Summary |
| **Status** | `draft` |
| **PM.md row** | `ES.6` |
| **Product mapping** | **not-started** — scale vision (bare-metal to global verifiable network) |

## 1. Reason for this document in DESIGN.md

The Executive Summary ends with a section about scale:

> The system scales smoothly from **embedded hardware** to a **global, verifiable compute network**.

DESIGN.md explains how to operate both levels:

- **Embedded:** Use the `#![no_std]` profile. Replace operating system (OS) capabilities with hardware capabilities (for example, `&GpioPin4`, `&I2cBus`). Run the code directly on bare-metal hardware (§4.1.5).
- **Network and ecosystem:** Use a Verifiable Web of Code (§5.2). This includes zero-trust packages with capability manifests and cryptographic proofs. Use self-hosted registry nodes (§5.1). Use holographic data storage and multi-target backends (WASM, LLVM, GPU) for the middle levels (§4).

This document shows why **scale** is an important part of the Executive Summary. A single language for all systems (from small microcontrollers (MCUs) to large networks) prevents the use of different languages (like C on the device, Python or Go in the cloud, and YAML in the network mesh). Different languages cause problems for security and artificial intelligence (AI) tools.

## 2. Problem statement

### 2.1 Fragmented systems

Current systems usually use:

| Level | Typical languages | Security model |
|------|-------------------|----------------|
| MCU and bare-metal | C, C++, some Rust `no_std` | Custom, often general permissions |
| Edge and WASM | Rust, Go, JS | WASI and capabilities are developing |
| Cloud services | Many | IAM and mesh sidecars |
| Package ecosystem | Language-specific | TUF and sigstore vary |

Problems:

1. **You write the same business logic again** in different languages.
2. **Security permissions are not consistent.** You use specific capabilities on one level, but general permissions on another level.
3. **AI agents** cannot easily move their skills and tools between levels.
4. **Code verification fails** at each network or language boundary.

### 2.2 Requirements for smooth scale

- **A shared semantic core** (`std::core` pure logic) that you can run on all systems.
- **A tiered capability system.** You must separate OS capabilities, hardware capabilities, and network service capabilities.
- **A multi-backend compiler.** You must compile the code for different targets without changing the source code.
- **Package trust** that operates correctly for small devices (using manifests, not large runtimes) and for global registries (using cryptography and proofs).

### 2.3 Users

| User | Requirement |
|-------|------|
| Embedded engineer | `no_std`, small binary files, hardware pin capabilities |
| Cloud and platform engineer | Native and WASM services, reproducible builds |
| Security architect | One policy language to control authority |
| AI agent | One system to outline, patch, and test across all targets |

## 3. Related work

### 3.1 Embedded systems languages

- **Rust `#![no_std]` and Embedded Rust Book:** Shows the difference between core and std. Shows how to run code without an OS. https://docs.rust-embedded.org/book/intro/no-std.html
- **Sharma et al.,** "Rust for Embedded Systems: Current State and Open Challenges," arXiv:2311.05063. This report studies the maturity and problems of the `no_std` ecosystem.
- **Espressif and industry Rust-on-MCU projects:** Practical, memory-safe embedded development.
- **Tock OS:** An embedded OS that isolates processes. It does not trust applications automatically.
- Historical examples: Ada and SPARK for safety-critical embedded systems. NesC and TinyOS for sensor networks.

### 3.2 Portable middle levels

- **WebAssembly:** A portable sandbox. The component model uses a capability style for imports.
- **LLVM multi-target:** An industrial compiler backend for many targets (DESIGN §4.1.2–4.1.4).
- **Zig and Rust:** Single languages with many targets. But they do not use a "verifiable global network" as their main identity.

### 3.3 Verifiable and decentralized code distribution

- **Sigstore, TUF, in-toto:** Systems that ensure the integrity of the software supply chain.
- **Content-addressed stores and Merkle DAGs** (IPFS, Git): These relate to the holographic and Merkle data storage concepts in DESIGN.
- **Unison and content-addressed functional systems:** Uses a "code as hash" model. This gives inspiration, but uses a different model.
- Capability OS networks (Fuchsia components, Genode): Uses distributed authority patterns.

## 4. Design rationale for openOODA

### 4.1 One ladder, many steps

```
Bare metal (hardware capabilities, no_std)
    → WASM and edge (sandbox imports as capabilities)
    → Native OS (File system, Network, and System capabilities, Backend-C/LLVM)
    → GPU and NPU (compute backends)
    → Verifiable package network (manifests and proofs)
```

The difference between **std::core and std::os** (§5.4) in DESIGN is the main technical rule. Pure modules are the portable units. Effects are explicit and you can change their target.

### 4.2 Capability vocabulary across scale

| Level | Example capability tokens |
|------|----------------|
| MCU | `&GpioPin4`, `&Uart0`, `&FlashRegion<…>` |
| Hosted OS | `&FsCap`, `&NetCap`, `&SysCap` |
| Network services | Limited network capabilities, secure RPC handles |
| Registry | Sign and verify capabilities. No general publish permissions |

This uses the same type-system as ES.2. Scale means that you **change the target of the designations**. You do not stop using the rule of least privilege.

### 4.3 Verifiable network without abandoning systems roots

Section 5.2 "Verifiable Web of Code" is not a different product. It is the **distribution system** for the same language. AI-generated packages (ES.1) are only safe if the manifests, capabilities, and tests (ES.3) move with the code.

### 4.4 Interaction with product purity

A self-hosted pure `.oo` compiler (5.1a) is necessary for a trustworthy scale system. The toolchain that compiles embedded and cloud artifacts must be part of the trust network.

## 5. Threat and failure model

### Prevents and mitigates (vision)

- You do not rewrite logic for each level. This causes fewer mismatch errors.
- Prevents general-permission embedded C designs (if you use hardware capabilities correctly).
- Prevents unsafe package installations that do not have capability manifests (if §5.2 is complete).

### Does **not** prevent

- Hardware trojans and bad boot ROMs.
- Network-level DDoS and routing attacks.
- Incorrect manifests that give too many capabilities.
- System divisions if developers still use unrestricted C code on the device.

### Failure modes

- You advertise an "embedded to global network" system, but you only have a Linux userland alpha version.
- You use a `no_std` profile that secretly adds OS system calls.
- You create a registry that centralizes trust, which contradicts the "verifiable and decentralized" claim.

## 6. Alternatives considered

| Alternative | Why it is not sufficient |
|-------------|------------------|
| **C everywhere with wrappers** | Memory is not safe. Tools for AI agents are weak. |
| **Rust-only scale** | A strong option. But it has less focus on AI-native contracts and capabilities as the main identity. (This is a competitive alternative, but openOODA does not use it). |
| **A different DSL for each level** | This breaks verification and stops AI skill transfer. |
| **Cloud-only managed runtime** | This stops the bare-metal goals of the Executive Summary. |
| **Bytecode-only VM everywhere** | Portability is easier. But bare-metal operation and zero-cost systems goals are harder. |

## 7. Product status (alpha version)

**PM.md — Bare-metal to global verifiable network: `not-started`.**

| Step | Alpha status |
|------|----------------|
| Pure `.oo` Linux and userland product compiler | **done** (alpha) |
| Backend-C native | **done** (alpha baseline) |
| LLVM | **smoke test** |
| WASM | **smoke test** |
| GPU and NPU | **not-started** |
| Bare-metal `no_std` and hardware capabilities | **not-started** (4.1.5) |
| Verifiable web of code and registry | **not-started** (5.2) |
| Full self-hosted package, LSP, and registry | remaining work (5.1 **partial**) |

**Honest summary:** The alpha version is a **single-machine pure systems language product** with smoke tests for multiple targets. The Executive Summary scale vision (MCU to global verifiable network) is a **future goal**, but it is not complete. The `fetch` function or WASM smoke tests do not mean that the embedded and network systems are complete.

## 8. Open research questions

1. What is the **smallest `core` application binary interface (ABI)** that works on MCUs but still supports contracts and capability metadata?
2. How must you write **hardware capabilities** so that pin multiplexing and direct memory access (DMA) do not cause general authority?
3. Can one package manifest format operate for both **offline embedded** systems and **online registry** trust systems?
4. Where do **real-time deadlines** connect with MaxCycles and contract fuzzing (ES.3 and ES.5)?
5. What consensus and cryptography model for a "global verifiable network" is practical and believable? (We must start with signed capability manifests and reproducible builds).

## 9. Acceptance criteria (to change PM status)

### `not-started` to `smoke test`

- [ ] Write a document that shows the target matrix (host, WASM, and at least one embedded profile).
- [ ] Make a `std::core` subset that compiles for a no-OS or freestanding test, **or** write a clear list of blockers.

### `smoke test` to `partial`

- [ ] Complete one non-host target on the product path (more than a basic smoke test).
- [ ] Write a document that explains how to change capability targets (OS to hardware) and give examples.
- [ ] Build a prototype for the package and capability manifest (a local version is acceptable).

### Executive Summary scale to `done` (long-term goal)

- [ ] Complete the owner requirements: for example, a freestanding profile and a minimum viable product (MVP) for a signed package network.
- [ ] Show that you can reuse pure modules across different levels in the test fixtures.
- [ ] Clearly list remaining items (GPU, holographic storage) as not complete or not required for this status.

## 10. References

1. openOODA, *DESIGN.md* Executive Summary; §4.1.4–4.1.5; §5.1–5.2; §5.4 std core vs os.
2. openOODA, *ooda-future.md* — A sketch of embedded hardware capabilities.
3. Embedded Rust Book, `no_std`. https://docs.rust-embedded.org/book/intro/no-std.html
4. A. Sharma et al., "Rust for Embedded Systems: Current State and Open Challenges," arXiv:2311.05063. https://arxiv.org/html/2311.05063v2
5. rust-embedded working group resources. https://github.com/rust-embedded/awesome-embedded-rust
6. Fuchsia capability model (distributed components)—https://fuchsia.dev/fuchsia-src/concepts/principles/secure
7. WebAssembly and WASI capability-oriented host interfaces (portable sandbox tier).
8. TUF and Sigstore documentation (package integrity baselines).
9. Related papers: RP-4.1.4, RP-4.1.5, RP-5.1, RP-5.2, RP-5.4, RP-ES.2.

---

## Conflicts with other DESIGN items

- **§3 full security engine vs MCU budgets:** You cannot put shadow-state, metamorphic mutation, and heavy automatic reference counting (ARC) on small MCUs. You must use tiered feature profiles. If you do not use them, ES.5 will only work on host systems.
- **§2.4 global hive-mind fuzz vs air-gapped embedded systems:** Overnight peer-to-peer (P2P) fuzzing requires a network. Device profiles must have local-only options.
- **§4.4 holographic NVMe persistence vs bare metal:** Immortal Merkle RAM mapping is a function for servers. This conflicts with the "one scale" idea unless you make it clearly optional for each level.
- **§5.1 100% self-hosted registry nodes vs embedded systems:** Registry nodes do not run on MCUs. A "single language" does not mean that "one binary runs all roles."

---

*Series: [Research papers index](./README.md). Template: [TEMPLATE.md](./TEMPLATE.md).*
