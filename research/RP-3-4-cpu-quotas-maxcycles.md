# RP-3.4: CPU quotas (`#[MaxCycles]`)

| Field | Value |
|-------|--------|
| **Paper ID** | `RP-3.4` |
| **DESIGN.md** | §3 Safety — CPU Quotas (Execution Sandboxing) |
| **Status** | `draft` |
| **PM.md row** | `3.4` |
| **Product mapping** | **not-started** |

## 1. Why this is in DESIGN.md

DESIGN.md §3 states:

> Functions can be tagged with `#[MaxCycles(5000)]`. If the static analyzer cannot mathematically prove the loop bounds will finish under that limit, it refuses to compile—making infinite loops impossible.

This is the temporal dual of heap quotas (§3.3). This limits execution to ensure that:

1. Untrusted or AI-generated code cannot hang the compiler, the test runner, or the agent loop.
2. Contracts and pure functions become practical for total subsets. The system can stop partial functions with a fuel error.
3. openOODA can host multi-tenant evaluation (plugins, hive-mind workers) without one loop locking the host.

The DESIGN text uses strong words. This paper separates static totality from practical fuel metering. Both concepts exist in literature and commercial systems.

## 2. Problem statement

### What goes wrong without CPU quotas

| Scenario | Impact |
|----------|--------|
| `while true {}` in agent-proposed patch | Developer loop hangs. Human OODA breaks. |
| Superlinear parser on hostile input | Denial of service (DoS) without high memory use. |
| Accidental exponential recursion | Stack and time overflow. |
| Fuzz target nontermination | Fuzzer stops. Test coverage ends. |
| Smart-contract-like guest code | The system needs gas limits or hard preemption. |

### Tension with DESIGN literal reading

The compiler cannot fully prove iteration limits for all Turing-powerful programs. Therefore, production systems use a combination of:

1. **Static restrictions** (bounded loops, sized types, and total functional subsets).
2. **Dynamic fuel counters** (gas or cycle limits).
3. **OS timers** (preemption as a final defense).

openOODA must document which layer it claims at each PM status.

### Core research question

What combination of static MaxCycles proof and runtime fuel fits a systems language with Backend-C? We must answer this without false marketing claims.

## 3. Related work

### 3.1 Worst-case execution time (academic and avionics)

- **WCET analysis**: Static timing for real-time systems. This uses hardware models and loop bounds annotations.
- **aiT, Bound-T, OTAWA:** Commercial and research WCET tools.
- **seL4 WCET work:** Binary-level worst-case analysis on verified paths.
- **Ravenscar and SPARK Ada:** Restricted profiles for analyzable real-time code.

Lesson: Full static proof requires language subsets and hardware models. openOODA general code requires hybrid enforcement.

### 3.2 Termination and totality (academic)

- **Sized types, DML, Agda, Coq:** Termination checking by construction.
- **Liquid Haskell and refinement types:** These sometimes prove loop metrics.
- **Cost semantics** (RAML): These infer polynomial bounds.

### 3.3 Gas metering and fuel (blockchain and commercial)

| System | Mechanism |
|--------|-----------|
| **Ethereum EVM** | Per-opcode gas, block gas limit, and out-of-gas revert. |
| **Fuel VM and Sway** | Parallel execution with explicit fuel. |
| **NEAR, Solana, and CosmWasm** | Metering or compute units. |
| **eBPF verifier** | Bounded loops and complexity limits for kernel safety. |

Gas is the most successful commercial analogue to MaxCycles. It is dynamic and predictable for untrusted code. It is not a full WCET proof.

### 3.4 Language and runtime fuel

- **Lua hooks:** Instruction count callbacks.
- **WebAssembly fuel (Wasmtime):** Store-level limits. This is an excellent model for openOODA.
- **Erlang reductions:** Cooperative scheduling budget.
- **Operating systems:** POSIX `RLIMIT_CPU` and cgroup `cpu.max`. These provide coarse process-level limits.

### 3.5 Fuzzing and sanitizers

- **libFuzzer and AFL++ timeouts:** Wall-clock kill of hung inputs.
- **ASan and TSan:** These do not solve nontermination. You must use explicit timeouts or fuel.

## 4. Design rationale for openOODA

### 4.1 Attribute semantics (DESIGN)

```text
#[MaxCycles(5000)]
fn parse_header(buf: Bytes) -> Result[Header, ParseErr]
```

**North star (static):** The compiler proves that every path uses 5000 or fewer cycles. If it cannot prove this, the compiler rejects the code.

**Pragmatic ladder:**

| Tier | Behavior | Status goal |
|------|----------|-------------|
| A | Runtime fuel decrement. Trap or `CycleErr` at 0. | partial |
| B | Static check for obvious unbounded loops. Require annotation. | partial+ |
| C | Formal cost proof for annotated subset. | done (hard) |
| D | OS cgroup CPU max for process. | always recommended backstop |

### 4.2 What is a "cycle"?

We define an abstract cost model. This model does not depend on x86 micro-operations:

- Baseline: Each IR operation or bytecode operation costs 1 cycle.
- Memory operations: These may cost more cycles.
- System calls: These have a large fixed cost or separate metering.

Backend-C native code cannot see this cost model. Therefore, we must do one of the following:

- Insert fuel checks in emit-c.
- Run untrusted code on the VM or WASM fuel path.
- Rely on the OS timer.

### 4.3 Interaction with other items

| Item | Link |
|------|------|
| 3.2 TimeCap | Wall-clock limits and cycle limits are both necessary. |
| 3.3 AllocCap | This is a dual resource limit. |
| 3.6 Fuzzer | A per-input cycle budget is mandatory. |
| 1.2 Contracts | Totality helps `ensures` statements. |
| 4.1.1 VM | This is a natural fuel host. |
| 4.1.4 WASM | We use Wasmtime fuel. |
| 5.2 Packages | A manifest needs max-cycles per entry. |

### 4.4 Error model

- **Static reject:** The compiler cannot prove the bound.
- **Dynamic `CycleErr`:** The system recovers in sandboxed hosts.
- **Never silent infinite loop:** Claimed sandboxed entry points must never loop silently.

## 5. Threat and failure model

### Prevents

- Cooperative hangs in pure computation with fuel.
- Many algorithmic DoS attacks.
- Runaway agent-generated loops in testing or fuzzing.

### Does not prevent

| Gap | Notes |
|-----|-------|
| Undecidable static proof for all programs | You must use a hybrid approach. |
| Uninstrumented native FFI | This code can spin without fuel limits. |
| Hardware interrupts and GPU kernels | These require a different model. |
| Priority inversion and lock spins | See concurrency section. |
| Cost-model mismatch | DoS is still possible if the cost is too low. |

### Adversarial cost-model attacks

Ethereum history shows that underpriced opcodes cause DoS attacks. openOODA must treat cost tables as security-critical data. We must version these tables.

## 6. Alternatives considered

| Alternative | Tradeoff |
|-------------|----------|
| **Wall-clock timeouts only** | Easy, but non-deterministic. It fails pure replay. |
| **OS `RLIMIT_CPU` only** | Process-coarse. SIGXCPU causes problems. |
| **Total functional language only** | Too restrictive for systems and I/O. |
| **Static proof only (no runtime)** | The DESIGN ideal, but it requires long research. |
| **Gas only (no static)** | Practical, but weakens the infinite loop claim. |
| **Preemptive OS threads** | Needs a runtime. It still needs a budget for fairness. |

**Recommended product path:** Build fuel-first (Tier A) on VM or WASM. Add optional emit-c instrumentation. The static MaxCycles analyzer will grow toward the DESIGN wording. This does not block the alpha release.

## 7. Product reality (alpha honesty)

**PM.md `3.4`: not-started.**

| Feature | Alpha |
|---------|-------|
| `#[MaxCycles(N)]` attribute | **not-started** |
| Static loop-bound proof | **not-started** |
| Runtime fuel on Backend-C | **not-started** |
| VM or WASM fuel integration | **not-started** (WASM executes, but lacks fuel) |
| Fuzzer timeout | Harness-level process kill is possible. |

**Do not claim:** You must not claim that infinite loops are impossible. You must not claim compile-time refusal based on cycle proofs.

## 8. Open research questions

1. **Cost model stability:** Can we use one IR cost table across Backend-C, LLVM, WASM, and VM?
2. **Proof automation:** What loop annotation language do we use?
3. **Interaction with ARC cost:** Should we charge memory traffic for retain and release?
4. **Async and multi-thread fuel:** Do we use a shared budget or a per-task budget?
5. **Smart-contract guests:** Should openOODA expose EVM-like gas for plugins?
6. **False reject rate:** How does the static analyzer compare to developer escape hatches?

## 9. Acceptance criteria (for PM status promotion)

### not-started to partial

- [ ] Parse `#[MaxCycles(N)]` and attach it to the function AST.
- [ ] Ensure at least one backend enforces fuel with a fail rail.
- [ ] Show that an infinite loop fixture terminates with CycleErr.
- [ ] Document the default fuzz harness budget.

### partial to done (pragmatic)

- [ ] Enforce fuel on all sandboxed entry points.
- [ ] Version the cost table and document adversarial reviews.
- [ ] Add static lints for obvious `while true` loops without attributes.

### done (DESIGN-strong)

- [ ] The analyzer proves bounds for a total subset. It rejects the rest without a fuel attribute.
- [ ] Provide a clear dual mode policy (`mode=static`, `mode=fuel`, or both).

## 10. References

1. Wilhelm, R., et al. *The worst-case execution-time problem—overview of methods and survey of tools.* ACM TECS.
2. Klein et al. seL4 verification series.
3. Ethereum Yellow Paper.
4. Fuel Labs. FuelVM documentation.
5. Wasmtime fuel and store limits documentation.
6. Hoffmann, J., et al. Resource-aware ML (RAML).
7. AFL++ and libFuzzer timeout and hang detection docs.
8. SPARK Ada and Ravenscar profiles.
9. openOODA: `spec/DESIGN.md` §3 CPU Quotas, `PM.md` 3.4, `RP-3-3`, `RP-3-6`, `RP-4-1-1`, `RP-4-1-4`.

---

*Series: [Research papers index](./README.md). Template: [TEMPLATE.md](./TEMPLATE.md).*
