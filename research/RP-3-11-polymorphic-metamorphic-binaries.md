# RP-3.11: Polymorphic metamorphic binaries

| Field | Value |
|-------|--------|
| **Paper ID** | `RP-3.11` |
| **DESIGN.md** | §3 Safety — *Polymorphic Metamorphic Binaries (Immune Systems)* |
| **Status** | `draft` |
| **PM.md row** | `3.11` |
| **Product mapping** | **not-started** |
| **Conflicts** | Fights **4.3.2** deterministic reproducible builds; also **3.9** CFI. See § Conflicts; DESIGN §6; RP-6.1 |

## 1. Introduction

DESIGN.md §3 gives this rule:

> **Polymorphic Metamorphic Binaries (Immune Systems):** Compiled files change their own assembly code very quickly during operation. The logical result is the same. But the computer changes the registers and memory locations again and again. This change makes it impossible for attackers to find a target.

DESIGN.md §6 speaks about the supply-chain conflict:

> **Metamorphic Binaries vs. Deterministic Builds:** ... The build process makes a **deterministic hash on the disk**. The software changes its code only **in the computer memory (RAM)** when the OS loads it or during the JIT phase.

This document gives reasons for runtime changes. The changes increase the cost for attackers. We must keep reproducible builds on the disk (4.3.2) as the trust anchor. If we do not separate the disk and the RAM, the "immune system" and the "verifiable supply chain" cancel each other.

## 2. Problem Statement

### 2.1 The Need for Changes

| Threat | Static identical binaries |
|--------|---------------------------|
| Mass ROP exploit kits | One gadget layout fits all systems |
| Wormable memory exploits | Homogeneous ASLR-break once gives scale |
| Targeted implant against known build | Stable code offsets over process lifetime |
| Shared cloud image monoculture | Single exploit breaks the whole fleet |

ASLR helps but is coarse. Sometimes attackers can read it. Continuous changes of the memory layout and the code increase the engineering cost for the attacker.

### 2.2 Stakeholders

| Actor | Need |
|-------|------|
| **Defender** | Different attack surface across systems and time |
| **Supply-chain auditor** | Rebuilds that are fully identical (4.3.2, 5.2) |
| **Debugger** | Symbols, crash stacks, reproducible failure |
| **Performance owner** | Limit on the cost of the changes |
| **Adversary** | Information leaks to find the layout; attack on the morph engine |

### 2.3 Terms

| Term | Meaning |
|------|---------|
| **Polymorphic** | Different encodings on different systems that keep the same logic |
| **Metamorphic** | Code that changes itself over time but keeps the same logic |
| **Diversifying compiler** | A compiler that makes many valid files from one source |
| **Runtime morph** | Changes in the memory after load or during JIT |
| **Reproducible build** | The same source, tools, and environment make the same bytes on the disk |

## 3. Related Work

### 3.1 Automatic Software Changes

- **SoK: Automated Software Diversity** — A survey of compiler diversity, load-time diversity, ASLR history, and threat models.
- **Compiler-Generated Software Diversity** — A compiler makes the diversity. Compile-time methods are orthogonal.
- **Multicompiler (UC Irvine / Franz group)** — An LLVM-based compiler. It randomizes layouts (globals, stack, functions, vtables) and changes instructions.
- **Obfuscator-LLVM** — Obfuscation transforms. These include control-flow flattening, bogus control flow, and instruction change. It trades performance for security via obscurity.
- **Profile-guided automated software diversity** — Software changes that are aware of performance.
- **N-Variant systems** — Run multiple changed systems. Cross-check the behavior without secrets.

### 3.2 Load-Time and Runtime Changes

- **ASLR / PIE** — Coarse base randomization. The industry uses this.
- **Fine-grained ASLR** — Function shuffling and basic-block randomization. Used in research.
- **Continuous re-randomization** — Research systems re-randomize during operation. This has a high engineering cost. It requires updates to code pointers.

### 3.3 Reproducible Builds

- **reproducible-builds.org** — Rules for bit-for-bit identical files.
- **Diverse Double-Compilation (Wheeler)** — A countermeasure against trusting-trust. Uses two compilers. This is different from a runtime morph.
- **Debian/Fedora reproducible builds** — Proof that determinism is possible and valuable.
- **Expert surveys** — Reproducibility has high utility and high cost.

**Key insight:** Changes and reproducibility both give security. But they operate at different layers. Reproducibility operates on the disk (provenance). Changes operate in the RAM (exploit resistance).

## 4. Design Rules for openOODA

### 4.1 Two-Phase Model

```text
Source ──► Deterministic compiler ──► File A (hash H is stable)
                                      │
                                      ▼
                              Loader / JIT morph engine
                                      │
                                      ▼
                              RAM instance A_t (changes in time and space)
```

- **Disk:** Deterministic, attestable, reproducible (4.3.2, 5.2).
- **RAM:** Changes of the layout and the code (3.11). These changes can be continuous.

### 4.2 Morph Levels

| Level | Transform | CFI Impact | Repro Impact |
|-------|-----------|------------|--------------|
| L0 | ASLR/PIE only | Low | Disk is deterministic |
| L1 | Function shuffle from seed at load | Medium | Disk is same. Seed is from OS entropy |
| L2 | JIT basic-block reorder or register rename | High | Disk is same |
| L3 | Continuous change every N ms | Very high | Disk is same. Debug is hard |
| L4 | Diversifying multicompile on disk | Breaks 4.3.2 | Needs seeded multicompile |

openOODA uses **L1 to L3 in RAM**. It does not use L4 as default.

### 4.3 Entropy and Limits

Morph seeds use entropy. Production morph requires an `&RandCap` or an `&MorphCap` under rule 3.2. Pure tests stay deterministic (`seed=0` gives no morph).

### 4.4 Semantic Identity

A morph is valid only if:
The behavior of File A is identical to the behavior of File A_t for all inputs.
This applies to defined behavior. Software changes change undefined layouts that are useful for exploits.

## 5. Threat Model

### 5.1 Threats Prevented

| Threat | How we stop it |
|--------|----------------|
| Mass gadget reuse | Layout differs on each host |
| Static offset implants | Offsets change |
| Code-reuse across the fleet | N-variant is optional |

### 5.2 Threats Not Prevented

| Threat | Reason |
|--------|--------|
| Logic bugs or capability abuse | Not related |
| Information leak re-sync | Attacker reads leaks to build a new map |
| Morph engine bugs | Self-modifying code can make new bugs |
| Supply-chain backdoor in the source | Needs 4.3.2 and 5.2 |
| Data-only attacks | Can survive the software changes |

### 5.3 New Problems

- Crash stacks have no meaning without morph maps.
- Hot reload, shadow-state, and CFI need a rebind (3.9, 3.10, 4.2).
- Continuous changes of large code can cause performance jitter.

## 6. Alternatives

| Alternative | Decision | Reason |
|-------------|----------|--------|
| Diversify on disk only | Optional mode | Breaks public reproducible hash |
| ASLR only | Do not use alone | Coarse and leakable |
| Full continuous morph | Aspirational. Ship L1 first | High engineering and CFI cost |
| Heavy obfuscation | Use caution | Bad for debug, trust, and performance |
| N-variant always-on | Optional high assurance | Uses 2x resources |

## 7. Product Status

**PM.md 3.11: not-started.**

| Item | Status |
|------|--------|
| Runtime code mutation | **not-started** |
| Load-time shuffle | **not-started** |
| Multicompiler backend | **not-started** |
| Morph and deterministic disk split | **design-only** |
| MorphCap and seeded morph for tests | **not-started** |
| Integration with CFI re-sign | **not-started** |

No product uses a metamorphic loop today. Rule 4.3.2 is **not-started**.

## 8. Open Questions

1. What is the minimum effective morph for openOODA (L1 vs L3)?
2. How do we give symbols to crashes with continuous morph?
3. Do we use OS entropy per boot or a sealed enclave seed?
4. How does LLVM interact with the Backend-C product? Do we morph after the C compile?
5. Can we test formal semantic identity with differential fuzzing of morph variants?
6. How often must we morph? Every few milliseconds, or only on a timer during an attack?
7. Do legal rules forbid self-modifying code in some environments?

## 9. Acceptance Criteria

### not-started to smoke

- [ ] Shuffle functions or data at load time with a seed.
- [ ] Keep the same disk artifact hash across rebuilds.
- [ ] Use two seeds to make different memory layouts. Ensure that functional tests pass on both.

### smoke to partial

- [ ] Document the morph levels. The default is off or L1.
- [ ] Do a CFI/PAC re-auth after a morph. Or turn off morph when CFI needs static text.
- [ ] Add the morph map ID to crash reports.

### partial to done

- [ ] Enforce the DESIGN section 6 split in CI. Put reproducible builds on the disk and diversified builds in the RAM.
- [ ] Meet the performance budget.
- [ ] Publish the security story. Tell users what is prevented and what is not prevented.

## 10. References

1. openOODA `spec/DESIGN.md` §3 and §6.
2. openOODA `PM.md` rows 3.11, 4.3.2, 6.1.
3. Larsen, P., Homescu, A., Brunthaler, S., Franz, M. — *SoK: Automated Software Diversity.*
4. Jackson, T., Salamat, B., et al. — *Compiler-Generated Software Diversity.*
5. Homescu, A. et al. — Multicompiler / profile-guided automated software diversity.
6. Cox, B. et al. — *N-Variant Systems: A Secretless Framework for Security through Diversity.*
7. reproducible-builds.org — *Why reproducible builds?*
8. Wheeler, D.A. — Diverse Double-Compilation.
9. Galois — *Protecting Applications with Automated Software Diversity.*
10. Obfuscator-LLVM — diversity transform suite.

---

## Conflicts

### Conflict A: 3.11 fights 4.3.2 (deterministic reproducible builds)

**The Problem**

| Goal | Requirement |
|------|-------------|
| **4.3.2 Reproducible builds** | Same inputs make **identical bytes** on disk. This gives a verifiable hash for supply-chain trust. |
| **3.11 Metamorphic / polymorphic** | **Different** code across builds, hosts, or time. |

If you apply polymorphism at compile time without a fixed seed, the hashes differ. Then auditors cannot match the source to the binary.

**The Solution in DESIGN.md §6**

- Make a deterministic file **on the disk**.
- Apply polymorphism **only in the RAM** during load or JIT.

**Proposed Solutions**

| ID | Solution | Repro | Diversity | Notes |
|----|----------|-------|-----------|-------|
| **S1. Phase split** | Compiler is deterministic. Loader or JIT morphs. | Yes | Yes, at load-time | Matches DESIGN |
| **S2. Seeded multicompile** | Use a `morph_seed` in the build. | Yes, per seed | Yes, across seeds | Put the seed in the SBOM |
| **S3. Two artifacts** | Make `app.repro` and `app.diversified`. | Yes, for repro | Yes | Clear product options |
| **S4. Runtime-only continuous morph** | Disk is identical. RAM changes. | Yes | Yes, strong | Hard with CFI and debug maps |
| **S5. Diversify data layout only** | Code text is fixed. Stack and heap randomize. | Yes | Partial | Easier to co-exist with CFI |
| **S6. Forbid morph in CI** | CI checks the disk. Morph tests use a different suite. | Yes, in CI | Yes, in other jobs | Process solution |

**Recommended Policy**

1. Make the default release file bit-reproducible.
2. Put the morph engine in the runtime, not the compiler.
3. Use CI gate A to check that two builds make the same hash.
4. Use CI gate B to check that two load seeds make different memory layouts but pass tests.
5. Write in the documents: The hash verifies provenance. The morph protects the system.
6. See also: [RP-6-1](./RP-6-1-tension-metamorphic-vs-deterministic.md), [RP-4-3-2](./RP-4-3-2-deterministic-reproducible-builds.md).

### Conflict B: Morph vs CFI (3.9)

Self-modifying code breaks landing pads and PAC signatures.

**Solutions:** Re-sign the code after a morph. Or morph only during a CFI pause. Use L1 data shuffle instead of L3 code rewrite when CFI is on. The `secure-static` profile turns off the morph.

### Conflict C: Morph vs Speed (1.1)

Continuous morph of large code takes too much time.

**Solutions:** Morph at load time and rare epochs. Do not morph every few milliseconds. Only morph security-sensitive processes. Do the morph when the CPU is idle.

### Conflict D: Morph vs Debug (2.1, 5.5)

Agents need a stable map of the code.

**Solutions:** Use morph maps. Turn off morph when you use `ooda run --debug`. Apply patches to the source. Do the morph again after reload.

### Conflict E: Morph vs Shadow-State (3.10)

**Solution:** Stop changes to the text during shadow commit windows (See RP-3.10 Conflict E).

---

*Series: [Research papers index](./README.md). Template: [TEMPLATE.md](./TEMPLATE.md).*
