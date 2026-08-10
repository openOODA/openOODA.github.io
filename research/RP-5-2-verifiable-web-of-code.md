# RP-5.2: Verifiable web of code (zero-trust packages)

| Field | Value |
|-------|--------|
| **Paper ID** | `RP-5.2` |
| **DESIGN.md** | §5 Ecosystem |
| **Status** | `draft` |
| **PM.md row** | `5.2` |
| **Product mapping** | **not-started** |

## 1. Why this is in DESIGN.md

DESIGN.md §5:

> A decentralized package manager where imported modules are mathematically proven by the compiler's Formal Verification solver. Third-party libraries are cryptographically minted with a strict capability manifest, allowing you to dynamically import AI-generated code with 100% mathematical trust.

openOODA uses AI-generated and multi-party code as standard. Old package managers (npm, PyPI, crates.io) focus on fast discovery and speed. They think trust means a good reputation, optional signatures, and fixing problems after they happen. The DESIGN document makes packages into artifacts with capabilities and proofs. When you import a dependency, you link a verified module. You do not run an unsafe script.

This paper explains the verifiable web of code. It shows what older tools (Sigstore, TUF, in-toto, SLSA, capability packages) do. It shows what openOODA must add (capability manifests and contract proofs). It explains the conflicts (for example, against hive-mind fuzzing) that we must solve.

## 2. Problem statement

### 2.1 Classical package failure modes

| Failure | Example class | Why capabilities and signatures are not enough |
|---------|---------------|----------------------------------------|
| Typosquatting | Package names that look similar | Identity does not equal behavior |
| Compromised maintainer | Stolen npm tokens | Signatures prove identity, not intent |
| Malicious install scripts | `postinstall` RCE | Package managers run code too early |
| Dependency confusion | Private and public names are the same | This is a registry rule, not a language rule |
| AI sludge | Code looks correct but is wrong or unsafe | The code needs contracts and capabilities, not user stars |

### 2.2 openOODA-specific pressure

1. **Agents import code faster than humans review it.**
2. **You must declare capabilities.** If a network library does not have `&NetCap` in its API, it is a lie or a sandbox error.
3. **Contracts** (`requires`/`ensures`) are the proof surface of the language. Packages must include obligations, not only types.
4. **Decentralized registry** goal (ES.6) does not permit a single trust root forever.

### 2.3 Users

- **Developer:** Wants to use `ooda pkg add` with fail-closed safety.
- **Agent:** Wants a machine-readable allow or deny list.
- **Adversary:** Wants to send signed malware, too many capabilities, or "verified" packages with empty contracts.

## 3. Related work

### 3.1 University and formal work

- **Capability-based security** (Miller; Dennis & Van Horn): Authority moves only through secure tokens. This connects to package APIs that require `&FsCap` or `&NetCap` instead of general authority.
- **Proof-carrying code** (Necula & Lee, 1996/97): Code has a checkable proof that it is safe. openOODA has "mathematically proven modules". This is a modern version (contracts and solver), not full binary proofs on the first day.
- **Module systems and sealing** (ML functors, sealed traits): You restrict the interface to make a trust boundary.
- **Software supply-chain research** (academic SLSA analyses; in-toto papers): The layout of steps, roles, and link data.

### 3.2 Commercial and open industry standards

| Tool or standard | Role | Gap for openOODA |
|-----------------|------|------------------|
| **Sigstore** (Cosign, Fulcio, Rekor) | Keyless signing, transparency log | Proves who and when, but not capability lattice or contracts |
| **TUF** (The Update Framework) | Secure distribution, stops rollbacks | Does not check package authority types |
| **in-toto** | End-to-end step proofs | Needs import rules at the language level |
| **SLSA** | Build history levels | Build history does not equal semantic safety |
| **crates.io / npm / PyPI signing** | Ecosystem use | These languages use general authority |
| **WebAssembly component model + WASI caps** | Portable capability input/output | Inspires `std::core` against `std::os` (RP-5.4) |
| **Deno permission model** | Runtime question/allow-list | Does not cryptographically mint packages |

**Sigstore against in-toto (industry view):** Sigstore keeps and checks signatures. in-toto organizes the steps that must occur. They work together. in-toto proofs go into Rekor. openOODA must use them as **distribution and history layers**. openOODA must add a **semantic layer**: capability manifest and optional proofs that `oodac` checks.

### 3.3 Capability packages (design pattern)

Prior work for packages that declare authority:

- Android permissions and iOS entitlements (OS-level, not specific).
- Capsicum, CloudABI, and WASI (runtime capability handles).
- Pony, E, and Cap'n Proto RPC (language and runtime capabilities).

openOODA packages must **mint** a manifest:

```text
package: foo@1.2.3
hash: sha256:…
requires_caps: [NetCap(scope=https://api.example.com/*)]
exports: …
contracts: verified|unverified|partial
attestations: [sigstore/rekor, in-toto layout]
```

The import fails closed if the **using module** cannot give those capabilities.

## 4. Design rationale for openOODA

### 4.1 Zero-trust import pipeline

```text
fetch (TUF-protected)
  → verify signature and Rekor inclusion (Sigstore-class)
  → verify in-toto layout (build steps)
  → check capability manifest fits in granted authority
  → run contract and proof obligations (solver and fuzz residual)
  → link into build with sealed hashes
```

"100% mathematical trust" in the DESIGN document is a **goal**. The alpha version will release layers step by step. Research must not say signatures are proofs of correct function.

### 4.2 Capability manifests as first-class

General imports are not permitted. A dependency that uses the network without `&NetCap` parameters is a capability error (RP-3.1). Package data must **match** the static analysis of the package body. You cannot use fake manifests.

### 4.3 AI-generated code

Agents can send packages. The web of code must support:

1. Ephemeral and content-addressed modules.
2. Narrow capabilities.
3. Mandatory contracts for high-risk APIs.
4. Human or policy checks (RP-5.6) before you publish.

### 4.4 Decentralized registry nodes

Registry nodes (RP-5.1 pure `.oo`) store manifests and proofs. The consensus and mirror rules are future product designs. Cryptographic minting needs **append-only or transparency** functions (like Rekor). It does not need a blockchain.

### 4.5 Conflict: hive-mind fuzz against package zero-trust

**Global hive-mind fuzzing (RP-2.4)** shares mutations, corpora, and package tests across idle nodes. **Zero-trust packages** use minimum trust, fixed hashes, and explicit grants.

| Dimension | Hive fuzz | Zero-trust package |
|-----------|-----------|----------------|
| Default stance | Share, mutate, explore | Deny, pin, verify |
| Network | Opportunistic P2P | Authenticated fetch |
| Code history | "Interesting crash" | Signed and attested |
| Risk | Bad data from the fuzz network | Stop progress if too closed |

**Resolution (design policy):**

1. Fuzz corpora and crash reports use a **separate channel** from packages.
2. Promotion path: `fuzz artifact → quarantine → attest → package mint` with an explicit capability check.
3. Hive nodes do not auto-install. They only trade **inputs and oracles**. They do not trade authority.
4. The package registry does not run package code at index time. There are no install scripts.

## 5. Threat and failure model

### Prevents

- General authority dependencies that claim they are "pure".
- Hidden code execution when you resolve a package.
- Registry responses with no authentication (when TUF protection is active).
- Capability increases through incorrect manifests (when the system checks the body against the manifest).

### Does not prevent

- Correctly signed packages that are **bad on purpose within their given capabilities** (you need contracts, reviews, and humans in the loop).
- Incomplete solver logic (incorrect "verified" labels).
- Stolen signing identities (transparency logs help you find them, not stop them).
- Side-channel or runtime bugs in verified modules.
- Social engineering against human approvers.

### Failure modes

| Mode | Mitigation |
|------|------------|
| Empty contracts marked verified | Strict levels: default is `unverified`; proof grades |
| Manifest lie | Compiler capabilities must equal the manifest |
| Sigstore centralization | Permit offline keys and a multi-log policy later |
| Capabilities are too broad (`FsCap /*`) | Linter and policy blocklist for publish |

## 6. Alternatives considered

| Alternative | Why it is not enough |
|-------------|------------------------|
| **Checksum lockfile only** (early Cargo/npm) | No identity, no capabilities, no proofs |
| **Sigstore only** | History but no semantic authority |
| **Central app store review** | Not decentralized; too slow for agents |
| **Full formal verification of all dependencies** | Costs too much money as a default |
| **Runtime-only permissions (Deno-style)** | Occurs too late; agents need a static fail-closed state |
| **Blockchain package registry** | Optional transport; not necessary for DESIGN |

## 7. Product reality (alpha honesty)

In the monorepo **PM.md** row `5.2`: **not-started**.

| Piece | Alpha state |
|-------|-------------|
| `ooda pkg` | Rejected as beta-out on CLI |
| Capability manifests on packages | Not productized |
| Sigstore, TUF, and in-toto integration | None |
| Contract proof at import | Residual; simple `requires` partial on native |
| Registry | None |

Prerequisite partials: pure package client (RP-5.1), capability system maturity (RP-3.1), and deterministic builds (RP-4.3.2) for true history.

## 8. Open research questions

1. What is the **minimum viable manifest** schema that agents can make and humans can check on one screen?
2. How do we grade "verified" without lying (proof, fuzz budget, human proof)?
3. Can capability scopes use **set theory** (URLs, paths) with easy inclusion checks?
4. How do reproducible builds work with changing dependencies under TUF?
5. Must AI-generated packages expire by default (time-boxed trust)?
6. What is the safe interoperation plan with crates and npm for FFI wrappers (RP-6.3)?

## 9. Acceptance criteria (for PM status promotion)

### not-started → smoke

- [ ] Local package format: directory + `manifest.oo`/`manifest.json` + content hash.
- [ ] `ooda pkg verify` pure path: hash + optional signature check (offline keys are acceptable).
- [ ] Static check that package public API capability requirements fit in the manifest.

### smoke → partial

- [ ] Lockfile + fetch over `&NetCap` with fixed hashes.
- [ ] Capability grant connected into the build.
- [ ] No install scripts run.

### partial → done

- [ ] TUF-class update security *or* documented pin and mirror policy.
- [ ] Attestation check (in-toto or subset) for release builds.
- [ ] Contract obligation gate with explicit trust levels.
- [ ] Publish path with minting and transparency log hook.
- [ ] Hive fuzz cannot install packages (policy tests).

## 10. References

1. G. Necula & P. Lee, "Proof-Carrying Code," *POPL*, 1997.
2. S. Torres-Arias et al., in-toto: Securing the Software Supply Chain (USENIX and project docs).
3. The Update Framework (TUF) specification — CNCF.
4. Sigstore project: Cosign, Fulcio, Rekor; "Sigstore: Software Signing for Everybody."
5. SLSA framework (supply-chain levels for software artifacts).
6. Chainguard and industry writeups on composing Sigstore, TUF, and in-toto.
7. M. Miller, capability security literature.
8. WASI and capability-oriented portable runtimes.
9. openOODA DESIGN §5, §3 caps; RP-2.4, RP-3.1, RP-5.1, RP-5.4, RP-6.3.

---

*Series: [Research papers index](./README.md). Template: [TEMPLATE.md](./TEMPLATE.md).*
