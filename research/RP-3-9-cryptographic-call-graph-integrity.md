# RP-3.9: Cryptographic call-graph integrity

| Field | Value |
|-------|--------|
| **Paper ID** | `RP-3.9` |
| **DESIGN.md** | Section 3 Safety — *Cryptographic Call-Graph Integrity* |
| **Status** | `draft` |
| **PM.md row** | `3.9` |
| **Product mapping** | **not-started** (advanced zero-day integrity) |
| **Conflicts** | Overhead against 1.1 OODA speed. Dynamism against 3.11 runtime mutation. Hot reload 4.2. See Section Conflicts. |

## 1. Why this is in DESIGN.md

DESIGN.md Section 3 says:

> **Cryptographic Call-Graph Integrity:** The compiler makes a cryptographic hash of all valid function transitions. If an attacker uses a vulnerability (for example, a ROP attack), the CPU stops the incorrect return pointer. Then, the CPU stops the process.

This feature is the language-level commitment of openOODA to control-flow integrity (CFI). This feature has a cryptographic element. The labels must match. Also, the hashes or MACs must connect to the transitions. Thus, forged return addresses and indirect calls do not operate. This feature stops the attack sequence after memory corruption occurs. Examples include ROP, JOP, return address overwrite, and function-pointer hijack.

It is a main part of the ES.5 zero-day defense goals. It adds to memory safety (3.7) and capabilities (3.1). It does not replace them.

## 2. Problem statement

### 2.1 What breaks without it

Residual bugs can cause memory corruption. Examples of residual bugs are FFI, logic bugs, and future free bugs. Without CFI, these attacks can occur:

| Attack | Result |
|--------|--------|
| ROP | Chain gadgets. Bypass NX. |
| JOP / COOP | Take control of indirect calls or vtables. |
| Return address overwrite | Change the direction of `ret`. |
| Function pointer smash | Change the direction of calls. |

AI-generated systems code and self-host compilers are high-value targets. It is better to stop the process on a mismatch than to allow a silent compromise.

### 2.2 Stakeholders

| Actor | Need |
|-------|------|
| **Defender** | Stop operation when a control-flow violation occurs. |
| **Compiler** | Make metadata and checks portably. (x86 CET, ARM PAC, software fallback). |
| **Performance owner** | Limit overhead to keep agent loops tight (1.1). |
| **Adversary** | Bypass coarse CFI. Do data-only attacks. Find a gadget in the allowed set. |

### 2.3 “Cryptographic” meaning (precise)

In DESIGN, “cryptographic hash of valid transitions” means one or more of these items:

1. **Static CFG commitment** — A hash of the allowed edge set.
2. **Dynamic edge authentication** — MAC or sign for return addresses and code pointers. (PAC-like).
3. **Label IDs** — Classic CFI equivalence-class IDs. These IDs are weaker and are not always cryptographic.

openOODA must prefer item (2) on hardware that supports it. Use item (1) to measure the supply-chain. Use item (3) as a portable software baseline.

## 3. Related work

### 3.1 Classic CFI

- **Abadi, Budiu, Erlingsson, Ligatti (2005)** — *Control-Flow Integrity*. Make sure that execution follows a set CFG. Check labels on indirect transfers. Use an optional shadow stack for returns.
- **Fine-grained against coarse-grained CFI** — The precision of allowed target sets. Coarse CFI is weaker against advanced ROP.
- **Burow et al.** — Surveys of CFI precision, security, and performance.

### 3.2 Code-Pointer Integrity (CPI)

- **Kuznetsov et al. (OSDI 2014)** — *Code-Pointer Integrity*. Keep the integrity of all code pointers. Keep the integrity of pointers to code pointers. Use a safe region or safe stack. This stops control-flow hijacks because it protects the pointers.
- **CPS (code-pointer separation)** — A related design point with different performance tradeoffs.
- **SafeStack (LLVM)** — Industrial ideas for stack separation.

### 3.3 Hardware enforcement

| Mechanism | Platform | Role |
|-----------|----------|------|
| **Intel CET** | x86 | Shadow stack for returns and IBT for forward-edge. |
| **ARM PAC** | Armv8.3-A+ / PACBTI M-profile | Cryptographic pointer authentication. |
| **ARM BTI** | Armv8.5-A+ | Branch target identification for forward-edge. |
| **ARM GCS** | newer A-profile | Guarded control stack. |
| **LLVM CFI** | software | Type-based or scheme-based forward-edge checks. |

V8 and major OSes combine PAC and shadow stacks for strong backward-edge CFI.

### 3.4 Industrial deployment notes

- Clang and LLVM CFI schemes operate for C++ virtual calls and indirect functions.
- Android and Apple platforms use PAC and BTI on supported silicon.
- The Linux kernel supports the CET shadow stack and IBT.

## 4. Design rationale for openOODA

### 4.1 Layered enforcement plan

```text
Layer 0  Portable software CFI labels and shadow stack for all targets.
Layer 1  Hardware: CET SS and IBT (x86). PAC, BTI, and GCS (ARM).
Layer 2  CFG commitment hash in binary metadata.
Layer 3  Optional full CPI-style safe region for high-assurance builds.
```

### 4.2 Compiler responsibilities

1. Make a precise CFG from openOODA types. Do not use C++-level ambiguity.
2. Make landing pads, PAC sign-auth, or ENDBR as the target requires.
3. Hash and embed the allowed transition set for runtime and offline verify.
4. On mismatch, stop the process. Do not continue in secure mode.
5. Connect with capability sandboxes. A CFI fault is a security event.

### 4.3 Interaction with language features

| Feature | CFI impact |
|---------|------------|
| **First-class functions / closures** | Indirect call sets must be precise. |
| **Hot reload (4.2)** | You must update the CFG hash and landing pads atomically. |
| **Metamorphic (3.11)** | You must re-sign and re-label runtime code moves. See Section Conflicts. |
| **FFI (6.3)** | External code is untrusted. Calls need boundary stubs. |
| **Intent / LLM codegen (2.3)** | Generated code must lower through the CFI pipeline. |

## 5. Threat / failure model

### 5.1 Prevents (strong schemes)

| Attack | Defense |
|--------|---------|
| Classic ROP | Shadow stack or PAC-ret. |
| Arbitrary indirect call | Fine-grained CFI or BTI and type sets. |
| Return address overwrite | Hardware SS or PAC. |
| Many code-pointer corruptions | CPI-class protection. |

### 5.2 Does not prevent

| Attack | Why |
|--------|-----|
| Data-only attacks | Control flow is legal. Data is corrupted. |
| Logic / capability abuse | Requires 3.1 or contracts. |
| Coarse-CFI gadget sets | Occurs if labels are too wide. |
| Kernel / hypervisor compromise | Out of process trust. |
| Speculative side channels | Separate problem (Spectre class). Related to 3.10 research. |

### 5.3 Failure policy

- **Secure default:** Stop the process or task when a CFI violation occurs.
- **Debug:** Give a rich narrative diagnostic (5.5) with the last legal edge.
- **Never:** Do not silently change the control flow to the nearest safe point.

## 6. Alternatives considered

| Alternative | Decision | Why |
|-------------|----------|-----|
| Software CFI only | Baseline. Not sufficient alone. | Hardware PAC or CET is better for backward-edge. |
| Coarse CFI (few labels) | Reject as sole defense. | There is known bypass literature. |
| CPI full isolation only | Optional high-assurance. | Complexity and portability. |
| Rely only on memory safety | Insufficient. | Residual bugs and FFI remain. |
| Continuous CFG re-hash every call | Too expensive. | Prefer pointer MAC and static labels. |

## 7. Product reality (alpha honesty)

**PM.md `3.9`: not-started.**

| Item | Status |
|------|--------|
| CFG extraction for CFI | **not-started** |
| Software label CFI emit | **not-started** |
| Shadow stack (soft or CET) | **not-started** |
| PAC / BTI codegen | **not-started** |
| Transition-set cryptographic hash metadata | **not-started** |
| CPI safe region | **not-started** |
| Detonate-on-mismatch runtime | **not-started** |

No production binary currently uses call-graph integrity checks as a language feature. It is false to claim ROP immunity today.

## 8. Open research questions

1. **Granularity:** Function-level, basic-block, or type-based sets for the simpler object model of openOODA?
2. **Hash algorithm & keying:** Static binary hash or keyed PAC-like MAC with per-process keys?
3. **Self-host compiler:** Can `oodac` start CFI and not break pure Backend-C bootstrap?
4. **Wasm / embedded targets:** Portable subset without PAC or CET?
5. **Multi-language LTO (4.3.1):** CFI across Rust and C++ boundaries?
6. **False positives:** setjmp, longjmp, computed goto equivalents, plugin reload?

## 9. Acceptance criteria (for PM status promotion)

### not-started to smoke

- [ ] Software forward-edge checks on indirect calls in Backend-C or LLVM path for a microbenchmark.
- [ ] Documented detonate policy and test that corrupted return address traps.

### smoke to partial

- [ ] Shadow-stack or PAC-ret path on at least one real ISA.
- [ ] CFG metadata emitted and verifiable offline.
- [ ] Overhead measured on self-host compile workload.

### partial to done

- [ ] Default-on for release builds on supported hardware. Portable fallback elsewhere.
- [ ] FFI boundary stubs documented and tested.
- [ ] No systematic false positives on stdlib and oodac self-host.

## 10. References

1. openOODA `spec/DESIGN.md` Section 3 Cryptographic Call-Graph Integrity. ES.5 zero-day goals.
2. openOODA `PM.md` row 3.9. Advanced integrity not-started note.
3. Abadi, M., Budiu, M., Erlingsson, Ú., Ligatti, J. (2005). *Control-Flow Integrity.* CCS / TISSEC.
4. Kuznetsov, V. et al. (2014). *Code-Pointer Integrity.* OSDI. https://dslab.epfl.ch/research/cpi/
5. Intel — Control-flow Enforcement Technology (CET): shadow stack and IBT.
6. Arm — Pointer Authentication (PAC), Branch Target Identification (BTI), PACBTI for M-profile.
7. Burow, N. et al. — *Control-Flow Integrity: Precision, Security, and Performance* (CSUR survey).
8. LLVM / Clang CFI documentation. V8 control-flow integrity notes.
9. Linux kernel docs — x86 CET shadow stack.

---

## Conflicts

### Conflict A — CFI checks against OODA loop speed (1.1)

Fine-grained CFI and PAC auth use cycles on every indirect call and return.

**Solutions**

| Approach | Detail |
|----------|--------|
| Hardware first | Prefer CET or PAC. |
| Profile-guided edge sets | Hot paths monomorphize to direct calls. |
| Tiered builds | `dev` has soft checks. `release` has hardware CFI. `secure` has CPI. |
| Contract strip analogy | Mirror SPEC: heavy checks in test. Measured budget in release. |

### Conflict B — CFI against polymorphic and metamorphic binaries (3.11)

Runtime code mutation invalidates static landing pads, PAC signatures, and CFG hashes.

**Solutions**

| Approach | Detail |
|----------|--------|
| **Mutate then re-auth** | After morph, re-sign pointers and refresh IBT maps under lock. |
| **Morph only data layout** | Diversify stack and heap layout without moving code. |
| **Phase separation** | On-disk deterministic (4.3.2). Morph in loader with CFI reinit. |
| **Disable morph in CFI-secure profile** | Product flag: `secure-static` against `immune-morph`. |

### Conflict C — CFI against hot reload (4.2)

**Solution:** Reload transactions: install new code, new CFG commitment, and barrier. Do not make concurrent calls into half-updated text.

### Conflict D — Detonate against temporal recovery (3.8)

CFI violation is an adversarial class. Temporal rollback is for non-adversarial faults.

**Solution:** CFI detonation **does not** automatically roll back. You can do a supervised restart of a fresh task without restoring an attacker-tainted temporal log.

---

*Series: [Research papers index](./README.md). Template: [TEMPLATE.md](./TEMPLATE.md).*
