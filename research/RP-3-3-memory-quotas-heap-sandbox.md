# RP-3.3: Memory quotas (heap sandboxing)

| Field | Value |
|-------|--------|
| **Paper ID** | `RP-3.3` |
| **DESIGN.md** | §3 Safety — Memory Quotas (Heap Sandboxing) |
| **Status** | `draft` |
| **PM.md row** | `3.3` |
| **Product mapping** | **not-started** |

## 1. Why this is in DESIGN.md

DESIGN.md §3 states:

> Capabilities like `&AllocCap<10MB>` mathematically restrict a specific module from allocating more than a designated RAM limit, neutralizing Out-Of-Memory (OOM) and zip-bomb attacks from 3rd-party libraries.

openOODA puts **AI-generated and third-party modules** in the same process as trusted tools. Examples of trusted tools include the compiler and agent loops. Traditional isolation methods, such as OS processes and cgroups, are necessary. However, they do not meet the DESIGN goals. You must have:

1. **Per-module / per-trust-domain limits** inside a single language runtime.
2. **Signature-visible** quotas. These quotas let agents and package manifests state: “This plugin can use ≤10MB.”
3. **Fail-closed allocation.** This uses a typed error or trap. It replaces a silent host OOM killer.

This item relates to §3.4 CPU quotas (MaxCycles). It limits *resources*, not only the authority to do I/O (§3.1).

## 2. Problem statement

### Attacks and failures

| Class | Mechanism |
|-------|-----------|
| Zip / decompression bomb | Tiny input → huge heap |
| Parser quadratic / huge AST | Malicious source or JSON |
| Dependency runaway | Library caches without bound |
| Agent loop leak | Iterative patch/test retains arenas |
| Multi-tenant host | One module starves others |

### Why OS-only limits are incomplete

- **cgroups / rlimit** apply to *processes*. They do not apply to `import evil_pkg` trust domains.
- Language runtimes like Go, JVM, and Python grow heaps until the OS kills them. This causes poor user experience for contracts.
- AI tools often run untrusted evaluations in-process to reduce latency (OODA speed).

### Core research question

Can parametric capabilities (`&AllocCap<N>`) provide *module-granular* heap accounting? This accounting must work with ARC/RAII (§3.7), Backend-C, and self-host. It must not use a full userspace hypervisor.

## 3. Related work

### 3.1 OS and container quotas (industry)

- **Linux rlimit (`RLIMIT_AS`, `RLIMIT_DATA`):** These define process address-space limits. They are coarse. SIGSEGV and ENOMEM behaviors vary.
- **cgroups v2 memory controller:** This provides hard and soft limits. It integrates the OOM killer. It is a standard for Docker and Kubernetes.
- **FreeBSD rctl / jail resources; illumos zones.**
- **Web browsers:** These use per-tab process limits. Site isolation acts as an extreme sandbox.
- **WASM engines (Wasmtime, V8):** These use memory.max pages. They bound grow_memory. This sets a precedent for *language-runtime* heap limits.

### 3.2 Language and runtime quotas (academic + commercial)

| System | Approach |
|--------|----------|
| JVM `-Xmx` | Process-wide heap max |
| Erlang/OTP | Process (actor) memory; supervisors |
| JavaScript realms / ShadowRealms | Isolation research; limited heap APIs |
| Lua custom allocators | Inject `lua_Alloc` with budgets |
| Apache Lucene / Solr circuit breakers | Query-level memory accounting |
| Apache Spark / Flink | Task memory managers |
| .NET `GC.GetTotalMemory` + hosting limits | Host-imposed |

### 3.3 Capability systems with resource accounting

- **EROS / KeyKOS:** These systems use explicit resource accounting. Space banks act as capabilities. This concept is the closest ancestor to `&AllocCap`.
- **seL4:** This uses untyped memory capabilities. You retype memory into objects. There is *no* ambient heap. It is the best example for “memory is a cap.”
- **Fuchsia:** This manages VMOs and job memory limits. It uses kernel objects and handles.

### 3.4 Soft bounds and verification

- **Region / arena papers; Cyclone; MLKit regions** — These bind lifetimes more than bytes.
- **Static memory bounds (WCET’s cousin):** These are usually undecidable for general programs. You need a hybrid of static and runtime methods.
- **eBPF / kernel verifier memory model** — This uses small programs and strong limits.

## 4. Design rationale for openOODA

### 4.1 AllocCap as parametric capability

```text
fn parse_untrusted(alloc: &AllocCap<10MB>, input: Bytes) -> Result[Ast, ParseErr]
fn plugin_main(alloc: &AllocCap<1MB>, fs: &FsCap) -> Result[(), PlugErr]
```

- All heap growth in a trust domain subtracts from the limit. It can also subtract from a child budget.
- An exceeded limit causes an `AllocErr` or a trap. It does **not** cause a host-wide OOM if the parent keeps spare memory.
- Pure code in `std::core` can use stack-only or caller-provided buffers. Dynamic heap requires AllocCap (DESIGN direction).

### 4.2 Composition rules (proposed)

1. **Sub-budgeting:** `AllocCap<10MB>` can create `AllocCap<1MB>` children. The sum of children must be ≤ the parent limit.
2. **No ambient global allocator.** Sandboxed modules cannot use an ambient global allocator. Only `main` or the runtime holds the root limit.
3. **ARC/RAII (§3.7):** A free operation returns bytes to the same limit. Leaks hold the quota until the process ends. This causes fail-closed pressure.
4. **Arenas:** An epoch free returns bulk quota. This is important for a compiler self-host.

### 4.3 Dual enforcement

| Layer | Role |
|-------|------|
| Language AllocCap | Fine-grained, manifestable, agent-visible |
| OS cgroup/rlimit | Last line against runtime bugs / FFI |
| WASM memory.max | When targeting WASM |

You must not rely on only one layer. That causes production failures.

### 4.4 Interaction matrix

| Item | Interaction |
|------|-------------|
| 3.1 Caps | AllocCap is a cap class |
| 3.4 MaxCycles | Zip bombs may be CPU-bound *and* memory-bound |
| 3.6 Fuzzer | Must run under tight AllocCap to survive hostile inputs |
| 3.7 ARC | Accounting must understand retain/release |
| 3.8 Temporal memory | History buffers consume quota |
| 5.2 Packages | Manifest: `alloc <= 10MB` |
| 6.2 ARC vs temporal | Ring buffers need explicit budgets |

## 5. Threat / failure model

### Prevents (full design)

- The design prevents many in-process zip-bomb and cache-unbounded DoS classes.
- It prevents untrusted plugins from exhausting host RAM. This avoids OS kill latency.
- It stops silent server failure for compiler-as-library embeddings.

### Does not prevent

| Gap | Notes |
|-----|-------|
| Stack overflow | Separate stack quotas / guard pages |
| Kernel memory / page tables | Language heap ≠ all RSS |
| FFI `malloc` | Bypass without §6.3 + allocator interposition |
| mmap / file-backed growth | Must count or deny |
| DESIGN “mathematically restrict” | Runtime accounting is enforcement; static proof of all alloc bounds is undecidable in general |

### Accounting pitfalls

- **Double-count / under-count:** This occurs with shared ARC objects across domains.
- **Allocator fragmentation:** RSS becomes greater than logical live bytes.
- **Metadata overhead:** You must charge slab headers. Otherwise, you risk a limit bypass.
- **External fragmentation:** Using many small limits causes fragmentation. You need a policy.

## 6. Alternatives considered

| Alternative | Why insufficient alone |
|-------------|------------------------|
| **OS cgroup only** | No per-module manifest; poor agent UX |
| **Process-per-plugin** | Strong isolation; high latency vs OODA; complex caps IPC |
| **Static only alloc proofs** | Does not scale to general AI-generated code |
| **Soft GC pressure only** | No hard guarantee; GC pauses fight “0ms GC” story |
| **Global `-Xmx` style** | One knob for whole process |
| **seL4 untyped only** | Correct but not Backend-C alpha path |

## 7. Product reality (alpha honesty)

**PM.md `3.3`: not-started.**

| Feature | Alpha |
|---------|-------|
| `&AllocCap<N>` syntax / check | **not-started** |
| Runtime heap debit/credit | **not-started** |
| Fail-closed OOM as typed error | residual / ambient libc malloc via Backend-C |
| cgroup integration | **not-started** |
| Per-file load gates | **partial hygiene only** — e.g. hostile multi-MB source gated at load/check (size caps on *source*, not heap) documented in STATIC_CAPS audit notes |

Related to ARC path partial (`3.7`, `ARC_M2_RESIDUAL.md`): Free residual creates leak-safe behavior. You must not add the quota system until accounting works correctly with retain/release operations.

**Do not claim:** Do not claim zip-bomb neutralization or module RAM limits as product features.

## 8. Open research questions

1. **Parametric const generics:** Is `AllocCap<10MB>` a type parameter, a runtime value, or both? Both means a static upper limit and a runtime remaining value.
2. **Cross-domain ARC:** Which module receives the charge when module A shares an object with module B?
3. **Compiler self-host:** How does oodac work under AllocCap without thrashing multi-module builds?
4. **Stack + heap unified budget?**
5. **Integration with temporal memory arenas (3.8):** How do history depth and bytes interact?
6. **WASM grow_memory** vs native malloc interposition: Do we need one abstract allocator trait?

## 9. Acceptance criteria (for PM status promotion)

### not-started → partial

- [ ] Syntax + static requirement: heap-allocating std ops need AllocCap (or documented ambient root only in `main`)
- [ ] Runtime counter with hard fail at limit; pass/fail fixtures (allocate under/over)
- [ ] At least one child-budget mint API
- [ ] Documented interaction with current ARC/leak-safe free residual

### partial → done

- [ ] Package manifest alloc limits enforced at load
- [ ] FFI malloc either charged or requires UnsafeFFICap + separate OS limit
- [ ] Dual enforcement guide (cgroup recipe + language)
- [ ] Fuzzer default runs under small AllocCap rail

## 10. References

1. Shapiro et al. *EROS: a fast capability system* — space banks / resource accounting.
2. Klein et al. seL4 untyped memory and capability retyping.
3. Linux cgroups v2 memory controller documentation; `setrlimit(2)`.
4. WebAssembly core spec — memory size and `memory.grow`.
5. Erlang/OTP memory management; JVM heap ergonomics (industry practice).
6. Fuchsia job/VMO memory limits.
7. Circuit breaker patterns (Elasticsearch, Lucene) for query memory.
8. openOODA: `spec/DESIGN.md` §3 Memory Quotas; `PM.md` 3.3, 3.7; `ARC_M2_RESIDUAL.md`; `RP-3-1`, `RP-3-4`.

---

*Series: [Research papers index](./README.md). Template: [TEMPLATE.md](./TEMPLATE.md).*
