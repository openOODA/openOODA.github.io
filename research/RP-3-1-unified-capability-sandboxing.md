# RP-3.1: Unified Capability Sandboxing

| Field | Value |
|-------|--------|
| **Paper ID** | `RP-3.1` |
| **DESIGN.md** | §3 Safety — Unified Capability Sandboxing |

## Abstract

This paper presents a unified capability sandboxing model for systems programming languages. Ambient authority is the default security model in most operating systems. It is the root cause of many security vulnerabilities. This risk increases when artificial intelligence writes the software code. We propose a strict default-deny security architecture. In this architecture, functions cannot perform input or output operations without explicit capability tokens. These tokens represent permissions for file system, network, and biometric access. The compiler checks these capabilities statically during the build process. The runtime environment verifies them dynamically during execution. This dual-verification design guarantees that the system is secure by construction. The token itself is the only accepted authority for privilege.

## 1. Introduction

Ambient authority is the default security model in POSIX systems and standard libraries. In an ambient authority system, a process receives privileges based on the identity of the user. This model causes significant security risks. It often leads to the confused deputy problem. In this problem, a privileged service accepts a malicious input and misuses its given authority.

The rapid rise of artificial intelligence in software engineering increases these security risks. AI-generated code can accidentally introduce unauthorized operations. For example, a helper function might attempt to read a sensitive configuration file without explicit permission. We cannot rely only on manual code reviews to catch these deep logical errors. Traditional security tools often fail to detect these implicit assumptions.

We introduce a unified capability sandboxing system to solve this problem. This system completely inverts the default security model. It replaces implicit ambient authority with explicit object capabilities. In this model, system effects are explicit arguments. You can see them directly in function signatures. The compiler checks these signatures before execution. The runtime enforces the capability tokens during execution. This design connects capability security directly to the programming language boundary.

## 2. Problem Statement

A system without explicit language-level capabilities faces several critical problems.

First, ambient input and output operations occur invisibly in software agent loops. Code can read sensitive files without explicit authorization. A strong and secure system requires the caller to pass an explicit capability token for every operation.

Second, third-party software modules can easily escalate privileges. Verifiable software packages need a strict capability manifest. The manifest specifies the exact capabilities that the package needs to function. Without language-level enforcement, these manifests are only text documentation. They give no actual security guarantees to the user.

Third, the confused deputy problem remains a persistent threat. A privileged process can execute malicious requests from untrusted inputs. Object capabilities solve this problem effectively. The capability token itself becomes the sole authority. The identity of the executing process is not the authority.

Finally, untracked privilege escalation occurs easily in complex systems. Different operations carry different security risks. Network access, file system access, and system execution require distinct capability levels. A simple boolean security check is insufficient for modern software. We need specific and granular capability levels. These levels must scale up to include biometric attestation for critical actions.

## 3. Related Work

### 3.1 Classical Object-Capability Systems

KeyKOS and GNOSIS established the persistent capability nanokernel architecture. In these classical systems, authority strictly requires possession of a capability key. They eliminate ambient authority completely from the system design.

EROS reconstructed the KeyKOS architecture for commodity processors. It uses pure capability mechanisms for inter-process communication. It provides explicit resource accountability. EROS showed that capability systems work efficiently on standard computer hardware.

seL4 is a capability-based microkernel with machine-checked functional correctness. Capabilities exist in specialized nodes within the kernel. Authority strictly requires possession of the capability token. seL4 verified kernel capabilities end-to-end. Our architecture achieves this verification at the programming language level.

Dennis and Van Horn published the original capability paper in 1966. They established the fundamental concept that the token must act as the authority.

### 3.2 Hybrid Operating System Capabilities

Capsicum adds capability mode to a production UNIX environment. A process enters the sandbox voluntarily. The system then denies all global namespace operations. File descriptors retain their specific granted rights. Capsicum demonstrates the high value of extending UNIX with explicit capabilities.

Google Fuchsia uses explicit handles to kernel objects. System components receive the minimum necessary capabilities through explicit manifests. This architecture shows strong industrial support for capability-style design in modern systems.

The CloudABI and WASI models use capability-oriented application binary interfaces. Programs start only with granted file descriptors. These models remove path-based ambient access completely. They are highly relevant to WebAssembly sandbox targets.

### 3.3 Language-Level Capabilities

Languages like E and Pony use object capabilities and reference confinement. They show that unforgeable references provide stronger security than integer identifiers.

Languages like Wyvern, Effekt, and Koka use explicit effect types and handlers. Effects scale well with modern type inference. Capabilities function as a coarse effect lattice in these systems.

Rust provides safe memory management. However, memory ownership does not equal authority. Safe memory does not guarantee least-privilege input and output operations.

Deno uses permission flags for security. These flags provide a command-line grant model. They are coarse ambient flags. They are not fine-grained, per-function capability tokens.

Android and iOS use platform entitlements. These systems show that hardware attestation exists commercially. Biometric capabilities are realistic and necessary for high-assurance operations.

## 4. Architecture and Methodology

### 4.1 Language Design

This language uses a strict default-deny model. Protected operations always require a correct capability parameter. Examples of protected operations include file reading, system execution, environment access, and network fetching.

A capability in the current scope is not sufficient. The function call must send the correct capability identifier explicitly. This design prevents the confused deputy problem.

The system supports different capability levels. A file system capability permits standard file access. A network capability permits external data transfer. A biometric capability needs human verification for critical paths. This hierarchy scales security correctly for different threat levels.

Foreign function interfaces often break the capability model. The compiler must require an explicit unsafe capability token for any foreign function call. This requirement isolates unverified external code.

### 4.2 Unified System

The architecture is completely unified. It uses one static checker and one runtime verification process. It uses one diagnostic family and one package manifest schema. Separate mechanisms for file system and network policies cause unmaintainable tools. A unified system provides a single, consistent authority model.

### 4.3 System Architecture

The system architecture uses a robust multi-layer design to ensure security.

First, the compiler enforces static default-deny rules on sealed names. Pure functions do not compile if they attempt to do input or output. This static check prevents errors early in the development cycle.

Second, the system uses opaque and unforgeable runtime tokens. The software process keeps these tokens strictly private. Other processes cannot forge or steal these tokens.

Third, the system connects these software capabilities to operating system handles. It derives Capsicum, Landlock, or seccomp profiles from the capability set. This translation secures the process at the operating system level.

Finally, the system uses hardware and biometric attestation for high-assurance capabilities. Critical logic pauses execution automatically. It requires a physical hardware enclave or a facial scan to proceed. This mechanism guarantees human approval for sensitive actions.

## 5. Threat Model

This capability architecture prevents several major security threats. It prevents accidental ambient input and output from pure functions. It stops dependency code from opening file systems or networks without declared authority. It stops confused deputy bugs by enforcing strict path restrictions. It prevents silent privilege growth across software code changes. Code changes that require more authority also require updated capability signatures.

The architecture does not prevent threats outside its scope. It does not prevent kernel or hardware compromise. Capabilities apply to the language and runtime, not the underlying kernel. It does not prevent covert channels via timing or cache analysis. Social engineering of the biometric prompt remains possible. Biometric attestation requires aware user interaction.

## 6. Conclusion

A unified capability sandboxing system provides robust security at the programming language boundary. It eliminates ambient authority completely. It requires explicit capability tokens for all effectful operations. This architecture scales from basic file system access to biometric hardware attestation. It connects language-level security directly to operating system isolation mechanisms. This design ensures that software remains secure by construction. This guarantee holds true even when artificial intelligence generates the software code.

## 7. References

1. Dennis, J. B., & Van Horn, E. C. (1966). Programming semantics for multiprogrammed computations. Communications of the ACM, 9(3), 143-155.
2. Shapiro, J. S., Smith, J. M., & Farber, D. J. (1999). EROS: a fast capability system. SOSP.
3. Shapiro, J. S. EROS: A Capability System. PhD thesis, University of Pennsylvania.
4. KeyKOS / GNOSIS architecture documentation (Key Logic / Tymshare lineage).
5. Klein, G., et al. (2009). seL4: Formal verification of an OS kernel. SOSP.
6. Watson, R. N. M., et al. (2010). Capsicum: practical capabilities for UNIX. USENIX Security Symposium.
7. Google. Fuchsia / Zircon concepts: handles, rights, components (fuchsia.dev).
8. Miller, M. S. Robust Composition: Towards a Unified Approach to Access Control and Concurrency Control. PhD thesis, Johns Hopkins University.

---

*Series: [Research papers index](./README.md). Template: [TEMPLATE.md](./TEMPLATE.md).*
