# RP-3.7: Zero millisecond garbage collection and memory safety (ARC/RAII)

| Field | Value |
|-------|--------|
| **Paper ID** | `RP-3.7` |
| **DESIGN.md** | Section 3 Safety — *Zero millisecond garbage collection and memory safety* |
| **Status** | `draft` |
| **PM.md row** | `3.7` |
| **Product mapping** | **partial** — We keep retain and release on. We keep residual free or leak-safe (`ooda/bootstrap/ARC_M2_RESIDUAL.md`). |
| **Conflicts** | This conflicts with **3.8** Temporal memory (instant free against history). Refer to Section Conflicts. |

## 1. Why this is in DESIGN.md

Section 3 of DESIGN.md says:

> **Zero millisecond garbage collection and memory safety:** Scope-based Resource Acquisition Is Initialization (RAII) and Automatic Reference Counting (ARC) stop memory leaks. They prevent Stop-The-World garbage collection pauses.

Section 14 and Section 16 of SPEC.md support the first principle. Most application memory belongs to a request, a task, or a function block. Garbage collectors use too much CPU to find lifecycle patterns. Execution scopes already define these patterns. Scope-based RAII and region arenas try to give O(1) deallocation. They give zero millisecond stop-the-world pauses. They give C-level steady-state performance.

This paper gives reasons to choose RAII and ARC. We do not choose a tracing garbage collector (GC). We do not choose pure manual `malloc` and `free`. We choose RAII and ARC as the default memory model for AI-native systems code in openOODA. This model gives predictable latency for the OODA feedback loop. It stops Use-After-Free (UAF) and double-free errors. It lets us compile the code in pure Backend-C.

## 2. Problem statement

### 2.1 What breaks without it

| Failure mode | User impact |
|--------------|-------------|
| Tracing GC pauses | Agent and human edit-run loops jitter. Hard real-time budgets and game-frame budgets break. |
| Manual C-style ownership | UAF, double-free, and leaks cause many zero-day errors. They cause approximately 70% of memory-safety bugs. |
| Unbounded heap growth | The self-host compiler and long-lived agents run out of memory under load. |
| Non-deterministic free timing | Contracts, fuzzing (3.6), and replay (SPEC Section 15) lose deterministic memory timelines. |

### 2.2 Stakeholders

| Actor | Need |
|-------|------|
| **Human developer** | Predictable latency. No GC tuning. |
| **AI agent** | Safe heap operations without the invention of a free discipline for each patch. |
| **Adversary** | Uses UAF and heap metadata as weapons if ownership is weak. |
| **Self-host or product** | ARC must not prevent a pure rebuild of `oodac`. |

### 2.3 Design target

- **Default path:** Scope drops (RAII) and retain and release (ARC) for shared values. Shared values include strings, lists, and heap objects.
- **Arenas:** Region allocation or bump allocation for request-scoped bulk free.
- **Not claimed yet:** Cycle-collecting GC, full borrow checker, or production leak-free free-on-zero for all types.

## 3. Related work

### 3.1 RAII and ownership

- **C++ RAII** — Resource lifetime connects to scope through constructors and destructors. This is the foundation of modern C++ resource safety. It is not memory-safe without discipline.
- **Rust ownership and borrow checker** — Exclusive ownership and borrow rules stop data races. They stop most UAF at compile time with almost zero runtime cost. Shared ownership with `Rc` or `Arc` is optional. The language does not treat memory leaks as unsafe. Reference cycles with `Rc` or `Arc` can leak. `Weak` breaks cycles without keeping objects alive.
- **Rust book (chapter 15.6)** — This document shows that reference cycles and memory leaks are safe (no undefined behavior). But they are still a resource problem.

### 3.2 Automatic reference counting

- **Swift ARC** — Apple Automatic Reference Counting adds retain and release at compile time. There is no Stop-The-World (STW) GC. Strong reference cycles are a primary problem. The language gives `weak` and `unowned` to break cycles. The Swift Ownership Manifesto moves to finer ownership.
- **Objective-C ARC** — This is a predecessor. It has the same reference cycle bugs.
- **Python and CPython** — Classic reference counting (RC) and cycle GC. This is not a model for zero millisecond system pauses.
- **Rust `Rc` and `Arc`** — Library-level RC with atomics on `Arc`. Cycles need `Weak`.

### 3.3 Arenas and regions

- **Region or arena allocators** — You use these in games, compilers, and request handlers. You free a full generation in O(1). This aligns with SPEC "request or frame" lifetimes.
- **MLKit or region inference** — Academic region systems. They do compile-time region placement.

### 3.4 Comparative takeaway

| System | STW GC? | Cycles | Compile-time ownership | Runtime cost |
|--------|---------|--------|------------------------|--------------|
| Java or Go GC | Yes | Collected | No | Pause and throughput trade |
| Swift ARC | No | Manual weak or unowned | Partial | Retain and release |
| Rust | No | Leak-safe with Weak | Strong | Near zero |
| openOODA target | No | Must address | Growing | RAII, ARC, and arenas |

## 4. Design rationale for openOODA

### 4.1 Layered memory model

```
┌─────────────────────────────────────────────┐
│  Scope RAII drops                           │  ← default, 0ms, deterministic
├─────────────────────────────────────────────┤
│  ARC retain and release                     │  ← strings, lists, shared graphs
├─────────────────────────────────────────────┤
│  Region arenas                              │  ← requests, compile units, frames
├─────────────────────────────────────────────┤
│  temporal (optional) → Event Log Arena      │  ← DESIGN Section 6; see RP-3.8
└─────────────────────────────────────────────┘
```

### 4.2 Interaction with other DESIGN documents

| Leaf | Interaction |
|------|-------------|
| **3.3 Memory quotas** | ARC free and arena reset must charge and refund `&AllocCap` correctly. |
| **3.8 Temporal memory** | Instant free fights history. We use optional `temporal` and ring buffer. |
| **1.1 OODA speed** | No STW. Retain and release must stay cheap for agent feedback loops. |
| **5.3 Concurrency** | Cross-thread sharing needs atomic ARC or message-pass exclusive ownership. |
| **4.x Backend-C** | Emit retain and release into C. The runtime is in `chs_rt_*`. |

### 4.3 Why not tracing GC

A tracing GC conflicts with:

1. Sub-millisecond OODA loop predictability (1.1).
2. Bare-metal or `#![no_std]` targets (4.1.5).
3. Capability reasoning and secret lifetime reasoning (3.1, 3.5). GC roots hide when a secret is dead.

### 4.4 Leak-safety against free-on-zero

Industry precedent (Rust) shows that memory safety does not equal leak freedom. The openOODA product path gives priority to:

1. No UAF from double-free of objects that have aliases.
2. Self-host survival when ARC is on.
3. Free-on-zero as a staged residual procedure. Refer to Section 7.

## 5. Threat and failure model

### 5.1 Prevention (when complete)

| Threat | Mitigation |
|--------|------------|
| Use-after-free | Lifetime ends only when RC is 0 or when scope drops with unique ownership. |
| Double-free | A single owner makes the free decision. |
| STW latency attacks | There is no global collector. |
| Accidental unbounded live set | Scope and arenas reclaim bulk memory. |

### 5.2 Does not prevent

| Residual | Notes |
|----------|-------|
| **Retain cycles** | Similar to Swift. We need weak references or a cycle policy. |
| **Logical leaks** | Containers that grow are still live. |
| **Temporal rollback UAF** | Freeing and then rolling back is a classic fight with 3.8. |
| **FFI free** | C libraries operate outside ARC. They need 6.3 or `&UnsafeFFICap`. |
| **Adversarial OOM** | This needs 3.3 quotas. |

### 5.3 Adversary model

An attacker with a memory-corruption primitive tries to use UAF to get Return-Oriented Programming (ROP). This connects to 3.9 Control-Flow Integrity (CFI). A correct ARC and RAII design makes the corruption primitive surface smaller. It is not a replacement for CFI or capabilities.

## 6. Alternatives considered

| Alternative | Decision | Reason |
|-------------|----------|-----|
| Full tracing GC | **Reject as default** | STW and floating garbage break the zero millisecond goal. |
| Pure borrow checker | **Defer** | High language complexity. High cost for agent user experience. We still need ARC for graphs. |
| Manual free only | **Reject** | This is unsafe for the volume of AI-generated code. |
| RC and cycle GC | **Maybe later** | Cycle GC brings back non-determinism if it is not scoped. |
| Always-arena | **Insufficient** | Shared string graphs and shared list graphs need RC or deep copies. |

## 7. Product reality

**PM.md `3.7`: partial.** The source of truth is monorepo `PM.md` and `ooda/bootstrap/ARC_M2_RESIDUAL.md`.

| Capability | Reality |
|------------|---------|
| Retain and release emission | **Partial and on** (`PURE_NO_ARC=0` product path) |
| Scope drops | **Partial** — Nested bare blocks and formal softeners. |
| `arc_smoke.sh` fixtures | **Smoke** — Early return, concatenate reassign, list push, list get, nested scope string. |
| Free on refcount zero | **Residual and leak-safe** — Release can decrement without `free` for strings and lists. We blocked reclaim for self-host safety. The residual document tracks free-prep. |
| Full ownership analysis | **Not done** — Softeners use regular expressions. They are not a borrow checker. |
| Cycle and weak references | **Not started** |
| Region arenas | **Not started** |
| Interaction with temporal | **Not started** |

**Honesty rule:** Do not say "zero millisecond GC is complete". Do not say "leak-free production" while the free residual policy and the cycle policy remain open. DESIGN is aspiration. PM is product truth.

## 8. Open research questions

1. **Cycle policy:** Do we use language-level `weak` and `unowned`? Do we use static acyclicity? Do we use an optional cycle detector in debug mode only?
2. **When is free-on-zero safe for self-host?** Which static and dynamic invariants close alias holes that blocked free?
3. **Atomic against non-atomic RC:** How do we operate under fearless concurrency (5.3) and message-passing only?
4. **Arena escape analysis:** Can the compiler prove non-escaping allocations and skip ARC?
5. **Contract interaction:** Must `ensures` reason about deallocation and peak live bytes?
6. **Temporal handoff:** What is the correct ABI for the ARC route to the Event Log Arena?

## 9. Acceptance criteria

### partial to done (memory core)

- [ ] We have free-on-zero for core heap types under ARC-on self-host without corruption.
- [ ] We have a documented cycle story. We use weak references or we forbid cycles in safe mode.
- [ ] We have scope drops for all block exits. These include early return and reassign.
- [ ] The `arc_smoke` tests and the self-host pure rebuild operate correctly under free-enabled ARC.
- [ ] The residual document is closed or changed to "known minor".

### done to production-hardened (later)

- [ ] We have an arena keyword or a standard API with capability accounting (3.3).
- [ ] Temporal opt-in can coexist without UAF (cross-check RP-3.8, RP-6.2).
- [ ] Performance budget: The overhead of retain and release is bounded against the pure arena baseline on the agent compile workload.

## 10. References

1. openOODA `spec/DESIGN.md` Section 3, Section 6.
2. openOODA `spec/SPEC.md` Section 14, Section 16.
3. openOODA `PM.md` row 3.7. `ooda/bootstrap/ARC_M2_RESIDUAL.md`.
4. Apple Swift.org — *The Swift Programming Language: Automatic Reference Counting*.
5. Rust Book — *Reference Cycles Can Leak Memory*. Rustonomicon.
6. Bjarne Stroustrup — RAII as C++ resource idiom.
7. Alhazmi — Comparative notes on Rust ownership against Swift ARC.
8. Region inference and arena literature.

---

## Conflicts

### Conflict A — **3.7 (instant ARC free) fights 3.8 (temporal rollback)**

**Nature of the fight**

- ARC and RAII **destroy** values when RC hits 0 or when scope ends.
- Temporal memory must keep those values or their snapshots. They must remain reconstructible for 3 seconds after logical death.
- Classic failure: Free the object. Crash. Roll back. You get a use-after-free of reclaimed storage. Or, the rollback restores a pointer that has no RC metadata.

**DESIGN.md Section 6 resolution**

> Temporal Memory rollback is an **optional** keyword (example: `temporal struct`). For these structures, ARC routes them to a **ring-buffer Event Log Arena**. This arena removes states that are older than 3 seconds. This prevents Use-After-Free segfaults.

**Proposed solutions**

| Solution | Mechanism | Pros | Cons |
|----------|-----------|------|------|
| **S1. Opt-in temporal types** | Only `temporal T` fields enter the event log. Default types free instantly. | This matches DESIGN. Zero cost for the normal path. | Programmers must annotate crash-critical state. |
| **S2. Copy-on-write snapshots** | On mutation of a temporal object, we append an immutable snapshot. We free only after prune. | Clear RC story. Snapshots are immortal until prune. | High memory and write rate. Needs capability. |
| **S3. Generational arenas** | Temporal epoch N lives until epoch N-k is reclaimed. | Fast bulk free of old history. | Coarser than per-object RC. |
| **S4. Tombstone RC** | Free becomes logical free. Physical free is deferred until there is no temporal root. | Compatible with naive ARC emit. | Fragmentation. High complexity. |
| **S5. Disable free** | We hold frees for 3 seconds. | Simple. | Latency and RSS spikes. Fights zero millisecond story. |

**Recommended openOODA policy**

1. **Default = non-temporal, free as soon as possible** (honor 3.7).
2. **Temporal is opt-in and arena-scoped** (honor 3.8 and 6.2).
3. Temporal storage is **not** the standard ARC-free heap. It is a **separate Event Log Arena** with a prune policy.
4. Rolling back **never** resurrects a default pointer. Only temporal handles are valid restore roots.
5. Cross-paper acceptance: RP-3.8 and RP-6.2 must share the same ABI and tests.

See also: [RP-6-2-tension-arc-vs-temporal-memory.md](./RP-6-2-tension-arc-vs-temporal-memory.md), [RP-3-8-temporal-memory-rollback.md](./RP-3-8-temporal-memory-rollback.md).

### Conflict B — ARC retain cost against OODA speed (1.1)

Atomic RC on hot paths can slow agent compile loops. **Mitigation:** Use non-atomic RC in single-threaded tasks. Use arenas for short-lived bulk data. Use escape analysis to skip RC.

### Conflict C — Leak-safe residual against "eliminate memory leaks" marketing

The DESIGN language is absolute. The product is leak-safe by policy in the residual free path. **Mitigation:** We use PM honesty and staged free enablement. Never mark 3.7 as done until the free policy and the cycle policy meet Section 9.

---

*Series: [Research papers index](./README.md). Template: [TEMPLATE.md](./TEMPLATE.md).*
