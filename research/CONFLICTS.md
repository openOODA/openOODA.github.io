# CONFLICTS.md — Major DESIGN tensions (openOODA)

**Purpose:** Single index of **real fights** between DESIGN items (and DESIGN vs product reality).  
**Style:** Same boundary/policy discipline as DESIGN §6.  
**Status:** Research synthesis (`draft`). Not a substitute for `PM.md` progress.

| Doc | Role |
|-----|------|
| `openOODA/DESIGN.md` §6 | Three canonical tensions (policy one-liners) |
| [RP-6-1](./RP-6-1-tension-metamorphic-vs-deterministic.md) · [RP-6-2](./RP-6-2-tension-arc-vs-temporal-memory.md) · [RP-6-3](./RP-6-3-tension-caps-vs-ffi.md) | Full research drafts for §6 |
| **This file** | **All** major conflicts known to the research program, including product honesty fights |
| monorepo `PM.md` | What is actually shipped |

**Legend — Owner decision needed?**  
**Y** = product owner must pick a profile/priority before engineering ratholes.  
**N** = DESIGN §6 (or this file) already states a workable default; implementers should follow it.

---

## How to read each conflict

For every item:

| Field | Meaning |
|-------|---------|
| **Problem** | What collides |
| **DESIGN items fighting** | IDs / sections |
| **Why it matters** | Security, DX, honesty, or schedule impact |
| **Proposed solution** | Boundary/policy (DESIGN §6 style) |
| **Owner decision?** | Y/N |

---

## C1 — Metamorphic binaries vs deterministic builds

| | |
|--|--|
| **Problem** | Runtime code/layout mutation wants entropy; supply-chain verification wants bit-identical artifacts from the same sources. |
| **DESIGN items** | **3.11** (polymorphic metamorphic binaries) vs **4.3.2** (deterministic reproducible builds); policy **6.1** |
| **Why it matters** | Without a phase split, releases become unauditable *or* “immune system” never ships. Web of Code (5.2) and seed pins need hashes. |
| **Proposed solution** | **On-disk identity is deterministic.** Metamorphism only in **RAM** at load / JIT / optional harden runtime. Release `sha256` never depends on polymorphic entropy. Profiles: `audit` (no diversity), `release` (ASLR), `release+harden` (in-RAM mutation). See [RP-6-1](./RP-6-1-tension-metamorphic-vs-deterministic.md). |
| **Owner decision?** | **N** for the phase split (DESIGN §6 already decides). **Y** for whether 3.11 is ever productized vs research-only. |

**PM:** 3.11 / 4.3.2 / 6.1 all effectively unbuilt (policy text only).

---

## C2 — ARC free vs temporal memory

| | |
|--|--|
| **Problem** | ARC/RAII destroys values at last release; temporal rollback needs retained history (~3s event log). Instant free ⇔ no history. |
| **DESIGN items** | **3.7** (0ms GC ARC/RAII) vs **3.8** (temporal memory); policy **6.2** |
| **Why it matters** | Naive mix → UAF on restore or silent “GC” that kills the 0ms claim. Crash auto-heal marketing without arenas is false. |
| **Proposed solution** | **Default ARC destroy.** Temporal is **opt-in** (`temporal struct` / equivalent) allocated in a **ring-buffer Event Log Arena** with prune (≤T) and generation-checked handles. Ordinary path never pays the log. Pair with cap I/O record/replay as a cheaper reliability MVP. See [RP-6-2](./RP-6-2-tension-arc-vs-temporal-memory.md). |
| **Owner decision?** | **N** for opt-in arena (DESIGN §6). **Y** for default T window, and whether effect-replay ships before heap temporal. |

**PM:** 3.7 partial; 3.8 not-started; 6.2 partial (ARC side only).

---

## C3 — Capability sandbox vs C/C++ FFI

| | |
|--|--|
| **Problem** | Caps default-deny effects; C FFI can perform arbitrary syscalls and memory ops outside the lattice. |
| **DESIGN items** | **3.1** (unified caps) vs **4.3.3** (compile-time FFI) / SPEC §10; policy **6.3**; related **4.3.1** LTO |
| **Why it matters** | Without an explicit breach, “capability-secure” is theater once SQLite is linked. Agents must not get ambient foreign authority. |
| **Proposed solution** | Any user FFI / `import "C"` requires **`&UnsafeFFICap`** (or finer `FfiCap<…>` later). Taint foreign returns; generated wrappers always thread the cap. Runtime `chs_rt` is **TCB**, not user FFI. Prefer isolation (process/Wasm/CHERI) for high-assurance profiles. See [RP-6-3](./RP-6-3-tension-caps-vs-ffi.md). |
| **Owner decision?** | **N** for “FFI = named breach cap” (DESIGN §6). **Y** for attenuation granularity and whether out-of-process FFI is required for “secure” badge. |

**PM:** Caps partial (magic tokens); FFI / UnsafeFFICap not-started.

---

## C4 — DESIGN “JIT `ooda run`” vs product native Backend-C run

| | |
|--|--|
| **Problem** | DESIGN **4.1.1** advertises development JIT / bytecode VM for sub-ms `ooda run`. Product floor **`ooda run`** is **emit-c + compile + native exec** (Backend-C). Bytecode is **interpreter smokes**, not product run. |
| **DESIGN items** | **4.1.1** (dev bytecode/JIT) vs **4.x** (Backend-C product floor); marketing vs **ES.4** / **1.1** speed claims |
| **Why it matters** | Agents and docs that assume “`ooda run` = VM” mis-test and mis-benchmark. Dual stories confuse contributors. |
| **Proposed solution** | **Product truth wins in PM and user docs:** `run` = native Backend-C until a real VM is the default. Keep DESIGN 4.1.1 as **north-star** execution target. Label bytecode path `smoke` / `experimental`. Never claim sub-ms JIT for alpha native pipeline. Paper: [RP-4-1-1](./RP-4-1-1-development-bytecode-vm.md), [RP-4-x](./RP-4-x-backend-c-product-floor.md). |
| **Owner decision?** | **Y** — Is Backend-C the long-term default `run`, or must JIT replace it before beta? |

**PM:** 4.x done (alpha); 4.1.1 partial (interpreter smokes only).

---

## C5 — Hive-mind fuzzing vs capability/privacy and pure self-host

| | |
|--|--|
| **Problem** | **2.4** global P2P hive-mind fuzzing wants idle compilers to share mutations/contracts overnight. That implies network, possibly code/contract exfil, and non-pure trust. Conflicts with **3.1** least privilege, privacy, and **5.1** “pure OODA security chain.” |
| **DESIGN items** | **2.4** vs **3.1** / **3.2** (time/entropy) / **5.1** / **5.2** |
| **Why it matters** | Corporate and agent users will refuse a compiler that phones home with ASTs. Self-host purity does not magically make P2P safe. |
| **Proposed solution** | **Opt-in daemon only**; default **off**. Hive traffic requires explicit caps (`&NetCap` + future `&HiveCap`) and a **privacy profile**: hash-only findings, no full source upload unless user grants. Pure self-host still builds; hive is an **ecosystem service**, not a compiler correctness dependency. Local **3.6** fuzzer remains the offline path. |
| **Owner decision?** | **Y** — Ship local fuzz only for beta, or design hive threat model now? |

**PM:** 2.4 not-started; 3.6 partial (Int-domain); 5.1 partial.

---

## C6 — Sub-second OODA feedback vs heavy formal / LLM / hive goals

| | |
|--|--|
| **Problem** | **1.1 / ES.4** demand tight interactive loops (human + agent). **2.3** intent-driven LLM bodies, **2.4** hive, **3.10** shadow-state, full formal verification, and rich **3.6** multi-type fuzz are **heavy** (seconds–hours). |
| **DESIGN items** | **ES.4**, **1.1** vs **2.3**, **2.4**, **3.6** (full), **3.9–3.11**, formal proof goals |
| **Why it matters** | If every save waits on SMT/LLM/network, the language fails its own philosophy. |
| **Proposed solution** | **Tiered modes:** <br>• **Interactive (default):** parse, check, caps, JSON diags, fast native/emit — budget sub-second where feasible. <br>• **Async (background):** fuzz, hive, LLM fill-in, deep proofs — never block `ooda check` unless `--wait`. <br>• **Release:** optional full gates. LSP (5.7) shares the interactive tier. |
| **Owner decision?** | **Y** — Hard latency budgets per command for beta marketing claims. |

**PM:** Sub-second partial (product loops real; sub-ms not claimed); heavy goals mostly not-started.

---

## C7 — “0ms GC” claim vs residual leak-safe free in product

| | |
|--|--|
| **Problem** | DESIGN **3.7** claims 0ms GC and leak elimination via ARC/RAII. Product M2 historically (and residual messaging) uses **leak-safe** free (decrement without reclaim) or blocked free on self-host paths. That is **not** the same as 0ms *and* leak-free. |
| **DESIGN items** | **3.7** vs product reality (`ARC_M2_RESIDUAL.md`, PM M2 **PARTIAL**) |
| **Why it matters** | Overclaim destroys trust with systems programmers; agents generate code assuming real reclaim. |
| **Proposed solution** | **Honest layers:** (1) No tracing STW GC — true direction. (2) Retain/release instrumentation — partial shipped. (3) Reclaim on zero — gate for “memory-safe ARC done.” Marketing and PM must say **leak-safe residual** until free is default and self-host green. Separate conflict from **C2** (temporal); this is ARC completeness vs slogan. |
| **Owner decision?** | **Y** — Is beta blocked on true free, or is leak-safe acceptable with loud docs? |

**PM:** 3.7 partial; residual doc authoritative.

---

## C8 — Cryptographic / biometric caps vs process-local magic tokens

| | |
|--|--|
| **Problem** | DESIGN **3.1** scales to biometric attestation and high-assurance caps. Product implements **magic integers** injected in `main` (`STATIC_CAPS.md`) — forgeable by hostile binaries. |
| **DESIGN items** | **3.1** (full ladder) vs product partial; **ES.2** |
| **Why it matters** | Saying “capability-secure” without qualifying **threat model** misleads. |
| **Proposed solution** | Document two levels: **L0 process integrity** (today: static + magic token) vs **L1 unforgeable object-caps / attestation** (future). Never claim L1. Hostile-native threat needs OS sandboxing or crypto caps. |
| **Owner decision?** | **N** for L0 honesty. **Y** for roadmap priority of L1. |

---

## C9 — Pure self-host (5.1 / 5.1a) vs C runtime TCB and host gcc

| | |
|--|--|
| **Problem** | **5.1** wants full ecosystem in pure OODA for cryptographic security chain. Product **5.1a** is pure `.oo` compiler sources but still **seed binary + gcc/clang + C runtime (`chs_rt`)**. |
| **DESIGN items** | **5.1** vs **4.x** Backend-C floor; purity vs bootstrap |
| **Why it matters** | “Zero product `.rs`” ≠ “zero TCB.” Supply-chain story must name the C/tooling root of trust. |
| **Proposed solution** | **Layered purity:** (P0) no Rust in product path — alpha done. (P1) pin seed + runtime hashes. (P2) reproduce runtime from auditable C. (P3) optional eventual self-hosted backend without external cc — research. Do not claim P3 as alpha. |
| **Owner decision?** | **N** for P0/P1 framing. **Y** for how far P2 goes pre-beta. |

---

## C10 — Hot-code reload / live AST swap vs deterministic builds and CFI

| | |
|--|--|
| **Problem** | **4.2** hot reload swaps code in a live process. Conflicts with frozen layout assumptions for **3.9** call-graph integrity, **3.11** metamorphic epochs, and **4.3.2** “what binary am I running?” |
| **DESIGN items** | **4.2** vs **3.9**, **3.11**, **4.3.2**, **4.1.1** |
| **Why it matters** | Live coding is a DX win; integrity features need a **reload = new epoch** model or they false-trigger / go blind. |
| **Proposed solution** | Hot reload is **dev profile only**. Each successful reload reseals call-graph hashes and starts a new metamorphic epoch. Production builds disable reload. Reproducible artifacts describe **pre-reload** image only. |
| **Owner decision?** | **N** if reload stays dev-only. **Y** if production hot-patch is a goal. |

**PM:** 4.2 not-started.

---

## C11 — Shadow-state / multi-path execution vs performance and determinism

| | |
|--|--|
| **Problem** | **3.10** ghost execution ahead of commit fights **ES.4** latency and **3.2** deterministic tests (extra entropy, timing). |
| **DESIGN items** | **3.10** vs **ES.4**, **1.1**, **3.2** |
| **Why it matters** | Doubling work on critical modules can destroy sub-second loops and embedded budgets (**4.1.5**). |
| **Proposed solution** | Shadow-state is **opt-in per module** / release harden profile; off in interactive check. Deterministic tests use synthetic clocks. Never default-on for all code. |
| **Owner decision?** | **Y** — Is 3.10 research-only or a harden SKU? |

**PM:** 3.10 not-started.

---

## C12 — Fearless concurrency (message + caps) vs shared ARC and temporal arenas

| | |
|--|--|
| **Problem** | **5.3** wants no shared mutable memory (message passing + cap relinquish). ARC refcounts and temporal arenas are **shared-heap** concepts unless carefully regioned. |
| **DESIGN items** | **5.3** vs **3.7**, **3.8**, **6.2** |
| **Why it matters** | Cross-thread retain/release races; temporal restore across threads is a consistency nightmare. |
| **Proposed solution** | **Transfer or deep-copy** across actors; no shared `&mut` heaps. Temporal arenas are **per-actor** unless explicitly `shared temporal` under a research model. Prefer channels carrying values + attenuated caps. |
| **Owner decision?** | **N** for “no shared mut” default. **Y** for any shared-heap exceptions (e.g. work-stealing pools). |

**PM:** 5.3 not-started.

---

## C13 — Intent-driven LLM compilation (2.3) vs contracts, caps, and reproducibility

| | |
|--|--|
| **Problem** | **2.3** fills blank bodies via embedded LLM. Output may be nondeterministic, cap-violating, or non-reproducible across machines — fighting **4.3.2**, **3.1**, **1.2**. |
| **DESIGN items** | **2.3** vs **1.2**, **3.1**, **4.3.2**, **ES.4** |
| **Why it matters** | AI-filled bodies are a supply-chain and flaky-CI hazard if treated as normal source. |
| **Proposed solution** | LLM fill is a **dev command** that writes **checked-in source** after cap/contract verification; release builds **never** call network LLM. Pin model/seed in lockfile if generative step is retained. Fail closed if caps not satisfied. |
| **Owner decision?** | **Y** — Allow generative steps in CI at all? |

**PM:** 2.3 not-started.

---

## C14 — Holographic persistence (4.4) vs ARC lifetimes and temporal prune

| | |
|--|--|
| **Problem** | **4.4** immortal Merkle-mapped structs fight normal ARC drop and temporal 3s prune — “no save()” vs “destroy on scope exit.” |
| **DESIGN items** | **4.4** vs **3.7**, **3.8** |
| **Why it matters** | Unclear ownership → leaks, double-maps, or silent data loss on process exit. |
| **Proposed solution** | **Persistent region** distinct from ephemeral ARC heap (like temporal arena). Types are `persistent struct` / mapped; not default. Explicit unmap; crash consistency is the feature, not scope drop. |
| **Owner decision?** | **N** for separate region. **Y** for storage engine priority. |

**PM:** 4.4 not-started.

---

## C15 — MaxCycles / CPU quotas vs intentional unbounded services and JIT

| | |
|--|--|
| **Problem** | **3.4** `#[MaxCycles]` wants compile-time finite work. Servers, REPLs, and JITs are intentionally unbounded. |
| **DESIGN items** | **3.4** vs **4.1.1**, **4.2**, long-running **std::os** services |
| **Why it matters** | Over-application breaks legitimate programs; under-application fails the DoS story. |
| **Proposed solution** | MaxCycles for **pure/library** functions and untrusted agent snippets. `main` / server loops use **runtime budgets** or opt-out with audit. Static proof where possible; dynamic fuel for the rest. |
| **Owner decision?** | **Y** — Default for agent-loaded modules? |

**PM:** 3.4 not-started.

---

## C16 — Token-minimized outline/reflect vs narrative diagnostics depth

| | |
|--|--|
| **Problem** | **2.2** minimizes tokens for agents; **5.5** wants rich causal stories. Same diagnostic channel cannot be both maximal and minimal. |
| **DESIGN items** | **2.2** vs **5.5**, **2.1** JSON errors |
| **Why it matters** | Wrong default floods context windows or starves humans. |
| **Proposed solution** | **Dual emit:** machine JSON slim by default (`--json-errors`); narrative on human CLI or `--explain`. `outline` stays compressed; `reflect --full` optional. |
| **Owner decision?** | **N** (dual channel is clear). |

**PM:** 2.2 done; 5.5 not-started.

---

## Priority matrix (research recommendation)

| Priority | Conflicts | Rationale |
|----------|-----------|-----------|
| **P0 — honesty now** | C4, C7, C8, C9 | Stop false claims; cheap doc/PM discipline |
| **P1 — DESIGN §6 engineering** | C1, C2, C3 | Freeze boundaries before features land |
| **P2 — product architecture** | C5, C6, C13 | Mode splits (interactive vs async vs opt-in net) |
| **P3 — later systems** | C10–C12, C14–C15 | Depend on concurrency/persistence/reload work |

---

## Cross-reference: DESIGN §6 papers

| ID | Conflict | Paper |
|----|----------|-------|
| 6.1 | C1 | [RP-6-1-tension-metamorphic-vs-deterministic.md](./RP-6-1-tension-metamorphic-vs-deterministic.md) |
| 6.2 | C2 | [RP-6-2-tension-arc-vs-temporal-memory.md](./RP-6-2-tension-arc-vs-temporal-memory.md) |
| 6.3 | C3 | [RP-6-3-tension-caps-vs-ffi.md](./RP-6-3-tension-caps-vs-ffi.md) |

---

## References (supporting)

1. openOODA `openOODA/DESIGN.md` §1–§6; monorepo `PM.md`.  
2. Reproducible Builds — <https://reproducible-builds.org/>  
3. Lamb & Zacchiroli, arXiv:2104.06020 — reproducible builds for supply-chain integrity.  
4. Swift ARC — lifetime destroy vs retained history.  
5. Mozilla `rr` / Microsoft TTD — record/replay as alternative to full heap temporal.  
6. Rust/Vale/CHERI literature — FFI as sandbox breach; isolation options.  
7. Product: `ooda/bootstrap/ARC_M2_RESIDUAL.md`, `STATIC_CAPS.md`, `CAPS_MATRIX.md`.  
8. `ooda/fixtures/README.md` — product truth: `ooda run` = native Backend-C.

---

*Series index: [README.md](./README.md). Update this file when new DESIGN fights are discovered or owner decisions land.*
