# RP-1.1: Philosophy of speed (OODA loop)

| Field | Value |
|-------|--------|
| **Paper ID** | `RP-1.1` |
| **DESIGN.md** | §1 Language |
| **Status** | `draft` |
| **PM.md row** | `1.1` |
| **Product mapping** | **partial** — product + agent feedback loops exist; DESIGN “sub-millisecond compile” and full loop tightness are not claimed as shipped |

## 1. Why this is in DESIGN.md

DESIGN.md §1 opens with:

> **The Philosophy of Speed (The OODA Loop):** The language is fundamentally engineered around the *Observe, Orient, Decide, Act* cycle. By combining sub-millisecond compile times with rich JSON metadata, the language guarantees the tightest possible feedback loop between human intent, AI generation, and compiler validation.

This is not a marketing slogan. openOODA uses **loop tempo** as a primary design rule. Every feature must keep the OODA loop fast. If a feature slows the loop, we must evaluate it carefully. We measure features like JSON diagnostics and contracts as **loop enablers** or **loop taxes**. We do not look at them only as isolated features.

This document explains why we use the OODA loop for an AI-native language. It defines the word "speed" for this product. It also shows how military command, developer feedback loops, and compiler design support this claim.

## 2. Problem statement

### 2.1 What breaks if we omit the philosophy

Without a speed philosophy:

1. **Feature creep without a time limit.** Features like contracts and macros increase compile times. Without a speed goal, the language adds too many checks. The edit-compile-test loop becomes slow. It cannot compete with fast dynamic languages.
2. **Human and agent speeds separate.** Humans can wait seconds for large programs to compile. AI agents fail if they must wait tens of seconds. The AI tools in DESIGN §2 only work if the OODA loop stays very fast.
3. **False speed claims.** The word "fast" has no meaning without a clear definition. openOODA must state its speed rules clearly. This lets PM.md score features as **partial** (real loops) or **done** (sub-millisecond claims).

### 2.2 Users

| Actor | Failure mode if loop is slow |
|-------|------------------------------|
| Human developer | Context switch cost; fewer experiments; less contract/fuzz use |
| AI agent | Token waste, timeout cascades, patch thrashing |
| Security/QA | Long cycles discourage fuzz and verify runs |
| Adversary | Slow defender loops (patch + revalidate) increase exploit window—metaphorically and practically |

### 2.3 What “OODA” means here (not pure military doctrine)

Boyd designed the OODA loop as a **decision cycle under uncertainty**. It is not a strict sequence. Orientation is continuous. Speed alone does not win. You must act faster than your opponent. In openOODA:

| Phase | openOODA mapping |
|-------|------------------|
| **Observe** | Source, outline/reflect metadata, JSON diagnostics, runtime/verify output |
| **Orient** | Human understanding or agent context window; type/cap/contract model of the program |
| **Decide** | Patch plan, contract/body choice, backend/target selection |
| **Act** | Compile/run/test/fuzz; apply surgical AST patch |

DESIGN combines **fast compilers** with **metadata for machines**. This means the AI does not need to read the whole program again.

## 3. Related work

### 3.1 Boyd and military literature

- **John R. Boyd** (USAF): The OODA loop comes from his energy-maneuverability theory. The core idea is simple. The side that cycles faster and understands better will win.
- **Destruction and Creation** (Boyd, 1976): This work tells us to destroy and rebuild mental models. This helps AI agents understand errors after a build fails.
- Military doctrines use OODA for command and control. Books show that **orientation quality** is more important than pure speed.

Primary sources: Boyd's briefings and other military journals.

### 3.2 Software engineering: feedback loops

- **Agile / XP / DevOps**: Short feedback cycles improve quality and help teams learn. These are industry versions of the OODA loop.
- **Live programming** (Smalltalk, Lisp, Jupyter): These tools decrease the time from observation to action. Users orient themselves with live data.
- **Fast systems languages**: Go makes builds fast. Zig has fast compilers and incremental work. Rust balances safety checks with compile times. The game industry prioritizes fast iterations.

### 3.3 AI-assisted development

- AI agents edit code and read errors. They need **structured errors** and **small project views**. Slow loops cause the AI to waste tokens and fail.
- Sub-second local builds are the limit for fast AI loops. Slow, optimized builds belong in a separate production loop.

### 3.4 Compile times

Many systems measure compile times carefully. They use incremental compilers and fast language servers. openOODA goes further. It names the **whole product loop** after OODA, not just the compiler.

## 4. Design rationale for openOODA

### 4.1 Dual loop: development vs production

openOODA intentionally splits targets (DESIGN §4):

| Loop | Goal | Typical path |
|------|------|----------------|
| **Tactical / development** | Sub-second (DESIGN: sub-ms aspirational) validate | Backend-C native product floor today; bytecode VM / hot reload in DESIGN |
| **Strategic / production** | Peak performance, multi-target | LLVM, WASM, GPU/NPU, embedded |

Our speed rules put the **tactical** loop first. We do not let slow production features block fast edits. Features that need a long link time must not delay the tactical loop.

### 4.2 Metadata for orientation

The language uses JSON diagnostics, outlines, and reflection data. This makes orientation **incremental and structured**. A fast compiler with only text errors forces AI agents to read everything again. This wastes time and tokens.

### 4.3 Interaction with other DESIGN items

| Item | Interaction with 1.1 |
|------|----------------------|
| §2 AI tooling | Direct implementers of Observe/Act for agents |
| §1.2 Contracts | Specs that make Decide/Act checkable; must not destroy compile tempo |
| §3 Caps / security | Static checks add orient cost; must be incremental |
| §4 Multi-backend | Product floor (C emit) vs aspirational LLVM/WASM speed profiles |
| §5 LSP / narrative diags | Continuous orientation without full rebuild |

### 4.4 Honest meaning of "sub-millisecond"

The term "sub-millisecond compile times" is a goal for very small programs. It is not a guarantee for large programs today. We must state: **we have fast feedback loops, but we do not guarantee sub-millisecond speeds yet**.

## 5. Threat / failure model

### 5.1 What this philosophy prevents

- Creating a language that is too slow for AI agents to use.
- Adding new features that silently make the default compiler slow.
- Mixing slow production speeds with fast development speeds.

### 5.2 What it does not prevent

- **Wrong orientation:** The AI can still give fast, incorrect answers.
- **Security bugs:** Speed does not give memory safety or security.
- **Slow production builds:** Optimized production builds can still be slow.
- **Human limits:** Fast compilers do not help humans understand complex code.

### 5.3 Problems with too much speed

- We might skip static checks that find security errors.
- We might build fast, incomplete backends that act differently than production.
- We might measure only empty programs, while real programs take much longer.

## 6. Alternatives considered

| Alternative | Why insufficient alone |
|-------------|------------------------|
| **“Correctness first, speed later”** | Correctness features that destroy agent loops never get used; contracts and fuzz become dead surface. |
| **Dynamic language for AI, systems language separate** | Loses single surface for caps/contracts/native; dual-language OODA is worse for agents. |
| **Only LSP feedback, ignore full compile** | Agents and CI still need executable truth; LSP alone can drift from product backend. |
| **Only production LLVM performance** | Confuses run-time speed with **developer decision** speed. |
| **Military OODA as literal product process** | Overfit metaphor; software needs measurable edit→diag→retest SLOs, not doctrine cosplay. |

**Our choice:** We use Boyd's ideas (speed and orientation quality) as our **product philosophy**. We set strict time limits for the OODA loop. We provide metadata for agents. We report our status honestly in PM.md.

## 7. Product reality (alpha honesty)

**PM.md `1.1` status: `partial`.**

What is real in product (alpha, e.g. v0.183.0-alpha range):

| Claim | Reality |
|-------|---------|
| Named OODA / speed philosophy | Present in DESIGN and product narrative |
| Human edit → compile → run loop | **Real** via product `oodac` / Backend-C native path |
| Agent loop (outline, reflect, patch, JSON diags) | **Partial–done** components: outline/reflect and `patch replace_fn` are strong; full AST auto-fix residual (see §2 papers) |
| Sub-millisecond compile | **Not claimed.** Sub-second product loops in favorable cases may hold; DESIGN wording is aspirational |
| Sub-millisecond JIT VM as default `ooda run` | **Not** the production floor; DESIGN VM vs product native Backend-C (see RP-4.x / RP-4.1.1) |
| Global hive-mind / telepathic AST as part of “tight loop” | **not-started** (do not fold into 1.1 “done”) |

Honesty rule for this paper: **partial** means that fast loops exist and guide our work. It does **not** mean that we achieve the full speed goals in DESIGN.md.

Cross-links: monorepo `PM.md` row `1.1`; `SPRINT.md` for tip SHA; residual notes in `ooda/bootstrap/BUILD_OUT.md`, `OUTLINE_REFLECT.md`, `BETA.md`.

## 8. Open research questions

1. What is a good time limit (SLO) for openOODA's tactical loop?
2. How does incremental compilation work with security contracts without removing safety?
3. Can we measure **orientation quality** (diagnostic quality, token count, agent success rate) just like we measure compile time?
4. Where is the line between **fast incomplete** backends and **slow complete** backends? We must not let their behaviors diverge.
5. Does Boyd's idea of disrupting the opponent apply to our security models? Or should we track security loops in a separate document?

## 9. Acceptance criteria (for PM status promotion)

### partial → stronger partial / near-done (still not full DESIGN speed)

- [ ] Documented, measured tactical-loop benchmarks checked into product or QA (not anecdote).
- [ ] Agent turn success metrics: outline/reflect/patch/recompile path documented with rails.
- [ ] Explicit public wording: DESIGN sub-ms is goal; product claims match measurements.
- [ ] No regression policy: new language features that add >X ms to default `hello` path require design note.

### done (full DESIGN intent)

- [ ] Development path meets stated numerical compile/feedback targets on agreed hardware/corpus.
- [ ] JSON metadata + diagnostics sufficient for multi-turn agent repair without full-file re-ingest as default.
- [ ] Development and production backends semantic-compatible under a written conformance suite.
- [ ] ES.4 (sub-second feedback) and 1.1 consistent in PM.md.

Until those hold, status remains **partial**.

## 10. References

1. Boyd, J. R. *Patterns of Conflict* (briefing slides, multiple revisions). Secondary discussion: USMCU / Marine Corps University analyses of Boyd’s disruption and C2 concepts. https://www.usmcu.edu/Outreach/Marine-Corps-University-Press/MCU-Journal/JAMS-vol-14-no-1/Colonel-John-Boyds-Thoughts-on-Disruption/
2. Boyd, J. R. *Destruction and Creation* (1976). https://www.goalsys.com/books/documents/DESTRUCTION_AND_CREATION.pdf
3. Boyd, J. R. *The Essence of Winning and Losing* (1995 briefing; OODA diagram). Discussed in secondary guides, e.g. https://strategyu.co/ooda-loop/
4. Wikipedia overview (entry point, not primary): https://en.wikipedia.org/wiki/OODA_loop
5. Osinga, F. P. B. *Science, Strategy and War: The Strategic Theory of John Boyd*. Routledge, 2007. (Standard academic treatment of Boyd’s corpus.)
6. Marine Corps Gazette / MCA discussions evolving OODA for modern C2, e.g. https://www.mca-marines.org/gazette/ooda-loop-for-strategy/
7. Zig incremental compilation and feedback-loop goals (industrial systems-language parallel): e.g. https://mlugg.co.uk/posts/incremental-compilation-internals/ ; discussion of sub-second aims: https://www.scattered-thoughts.net/writing/assorted-thoughts-on-zig-and-rust/
8. openOODA `spec/DESIGN.md` §1, §2, §4; monorepo `PM.md` row `1.1`.
9. Product agent surfaces: `ooda/bootstrap/OUTLINE_REFLECT.md`, `BUILD_OUT.md`.

## Conflicts with other DESIGN items

| Conflict | Description | Resolution direction |
|----------|-------------|----------------------|
| **1.1 vs 1.2 / 3.6 / 2.3** | Deep contracts, fuzz, and LLM synthesis can dominate compile/test time | Keep **simple requires** on fast path; heavy proof/fuzz out-of-band or opt-in (`ooda test --fuzz`, overnight hive DESIGN) |
| **1.1 vs 3.1–3.5 static analyses** | Caps, taint, MaxCycles raise typecheck cost | Incremental/query-based analysis; fail-closed but cacheable; don’t re-analyze whole program per keystroke if avoidable |
| **1.1 vs 4.1.2 LLVM / 4.3.1 LTO** | Production optimization loops are slow | Dual-target architecture: Backend-C (or VM) for tactical OODA; LLVM for release |
| **1.1 vs 3.11 metamorphic / 3.9 call-graph crypto** | Runtime mutation and integrity checks tax act phase | Isolate to hardened builds; never gate default dev loop |
| **1.1 vs 1.4 AST macros** | Unbounded compile-time execution destroys tempo | Macro budget, phase separation, deterministic caps on comptime (see RP-1.4) |
| **1.1 vs 5.1 full self-host purity** | Pure rebuild of compiler may be long | Seed + incremental pure build; don’t require full self-host for every agent patch |
| **Metaphor risk** | Over-literal military OODA confuses contributors | Treat as **tempo + orientation** product doctrine; measure engineering SLOs |

---

*Series: [Research papers index](./README.md). Template: [TEMPLATE.md](./TEMPLATE.md).*
