# RP-ES.2: Capability-secure by construction

| Field | Value |
|-------|--------|
| **Paper ID** | `RP-ES.2` |
| **DESIGN.md** | Executive Summary |
| **Status** | `draft` |
| **PM.md row** | `ES.2` |
| **Product mapping** | **partial** — static check + process-local magic tokens. It does not have the full DESIGN capability ladder. |

## 1. Why this document is in DESIGN.md

The Executive Summary describes OODA as **capability-secure**. Section 3 of DESIGN.md gives these details:

> **Unified Capability Sandboxing:** A security model that denies access by default. Functions cannot do input or output (I/O) unless you give them explicit capability tokens (for example, `&NetCap`, `&FsCap`).

SPEC and RFC 0001 have the same rules. Third-party packages and AI-generated code **cannot** use the disk, network, environment, or process controls. They must get tokens from the `main()` function to do these operations. This rule is the primary defense against **supply-chain zero-day attacks** and **prompt-injection code**. It is also the foundation for biometric capability tokens (`&SysCap<RequireBiometric>`) at the highest security level.

This paper shows why **capability-secure by construction** is a primary requirement. If we only have memory safety, a bad dependency can still steal secrets during operation.

## 2. Problem statement

### 2.1 Ambient authority

Standard operating systems and language APIs give **ambient authority**. This means that any code can use `open()`, `connect()`, or `system()` if the *process* has permission. The system does not check which library started the operation. This design causes problems:

- **Supply-chain compromise**: The hidden code in a dependency operates with the full permissions of the application.
- **AI-generated code**: Bad or incorrect code can open network connections automatically.
- **Confused deputy**: Modules with high permissions do work for callers with low permissions. They do this without reducing their permissions first.

### 2.2 Requirements for capability security

A **capability** is a secure token. This token **identifies** a resource and **permits** specific operations on that resource. A module has authority **only** if it holds the token. The system does not use global names to approve operations. The system must do these things:

- **Default deny**: The system stops all I/O operations unless the code provides a capability token.
- **Attenuation**: You can give a weaker permission to a function (for example, read-only file access, or network access to one host).
- **No ambient revival**: Sandboxed code cannot get wide permissions again by using global names.

### 2.3 Users

| Actor | Need |
|-------|------|
| Application author | Clear token grants in `main()`. Easy to read permission graphs. |
| Library author | Pure programming interfaces (APIs) with no hidden file or network access. |
| AI agent | Compiler errors when the AI tries to use ambient I/O. |
| Adversary | Bad packages and exploits cannot get more permissions than the system grants. |

## 3. Related work

### 3.1 Foundations

- **Dennis and Van Horn (1966),** "Programming Semantics for Multiprogrammed Computations," *CACM*. This paper introduces **capabilities** to control permissions. Child processes get a smaller set of permissions from parent processes.
- **Henry M. Levy (1984),** *Capability-Based Computer Systems*. This book examines hardware and software capability designs. https://homes.cs.washington.edu/~levy/capabook/
- **Wikipedia: Capability-based security**. This page shows modern systems like Capsicum, Fuchsia, Genode, L4, and CHERI. https://en.wikipedia.org/wiki/Capability-based_security

### 3.2 Operating systems and hybrid systems

- **Watson et al. (2010),** *Capsicum: practical capabilities for UNIX* (USENIX Security). This system combines capabilities with UNIX. It uses file descriptors as capabilities. Capability mode stops the use of global names. https://www.usenix.org/legacy/event/sec10/tech/full_papers/Watson.pdf
- **Google Fuchsia and Zircon**. This kernel isolates processes automatically. Programs use **handles** to get access. The design does not use ambient authority. https://fuchsia.dev/fuchsia-src/concepts/principles/secure
- **Pagano et al.,** "Understanding Fuchsia Security." This paper analyzes Zircon handles.
- **CHERI and Cambridge CTSRD**. These projects use hardware capability pointers to keep memory and permissions safe.

### 3.3 Language-level designs

- **E, Cap’n Proto RPC, and object-capability languages**. These tools use object capabilities to write programs.
- **Wasm component model and WASI**. These models use capability handles for host resources.
- **CloudABI and OpenBSD pledge/unveil**. These interfaces reduce ambient authority, but they do not use full language capabilities.

openOODA puts capabilities directly into the **language type system and call graph**. For example, you send `&FsCap` as a value. This design enforces library rules during compilation, not just in the operating system.

## 4. Design rationale for openOODA

### 4.1 Language surface

```ooda
// Pure function. It cannot do I/O.
fn parse_jwt(token: String) -> Result[Claims, Error]

// The function must use an explicit token to do I/O.
fn send_webhook(net: &NetCap, url: String, data: String)
```

The DESIGN document adds more capabilities: `&TimeCap`, `&RandCap` (for clean and predictable code), `&AllocCap<N>` (for memory limits), biometric system capabilities, and `&UnsafeFFICap`. The `&UnsafeFFICap` token permits deliberate connections to C/C++ code (see Section 6.3).

### 4.2 Why we use language-level capabilities

| Approach | Problem for openOODA |
|----------|----------------------|
| Containers or seccomp only | These tools are too broad. You cannot give small permissions to single functions. AI code still has ambient authority inside the container. |
| Operating system capabilities (Capsicum) | This provides a good process model, but the compiler cannot check library APIs. |
| Effect systems without tokens | These systems track pure functions, but you cannot easily share or reduce resource permissions. |
| **Language capabilities with runtime seals** | This design stops bad AI code and supply-chain attacks. It perfectly separates pure code (`std::core`) from operating system code (`std::os`). |

### 4.3 Interaction with other systems

- **ES.1 AI-native:** The compiler rejects AI code that does not use capability tokens. This stops prompt-injection attacks.
- **ES.3 Self-testing:** Capability tokens make pure functions easy to test. Fuzz testing stays predictable when you control time and random numbers with tokens.
- **ES.5 Zero-day defense:** If memory corruption occurs, the default-deny rules limit the damage.
- **ES.6 Scale:** The same capability system works for server I/O and for embedded hardware (for example, `&GpioPin4`).

## 5. Threat and failure model

### 5.1 What the system prevents or decreases

- File, network, environment, or execution access by dependencies that do not have tokens.
- Accidental ambient I/O in pure logic modules.
- Many **confused deputy** attacks at API boundaries, if the system enforces argument flow.
- Bad AI code that tries to steal data, because the system does not give tokens to the AI code.

### 5.2 What the system does not prevent

- **Logic errors** that use a valid `FsCap` incorrectly.
- **Kernel and runtime errors** that operate below the capability checks.
- **Side channels** (like timing attacks) between tasks.
- **Memory attacks** that rewrite process memory to create fake magic tokens. True token security requires hardware capabilities, OS capabilities, or cryptography.
- **FFI escapes** that occur without an `&UnsafeFFICap` token.

### 5.3 Remaining attack surface

Magic-token runtime seals prevent **accidental** errors and **source-level** errors. They do not protect against an attacker who fully controls the memory address space. They are not as strong as Capsicum or Zircon object capabilities.

## 6. Alternatives considered

| Alternative | Why we rejected or delayed it |
|-------------|-------------------------------|
| **Ambient authority with optional sandbox tags** | Programmers forget tags easily. This design is not secure by construction. |
| **Effect rows only (no tokens)** | This design cannot easily share or reduce file and network permissions. |
| **Operating system capabilities only (Capsicum or seccomp)** | The compiler cannot check library rules with this design. |
| **Full pure object capabilities from day one** | The research takes too much time. The product requires simple runtime seals first. |
| **Access Control Lists (ACLs) or Role-Based Access Control (RBAC)** | These models use user identities. They do not work well for untrusted packages and AI code. |

## 7. Product status

**PM.md — Capability-secure: `partial`.**
**Row 3.1 Unified capability sandboxing: `partial`.** The system has static checks and process-local magic tokens. It does not have cryptographic or biometric capabilities.

From `ooda/bootstrap/CAPS_MATRIX.md` (alpha version):

| Area | Status |
|------|--------|
| Static default-deny rules for file, system, environment, and network operations | **Done** (`check_caps`) |
| Argument flow: The capability token must be the true argument | **Done** (fixtures) |
| Runtime `oo_cap_require` magic tokens for sealed operations | **Done** (process-local) |
| Operations: `read_file`, `write_file`, `sys_exec`, `env_get`, `fetch` | **Done** on the Backend-C path |
| Larger network API surface | **Not done** (fails closed) |
| Biometric and hardware capabilities | **Not started** |
| Time, random, memory limit, cycle limit, and secret taint capabilities | **Not started** (rows 3.2 to 3.5) |
| Secure operating system capabilities | **Not started** |
| `&UnsafeFFICap` implementation | **Not started** (section 6.3) |

**Summary:** The alpha version is a **capability-oriented product**. It has real static and runtime seals for specific operations. It does not have the full DESIGN "unified capability sandboxing" or Zircon handles. Read these documents for more information: `CAPS_MATRIX.md` and `STATIC_CAPS.md`.

## 8. Open research questions

1. How do we change **magic tokens to OS handles, Capsicum, or Landlock** without breaking the pure `.oo` self-hosting compiler?
2. What is the correct **syntax to reduce permissions** for file paths and network hosts?
3. How can **asynchronous threads** (DESIGN Section 5.3) send capability tokens without creating ambient authority?
4. Can we use **biometric verification** as a type-state without restricting the language to one operating system?
5. How do package manifests (Section 5.2, verifiable web of code) work with runtime capability tokens?

## 9. Acceptance criteria

### 9.1 Keep `partial` status but improve documentation

- [x] Create a public matrix of sealed operations (`CAPS_MATRIX`).
- [ ] Document all remaining ambient paths to make sure they fail safely.

### 9.2 Move from `partial` to a stronger claim

- [ ] Stop pure OODA code from making fake capability tokens. This includes bad modules that do not have raw memory access.
- [ ] Complete the network operations or make them fail safely with stable error messages.
- [ ] Write a clear policy for FFI connections (like `&UnsafeFFICap`) and write tests for it.

### 9.3 Move to `done` for "capability-secure"

- [ ] Complete a subset of capabilities for a release. This must include file, network, system, and environment capabilities. It must include a way to reduce permissions.
- [ ] Remove all silent ambient I/O from the product.
- [ ] Get approval from the owner to move biometric and hardware capabilities to future updates.

## 10. References

1. openOODA, *DESIGN.md*, Section 3: Unified Capability Sandboxing, and Section 6.3: Capabilities vs FFI.
2. openOODA, *SPEC.md*, Capability-Based Sandboxing and zero-day trapping.
3. openOODA RFC 0001, Capability-Based Security Model. `spec/rfcs/0001-capability-security.md`.
4. J. B. Dennis and E. C. Van Horn, "Programming Semantics for Multiprogrammed Computations," *Communications of the ACM*, 1966. https://dl.acm.org/doi/10.1145/365230.365252
5. H. M. Levy, *Capability-Based Computer Systems*, Digital Press, 1984. https://homes.cs.washington.edu/~levy/capabook/
6. R. N. M. Watson et al., "Capsicum: practical capabilities for UNIX," USENIX Security, 2010. https://www.usenix.org/legacy/event/sec10/tech/full_papers/Watson.pdf
7. Fuchsia documentation, "Secure" principle and Zircon capabilities. https://fuchsia.dev/fuchsia-src/concepts/principles/secure
8. F. Pagano et al., "Understanding Fuchsia Security," arXiv:2108.04183. https://arxiv.org/pdf/2108.04183
9. openOODA `ooda/bootstrap/CAPS_MATRIX.md` and `STATIC_CAPS.md`.
10. Related papers: RP-3.1 to 3.5, RP-6.3, RP-ES.1, and RP-ES.5.

---

## 11. Conflicts with other DESIGN items

- **Section 4.3.3 and Section 6.3**: C/C++ FFI uses ambient authority. If we do not require `&UnsafeFFICap` or stronger protection, the capability system does not protect the boundary.
- **Section 3.11**: Self-modifying code changes the security of check sites and call-graph hashes (read ES.5 and Section 6.1).
- **Section 5.2**: The system must load zero-trust packages securely. The user interface must not give ambient capabilities (for example, "install with full file system access") automatically.

---

*Series: [Research papers index](./README.md). Template: [TEMPLATE.md](./TEMPLATE.md).*
