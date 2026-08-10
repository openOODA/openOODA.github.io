# RP-6.2: Tension: ARC vs temporal memory

| Field | Value |
|-------|--------|
| **Paper ID** | `RP-6.2` |
| **DESIGN.md** | §6 Tensions |
| **Status** | `draft` |
| **PM.md row** | `6.2` |
| **Product mapping** | ARC path **partial** (leak-safe free residual); temporal memory **not-started** |
| **Related DESIGN** | `3.7` (0ms GC ARC/RAII), `3.8` (temporal memory rollback) |
| **Sibling papers** | [RP-3-7](./RP-3-7-zero-ms-gc-arc-raii.md), [RP-3-8](./RP-3-8-temporal-memory-rollback.md) |
| **Product residual** | `ooda/bootstrap/ARC_M2_RESIDUAL.md` |

## 1. Why this is in DESIGN.md

DESIGN §6 states:

> ARC strictly destroys standard variables the instant they leave scope. Temporal Memory rollback is an opt-in keyword (e.g., `temporal struct`). For these specific structures, ARC routes them to a ring-buffer Event Log Arena that prunes states older than 3 seconds, avoiding Use-After-Free segfaults.

| Goal | DESIGN claim | Tension |
|------|--------------|---------|
| **3.7 0ms GC / ARC** | Immediate destroy on last release / scope exit; no STW pauses | History is **erased** when refcount hits zero |
| **3.8 Temporal memory** | Keep ~3s of past state; crash → roll back and take fallback | History must **survive** past the logical “last use” |

If every value is freed at the first safe moment, there is nothing left to roll back. If every value is immortal for three seconds, you reintroduce a **bounded GC / arena** and lose the “0ms / instant free” slogan for those objects.

This paper justifies the **opt-in temporal arena** boundary so ARC remains the default and temporal is a deliberate cost.

## 2. Problem statement

### What breaks without a boundary

| Scenario | Without policy |
|----------|----------------|
| Default all-ARC free | Fatal fault cannot restore prior RAM; only OS-level core dumps |
| Default all-temporal | Huge RAM; “0ms GC” false; refcount semantics muddy |
| Mix without type tag | UAF: rollback restores pointer into freed object; or double-free on arena prune |
| Mix without prune | Unbounded event log → OOM (ironically needing 3.3 alloc caps) |

### Users

- **Systems programmer:** wants RAII predictability and no stop-the-world GC.  
- **Agent / reliability engineer:** wants “undo for RAM” after contract/fault explosions (DESIGN sci-fi safety net).  
- **Adversary:** may try to force prune races or restore secrets that should have been zeroized (`#[Secret]` / 3.5).

### Core invariant (policy)

```
default_values:     ARC/RAII, destroy on last release  (no history)
temporal_values:    live in Event Log Arena; snapshots retained ≤ T (e.g. 3s)
pointers:           never mix unchecked raw pointers across temporal epochs
```

Rollback is **not** a silent whole-process time machine for all heap. It is a **typed, opt-in** mechanism.

## 3. Related work

### ARC / deterministic lifetime

- **Swift / Clang ARC** — compiler inserts retain/release; deallocation when count hits zero; no tracing GC; cycles need weak refs.  
  <https://docs.swift.org/swift-book/documentation/the-swift-programming-language/automaticreferencecounting/>  
  Wikipedia overview: <https://en.wikipedia.org/wiki/Automatic_Reference_Counting>
- **C++ `shared_ptr` / RAII** — deterministic destruction; no automatic history.
- **Rust ownership** — often *earlier* free than ARC; even less natural fit for “keep last 3s” without explicit arenas.

### Time-travel / rollback / record-replay

- **Mozilla `rr`** — record syscalls + nondeterminism; reverse-debug by replaying from checkpoints; does **not** keep full heap history for production crash auto-heal.  
  <https://rr-project.org/> (see also Mozilla Firefox debugging docs)
- **Windows Time Travel Debugging (TTD)** — capture/replay traces for diagnostics.  
  <https://learn.microsoft.com/en-us/windows-hardware/drivers/debuggercmds/time-travel-debugging-overview>
- **Snapshot vs log vs instrumentation** — industry taxonomy: full snapshots (memory-heavy), input record/replay (cheaper if pure), or delta logs (event sourcing).  
  See e.g. discussions of snapshotting vs record/replay in production time-travel blogs.

### Event sourcing / persistent data structures

- **Event logs / CQRS** — state = fold(events); natural “rollback” = rebuild to earlier offset.  
- **Persistent / functional data structures** — structural sharing gives cheap snapshots; closer to “temporal struct” than raw ARC objects.  
- **Software transactional memory (STM)** — speculative state + abort; different API, similar “don’t commit bad mutation” spirit (related also to 3.10 shadow-state).

### Capability-assisted record/replay (openOODA-specific opportunity)

`ooda-future.md` notes that funneling I/O through caps yields a natural chokepoint for **record/replay of effects**. That is **orthogonal** to heap temporal memory:

| Mechanism | Restores | Cost |
|-----------|----------|------|
| Cap I/O record/replay | External world interactions | Log size of effects |
| Temporal heap arena | In-RAM variable history | Snapshot/log of values |
| Full `rr`-style | Everything | Heavy; debug-only |

DESIGN 3.8 is the **heap** story; product may ship **effect replay** earlier as a cheaper reliability tool.

## 4. Design rationale for openOODA

### 4.1 Type-directed memory domains

```text
┌──────────────────────────────┐
│  Ordinary values (default)   │  ARC retain/release → free on 0
│  RAII scopes                 │  No event log
└──────────────────────────────┘
┌──────────────────────────────┐
│  temporal T / temporal struct│  Allocated in Event Log Arena
│  (opt-in keyword)            │  Snapshots / CoW versions ≤ 3s
└──────────────────────────────┘
```

Compiler rules (target semantics):

1. **Default is non-temporal** — zero surprise cost.  
2. **`temporal` is viral in a controlled way** — storing a temporal into a non-temporal field either copies a *frozen snapshot* or is a type error.  
3. **Rollback API** is explicit (e.g. `temporal::restore(t, epoch)` or fault handler hook), not ambient.  
4. **Prune** drops versions older than `T` (DESIGN: 3 seconds); prune must be UAF-safe (no live handles into pruned epochs — epoch IDs, generation counters).

### 4.2 How ARC “routes” temporal objects

DESIGN says ARC routes temporal structures to the arena. Interpretation:

| Operation | Ordinary ARC | Temporal |
|-----------|--------------|----------|
| `retain` | +1 refcount | +1 refcount on *handle*; log may share payload |
| `release` → 0 | `free` payload | Drop handle; **payload may remain** until prune if snapshots reference it |
| Scope exit | release | release handle; arena owns history |
| Fault rollback | N/A | Restore arena head to epoch *e*; invalidate newer handles |

This is closer to **generational arena + refcounted handles** than pure Swift ARC.

### 4.3 Interaction with other DESIGN items

| Item | Interaction |
|------|-------------|
| **3.3 AllocCap** | Temporal logs must count against heap quotas or a dedicated `&TemporalCap` / budget |
| **3.5 Secret** | Rollback must not resurrect zeroized secrets past policy; prefer exclude `#[Secret]` from temporal or force scrub on prune |
| **3.10 Shadow-state** | Shadow execution may use short speculative buffers; not the same as 3s user-visible temporal |
| **3.2 TimeCap** | Prune clock should use sandboxable time (or relative ticks) for deterministic tests |
| **1.2 Contracts** | `ensures` after rollback need defined semantics (re-run ensures? skip?) |
| **Hot reload 4.2** | Live state vs temporal log consistency |

### 4.4 3-second window is a product parameter

Treat **3s** as DESIGN’s illustrative default, not a sacred constant:

- Embedded: maybe 50–200ms ring.  
- Servers: configurable, with hard RAM cap.  
- Tests: deterministic step count instead of wall clock (`&TimeCap`).

## 5. Threat / failure model

### Prevents

| Failure | Mitigation |
|---------|------------|
| UAF after “rollback into freed object” | Temporal-only restore targets; generation-checked handles |
| Silent unbounded memory | Ring prune + AllocCap |
| Accidental global time machine | Opt-in type; default ARC destroy |
| STW GC pauses on ordinary path | Ordinary path stays ARC/RAII |

### Does **not** prevent

| Residual | Why |
|----------|-----|
| Logic bugs that corrupted state *before* the window | Only ≤T history |
| External side effects already performed | Need cap record/replay or compensating transactions |
| Retain cycles in ARC | Still need weak refs / cycle discipline |
| Product free residual | Alpha may leak (leak-safe) — see §7 |

### Adversary angles

- Force massive temporal allocation to exhaust RAM (quota).  
- Roll back past a security decision (auth flag) — temporal state must not include security-critical tokens without re-validation.  
- Use restore to re-expose secrets — taint/secret policy.

## 6. Alternatives considered

| Alternative | Verdict | Notes |
|-------------|---------|-------|
| **Whole-process snapshot every N ms** | Reject as default | Huge RAM/CPU; not “0ms GC” |
| **Always-on event sourcing for all heap** | Reject | Defeats ARC simplicity |
| **Debug-only `rr` / TTD** | Accept as **complement** | Does not satisfy in-process “fallback path” of DESIGN 3.8 |
| **Cap I/O record/replay only** | Accept as **MVP reliability** | Cheaper; does not restore pure RAM corruption |
| **STM / transactions** | Defer | Different programmer model; may pair with 3.10 |
| **Persistent data structures for all** | Reject as default | Perf/idiom cost |
| **Opt-in `temporal` + arena (DESIGN)** | **Accept** | Clear boundary; cost paid only when requested |
| **Copy-on-write pages (OS)** | Defer | Coarse; good implementation tactic under the arena |

## 7. Product reality (alpha honesty)

| Layer | PM status | Truth |
|-------|-----------|-------|
| **3.7 ARC/RAII** | **partial** | Retain/release on pure path (`PURE_NO_ARC=0`); nested scopes; smokes exist |
| **Free on ref 0** | residual / evolving | `ARC_M2_RESIDUAL.md`: historically **leak-safe** (decrement without free); free reclaim work ongoing; **not beta** |
| **3.8 Temporal** | **not-started** | No `temporal` keyword, no event log arena, no crash rollback |
| **6.2 tension** | **partial** | Only because ARC side exists; resolution policy not engineered in runtime |

### What “0ms GC” means in alpha

Honest product language:

- **No tracing STW GC** — true direction.  
- **Instant reclaim of all dead objects** — **not** fully claimed while free is residual or leak-safe.  
- **Temporal window** — **not** implemented; do not market crash auto-heal.

### Recommended implementation order

1. Close **true free** on ARC (M2) without self-host brokenness.  
2. Add **arena allocator** primitive (may help lists/str later).  
3. Add **`temporal` types** + epoch handles + prune.  
4. Wire **fault → restore → fallback** only for annotated regions.  
5. Parallel track: **cap effect record/replay** for agent debugging (often higher ROI).

## 8. Open research questions

1. Exact surface syntax: `temporal struct`, type constructor `Temporal[T]`, or attribute `#[temporal]`?  
2. Can temporal objects contain ordinary ARC refs without epoch escapes?  
3. Multi-threaded temporal (5.3 fearless concurrency) — per-thread logs vs global epochs?  
4. Interaction with **Backend-C** lowering: can arenas be expressed portably before LLVM?  
5. Formal model: operational semantics of `restore` vs `ensures`?  
6. Is wall-clock 3s wrong for pure tests — should prune be `MaxEpochs` + `&TimeCap`?

## 9. Acceptance criteria (for PM status promotion)

### `partial` → stronger `partial` (policy + ARC honesty)

- [ ] Product docs state: default ARC **destroys**; temporal is opt-in (even if temporal not shipped).  
- [ ] ARC free path documented honestly (leak-safe vs reclaim) in PM + residual.  
- [ ] No marketing claim that alpha rolls back RAM on crash.

### Temporal `not-started` → `smoke`

- [ ] `temporal` type (or attribute) parsed; non-temporal code unchanged.  
- [ ] Arena allocates + prunes under test (fixed epoch count, not wall clock).  
- [ ] Intentional UAF test: restoring pruned epoch **fails closed**.

### → `partial` / `done`

- [ ] Fault injection: mutate temporal state → trap → restore → fallback runs.  
- [ ] Ordinary ARC path shows no temporal log traffic (perf/trace).  
- [ ] AllocCap (or budget) bounds arena growth.  
- [ ] Secrets policy: documented + tested.

## 10. References

1. openOODA `spec/DESIGN.md` §3.7, §3.8, §6.  
2. openOODA `PM.md` rows 3.7, 3.8, 6.2; `ooda/bootstrap/ARC_M2_RESIDUAL.md`.  
3. Swift ARC documentation — <https://docs.swift.org/swift-book/documentation/the-swift-programming-language/automaticreferencecounting/>  
4. Automatic Reference Counting — <https://en.wikipedia.org/wiki/Automatic_Reference_Counting>  
5. Mozilla `rr` record/replay debugger — <https://rr-project.org/>  
6. Microsoft Time Travel Debugging overview — <https://learn.microsoft.com/en-us/windows-hardware/drivers/debuggercmds/time-travel-debugging-overview>  
7. openOODA `ooda-future.md` — deterministic time-travel debugging via capability chokepoints.  
8. Sibling papers: [RP-3-7](./RP-3-7-zero-ms-gc-arc-raii.md), [RP-3-8](./RP-3-8-temporal-memory-rollback.md).

---

*Series: [Research papers index](./README.md). Template: [TEMPLATE.md](./TEMPLATE.md). Conflicts index: [CONFLICTS.md](./CONFLICTS.md).*
