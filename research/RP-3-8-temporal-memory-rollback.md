# RP-3.8: Temporal memory (state rollback)

| Field | Value |
|-------|--------|
| **Paper ID** | `RP-3.8` |
| **DESIGN.md** | §3 Safety — *Temporal memory (state rollback)* |
| **Status** | `draft` |
| **PM.md row** | `3.8` |
| **Product mapping** | **not-started** |
| **Conflicts** | Fights **3.7** ARC/RAII instant free. Read § Conflicts; DESIGN §6; RP-6.2. |

## 1. Why this is in DESIGN.md

DESIGN.md §3 says:

> **Temporal memory (state rollback):** "Undo for RAM." Variables keep their past states. If a fatal crash occurs, the runtime can move memory back 3 seconds. It goes to a known safe state and runs a fallback path. It does not cause a segmentation fault.

This is a **resilience** feature. It is not a time-travel debugger product. It makes the damage area smaller when contracts fail, panics occur, or memory safety fails. This lets agent-driven systems **recover**. They do not stop in the middle of a loop. It operates with contracts (1.2), fuzzing (3.6), and narrative diagnostics (5.5).

DESIGN §6 gives the hard constraint: temporal storage must not fight default ARC free.

## 2. Problem statement

### 2.1 What breaks without it

| Scenario | Result without temporal memory |
|----------|--------------------------------|
| Contract `ensures` fail during mutation | Partial corrupt state. Process stops. |
| Agent-generated bad patch at runtime | Hard fault. You lose the live session or hot state. |
| Rare use-after-free (UAF) during ARC free enablement | Segmentation fault with no recovery path. |
| Long-running daemon | A single fault stops the OODA loop. |

### 2.2 Stakeholders

| Actor | Need |
|-------|------|
| **Operator or runtime** | Survive normal faults with bounded memory limits. |
| **AI agent** | Retry or use a fallback path after a bad Act step. |
| **Debugger (future)** | Optional time-travel. This is a related but different product. |
| **Adversary** | Must not use rollback as a free oracle or a state confusion gadget. |

### 2.3 Scope boundaries

**In scope (DESIGN):** crash or fault recovery window (almost 3 seconds), historical values for opted-in state, fallback path execution.

**Out of scope for the first release:** full-process CRIU migration, distributed snapshot consensus, unlimited history. We also do not replace reproducible builds or audit logs.

## 3. Related work

### 3.1 Software transactional memory (STM)

- **Herlihy and Moss (1993)** — *Transactional Memory: Architectural Support for Lock-Free Data Structures* — hardware TM inspiration.
- **Shavit and Touitou** — software transactional memory formulations.
- **Harris, Marlow, Peyton Jones, Herlihy (2005)** — *Composable Memory Transactions* (Concurrent Haskell) — atomic composition, retry.
- **DSTM or DSTM2 (Herlihy et al.)** — object-based STM frameworks.

**Takeaway for openOODA:** STM gives **optimistic mutation and abort**. This is closer to **3.10 shadow-state** for semantic commit. Temporal memory gives **time-indexed history and crash rollback**. It overlaps with STM only when a transaction equals the last mutations of N milliseconds.

### 3.2 Checkpoint and restore

- **CRIU (Checkpoint/Restore In Userspace)** — Freezes Linux processes or containers. It dumps memory, file descriptors, and TCP. It restores them later. Operators use it for live migration, snapshots, and debugging.
- **Virtual machine or container snapshots** — Coarse and high latency. They are not variable-level "undo for RAM".
- **Incremental or lazy restore** (CRIU lineage) — Pages on demand. This is relevant for large memory heaps.

**Takeaway:** CRIU uses an **OS-process grain**. openOODA needs **language-grain** temporal types and ring buffers of almost 3 seconds. It must not dump the full process on every fault because it is too slow for the OODA loop.

### 3.3 Time-travel debugging

- **Mozilla `rr`** — Record and replay. It does reverse execution through checkpoints and forward replay under gdb.
- **UndoDB and commercial TTD** — Similar record and replay products.
- **PANDA and whole-system record** — Used for research and forensics.

**Takeaway:** TTD optimizes **developer diagnosis**, not production crash fallback. openOODA can expose `ooda replay` (SPEC §15) later with similar checkpoint ideas. The 3.8 production path must stay lighter.

### 3.4 Persistent and holographic memory (adjacent)

DESIGN 4.4 holographic persistence is **immortal disk-backed state**. It is not a short-window RAM undo. Do not mix them.

## 4. Design rationale for openOODA

### 4.1 Opt-in temporal model (DESIGN §6)

```text
default type T      → ARC free on death (3.7).
temporal type T     → Append-only or COW log in Event Log Arena.
                      Delete data older than 3 seconds or capacity limit.
fault               → Restore temporal roots to the last safe epoch.
                      Run fallback path. This ensures a recovery path.
```

### 4.2 Proposed runtime shape

1. **Epoch clock** — A monotonic runtime epoch or logical tick. This can require a `&TimeCap` policy if it operates in a sandbox. Read 3.2.
2. **Event Log Arena** — A ring buffer of snapshots or deltas for `temporal` allocations.
3. **Safe points** — Restore points include contract boundaries, capability checks, and explicit `checkpoint!()` calls.
4. **Fallback path** — The user or supervisor defines the fallback path. It must not do silent retries forever (DoS).
5. **Capabilities** — A rollback must not resurrect revoked capabilities without a new check (3.1).

### 4.3 Interaction matrix

| Feature | Interaction |
|---------|-------------|
| **3.7 ARC** | Temporal objects do not use instant free. Read § Conflicts. |
| **3.10 Shadow-state** | Shadow is speculative and looks ahead. Temporal looks behind. They can operate together. Shadow abort means no log append. Temporal restore moves to an earlier epoch. |
| **1.2 Contracts** | An `ensures` failure causes a restore to the pre-condition snapshot. |
| **3.3 Allocation quotas** | Log size counts against the capacity limit. Delete data under pressure. |
| **4.2 Hot reload** | A reload can invalidate code pointers in old snapshots. Use version epochs. |
| **5.3 Concurrency** | Use temporal logs for each task. Do not do a cross-task silent rollback. |

## 5. Threat and failure model

### 5.1 Prevention and mitigation

| Failure | Mitigation |
|---------|------------|
| Fatal panic with partial heap mutation | Roll back the temporal roots and run the fallback path. |
| Contract violation after writes | Restore to the pre-call snapshot. |
| Transient agent error | Do a bounded retry with a clean state. |

### 5.2 What it does not prevent

| Issue | Notes |
|-------|-------|
| Adversarial memory corruption of the log | It requires integrity checks (checksums or 3.9 adjacency). |
| Non-temporal external side effects | It does not undo disk or network operations. Keep capabilities and journals separate. |
| Infinite fault loops | You require a maximum restore count or a circuit breaker. |
| Full process compromise | Rollback is not a sandbox. |

### 5.3 Security caveats

- Restored secrets can **show again** after a logical wipe. Examine the interaction with `#[Secret]` (3.5).
- The timing of prune against free can make **oracle** channels if you do not use a constant policy.
- A rollback across Foreign Function Interface (FFI) (6.3) is not safe unless you gate external effects.

## 6. Alternatives considered

| Alternative | Decision | Why |
|-------------|----------|-----|
| Full-process CRIU on every fault | **Reject as default** | It is too slow and heavy for a language runtime. |
| Always-on record and replay (`rr` style) | **Developer-only option** | It has a high overhead. It is not for a zero-millisecond production path. |
| STM for all memory | **Reject** | It has a high throughput cost. It uses different semantics. |
| No history. Only restart the task. | **Insufficient** | It loses the DESIGN "undo for RAM" goal. |
| Unlimited immutable log | **Reject** | It causes RSS limits or DoS problems. |

## 7. Product reality (alpha honesty)

**PM.md `3.8`: not-started.**

| Item | Status |
|------|--------|
| `temporal` keyword or type qualifier | **not-started** |
| Event Log Arena | **not-started** |
| Crash rollback and fallback | **not-started** |
| Integration with the ARC free path | **not-started** (Blocked on the 3.7 free residual and design). |
| CRIU or OS checkpoint hooks | **not-started** (Not necessary for the MVP). |
| Time-travel debugger user experience | **not-started** (Adjacent to SPEC replay). |

No product API, runtime, or tests have temporal rollback today. Any demo that shows "undo for RAM" without a PM promotion is incorrect.

## 8. Open research questions

1. **Snapshot grain:** Do we use full object COW, field-level deltas, or page-level `mprotect`?
2. **3-second prune:** Do we use a wall clock (requires a TimeCap policy) or an instruction epoch count?
3. **What is a "safe state"?** Is it the last successful `ensures` check? Is it the last capability check? Do we only use explicit markers?
4. **Interaction with Backend-C stack frames:** Do we restore the heap only, or the stacks too?
5. **Multi-thread operations:** Do we use coordinated epochs or only task-local epochs?
6. **Proof obligations:** Can contracts show "rollback-safe" functions?

## 9. Acceptance criteria (for PM status promotion)

### not-started to smoke

- [ ] The language surface for `temporal` (or attribute) parses and does type-checks.
- [ ] The runtime ring buffer stores 1 or more snapshots. It restores them under a test harness.
- [ ] Write a documented non-goal list (no full CRIU claim).

### smoke to partial

- [ ] Integrate with ARC. Defer temporal free to prune operations. Make sure that no UAF occurs in the arc+temporal stress test.
- [ ] Make the contract failure path restore the data and run the fallback path.
- [ ] Implement capability accounting for log memory or a hard maximum limit.

### partial to done

- [ ] Document a 3-second (or configurable) prune limit. Keep the RSS bounded under load.
- [ ] Make a self-host or product daemon show recovery from an injected fault.
- [ ] Verify that cross-checked RP-6.2 acceptance tests pass.

## 10. References

1. openOODA `spec/DESIGN.md` §3 Temporal memory; §6 ARC vs temporal.
2. openOODA `PM.md` row 3.8; related residual `ARC_M2_RESIDUAL.md` (3.7 only).
3. Herlihy, M. and Moss, J.E.B. (1993). *Transactional Memory: Architectural Support for Lock-Free Data Structures.* ISCA.
4. Harris, T., Marlow, S., Peyton Jones, S., Herlihy, M. (2005). *Composable Memory Transactions.* PPoPP.
5. CRIU project — https://criu.org/ — Checkpoint/Restore In Userspace.
6. Mozilla `rr` — https://rr-project.org/ — Record/replay and reverse execution through checkpoints.
7. Shavit, N. and Touitou, D. — Software Transactional Memory (foundational STM).
8. ACM Queue — *The Record-and-Replay Approach to Debugging* (checkpoint and reverse execution overview).

---

## Conflicts

### Conflict A — **3.8 temporal fights 3.7 ARC free** (primary)

**Problem:** Instant free erases the bytes that a temporal restore requires. A restore without free coordination causes a UAF. Holding all frees stops 0-millisecond GC.

**Solutions (align with RP-3.7 Conflicts)**

| ID | Solution | Recommendation |
|----|----------|----------------|
| S1 | Opt-in `temporal` only | **Required** |
| S2 | Event Log Arena separate from the ARC heap | **Required** |
| S3 | COW snapshots with RC on snapshot nodes | Preferred implementable path |
| S4 | Generational prune (drop epoch N−k) | Preferred for bulk reclaim |
| S5 | Global free-hold for 3 seconds | Reject as default. Use for emergency only. |

**Invariant:**  
`∀ p. restored(p) ⇒ p was temporal_root ∨ p reachable from temporal_root at epoch e.`  
Non-temporal pointers are **invalid** after a restore operation.

**Tests that define "resolved"**

1. Free non-temporal data under a churn. Inject a fault. Make sure that the process recovers **without** reading freed non-temporal memory.
2. Mutate a temporal object. Roll back the object. Make sure that the values match the pre-mutation snapshot.
3. Keep the RSS under a temporal workload within the configured limit after a prune operation.

### Conflict B — Temporal vs deterministic testing (3.2 TimeCap)

A wall-clock 3-second window fights pure deterministic tests. **Solution:** Use epoch counters in test or fuzz builds. Use the wall clock only with a `&TimeCap` in production.

### Conflict C — Temporal vs external effects

A rollback cannot undo sent packets. **Solution:** Temporal memory controls RAM only. Input/Output (I/O) remains capability-journaled or idempotent. Document that "RAM undo is not world undo."

### Conflict D — Overlap with 3.10 shadow-state

Both functions "cancel" work. **Solution:** A shadow is speculative forward work (pre-commit). Temporal memory is historical reverse work (post-commit recovery). They have different APIs. Shared arena technology is possible.

---

*Series: [Research papers index](./README.md). Template: [TEMPLATE.md](./TEMPLATE.md).*
