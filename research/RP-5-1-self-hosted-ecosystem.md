# RP-5.1: 100% self-hosted ecosystem

| Field | Value |
|-------|--------|
| **Paper ID** | `RP-5.1` |
| **DESIGN.md** | §5 Ecosystem |
| **Status** | `draft` |
| **PM.md row** | `5.1` |
| **Product mapping** | **partial** — We have a pure `.oo` compiler and CLI. The package manager, LSP, testing framework, and registry need work. |

## 1. Why we put this in DESIGN.md

DESIGN.md §5 says:

> A self-hosted compiler is not sufficient. You must write the package manager, the Language Server, the testing framework, and the network registry nodes in pure openOODA. This preserves the cryptographic security chain.

The security of openOODA relies on a **chain of trust**. Memory safety alone is not sufficient. Capability manifests, signed packages, contract proofs, and call-graph integrity remain secure only if the tools that read them follow the same rules. A package manager in a different language can open any file and run shell commands. This creates a security risk outside of the rules of openOODA. A registry node without capability limits becomes a security risk.

This paper shows why we make **ecosystem self-hosting** a primary design goal. This goal includes the compiler, package manager, LSP, test runner, and registry. This goal is different from the compiler and CLI milestone (RP-5.1a).

## 2. Problem statement

### 2.1 What breaks if the ecosystem is not self-hosted

| Component | If written in a different language (Rust/Python/shell) | Result for openOODA |
|-----------|-----------------------------------------------------|---------------------------|
| Compiler | Trust decreases to the seed and C runtime. | We accept this for now (RP-5.1a). |
| Package manager | Package rules bypass the capability limits. | Security claims become false. |
| LSP | The IDE can read all files and run tools. | AI agents get too much access. |
| Test runner | Tests operate outside the security rules. | The testing process becomes complex. |
| Registry | Security checks occur in untrusted code. | Zero-trust packages (RP-5.2) do not work. |

A user can be a **human** developer, an **AI agent** that uses the CLI, or an **attacker**. An attacker can send a dangerous package, a bad CI script, or a malicious LSP plugin.

### 2.2 Trust boundaries

Self-hosting only the compiler is standard practice. openOODA requires more. The **tools that execute code** must obey the capability limits of the language. If they do not, the security chain breaks.

### 2.3 Operational problems

Full self-hosting makes Continuous Integration (CI) difficult. Shell scripts and Python tools are easy to use and currently work. If we do not clearly define the rules for **product, bootstrap, and CI**, we will delay software releases or give false information about system purity.

## 3. Related work

### 3.1 Academic research

- **Bootstrapping compilers:** Thompson (1984) describes attacks on self-hosting. A bad compiler can add malicious code again and again. A fully self-hosted ecosystem increases this risk. We must use diverse compilation and reproducible builds (see RP-4.3.2, RP-6.1) to decrease this risk.
- **Capability systems:** The security of a system needs all tools to follow the capability rules. Package managers and registries must use capability types.
- **Software supply-chain integrity:** Frameworks like in-toto and SLSA verify steps. Self-hosting makes all tools **use the same language**. This makes sure that capability limits and contracts apply to the tools.

### 3.2 Industrial self-hosting

| System | Self-hosted parts | Remaining external parts |
|--------|-------------------|---------------|
| **Go** | Compiler and most tools. | Uses the OS and linker. Bootstraps with older Go. |
| **Rust** | Rustc and Cargo. | Uses LLVM/C++. |
| **OCaml** | Compiler. | Bytecode virtual machine is in C. |
| **Chicken Scheme** | Scheme to C compiler. | Uses a C runtime. |
| **Swift / Kotlin** | Large parts. | Uses platform SDKs and JVM tools. |
| **Deno / Bun** | Runtimes in Rust/Zig. | Tools use different languages. |

Industry standard practice is to self-host the compiler. It is rare to self-host the package manager, IDE, and registry. openOODA has stricter design rules than the industry. We must build these tools in phases.

### 3.3 Related openOODA papers

- **RP-5.1a** — Pure compiler and CLI (alpha version is complete).
- **RP-5.2** — Verifiable packages. This needs a pure package manager and registry.
- **RP-5.7** — LSP. This must be a pure `.oo` program.
- **RP-3.1 / RP-3.9** — Capability and call-graph integrity. Tools must obey these rules to work correctly.

## 4. Design reasons for openOODA

### 4.1 Definition of a 100% self-hosted ecosystem

| Layer | Must use pure `.oo` | Allowed external parts |
|-------|------------------------------|------------------|
| Frontend | Yes | None |
| Emit backends | Yes | Small C runtime (FLOOR.md) |
| CLI (`ooda`) | Yes | Shell only for basic tasks |
| Package manager | Yes | Network access with `&NetCap` |
| LSP daemon | Yes | Editor is external |
| Test runner | Yes | Human input with capabilities |
| Registry node | Yes | OS process with capabilities |
| **CI scripts and C runtime** | No | Explicit trusted computing base |

### 4.2 How pure code keeps the system secure

1. **Capability rules:** A pure package manager must use file and network capabilities (`&FsCap`, `&NetCap`). A Python tool does not have these limits.
2. **Verification:** Package checks (RP-5.2) can use the same code as the compiler check.
3. **Agent standard:** AI agents use JSON messages. A pure ecosystem gives one standard for all tasks.
4. **Code review:** Reviewers only need to read `.oo` code, not many different languages.

### 4.3 Project phases

```text
Phase A: Pure compiler and pure CLI  → RP-5.1a is complete.
Phase B: Pure test runner  → RP-5.4, RP-3.6.
Phase C: Pure LSP (check, outline, hover)  → RP-5.7.
Phase D: Pure package manager  → Starts RP-5.2.
Phase E: Pure registry node  → Completes RP-5.2.
```

We complete RP-5.1 when Phases A to E use pure code. The CI must not need other languages for the main product.

### 4.4 CI conflicts

Pure code does **not** prevent the use of shell scripts to start the system. It prevents the use of shell, Python, or Rust for the main `ooda`, `pkg`, or `lsp` tools.

## 5. Security threats and failures

### 5.1 What this prevents

- Unauthorized access from a package manager or LSP that lacks capability limits.
- The risk of an installer running with administrator rights.
- Differences between CI tools and the compiler.
- AI tools that need an OS sandbox to be secure.

### 5.2 What this does not prevent

- Attacks on the initial binary or C runtime (`chs_rt`).
- Bad decisions by human code reviewers.
- Dangerous package content that passes checks but causes harm. This requires RP-5.2.
- Operating system errors.
- CI scripts that run outside the main product.

### 5.3 System failures

| Failure | Problem | Solution |
|---------|---------|------------|
| Fake purity | The package manager uses an external tool like npm. | Use strict checks. |
| Early rewrites | Broken tools stop users. | Build in phases (A to E). |
| Infinite loops | The system cannot start. | Use a fixed starting binary with checksums. |
| Fake capabilities | Pure tools have full system access (`SysCap`). | Use strict capability limits. |

## 6. Other options

| Option | Reason for rejection |
|-------------|-------------------------|
| **Self-host the compiler only** | Keeps the package manager and LSP as security risks. |
| **Use Rust for all tools** | Creates two security models. Breaks our basic rules. |
| **Use WASM sandboxes for external tools** | Does not replace capability limits in the language. |
| **Use a microkernel OS** | openOODA must work on standard operating systems. |
| **Do not make the registry pure** | The long-term design needs secure network nodes. |

## 7. Current status

From the **PM.md** file, row `5.1` is **partial**.

| Component | Status | Notes |
|-----------|--------|------------------|
| Compiler | **Complete** | Pure `.oo` with a C runtime. |
| CLI (`ooda`) | **Complete** | Pure `.oo`. Uses shell for basic tasks. |
| Package manager | **Not started** | The CLI does not accept `pkg`. |
| LSP | **Not started** | The CLI does not accept `lsp`. |
| Test framework | **Partial** | Some tests work. Full testing is missing. |
| Registry nodes | **Not started** | No work done. |
| CI scripts | **External** | Uses shell and Python. |

Note: Milestone **5.1a** (pure compiler and CLI) is complete. The remaining work is for full ecosystem purity.

## 8. Open questions

1. What is the minimum code for a package manager that supports lockfiles, mirrors, and offline installation without a shell?
2. How do we measure purity for tools that install packages?
3. Can registry nodes use the same binary as the CLI with different capability limits?
4. How does diverse double-compilation work with the package manager and LSP?
5. Should the test tools and the fuzzer combine with the LSP to share data?
6. How do we prove to auditors that a tool meets the design security rules?

## 9. Acceptance criteria

### 9.1 Requirements to finish

- [ ] Build a pure `.oo` package manager with network and file capability limits. Do not use shell commands.
- [ ] Build a pure `.oo` LSP that provides diagnostics, outlines, and hover data.
- [ ] Build a pure `.oo` test runner with an API to pause for human input.
- [ ] Build a pure `.oo` registry client that verifies signed files.
- [ ] Document the trusted parts (seed, C runtime, OS). Do not require Rust or Python.
- [ ] Make sure CI tests do not use external programs for the package manager, LSP, or tests.

### 9.2 Optional intermediate steps

- [ ] Make a basic package manager that only checks local files.
- [ ] Make a basic LSP that only runs error checks when you open a file.

## 10. References

1. K. Thompson, "Reflections on Trusting Trust," *CACM*, 1984.
2. J. Dennis & E. Van Horn, "Programming Semantics for Multiprogrammed Computations," *CACM*, 1966.
3. M. Miller, *Robust Composition: Towards a Unified Approach to Access Control and Concurrency Control*, PhD thesis, Johns Hopkins, 2006.
4. Go Team, *The Go Programming Language* toolchain documents.
5. Rust Project, rustc bootstrap notes.
6. OCaml and Chicken Scheme bootstrap documents.
7. in-toto and SLSA project documents.
8. openOODA documents: `spec/DESIGN.md` §5, `PM.md` §5, `ooda/bootstrap/FLOOR.md`, `ooda/bootstrap/seed/README.md`.
9. Papers RP-5.1a, RP-5.2, RP-5.7.

---

*Series: [Research papers index](./README.md). Template: [TEMPLATE.md](./TEMPLATE.md).*
