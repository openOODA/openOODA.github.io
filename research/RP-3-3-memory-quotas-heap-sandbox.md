# RP-3.3: Memory Quotas (Heap Sandboxing)

## Abstract
This paper presents the memory quota system for the openOODA architecture. The system uses parametric capabilities to provide heap sandboxing at the module level. This method controls memory use in environments that mix trusted and untrusted code within a single runtime. The design replaces silent out-of-memory failures with typed errors. This ensures system stability and fast execution.

## 1. Introduction
Traditional operating systems isolate programs. They use processes and control groups. These methods are strong but they add latency. They do not work well for systems that run many untrusted modules in one process space. The openOODA system puts artificial intelligence modules and third-party tools together in the same process. This design requires strict memory control at the module level. We propose a system based on parametric capabilities. This capability limits the memory a module can allocate. Agents and package managers can read these quotas from signatures. The system uses a fail-closed allocation strategy. This strategy traps errors. It stops the host out-of-memory killer from stopping the whole process.

## 2. Problem Statement
The openOODA architecture must protect itself against memory exhaustion. Memory exhaustion can occur through several attacks and failures. A decompression bomb gives a tiny input that causes a huge heap allocation. A malicious source file or JavaScript Object Notation payload can create a huge abstract syntax tree. This causes quadratic parser growth. Dependency runaway happens when library caches grow without limit. An agent loop leak occurs when iterative operations keep memory arenas active. In a multi-tenant host, one module can use all the memory and starve other modules.

Operating system limits are incomplete. Control groups and resource limits apply to processes. They do not apply to specific trust domains inside a single process. Language runtimes like Go, the Java Virtual Machine, and Python grow their heaps until the operating system kills them. This causes a poor user experience. Artificial intelligence tools often run untrusted evaluations in-process to keep latency low. The core research question is whether parametric capabilities can provide granular heap accounting for modules. This accounting must function with automatic reference counting, resource acquisition is initialization, and native compiler backends. It must not require a full userspace hypervisor.

## 3. Related Work
Industry systems use operating system and container quotas. Linux resource limits define process address-space bounds. The control groups version 2 memory controller gives hard and soft limits. These are standards for Docker and Kubernetes. Web browsers use process limits for each tab. Site isolation acts as an extreme sandbox. WebAssembly engines use memory maximum limits to bound memory growth. This sets a precedent for heap limits inside language runtimes.

Academic and commercial systems use language runtime quotas. The Java Virtual Machine uses a maximum heap limit for the whole process. Erlang manages memory for each process actor. Custom Lua allocators can inject budgets into operations. Apache Lucene uses circuit breakers for query memory.

Capability systems account for resources differently. EROS and KeyKOS use explicit resource accounting with space banks. This concept is the closest relative to the parametric capability. The seL4 microkernel uses untyped memory capabilities. You must retype memory into objects. There is no ambient heap. This is the best example of treating memory as a capability.

## 4. Architecture and Methodology
The system uses the parametric capability as its foundation. A trust domain must present this capability to allocate heap memory. For example, a parse function takes an allocation capability parameter. All heap growth in a trust domain subtracts from this capability limit. It can also subtract from a child budget. An exceeded limit causes a trap or an allocation error. It does not cause a host-wide out-of-memory event if the parent keeps spare memory. Pure code in standard libraries can use stack-only operations or buffers that the caller provides. Dynamic heap allocation requires the capability.

The rules for composition ensure strict accounting. Sub-budgeting lets a parent capability create a child capability. The sum of all child limits must be less than or equal to the parent limit. Sandboxed modules cannot use an ambient global allocator. Only the main entry point or the runtime holds the root limit. The system integrates with automatic reference counting and resource acquisition is initialization. A free operation returns bytes to the same limit that allocated them. Leaks hold the quota until the process ends. This causes fail-closed pressure on the module. Arenas can free memory in epochs to return a bulk quota.

The architecture enforces quotas at multiple layers. The language capability provides fine-grained control that agents can see in manifests. The operating system control groups act as the final defense against runtime bugs and foreign function interfaces. WebAssembly memory maximums enforce limits when the system targets WebAssembly. You must not rely on only one layer.

## 5. Threat and Failure Model
The capability architecture prevents many attacks. It prevents in-process decompression bombs and unbounded cache denial of service attacks. It stops untrusted plugins from exhausting the host memory. This avoids operating system kill latency. It stops silent server failures for embedded compilers.

The design does not prevent all failures. Stack overflows require separate stack quotas and guard pages. The language heap does not equal all resident set size memory. Kernel memory and page tables use extra memory. Foreign function interface operations can bypass limits without custom allocator interposition. Memory-mapped files must count against the limit or the system must deny them.

Runtime accounting presents challenges. Shared objects across trust domains can cause double counting or under counting. Allocator fragmentation makes the resident set size larger than the logical live bytes. You must charge for metadata and slab headers. Otherwise, a module can bypass the limit. A policy must manage external fragmentation from many small limits.

## 6. Conclusion
The parametric allocation capability gives openOODA robust heap sandboxing. It controls memory at the module level. This design prevents untrusted code from crashing the host process. It replaces unpredictable operating system interventions with typed errors. This architecture ensures high-speed, secure execution for artificial intelligence agents and untrusted plugins. The integration of language capabilities with operating system limits provides a strong defense against memory exhaustion.

---
*Series index: [README.md](./README.md).*
