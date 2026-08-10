# RP-6.1: Tension: metamorphic vs deterministic builds

| Field | Value |
|-------|--------|
| **Paper ID** | `RP-6.1` |
| **DESIGN.md** | §6 Tensions |
| **Status** | `draft` |
| **PM.md row** | `6.1` |
| **Product mapping** | Policy only in DESIGN; 3.11 and 4.3.2 both **not-started** |
| **Related DESIGN** | `3.11` (polymorphic metamorphic binaries), `4.3.2` (deterministic reproducible builds), ES.5 (zero-day defense) |
| **Sibling papers** | [RP-3-11](./RP-3-11-polymorphic-metamorphic-binaries.md), [RP-4-3-2](./RP-4-3-2-deterministic-reproducible-builds.md) |

## 1. Why this is in DESIGN.md

DESIGN §6 states:

> To support supply-chain security, compilation produces a byte-for-byte deterministic hash on disk. The polymorphic metamorphism only occurs dynamically in RAM during the OS load sequence or JIT phase, ensuring reproducible builds don't fight binary immune systems.

Two DESIGN goals pull in opposite directions:

| Goal | DESIGN claim | Security benefit |
|------|--------------|------------------|
| **4.3.2 Deterministic builds** | Same sources → same on-disk bytes everywhere | Independent rebuild verifies the shipped artifact was not injected; SBOM / attestation honesty |
| **3.11 Metamorphic binaries** | Runtime mutates assembly, registers, layouts continuously | Raises cost of reliable ROP gadgets, static signatures, and shared exploit offsets |

Without an explicit **phase boundary**, implementers will either:

1. bake entropy into the **artifact** (breaking rebuild equality and auditor trust), or  
2. ship a fully static layout (weakening the “binary immune system” story).

This paper records the **boundary policy** so later 3.11/4.3.2 work cannot re-litigate the conflict ad hoc.

## 2. Problem statement

### What breaks if we omit the boundary

| Stakeholder | Failure mode |
|-------------|--------------|
| **Supply-chain auditor** | Two builds of the same pin produce different hashes → cannot prove source↔binary correspondence |
| **Package registry / Web of Code (5.2)** | “Proven” modules cannot be re-minted or re-verified independently |
| **Defender (3.11)** | If metamorphism is only a marketing claim and never runs, advanced integrity is vaporware |
| **Defender (if metamorphism is on-disk)** | Every install is unique → signature allowlists, crash symbolication, and content-addressed caches collapse |
| **Agent / CI** | Flaky hashes break cache keys, lockfiles, and “did this agent ship the same binary?” workflows |

### Who is the user / adversary

- **User (human / org):** wants both “I can rebuild what you shipped” and “runtime is hard to weaponize.”  
- **Adversary (supply chain):** wants to inject a backdoor that survives signing or that looks like a “legitimate metamorphic variant.”  
- **Adversary (memory exploit):** wants stable gadgets and predictable layouts across victims.

The tension is real: **diversity of runtime state** vs **identity of build artifacts**.

### Core invariant (policy)

```
identity(on_disk_artifact)  =  hash(sources, toolchain_pin, build_flags, SOURCE_DATE_EPOCH, …)
diversity(in_memory_image)  =  f(artifact, load_entropy, optional_runtime_policy)
```

Metamorphism must **never** be an input to `identity`. Diversity is allowed only **after** the artifact is fixed.

## 3. Related work

### Reproducible / deterministic builds

- **Reproducible Builds project** — independently verifiable path from source to binary; bit-for-bit equality as the gold standard for “this binary came from that source.”  
  <https://reproducible-builds.org/>
- **Lamb & Zacchiroli, “Reproducible Builds: Increasing the Integrity of Software Supply Chains”** (IEEE Security & Privacy / arXiv:2104.06020) — academic framing of reproducibility for supply-chain integrity.  
  <https://arxiv.org/pdf/2104.06020>
- **`SOURCE_DATE_EPOCH`** — standardized build timestamp so embedded dates do not break equality.  
  <https://reproducible-builds.org/docs/source-date-epoch/>
- **Nix / Guix-style sandboxing** — hermetic inputs; still distinguish *repeatable* vs *bit-reproducible* (tooling residual).

### Runtime diversity without breaking identity

- **ASLR / PIE** — OS randomizes load bases per process; on-disk ELF/PE remains unchanged. Classic proof that **runtime entropy ≠ build non-determinism**.  
  (Industry standard; see any modern OS ASLR documentation.)
- **Position-independent code + load-time relocation** — diversity at map time, fixed file hash.
- **Control-flow integrity / CFI, PAC, CET** — integrity without rewriting every instruction every few ms (weaker “immune system,” stronger deployability).

### Metamorphic / polymorphic code (offense and defense)

- **Polymorphic / metamorphic malware engines** — junk insertion, instruction substitution, register reassignment; historically used by *attackers* to evade signatures. Defensive reuse is research-grade and rare in production systems languages.  
  Survey context: polymorphic mutation engines (e.g. academic analyses of metamorphic malware).
- **Software diversity / multivariant execution** — N-version or diversifying compilers (e.g. instruction scheduling noise) usually applied **per-build** or **per-install**, which *does* fight reproducibility unless diversity is deferred to load/JIT.
- **AOT binary still hashable; JIT diversifies** — V8/JVM style: cold artifact fixed, warm code generated with runtime policy (openOODA’s DESIGN explicitly names load/JIT phase).

### Security trade-off literature

- StackExchange / industry discussion: reproducible builds do **not** replace signing or runtime mitigations; they answer a different question (“was the build honest?”). Combining them requires **orthogonal layers**, not a single knob.

## 4. Design rationale for openOODA

### 4.1 Phase split (canonical policy)

| Phase | What is fixed | Entropy allowed? | Hashing surface |
|-------|---------------|------------------|-----------------|
| **Compile / link (4.3.2)** | IR, object code, final on-disk image | **No** host clock, host path, or RNG in artifact | `ooda build` / release tarball / `sha256` pin |
| **Install / package** | Same bytes shipped to users | Optional per-machine *wrapper* (not rewriting payload) | Content-addressed store |
| **Load / map (3.11 entry)** | Logical program = artifact | **Yes**: ASLR-class base, optional layout shuffle **in RAM only** | Not hashed as “the release” |
| **JIT / warm path** | Semantics of OODA program | **Yes**: register allocation noise, trampoline rewrites under policy | Dev JIT only if product has VM; not alpha floor |
| **Steady-state metamorphism** | Semantics + contracts still hold | **Yes** only if safety proofs / CFI still valid | Optional hardened profile; off by default |

### 4.2 Interaction with other DESIGN items

| Item | Interaction |
|------|-------------|
| **3.9 Call-graph integrity** | Metamorphic rewrites must preserve hashed legal transitions or re-seal after rewrite; otherwise 3.11 defeats 3.9 |
| **3.10 Shadow-state** | Ghost execution must track the *current* layout, not a stale on-disk view |
| **4.1.1 Dev VM / product run** | Product floor is Backend-C native (`4.x`); metamorphism is not on the alpha critical path |
| **5.2 Web of Code** | Registry mints hashes of **deterministic artifacts**; runtime diversity is local policy |
| **5.1 Self-host** | Pure `.oo` compiler must itself rebuild reproducibly; metamorphic “immune” mode must not poison seed pins |

### 4.3 Profiles (product-facing)

Recommended long-term flags (names illustrative):

| Profile | Deterministic artifact | Runtime diversity |
|---------|------------------------|-------------------|
| `release` (default) | Required | ASLR only (OS) |
| `release+harden` | Required | Load-time diversity + optional periodic rewrite in RAM |
| `audit` | Required + rebuild CI | Diversity **disabled** for forensics |
| `dev` | Best-effort | Hot-reload may invalidate long-lived addresses (document) |

### 4.4 What “mathematically identical logical output” means

DESIGN claims metamorphism preserves logical output. For openOODA that must mean:

1. **Observable pure functions** (no `&TimeCap` / `&RandCap`) remain deterministic.  
2. **I/O via caps** may still be non-deterministic only through granted caps (already sandboxed).  
3. **Memory safety / ARC** invariants hold across rewrite epochs.  
4. **Contract `ensures`** still apply; rewrites are not a license to weaken verification.

## 5. Threat / failure model

### Prevents (when policy is enforced)

| Threat | How boundary helps |
|--------|--------------------|
| Compromised CI injects different payload than signed source tree | Independent rebuild mismatch detects injection |
| “Metamorphic” excuse for non-reproducible releases | Policy forbids on-disk polymorphism as the release identity |
| Single static ROP chain across all victims | Load/JIT diversity breaks shared offsets (when 3.11 exists) |

### Does **not** prevent

| Residual | Why |
|----------|-----|
| Compromised **source** | Reproducible builds faithfully reproduce malicious source |
| Compromised **toolchain** | Same malicious compiler → same “reproducible” evil binary |
| Info-leak of randomized layout (side channels) | Diversity weakens but does not eliminate targeting |
| Formal proof of “immune every few ms” | Unimplemented; physics/performance limits |
| Hostile rewrite of running process with debugger | Local root / ptrace still wins |

### Failure modes of a bad implementation

1. **Entropy in object files** (timestamps, build IDs, unsorted maps) → false “3.11” that only breaks 4.3.2.  
2. **Self-modifying code without W^X policy** → new RCE surface.  
3. **Debuggers and crash dumps unusable** → operator refuses harden profile.  
4. **Antivirus false positives** — defensive metamorphism can look like malware engines; packaging must document intent.

## 6. Alternatives considered

| Alternative | Verdict | Why rejected / deferred |
|-------------|---------|-------------------------|
| **On-disk unique binary per install** | Reject as release identity | Breaks content-addressing, audit, and Web of Code |
| **Diversity only via ASLR** | Accept as **MVP harden** | Cheap, OS-provided; does not need full 3.11 |
| **Diversifying compiler (different .o each build)** | Reject for release hashes | Same as non-reproducible builds |
| **Multivariant N copies on disk** | Defer | Storage cost; still need a primary hash for “the” package |
| **No metamorphism ever** | Acceptable product choice | Honest: drop 3.11 or mark research-only; keep 4.3.2 |
| **Full continuous rewrite every few ms** | Defer / research | Extreme cost; interacts poorly with CFI, debugging, and embedded |
| **Encrypt payload on disk, decrypt unique in RAM** | Partial | Disk ciphertext can still be reproducible; keys/load path carefully designed |

**Chosen synthesis (DESIGN §6):** deterministic **on disk**; metamorphic **in RAM** (load/JIT/optional runtime), never in the release hash identity.

## 7. Product reality (alpha honesty)

| Layer | Status (PM.md) | Evidence |
|-------|----------------|----------|
| **6.1 policy** | **not-started** as engineered gate | Text only in `spec/DESIGN.md` §6 |
| **3.11 metamorphic** | **not-started** | No runtime rewriter, no harden profile |
| **4.3.2 reproducible** | **not-started** | No `SOURCE_DATE_EPOCH` / hermetic build contract in product rails |
| **Product floor** | **4.x Backend-C done (alpha)** | `emit-c` + `chs_rt` + gcc; self-host via seed |
| **Dev “JIT”** | DESIGN aspirational | Product `ooda run` is **native Backend-C**, not bytecode JIT |

**Honest alpha claim:** openOODA does **not** yet offer either pole of this tension. The research value of 6.1 is to **freeze the policy** before either feature lands, so implementers do not encode the wrong phase.

When work starts, prefer:

1. **4.3.2 first** (audit value for self-host pins and releases).  
2. **ASLR / PIE hygiene** as free diversity.  
3. **3.11 only behind `release+harden`**, off by default, with audit profile that freezes layout.

## 8. Open research questions

1. Can continuous in-RAM rewriting preserve **3.9 call-graph hashes** without pausing the world?  
2. What is a **safe rewrite interval** on bare metal / embedded (4.1.5) vs server?  
3. How do we **symbolicate** crashes under metamorphism without shipping a side-channel of the live layout?  
4. Should **Web of Code (5.2)** attest *semantic* hashes (IR) instead of machine code when harden profiles differ by arch?  
5. Does defensive metamorphism trigger **AV / EDR** heuristics enough to be non-viable for open-source distribution?  
6. Interaction with **hot-code reload (4.2)** — is reload a controlled metamorphic epoch?

## 9. Acceptance criteria (for PM status promotion)

### `not-started` → `partial` (policy engineered)

- [ ] Written **build profile matrix** checked into product docs (`bootstrap/` or `DESIGN` product note).  
- [ ] CI job: same sources twice → **byte-identical** Backend-C intermediate and/or final binary under `audit` profile (even if only `.c` emit is pinned first).  
- [ ] Explicit test that **no** build path embeds wall-clock or hostname in default release artifacts.  
- [ ] Document: metamorphism **must not** change release `sha256`.

### `partial` → `done` (boundary proven)

- [ ] 4.3.2: independent rebuild of a pinned release matches published hash on two machines/CI images.  
- [ ] If 3.11 ships: harden profile mutates **only** process memory (or JIT code cache); disk hash unchanged before/after run.  
- [ ] 3.9/CFI interaction tests: rewrite epoch does not open arbitrary control flow.  
- [ ] Audit profile disables diversity; crash dumps match static symbols.

## 10. References

1. openOODA `spec/DESIGN.md` §3.11, §4.3.2, §6.  
2. openOODA monorepo `PM.md` rows 3.11, 4.3.2, 6.1, 4.x.  
3. Reproducible Builds project: <https://reproducible-builds.org/>  
4. C. Lamb & S. Zacchiroli, *Reproducible Builds: Increasing the Integrity of Software Supply Chains*, arXiv:2104.06020 — <https://arxiv.org/pdf/2104.06020>  
5. `SOURCE_DATE_EPOCH` specification — <https://reproducible-builds.org/docs/source-date-epoch/>  
6. ASLR (industry): OS-level load randomization vs fixed on-disk images.  
7. Polymorphic/metamorphic code literature (malware mutation engines; defensive diversity is the dual).  
8. Sibling research stubs: [RP-3-11](./RP-3-11-polymorphic-metamorphic-binaries.md), [RP-4-3-2](./RP-4-3-2-deterministic-reproducible-builds.md).

---

*Series: [Research papers index](./README.md). Template: [TEMPLATE.md](./TEMPLATE.md). Conflicts index: [CONFLICTS.md](./CONFLICTS.md).*
