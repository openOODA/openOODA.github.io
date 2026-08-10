# The Boundary Policy: Resolving the Tension Between Metamorphic Binaries and Deterministic Builds

## Abstract
This paper explores the inherent tension between two critical security goals in software distribution: deterministic builds and metamorphic binaries. Deterministic builds ensure that the same source code always produces the exact same on-disk binary. This prevents supply chain attacks. Metamorphic binaries mutate their assembly instructions, register allocations, and memory layouts at runtime. This prevents memory exploit attacks. These two goals pull in opposite directions. If developers bake entropy into the build artifact, they break auditability. If they ship a fully static layout, they weaken runtime immunity. This paper proposes a strict boundary policy to resolve this tension. We establish that the identity of an on-disk artifact must remain deterministic. Runtime diversity must only occur in memory during the load sequence or just-in-time compilation phase. This paper details the architecture, threat models, and operational profiles required to support this boundary.

## 1. Introduction
Software systems must defend against two distinct categories of attacks. The first category targets the supply chain. Attackers try to inject malicious code into the build process. The second category targets memory vulnerabilities. Attackers exploit predictable memory layouts to execute arbitrary code.

To stop supply chain attacks, systems use deterministic builds. Deterministic builds guarantee that a specific version of source code always produces the exact same byte-for-byte binary on disk. This allows independent auditors to rebuild the software and verify the artifact. If the hashes match, the artifact is honest.

To stop memory exploits, systems use metamorphic binaries. A metamorphic binary changes its internal structure continuously. It alters assembly instructions, reassigns registers, and shuffles memory layouts. This diversity raises the cost for attackers. Attackers cannot rely on stable return-oriented programming (ROP) gadgets or predictable memory offsets.

These two defense mechanisms create a fundamental tension. Deterministic builds require the artifact to be identical everywhere. Metamorphic binaries require the execution state to be unique everywhere. Without an explicit phase boundary, implementers face a difficult choice. They must either bake entropy into the compiled artifact, which breaks reproducibility, or they must ship a static layout, which weakens the runtime defense.

This paper presents a formal boundary policy to solve this conflict. The policy separates the static identity of the build artifact from the dynamic diversity of the runtime image. We define the problem, examine related work, and propose a theoretical architecture that supports both goals without compromise.

## 2. Problem Statement
The conflict between deterministic builds and metamorphic binaries introduces severe failure modes if left unresolved.

If developers prioritize metamorphism and omit the boundary, they destroy supply-chain auditability. Two builds of the same source code will produce different binary hashes. Auditors cannot prove that the binary corresponds to the source. Package registries cannot independently verify modules. Furthermore, if every installation has a unique file hash, standard infrastructure collapses. Signature allowlists, crash symbolication, and content-addressed caches all rely on stable file hashes.

Conversely, if developers prioritize deterministic builds without a runtime boundary, they create a static system. The metamorphic capability becomes merely a theoretical concept. The system remains vulnerable to advanced memory exploits because the layout is identical across all installations.

Users need both properties. They must verify that the shipped software is honest. They also need a runtime environment that resists weaponization. Attackers want to exploit the absence of either property. Supply-chain adversaries want to inject backdoors that survive the signing process. Memory-exploit adversaries want stable gadgets across different victims.

To resolve this, we define a core invariant. The identity of the on-disk artifact must be a pure function of the source code, toolchain, and build parameters.

```
identity(on_disk_artifact) = hash(sources, toolchain_pin, build_flags, SOURCE_DATE_EPOCH)
```

The diversity of the in-memory image must be a function of the artifact, load-time entropy, and optional runtime policies.

```
diversity(in_memory_image) = f(artifact, load_entropy, runtime_policy)
```

Metamorphism must never act as an input to the artifact identity. The system allows diversity only after it fixes the artifact on disk.

## 3. Background and Related Work
This tension intersects with several established domains in computer science and security research.

### 3.1. Reproducible Builds
The Reproducible Builds project establishes the standard for supply-chain integrity. It defines reproducible builds as an independently verifiable path from source to binary. Bit-for-bit equality proves that a binary came from a specific source. Researchers have formalized this framing to highlight its importance against supply chain attacks. Standardization efforts, such as the `SOURCE_DATE_EPOCH` variable, remove embedded timestamps so they do not break binary equality.

### 3.2. Runtime Diversity
Modern operating systems use Address Space Layout Randomization (ASLR) and Position Independent Executables (PIE). These mechanisms randomize the base address of a program when the operating system loads it. The on-disk executable file remains unchanged. This provides a classic proof that runtime entropy does not require build non-determinism. Other techniques include load-time relocation and Control-Flow Integrity (CFI). These offer integrity without rewriting instructions constantly, providing a balance between security and deployability.

### 3.3. Metamorphic Code
Historically, malware authors used polymorphic and metamorphic engines to evade signature-based detection. These engines insert junk code, substitute instructions, and reassign registers. Using these techniques for defensive purposes remains rare in production environments. Defensive software diversity usually happens during the build or installation phase. This traditional approach breaks reproducibility. However, Just-In-Time (JIT) compilation in modern virtual machines demonstrates a better model. The cold artifact remains fixed and hashable, while the warm code changes based on runtime policies.

## 4. Architecture and Methodology
The architecture resolves the tension by strictly dividing the software lifecycle into distinct phases. Each phase has specific rules regarding entropy and hashing.

### 4.1. Phase Split Policy
The system relies on a canonical policy that separates compilation from execution.

During the compile and link phase, the system generates the intermediate representation, object code, and final on-disk image. This phase forbids any environmental entropy. The system cannot use the host clock, host paths, or random number generators. The resulting artifact yields a deterministic hash.

During the install and package phase, the system distributes the exact same bytes to all users. The system stores the artifact in a content-addressed store.

During the load and map phase, the system brings the artifact into memory. Here, the system allows entropy. The operating system applies ASLR. The system may also shuffle the memory layout. This diversity happens in RAM only. The system does not hash the memory image as the release identity.

During the execution phase, the system applies continuous steady-state metamorphism. The system rewrites registers and trampolines under a strict safety policy. This dynamic rewriting changes the structure but preserves the original semantics.

### 4.2. Operational Profiles
The architecture supports different operational profiles to balance security and performance requirements.

The standard release profile requires a deterministic artifact. It uses basic load-time diversity, such as ASLR, provided by the operating system.

The hardened release profile requires a deterministic artifact. It applies load-time diversity and enables continuous, periodic metamorphic rewriting in RAM. This provides the highest level of memory defense.

The audit profile requires a deterministic artifact. It disables all runtime diversity. This profile allows security teams to conduct forensics and symbolicate crash dumps reliably.

### 4.3. Preserving Logical Integrity
The metamorphic rewrites must preserve the logical output of the program. Observable pure functions must remain deterministic. Input and output operations must obey the strict capability boundaries defined in the sandbox. The system must maintain memory safety invariants across all rewrite epochs. Formal contract verification must remain valid. Metamorphism is not an excuse to weaken mathematical proofs of correctness.

## 5. Threat and Failure Model
The phase boundary provides specific security guarantees, but it also has known limits.

### 5.1. Prevented Threats
When the system enforces the boundary policy, it prevents several severe attacks. If a compromised build server injects a malicious payload, an independent rebuild will expose the mismatched hash. The policy prevents developers from using metamorphism as an excuse for non-reproducible releases. Furthermore, load-time and runtime diversity prevent attackers from using a single, static ROP chain across multiple victims.

### 5.2. Residual Risks
The boundary policy does not solve all security problems. If an attacker compromises the source code repository, a reproducible build will faithfully reproduce the malicious source. If an attacker compromises the compiler, the compiler will generate the same malicious binary every time. Runtime diversity weakens targeting, but it does not eliminate information leaks or side-channel attacks. Finally, if an attacker gains root privileges and uses a debugger to rewrite the running process, the local attacker still wins.

### 5.3. Implementation Failures
A poor implementation of this architecture will introduce new vulnerabilities. If developers accidentally leak entropy into object files, they break reproducible builds without adding any runtime defense. If the system modifies code without enforcing strict write-xor-execute (W^X) policies, it creates a new attack surface for remote code execution. If the defensive metamorphism triggers false positives in antivirus software, organizations will refuse to deploy the system.

## 6. Conclusion
The tension between deterministic builds and metamorphic binaries is a fundamental architectural challenge. Deterministic builds secure the software supply chain. Metamorphic binaries secure the runtime environment. A system cannot achieve both if it mixes build-time identity with runtime entropy.

This paper establishes a strict phase boundary policy. The on-disk artifact must remain completely deterministic and mathematically verifiable. The system introduces entropy and structural diversity only after the operating system loads the artifact into memory. By separating the identity of the software from its execution state, systems can provide both independent auditability and advanced immune defenses against memory exploitation. This theoretical model provides a robust foundation for building secure, verifiable, and resilient software infrastructure.

## References
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
