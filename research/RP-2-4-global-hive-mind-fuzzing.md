# RP-2.4: Global hive-mind fuzzing

| Field | Value |
|-------|--------|
| **Paper ID** | `RP-2.4` |
| **DESIGN.md** | Section 2 AI tooling — Global Hive-Mind Fuzzing |
| **Status** | `draft` |
| **PM.md row** | `2.4` |
| **Product mapping** | **not-started** — Peer-to-peer (P2P) mutations overnight; local contract fuzzing is only partial |

## 1. Why this is in DESIGN.md

DESIGN.md Section 2 states:

> **Global Hive-Mind Fuzzing:** The compiler runs as a background process. It connects to a global peer-to-peer network of idle openOODA compilers. The network uses artificial intelligence (AI) to generate semantic mutations while you sleep. This process mathematically proves or breaks your contracts overnight.

This document expands on local automated contract fuzzing (RP-3.6). It describes a distributed and AI-assisted search for errors and proofs. The network shares idle computer resources (CPU) across a community. This is similar to distributed fuzzing systems like OSS-Fuzz or ClusterFuzz. But this system focuses on contracts and semantic mutations. It does not only look for system crashes.

This paper gives reasons for the vision. It looks at existing distributed fuzzing software. It analyzes the privacy and security of P2P networks. It states conflicts with capability isolation, determinism, and the core product. The current product status is **not-started**.

## 2. Problem statement

### 2.1 Local fuzzing is not enough

Contract fuzzing on one computer has limits:

- It does not explore large state spaces fully.
- It stops when the computer of the developer goes to sleep.
- It is hard to share interesting seeds or mutations across projects without special infrastructure.

### 2.2 Design user story

1. A developer writes code modules with `requires` and `ensures` statements.
2. The `ooda` daemon adds the project into a network.
3. Peer computers run AI-guided semantic mutations and contract rules.
4. The system gives a morning report. The report shows breaking inputs, small reproductions of the error, or better confidence metrics. It does **not** change the source code without review.

### 2.3 Users and adversaries

| Actor | Goal |
|-------|------|
| Developer or team | Find more software bugs per hour. |
| Open-source maintainer | Get community fuzzing resources like OSS-Fuzz. |
| Network peer operator | Give idle CPU time. Must not get malicious code. |
| Adversary peer | Steal source code, poison the test data, execute code on other computers, or get false credits. |
| Nation-state or curious ISP | Look at who tests what code. |

### 2.4 Success definition

**Version 1 success** is a distributed search for errors with strong isolation. It is not literal "mathematical proof overnight." Proof is a later step that uses SMT solvers or proof artifacts. This step might never fully work for all code.

## 3. Related work

### 3.1 Industrial distributed fuzzing

- **OSS-Fuzz** (Google and OpenSSF): This does continuous fuzzing for open-source software. It uses scalable distributed execution. It includes libFuzzer, AFL++, Honggfuzz, Centipede, and sanitizers. It has found tens of thousands of bugs. It uses the ClusterFuzz backend.
- **ClusterFuzz and ClusterFuzzLite**: This is open-source scalable fuzzing infrastructure. It manages test data, removes duplicates, makes data smaller, and files bugs.
- **Centipede** and related Google engines: These engines do large-scale fuzzing based on code coverage.

**Lesson:** Successful systems use **central management** with trusted worker computers. They do not use open P2P networks. This is necessary for good security.

### 3.2 Collaborative and untrusted-client fuzzing research

- **Fuzzing@Home** (Jang et al., RAID 2022): This is public collaborative fuzzing on untrusted client computers. It solves problems with result integrity, incentives, and bad inputs. It is the primary academic reference for the P2P design.

### 3.3 Coverage-guided and semantic fuzzing

- AFL family and libFuzzer: These use coverage feedback.
- Grammar and structure-aware fuzzing; API fuzzing.
- **Contract and property fuzzing**: This includes QuickCheck and language-integrated properties.
- AI and ML-guided mutations: These use neural networks or LLMs to suggest inputs. This is active research. The quality varies and the cost is high.

### 3.4 Distributed trust networks

- BOINC and Folding@Home: These networks use volunteer computers with applications signed by the project. They do **not** use general P2P code sharing.
- Blockchain compute markets: These give an incentive layer. They often have weak isolation rules.

### 3.5 Gap

No mainstream programming language has **opt-in global P2P contract fuzzing** with capability-isolated execution of untrusted test code. The openOODA project uses capability limits (RP-3.1), time and entropy limits (RP-3.2), and memory and CPU limits (RP-3.3 and 3.4). These limits are the intended differences. We must implement them before we make the network.

## 4. Design rules for openOODA

### 4.1 Proposed layered architecture

```
┌─────────────────────────────────────────┐
│  Central Manager (opt-in daemon)        │
│  Job queue, test data, reports          │
└───────────────┬─────────────────────────┘
                │ Sanitized jobs
┌───────────────▼─────────────────────────┐
│  Worker (peer computer)                 │
│  - Sandbox for the target code          │
│  - Mutator (coverage, AI, or semantic)  │
│  - Contract oracle                      │
└───────────────┬─────────────────────────┘
                │ Error reports (small)
┌───────────────▼─────────────────────────┐
│  Developer project                      │
│  - Review (Section 5.6)                 │
│  - Do not change code without approval  │
└─────────────────────────────────────────┘
```

### 4.2 What the network shares

| Item to share | Risk | Default rule |
|-------|------|---------|
| Coverage bitmaps and hashes | Low to medium | OK if the project is public |
| Small failing inputs | Medium | Remove secrets; use secret taint (RP-3.5) |
| Source code | **High** | **Off** for private code; opt-in for public code |
| Model weights and prompts | Medium | Prefer local mutators |
| Raw crash memory dumps | High | Remove sensitive data |

**Private projects** must support a **local network** (team VPN or self-hosted manager) before they use the public global network.

### 4.3 AI-driven semantic mutations

The system has three levels:

1. **Classical mutators** on structured inputs. This matches RP-3.6.
2. **Syntax-level semantic mutators** for test code and property generators. Do not use these to mutate production code without review.
3. **LLM-proposed inputs and generators**. These operate offline. They are not required for network membership.

The AI-driven semantic mutations must target **inputs and test code**. They must not silently rewrite production code. Silent rewrites conflict with RP-2.3 and Human-in-the-Loop rules.

### 4.4 "Mathematically proving" overnight

This means staged confidence levels:

| Level | Meaning |
|------|---------|
| Level 0 | No crash and no contract failure on the test data. |
| Level 1 | Code coverage reaches a maximum plateau. |
| Level 2 | Bounded model check or SMT on a small part of code. |
| Level 3 | Full mathematical proof objects. |

Version 1 of the network provides Level 0 and Level 1 at a large scale. Marketing material must not say that Level 0 is a mathematical proof.

### 4.5 Why language-integrated fuzzing is better than OSS-Fuzz

- Contracts are **in the source code**, not only in external test code.
- Capability limits make untrusted peer jobs safer than raw C code.
- The compiler acts as a long-lived service, similar to a Language Server Protocol (RP-5.7).

However, an **OSS-Fuzz-style central service** is likely the correct first product. The P2P network will be an experimental addition later.

## 5. Threat and failure model

### 5.1 P2P and distributed security threats

| Threat | Description | Mitigation rule |
|--------|-------------|----------------------|
| **Source code theft** | A peer gets enough data to rebuild private code. | Share hashes and test code only; encrypt jobs; use a private manager. |
| **Test data poison** | Bad inputs waste time or hide bugs. | Use peer reputation; use deterministic replay; verify on the local computer. |
| **Fake bug reports** | A peer makes false claims. | You **must** run the report locally in a sandbox before you trust it. |
| **Remote code execution on a worker** | A bug in the fuzzer lets a peer run bad code. | Use capability limits, CPU quotas, and process isolation. Do not use `UnsafeFFICap`. |
| **Remote code execution on a developer** | Opening a bad bug report runs bad code. | Treat the report as data. Run it in a maximum sandbox. |
| **Privacy loss** | Network data shows who you are. | Tor or VPN are optional. Do not send data by default. |
| **Resource theft** | Peers use the network to mine cryptocurrency. | Use a strict job format allowlist, CPU quotas, and signed jobs. |
| **Bad software update** | A peer sends a bad update for the daemon. | Use pinned signatures and reproducible builds. |
| **Model prompt leak** | The AI mutator sends private code to a cloud API. | Use **local-only** mutators by default. |

### 5.2 What network fuzzing can prevent (when mature)

- Hidden contract errors that unit tests miss.
- Code regressions across software versions.
- Bugs in open-source dependencies (if they join the network).

### 5.3 What it cannot prevent

- Missing specifications.
- Logic errors that are outside the written contracts.
- Social engineering where developers accept bad code fixes.
- Hardware bugs and side channels.

## 6. Alternatives considered

| Alternative | Assessment |
|-------------|------------|
| **Local-only `ooda test --fuzz`** | **Necessary foundation** (RP-3.6). We must ship this before any network. |
| **Central OSS-Fuzz-like service** | This gives the best security and operations balance for version 1. |
| **Open global P2P network** | This is the design vision. It has the highest risk. We will do this last. |
| **Enterprise private cluster** | This is practical for companies. It uses the same worker protocol. |
| **Pay cloud fuzzing vendors** | This is fine for external use. It does not differentiate the language. |
| **Automatic code fixes from the network** | We reject this without human review. It has a high risk of regressions. |

## 7. Product reality

**PM.md `2.4`: not-started.**

| Part | Reality |
|-------|---------|
| P2P daemon and global network | **Not-started** |
| AI semantic mutation network | **Not-started** |
| Overnight collaborative proving | **Not-started** |
| Local contract fuzzing | **Partial** on RP-3.6. |
| Compiler background daemon | This relates to LSP goals (RP-5.7). |

**Summary:** Network fuzzing is a **vision**. Initial work must focus on **local fuzzing quality** and sandbox limits. Network features are premature until capability limits and quotas can isolate workers safely.

## 8. Open research questions

1. **Trust model:** Should we use open P2P, federated managers, or a central hub?
2. **Job packaging:** What is the minimum source code a worker needs to fuzz contracts?
3. **Incentives:** How do we design incentives without bad token economics?
4. **Effectiveness:** Are semantic mutators better than coverage-guided fuzzing on openOODA code?
5. **Legal rules:** What happens if we accidentally distribute inputs that contain personal data?
6. **Licenses:** What is the license for shared bug reports?
7. **Integration:** How do we integrate this with a verifiable web of code (RP-5.2) to publish "fuzz badges"?

## 9. Acceptance criteria

### Not-started to smoke

- [ ] Local fuzzing (RP-3.6) can find multiple types of errors.
- [ ] A **single-machine** daemon runs long fuzzing jobs and saves the data (no network).
- [ ] We have a draft for the job format and the worker capability limits.

### Smoke to partial

- [ ] A self-hosted manager runs with multiple workers on a trusted local network.
- [ ] The local computer verifies all remote bug reports.
- [ ] Privacy mode operates correctly: no source code leaves the developer computer, **or** the code uses documented encryption.

### Partial to done (global)

- [ ] A public network operates with defenses against bad peers.
- [ ] We complete a security audit of the worker sandbox.
- [ ] The user interface is clear. The system uses human review. The system does **not** change production code silently.

## 10. References

1. DESIGN.md Section 2 — Global Hive-Mind Fuzzing; Section 3 Automated Contract Fuzzer.
2. openOODA `PM.md` 2.4, 3.6; `bootstrap/FUZZ_DEFER.md`.
3. Google — OSS-Fuzz documentation; OSS-Fuzz GitHub; bug volume reports.
4. Google — ClusterFuzz and ClusterFuzzLite.
5. LLVM libFuzzer; AFL++; Honggfuzz; Centipede.
6. Jang, D. et al. — *Fuzzing@Home: Distributed Fuzzing on Untrusted Heterogeneous Clients* (RAID 2022).
7. Serebryany et al. — Sanitizers and large-scale fuzzing practice at Google.
8. Claessen and Hughes — QuickCheck.
9. Research on ML and AI-guided fuzzing mutators.
10. BOINC and volunteer computing.
11. Related papers: RP-3.1 (capabilities), RP-3.3 and 3.4 (quotas), RP-3.6 (local fuzzing), RP-5.6 (human-in-the-loop), RP-5.2 (web of code).

---

## Conflicts with other DESIGN items

| Tension | Conflict | Resolution rule |
|---------|----------|----------------------|
| **Network fuzzing against capability isolation (Section 3.1)** | Network workers must run untrusted jobs. Capability limits must deny file system and network access by default. | Network workers run with **minimum capabilities**. The job profile must not use `UnsafeFFICap` or the ambient OS. |
| **Network fuzzing against time and entropy limits (Section 3.2)** | Fuzzing needs a random number generator. "Overnight" operation uses wall-clock time. | Mutators use `RandCap` injected by the test code. This keeps the production code pure. |
| **Network fuzzing against deterministic builds (Section 4.3.2)** | Distributed AI mutations are not deterministic. | Fuzzing is **not** part of the compile process. Only verified error reports enter version control after review. |
| **Network fuzzing against metamorphic binaries (Section 3.11)** | Changing binaries breaks code coverage tools. | The fuzzing build profile disables metamorphism. |
| **Network fuzzing against secret taint (Section 3.5)** | Inputs and outputs can leak secrets over the network. | The system must remove `#[Secret]` modules from remote jobs. Use local-only fuzzing for secret code. |
| **Network fuzzing against self-hosting rules (Section 5.1)** | The network needs networking stacks and AI model software. | The network is an optional component. It is not required for the bootstrap compiler. |
| **Network automatic fixes against human review (Section 5.6)** | The design says mutations happen overnight. This is dangerous if applied directly to the source code. | The system must **mutate inputs and test data**, not the production code, without human approval. |
| **Network fuzzing against telepathic AST (Section 2.3)** | Both systems want overnight AI code changes. | Unify these under a "proposals queue". Do not compile unreviewed code changes. |
| **Global network against enterprise privacy** | The "global" design conflicts with private code. | Use profiles: `local`, `organization`, and `public-oss`. |

---

*Series: [Research papers index](./README.md). Template: [TEMPLATE.md](./TEMPLATE.md). Related: [RP-3.6](./RP-3-6-automated-contract-fuzzer.md).*
