# RP-3.1: Unified capability sandboxing

| Field | Value |
|-------|--------|
| **Paper ID** | `RP-3.1` |
| **DESIGN.md** | §3 Safety — Unified Capability Sandboxing |
| **Status** | `draft` |
| **PM.md row** | `3.1` |
| **Product mapping** | **partial** — static check + process-local magic tokens; not crypto/biometric caps |

## 1. Why this is in DESIGN.md

DESIGN.md §3 states:

> A default-deny security model where functions cannot perform I/O without explicit capability tokens (e.g., `&NetCap`, `&FsCap`). This scales all the way up to **Biometric Attestation** (e.g., `&SysCap<RequireBiometric>`), which pauses execution to require a physical hardware enclave or FaceID scan before running critical logic.

This is the primary least-privilege system for openOODA.
Ambient authority is the default in POSIX and most standard libraries.
It is the root cause of many bugs.
AI-generated code makes these bugs more common.
For example, a helper function opens a path without permission.
Capability tokens invert this default.
Effects are explicit arguments.
You can see them in signatures.
The compiler checks them.
The runtime checks them again.

This item supports the Executive Summary concept of "capability-secure by construction".
It connects to §5.4 (`std::core` pure vs `std::os` effectful).
It connects to §5.2 (package manifests with capability lists).
It connects to §6.3 (FFI as an explicit cap-tainted breach).
Other safety features need unified capabilities.
Taint, quotas, and fuzzing require a single authority model.

## 2. Problem statement

### What breaks without it

1. **Ambient I/O in agent loops.** openOODA targets AI-authored and AI-patched code. Code like `read_file("/etc/passwd")` must fail automatically unless the caller passed `&FsCap`. We cannot rely only on code reviews.
2. **Third-party modules.** Verifiable packages (§5.2) need a capability manifest. The manifest must specify allowed capabilities, like "this crate may use Net". Without language-level capabilities, manifests are only documentation.
3. **Confused deputy.** A privileged service might accept a path from untrusted input and open it. This causes the confused deputy problem. Capabilities make the token the authority. The process identity is not the authority.
4. **Untracked privilege escalation.** System execution, network fetch, and environment reads are different risk classes. A simple boolean value is insufficient. We need specific capability levels, up to biometric attestation.

### Users and adversaries

| Actor | Need |
|-------|------|
| Human developer | Signatures that document effects; fail-fast when a pure function acquires I/O |
| AI agent / patch tool | Static `E_CAP` diagnostics with fix hints (“add `&FsCap` param”) |
| Package consumer | Manifest + compile refusal if dependency claims more caps than granted |
| Adversary | Compromised pure logic, malicious dependency, or hostile binary rewrite |

### Core research question

Can a systems language provide object-capability discipline at the language boundary? It must target standard operating systems like Linux. It must use Backend-C. It must remain self-hosted in pure `.oo`.

## 3. Related work

### 3.1 Classical object-capability systems (university / research OS)

**KeyKOS / GNOSIS (Tymshare, Key Logic).** This is a persistent capability nanokernel. Authority requires possession of a capability key. It has no ambient authority.

**EROS (Shapiro et al., University of Pennsylvania; SOSP 1999).** This reconstructs KeyKOS for commodity processors. It uses pure capability IPC and explicit resource accountability. It showed that capability systems work on standard hardware.

**seL4 (Klein et al., NICTA/UNSW; SOSP 2009 and follow-ons).** This is a capability-based microkernel. It has machine-checked functional correctness. Capabilities live in CNodes. Authority requires possession of the capability. seL4 verified kernel capabilities end-to-end. openOODA wants to achieve this at the language level.

**Dennis & Van Horn (1966).** This is the original capability paper. It established the concept that the token is the authority.

### 3.2 Hybrid / practical OS capabilities (university + industry)

**Capsicum (Watson et al., University of Cambridge / FreeBSD; USENIX Security 2010).** This adds capability mode to a production UNIX. A process enters the sandbox voluntarily. The system denies global namespace operations. File descriptors retain rights. This shows the value of extending UNIX. openOODA extends Backend-C and Linux similarly.

**Google Fuchsia / Zircon.** This uses handles to kernel objects with rights. Components receive the minimum capabilities through manifests. This shows industrial support for capability-style design.

**CloudABI / CapsiCloud lineage & WASI.** This is a capability-oriented cloud ABI. Programs start with given file descriptors. Path-based ambient access is removed. This influenced the WASI model for WebAssembly sandboxes. This is relevant to the openOODA WASM target.

### 3.3 Language-level capabilities and effect systems

| System | Mechanism | Lesson for openOODA |
|--------|-----------|---------------------|
| E / Pony / Cap’n Proto RPC | Object-caps / reference confinement | Unforgeable references are better than magic integers |
| Wyvern / Effekt / Koka | Effect types / handlers | Effects as types scale with inference; caps are a coarse effect lattice |
| Rust (no built-in caps) | Ownership ≠ authority | Safe memory ≠ least privilege I/O |
| Deno permission flags | CLI grant model | Coarse ambient flags; not per-function tokens |
| Android Binder / iOS entitlements | Platform capability-ish APIs | Hardware attestation exists commercially; biometric capabilities are realistic |

### 3.4 Commercial sandboxing (non-cap but related)

Chrome site isolation, Linux seccomp-bpf, Flatpak/Snap portals, and AWS/GCP IAM use identity-based authority. These systems are different. openOODA uses token authority in parameters. AI and humans can see token authority in the code structure.

## 4. Design rationale for openOODA

### 4.1 Language shape (DESIGN north star)

```text
fn load_config(fs: &FsCap, path: String) -> Result[Config, IoErr]
fn post_metrics(net: &NetCap, body: Bytes) -> Result[(), NetErr]
fn pure_hash(data: Bytes) -> Hash   // no caps → pure by signature
```

- **Default deny:** Sealed operations require a matching capability parameter. Examples include `read_file`, `sys_exec`, `env_get`, and `fetch`.
- **Arg-flow:** A capability in scope is not sufficient. The call must pass the correct capability identifier. This prevents the confused deputy problem.
- **Ladder:** The system supports a range of capabilities. `&FsCap` allows file access. `&SysCap<RequireBiometric>` requires human verification for critical paths.
- **FFI breach:** Section 6.3 states C and C++ are outside the model. The compiler must require an `&UnsafeFFICap` token.

### 4.2 Why “unified”

The system uses one static checker and one runtime verification process. It uses one diagnostic family (`E_CAP`) and one package manifest schema. Separate mechanisms for file system and network policies cause unmaintainable agent tools.

### 4.3 Interaction with other DESIGN items

| Item | Interaction |
|------|-------------|
| 3.2 Time/Rand caps | Same lattice; purity of pure functions |
| 3.3 AllocCap | Cap-parameterized resource quota |
| 3.5 Secret taint | Caps as *sinks* for secret policy (no Secret → unencrypted Net) |
| 3.6 Fuzzer | Effectful fuzz needs cap-aware harnesses |
| 5.4 std::core vs os | Core = no caps; os = cap-gated |
| 5.2 Verifiable packages | Cap manifests |
| 6.3 Caps vs FFI | Explicit breach token |

### 4.4 Alpha implementation strategy

1. **Static default-deny** on sealed names. The product uses `check_caps.oo`.
2. **Runtime magic-token check** on Backend-C. The system uses `oo_cap_require`. These tokens are forgeable.
3. **Opaque and unforgeable runtime tokens**. The process keeps these private.
4. **OS-backed handles**. The system derives Capsicum, Landlock, or seccomp profiles from the capability set.
5. **Hardware and biometric attestation** for high-assurance capabilities.

The current product includes steps 1 and 2. The design plan includes steps 1 through 5.

## 5. Threat / failure model

### Prevents (when fully realized)

- Accidental ambient I/O from pure functions.
- Dependency code opening file systems or networks without declared authority.
- Many confused deputy bugs, if the system enforces path attenuation.
- Silent privilege growth across code changes. Changes require updated signatures.

### Does **not** prevent (alpha and/or by design)

| Gap | Reality |
|-----|---------|
| Hostile binary rewrite of magic constants | Users can forge magic tokens by editing the binary (`STATIC_CAPS.md`) |
| Hand-written C linked without check | Backend-C/gcc path; see §6.3 residual |
| Kernel / hardware compromise | Capabilities apply to language and runtime, not seL4 |
| Covert channels via timing/cache | The system requires 3.2/3.5 and hardware assumptions |
| Social engineering of biometric prompt | Attestation requires user interaction |
| Incomplete sealed name list | Residual aliases may fail at the link stage, not the check stage |

### Failure modes product already documents

- The capability parameter is present, but the identifier is incorrect. This causes an arg-flow failure.
- The system receives a zero or incorrect magic token. This causes an `ERR\tcap\t…` exit.
- The system attempts network operations other than `fetch`. This emits a residual and fails closed.

## 6. Alternatives considered

| Alternative | Why rejected / deferred |
|-------------|-------------------------|
| **POSIX UID / DAC only** | Authority is ambient for the entire process. There is no per-function least privilege. |
| **seccomp-only sandbox** | The mechanism is hidden from the language and AST. It does not appear in signatures. |
| **Effect systems without tokens** | Capabilities use explicit tokens for better agent readability. |
| **Deno-style CLI grants only** | The grants apply process-wide and do not compose well for libraries. |
| **Full seL4 userspace first** | This blocks the initial release for commodity Linux. |
| **Capability inference (no params)** | This hides effects from signatures. It decreases transparency for agents. |
| **Published magic ints forever** | This is acceptable for early releases. We must not label this as object capabilities. |

## 7. Product reality (alpha stage)

**PM.md `3.1`: partial.**

| Layer | Status | Evidence |
|-------|--------|----------|
| Static check | **real** | `oodac/check_caps.oo`; fixtures `no_cap_*` / `ok_*` |
| Cap classes | Fs, Sys, Env, Net | Net: `fetch` lowered; other net names residual |
| Runtime seal | **magic tokens** | `OO_CAP_FS/SYS/ENV/NET`; `oo_cap_require` in `chs_rt` |
| Unforgeable object-caps | **not claimed** | `STATIC_CAPS.md`, `BETA.md` Out surface |
| Biometric / enclave caps | **not-started** | DESIGN upper bound only |
| `&UnsafeFFICap` | **not-started** | PM `6.3` |
| Attenuation (path/prefix rights) | residual | Full-path ambient once FsCap held |

Canonical docs:

- `ooda/bootstrap/STATIC_CAPS.md`
- `ooda/bootstrap/CAPS_MATRIX.md`
- `ooda/bootstrap/BETA.md` (In vs Out)
- Smoke: `scripts/caps_matrix_smoke.sh`

**Do not claim:** Cryptographic capabilities, cross-process unforgeability, or biometric-gated capabilities.

## 8. Open research questions

1. **Token representation:** When should we transition from local magic variables to opaque heap tokens or OS handles? This transition must not break Backend-C self-hosting or increase build time.
2. **Attenuation algebra:** Should we use static syntax or runtime objects for path-prefix, read-only, and time-bounded capabilities?
3. **Cap polymorphism / inference:** How can agents write less boilerplate code without restoring ambient authority?
4. **Multi-module check completeness:** How do we maintain capability soundness within time limits during multi-module builds?
5. **WASM / embedded mapping:** Can we treat WASI preopens and bare-metal GPIO capabilities as the same lattice?
6. **Biometric pause semantics:** Should the system use a sync block, an async effect, or typed errors for timeouts and denials?
7. **Package minting:** How do we bind capability manifests to module hashes cryptographically without a full registry?

## 9. Acceptance criteria (for PM status promotion)

### partial → stronger partial / done (language + runtime)

- [ ] Opaque runtime tokens for Fs/Sys/Env/Net on claimed paths.
- [ ] Full sealed operation matrix. Every sealed name is lowered and checked, or it fails closed.
- [ ] Path attenuation MVP with pass/fail fixtures.
- [ ] Stable capability diagnostics (`E_CAP`) and fix hints in JSON format.
- [ ] Documented threat model. The document explains what hostile binaries can and cannot do.

### done (DESIGN-aligned, still without biometric)

- [ ] Capabilities are unforgeable within the process.
- [ ] The compiler checks the package-level capability manifest at import.
- [ ] The compiler requires `&UnsafeFFICap` for FFI.
- [ ] Threads do not share capabilities secretly.

### biometric / hardware (stretch; separate gate)

- [ ] Provide at least one platform path for the user attestation gate.
- [ ] Fail closed when hardware is unavailable.

## 10. References

1. Dennis, J. B., & Van Horn, E. C. (1966). *Programming semantics for multiprogrammed computations.* CACM.
2. Shapiro, J. S., Smith, J. M., & Farber, D. J. (1999). *EROS: a fast capability system.* SOSP.
3. Shapiro, J. S. *EROS: A Capability System.* PhD thesis, University of Pennsylvania.
4. KeyKOS / GNOSIS architecture documentation (Key Logic / Tymshare lineage).
5. Klein, G., et al. (2009). *seL4: Formal verification of an OS kernel.* SOSP; extended in TOCS 2014, *Comprehensive formal verification of an OS microkernel.*
6. Watson, R. N. M., et al. (2010). *Capsicum: practical capabilities for UNIX.* USENIX Security.
7. FreeBSD Capsicum man pages / Cambridge Capsicum project.
8. Google. *Fuchsia* / Zircon concepts: handles, rights, components (fuchsia.dev).
9. CloudABI design notes; WASI (WebAssembly System Interface) capability-oriented preview APIs.
10. Miller, M. S. *Robust Composition: Towards a Unified Approach to Access Control and Concurrency Control* (E language / object-caps).
11. openOODA product: `spec/DESIGN.md` §3, §6.3; `PM.md` row 3.1; `ooda/bootstrap/STATIC_CAPS.md`, `CAPS_MATRIX.md`, `BETA.md`.

---

*Series: [Research papers index](./README.md). Template: [TEMPLATE.md](./TEMPLATE.md).*
