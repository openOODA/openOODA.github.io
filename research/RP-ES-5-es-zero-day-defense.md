# RP-ES.5: Zero-day defense goals

| Field | Value |
|-------|--------|
| **Paper ID** | `RP-ES.5` |
| **DESIGN.md** | Executive Summary |
| **Status** | `draft` |
| **PM.md row** | `ES.5` |
| **Product mapping** | **not-started** — advanced integrity (call-graph crypto, metamorphic, shadow-state, etc.) |

## 1. Why this is in DESIGN.md

The Executive Summary includes **zero-day defense** with AI-native and capability security. DESIGN Section 3 and SPEC show a multi-layer architecture:

1. **Memory safety** (RAII/ARC, bounds): Stops many corruption bugs.
2. **Capability default-deny**: Stops exploits and bad packages when the logic has errors.
3. **Advanced integrity**: Includes cryptographic call-graph integrity, shadow-state semantic reversion, polymorphic and metamorphic binaries, temporal memory rollback, and task isolation.

SPEC shows industry memory-unsafety data. SPEC shows how to stop zero-day attacks with capabilities and isolation. This paper explains the Executive Summary **goal**: openOODA is memory safe. openOODA also gives **defense-in-depth against unknown exploits** and AI-era code risks. We must tell users that advanced layers are research. They are not in the alpha product.

## 2. Problem statement

### 2.1 Zero-days continue to occur

**Memory corruption** (use-after-free, OOB) causes most high-severity browser and OS vulnerabilities. Chromium says that memory unsafety causes approximately **70% of high-severity security bugs**. Microsoft shows the same 70% for its products. Real-world zero-day attacks often use renderer and kernel memory bugs together.

Memory-safe languages decrease this problem. But, they do not stop all zero-day attacks. The remaining problems are:

- Logic and authentication bugs
- Supply-chain bad code
- Spec confusion, injection, and side channels
- Unsafe FFI boundaries
- JIT and compiler bugs

### 2.2 AI changes the threat model

- AI writes more code faster (ES.1). This creates a larger attack surface.
- Prompt injection can create bad code. This requires ES.2 containment.
- AI can write dependencies with hidden backdoors. This requires capabilities and verification (ES.3, Section 5.2).

### 2.3 Definition of "zero-day defense goals"

This does not mean the system is fully secure. The **goal stack** is:

| Layer | Intent |
|-------|--------|
| Prevent | Memory safety, type-state, bounds |
| Contain | Capabilities, task isolation, quotas |
| Detect and abort | Contracts, CFI-like call-graph integrity |
| Recover | Temporal rollback, shadow-state reversion |
| Increase cost | Metamorphic binaries, diversity |

## 3. Related work

### 3.1 Industry measurements

- **Chromium Memory Safety:** Chromium says that memory unsafety causes approximately 70% of their high-severity security bugs. Use-after-free causes half of those bugs. See https://www.chromium.org/Home/chromium-security/memory-safety/.
- **Google Security Blog (2021):** "An update on Memory Safety in Chrome." See https://security.googleblog.com/2021/09/an-update-on-memory-safety-in-chrome.html.
- **Microsoft:** Microsoft security analyses show approximately 70% memory safety issues.

### 3.2 Exploit mitigation history

- **Abadi et al. (2005):** Control-Flow Integrity (CFI). CFI limits execution to the correct control-flow graph. CFI stops ROP and JOP attacks.
- **Industry baseline mitigations:** W^X, ASLR, stack canaries, CET, and shadow stacks.
- **Capsicum and Fuchsia** (ES.2 references): Use capability containment for compromised areas.
- **CHERI:** Uses hardware fat pointers and capabilities for spatial and temporal memory safety.

### 3.3 Diversity and moving-target defenses

- **Moving-target defenses:** N-variant systems, address space layout randomization, and instruction set randomization. These are similar to DESIGN **metamorphic binaries**. They increase the cost for the attacker.
- **Semantic defenses:** Formal verification and contract checking. These identify problems before the system stops.

## 4. Design rationale for openOODA

### 4.1 Map DESIGN machinery to defensive roles

| DESIGN item | Defensive role | PM status (alpha) |
|-------------|----------------|-------------------|
| ARC/RAII, bounds (Section 3.7) | Prevent classic memory zero-day attacks | **partial** |
| Capability sandbox (Section 3.1) | Contain supply-chain and post-exploit I/O | **partial** |
| Alloc/CPU quotas (Sections 3.3 to 3.4) | Contain DoS and zip-bombs | **not-started** |
| Secret taint (Section 3.5) | Prevent data exfiltration | **not-started** |
| Contract fuzzer (Section 3.6) | Find semantic errors before deployment | **partial** |
| Temporal memory (Section 3.8) | Recover from fatal faults | **not-started** |
| Crypto call-graph integrity (Section 3.9) | Stop control-flow hijacks | **not-started** |
| Shadow-state reversion (Section 3.10) | Stop semantic contract breaks before commit | **not-started** |
| Metamorphic binaries (Section 3.11) | Moving-target defense | **not-started** |
| Task isolation (SPEC) | Limit blast radius | **not-started** |

### 4.2 Why list this in the Executive Summary

Without ES.5, users can think openOODA is only "Rust with capabilities". The zero-day **goal stack** shows why the advanced Section 3 items are necessary. It shows how they connect to ES.2 and ES.3. It also gives the correct product status: **partial memory safety and capabilities do not equal a full zero-day architecture**.

### 4.3 Interaction with AI-native and self-testing

- Fast agent loops change the code frequently. You must use automated contract attacks (ES.3).
- Contained AI code (ES.2) is the first practical zero-day defense that we will release.
- Advanced integrity is a research goal for the future.

## 5. Threat and failure model

### Stops or decreases (when layers exist)

- A large quantity of historic memory-corruption exploits (with real memory safety).
- Dependency zero-day attacks that need the file system or network (with real capabilities).
- Some control-flow hijacks (with CFI-like integrity, as a future goal).
- Single-task errors from breaking the whole process (with isolation, as a future goal).

### Does **not** stop

- Correct use of capabilities that are too large.
- Cryptographic failures, social engineering, and hardware errors.
- Spec and logic zero-day attacks when contracts have errors or are missing.
- Attacks outside the language runtime (host OS).
- Guaranteed protection against nation-state zero-day attacks.

### Overclaim risk

We say openOODA "eliminates ~70% of historic zero-days" (SPEC). This is true only for **memory-unsafety in pure OODA code**. This is not true for all real-world zero-day attacks in a full product with a C runtime (`chs_rt`) and FFI.

## 6. Alternatives considered

| Alternative | Why insufficient alone |
|-------------|------------------------|
| **Memory safety only** | Supply-chain and logic attacks still occur |
| **OS sandbox only** | Too general. Weak in-language API graph |
| **Antivirus and post-hoc scanning** | Fails against unknown zero-day attacks |
| **Full formal proof of all code** | Does not scale for fast AI code writing |
| **Metamorphic-only without determinism policy** | Breaks supply-chain hash verification (Section 6.1 tension) |

## 7. Product reality (alpha status)

**PM.md — Zero-day defense (advanced integrity): `not-started`.**

These items related to zero-day *themes* are available (not the ES.5 advanced stack):

| Mechanism | Status |
|-----------|--------|
| Capability static and runtime seals on sealed operations | **partial** (ES.2) |
| Memory management ARC path | **partial** |
| Integer-domain contract fuzzing | **partial** |
| Cryptographic call-graph, shadow-state, metamorphic, and temporal rollback | **not-started** |
| Full memory-safety proof against C runtime UB | **not claimed** (Backend-C and `chs_rt` are C) |

**Honest summary:** Alpha gives **early containment and partial safety**. Alpha does not have the advanced zero-day immune system from the Executive Summary. Do not say that metamorphic binaries, shadow-state, or call-graph cryptography are available.

## 8. Open research questions

1. Which advanced layer gives the best **security return on investment** after capabilities and memory safety? (CFI, shadow-state, or isolation).
2. How do we make call-graph integrity on the **Backend-C** floor without decreasing performance or portability?
3. Can we keep metamorphic mutation only in **RAM** to keep disk builds deterministic? (Section 6.1).
4. What adversary model is correct for "unforgeable" software integrity on standard CPUs without CET or CHERI?
5. How must we **measure** zero-day defense claims? (Use bug-class coverage, not slogans).

## 9. Acceptance criteria (for PM status promotion)

### `not-started` to `smoke` or `partial`

- [ ] Complete at least one advanced integrity mechanism (for example, basic CFI or runtime contracts in debug) with test fixtures.
- [ ] Write the adversary model and non-claims document for release notes.

### Executive Summary ES.5 to `done` (strict)

- [ ] Complete an owner-defined part of Sections 3.8 to 3.11 with tests. **Or**, change ES.5 to "memory safety and capability containment" and move advanced items out of the Executive Summary.
- [ ] Stop all marketing of unavailable immune-system features.
- [ ] Put the FFI and C runtime risks clearly in the threat model.

*(Recommendation: Keep ES.5 as `not-started` until advanced integrity has real code. Do not promote it using only capabilities. That is ES.2.)*

## 10. References

1. openOODA, *DESIGN.md* Section 3: Safety and Security Engine; Section 6.1: Metamorphic vs deterministic.
2. openOODA, *SPEC.md*: Zero-Day Vulnerability Defense Architecture.
3. Chromium, "Memory safety". https://www.chromium.org/Home/chromium-security/memory-safety/
4. Google Security Blog, "An update on Memory Safety in Chrome", 2021. https://security.googleblog.com/2021/09/an-update-on-memory-safety-in-chrome.html
5. M. Abadi, M. Budiu, Ú. Erlingsson, J. Ligatti, "Control-Flow Integrity", CCS 2005.
6. R. N. M. Watson et al., "Capsicum (containment)", USENIX Security 2010.
7. CHERI project literature (Cambridge): Hardware capability memory safety.
8. Related: RP-3.1, RP-3.7 to 3.11, RP-6.1, RP-ES.2, RP-ES.3.

---

## Conflicts with other DESIGN items

- **Section 6.1 Metamorphic binaries vs deterministic reproducible builds:** There is direct tension. The DESIGN policy says to mutate only in RAM after a deterministic disk artifact. The implementation must apply that boundary or it will break supply-chain security.
- **Section 3.7 ARC vs Section 3.8 temporal memory (Section 6.2):** Rollback arenas conflict with immediate destroy-on-scope. This needs opt-in `temporal` types.
- **Section 4.x Backend-C product floor vs memory-safety zero-day claims:** Emitted C and runtime C can cause UB classes again if we do not carefully limit the subset. This breaks the "eliminates memory zero-days" absolute claim.

---

*Series: [Research papers index](./README.md). Template: [TEMPLATE.md](./TEMPLATE.md).*
