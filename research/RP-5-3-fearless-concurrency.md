# RP-5.3: Fearless concurrency

| Field | Value |
|-------|--------|
| **Paper ID** | `RP-5.3` |
| **DESIGN.md** | §5 Ecosystem |
| **Status** | `draft` |
| **PM.md row** | `5.3` |
| **Product mapping** | **not-started** |

## 1. Why this document is in DESIGN.md

Section 5 of DESIGN.md says:

> Multithreading without mutexes. Threads use message passing to communicate. The compiler makes sure that capabilities stop at thread boundaries. This prevents data races at compile time.

We list fearless concurrency under **Ecosystem & DX**. Concurrency changes how you write the standard library, agents, and multi-core services. It is not only a hidden runtime feature. 

The openOODA project uses **capabilities** (RP-3.1). Concurrency must not bring back shared mutability. Shared mutability removes the safety of capabilities. APIs that use many mutexes cause deadlocks for AI agents. They also make the code hard to understand.

This document compares openOODA design to **Rust ownership**, **Erlang actors**, and **Pony reference capabilities**. It tells how openOODA combines message passing with **capability relinquishment** across thread and actor boundaries.

## 2. Problem statement

### 2.1 Problems with shared memory and locks

| Hazard | User effect | Agent effect |
|--------|-------------|--------------|
| Data races | Random bugs, undefined behavior in unsafe languages | Test failures that you cannot reproduce |
| Deadlocks | Production stops | Fuzz loops stop |
| Priority inversion or convoying | High latency | Broken OODA loop timing |
| Capability leakage across threads | Aliasing of file system or network authority | Sandbox bypass |

### 2.2 openOODA constraints

1. **Capabilities are values**. You must not alias them secretly across concurrent tasks.
2. **ARC/RAII** (RP-3.7) must stay free of races when you share it.
3. **Temporal memory** (RP-3.8) and concurrent mutation cause critical errors if you combine them.
4. Fast developer experience (DX): The compiler must easily diagnose complex borrow-checker problems (RP-5.5). You must be able to teach these concepts easily.

### 2.3 Design goals

- **No user-facing mutexes** for standard code. You can use internal runtime locks if you hide them.
- **Message passing** is the primary concurrency model.
- **Compile-time prevention** of data races for shared state.
- **Capability transfer**: When you send a capability, you move it or end the sender's right to use it.

## 3. Related work

### 3.1 Formal models

- **Actor model**: Isolated state machines and asynchronous messages. The pure model has no shared memory.
- **π-calculus and session types**: Structured communication. Session types can show protocol safety.
- **Ownership types and regions**: Alias control for mutation.
- **Reference capabilities**: Pony language concepts (`iso`, `trn`, `ref`, `val`, `box`, `tag`) classify safe concurrent sharing.
- **Encore**: Compares object capabilities, reference capabilities, and Rust limits.
- **Concurrent separation logic**: A proof foundation for race-freedom. It is too complex for standard developers, but it helps compiler checks.

### 3.2 Industrial systems

| System | Model | Safety mechanism | Cost |
|--------|-------|------------------|------|
| **Rust** | Shared memory and ownership | `Send`/`Sync`, borrow checker. Mutexes are explicit. | Hard to learn. Interior mutability escapes. |
| **Erlang/OTP** | Actors and mailboxes | Process isolation. Copy or share immutably. | Soft realtime garbage collection (GC). |
| **Pony** | Actors and reference capabilities | Prevents data races and deadlocks by design. | Smaller ecosystem. GC for each actor. |
| **Go** | CSP channels and shared memory | Dynamic race detector. Mutexes are common. | Data races are possible. |
| **Java** | Shared memory | Happens-before rules. Hard to write correctly. | |
| **Akka / Orleans** | Actors on JVM or .NET | Runtime rules. | No compile-time capabilities. |

**Rust fearless concurrency**: The type system prevents data races in safe Rust. But openOODA wants "no mutexes". This is more similar to **Erlang** and **Pony** than to Rust. High-performance Rust servers still use `Mutex` and `RwLock`.

**Pony** is the most similar system. It uses actor isolation and reference capabilities for safe message passing. The `iso` capability transfers unique mutable graphs.

**Erlang** shows the success of "share nothing, message everything" in telecommunications. But openOODA needs systems-language performance and capability security. It does not need BEAM rules.

### 3.3 Research hybrids

- Ownership and actors in research languages.
- Rust actor frameworks (Actix, Aquarium). These use library-level isolation. They do not enforce isolation at the language level.

## 4. Design rules for openOODA

### 4.1 Chosen design

```text
openOODA concurrency ≈
    Erlang-style isolation (default message passing)
  + Pony-style transfer rules for capabilities and unique graphs
  + Rust-style explicit rules for shared immutable data
  − User-level mutexes
```

### 4.2 Capability transfer across boundaries

When task A sends data to task B, use these rules:

| Data type | Rule |
|-----------|------|
| Pure data (`std::core`) | Copy or deep-move. Do not use capabilities. |
| `&Cap` tokens | **Move**. The sender cannot use it after the send. Use an explicit `split` if the capability type permits it. |
| Mutable unique structures | Transfer ownership. |
| Shared immutable data | Only transfer if the type is deep-immutable. |

These rules connect concurrency to RP-3.1. Capabilities are not global authority for threads.

### 4.3 API example

```text
spawn(fn) -> JoinHandle   // Do not share mutable data or capabilities unless you move them.
chan<T>::send(T)          // T must be Send. Move the capabilities.
select! { ... }           // Wait for multiple events without a mutex.
```

The internal scheduler can use locks. If user code needs shared mutability, it must use **single-owner actors** or approved primitives. Do not use `Mutex<T>`.

### 4.4 Interaction with other design pillars

| Pillar | Interaction |
|--------|-------------|
| ARC (3.7) | Use atomic reference counting only for shared immutable data. Moves are better. |
| Temporal memory (3.8) | Do not use `Send` by default. |
| Contracts (1.2) | Message handlers can use `requires` on mailbox types. |
| Hive fuzz (2.4) | Concurrent fuzz workers must isolate mutable corpora. |
| HITL (5.6) | Serialize human prompts on the UI actor. |

### 4.5 Performance impact

Preventing data races has a cost. Copying messages, serialization, and ownership transfers take time. System paths can permit **region borrowing inside one actor** if they do not share across threads. The rule "no mutexes" does not prevent the runtime from using lock-free rings internally.

## 5. Threat and failure model

### What the design prevents

- Data races on shared mutable data at the language level.
- Accidental use of the same `&FsCap` from two different threads at the same time.
- Deadlocks from user mutex graphs, because the design removes mutexes.
- AI agents writing incorrect code like `lock(); lock();`.

### What the design does not prevent

- **Logical** deadlocks in message cycles. For example, task A waits for task B, and task B waits for task A.
- Resource exhaustion (mailbox flood). You must use quotas (RP-3.3/3.4).
- Incorrect protocols, such as wrong message order, unless you use session types.
- Data races inside `UnsafeFFICap` or C language threads (RP-6.3).
- Speculative execution risks in hardware for unsafe code.

### Failure modes and solutions

| Mode | Solution |
|------|----------|
| Too many escape hatches | Reject `unsafe` shared mutability by default. |
| Function colors for actors | Teach one standard concurrency model. |
| Capability copy errors | Use move semantics and explicit `Cap::attenuate`. |
| Copying too much data | Transfer unique data and share immutable data. |

## 6. Alternatives

| Alternative | Decision |
|-------------|----------|
| **Rust-like mutexes and Send/Sync** | Powerful, but goes against the "no mutex" rule. It is too complex for AI agents. |
| **Go-like shared memory and channels** | Does not prevent data races at compile time. |
| **Pure CSP without actors** | Possible, but actors work better for capability isolation. |
| **Software transactional memory** | Too complex. Retrying transactions does not work well with I/O capabilities. |
| **Structured concurrency only** | Good addition to actors, but not a complete replacement. |
| **Full Pony reference capabilities** | Good system, but too large for the alpha version. We will use a smaller subset. |

## 7. Product status

According to **PM.md** row `5.3`, this work is **not started**.

| Component | Status |
|-----------|--------|
| Language threads and actors | Not available to users. |
| Message types and send checks | Not started. |
| Capability transfer on spawn or send | Not started. |
| Standard library concurrency modules | Not present. |
| Mutex-free claim | Only in design. |

The alpha product is **single-threaded** for user programs. C runtime threads can exist, but they do not follow this language model.

## 8. Open research questions

1. What is the **one** default concurrency model for openOODA: actors, tasks, or lightweight fibers?
2. How strict must the capability transfer rules be? Do servers need to split a `NetCap` into a child scope?
3. Can error messages (RP-5.5) explain **capability move errors** easily?
4. Which parts of the Pony capability system are necessary?
5. How do GPU and NPU systems (RP-4.1.3) share a memory model with fearless concurrency?
6. How do we limit mailbox sizes and guarantee fairness under MaxCycles (RP-3.4)?

## 9. Acceptance criteria

### Not started to smoke

- [ ] Add `spawn` and channel functions (or actor mailboxes) to the language or standard library. This is for a single process.
- [ ] The compiler must show a type error if you share mutable state that is not `Send`.
- [ ] You cannot use a capability parameter after you send it.

### Smoke to partial

- [ ] Write documentation for the memory model for safe openOODA concurrent code.
- [ ] Add standard library examples: build a worker pool without user mutexes.
- [ ] Add stress tests to CI. Prove there are no data races on safe code.

### Partial to done

- [ ] The compiler must prevent all data races for the safe subset of the language.
- [ ] Implement capability transfer for all capability types.
- [ ] Remove all mutexes from the standard public API. Write rules for internal runtime locks.
- [ ] Make clear error messages for concurrent capability and ownership errors.

## 10. References

1. C. Hewitt and others, actor model foundational papers.
2. G. Agha, *Actors: A Model of Concurrent Computation in Distributed Systems*, MIT Press.
3. S. Clebsch and others, Pony reference capabilities documentation.
4. J. Hillert, "A Comparison of the Capability Systems of Encore, Pony and Rust," thesis, 2019.
5. Rust book: Fearless Concurrency and `Send`/`Sync` documentation.
6. J. Armstrong, Erlang/OTP concurrency model.
7. Ownership types literature (Clarke, Noble, and others).
8. Dynamic region ownership for concurrency safety (recent ACM papers).
9. openOODA DESIGN Section 5 Fearless Concurrency; RP-3.1, RP-3.7, RP-6.2, RP-6.3.

---

*Series: [Research papers index](./README.md). Template: [TEMPLATE.md](./TEMPLATE.md).*
