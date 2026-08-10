# RP-ES.1: AI-native systems language

| Field | Value |
|-------|--------|
| **Paper ID** | `RP-ES.1` |
| **DESIGN.md** | Executive Summary |
| **Status** | `draft` |
| **PM.md row** | `ES.1` |
| **Product mapping** | **partial** — direction + agent tools; full AI stack residual |

## 1. Purpose in DESIGN.md

The DESIGN Executive Summary states:

> **OODA** (*Observe, Orient, Decide, Act*) is an **AI-native**, capability-secure, self-testing systems programming language…

"AI-native" is a primary design rule. Humans and AI agents must write code together easily. They must write systems code for cache limits, security rules, and direct hardware access. DESIGN Section 2 (AI-Native Tooling) explains this. It includes precise code changes, small data summaries, goal-based compiling, and joint software testing.

This document explains why we include **AI-native systems language** in the Executive Summary. If we remove it, openOODA becomes just another memory-safe language. It loses the OODA-loop workflow (Observe, Orient, Decide, Act) that connects human goals, AI code generation, and compiler checks.

## 2. Problem statement

### 2.1 Problems without AI-native design

Current software development uses humans and AI. Humans write goals and check code. AI models write code, change code, and complete standard code. Studies show that AI tools make work much faster. But code quality and human learning stay inconsistent. This causes four problems for systems languages:

1. **Incorrect tools.** C, C++, and Rust tools are for humans. AI agents need stable machine data, small project summaries, and precise code change tools. They cannot use large log files or full-file replacements.
2. **Incorrect authority.** You cannot trust AI-generated code. The language must stop all input and output (I/O) by default. The language must need explicit permissions (ES.2). If not, AI errors cause system failures at runtime instead of compiler errors.
3. **Incorrect tests.** AI agents guess code. You must put rules and tests in the code (ES.3). Without rules, the "Orient" phase of the OODA loop has no standard to check the code.
4. **Incorrect speed.** AI agents make slow compilers worse. Feedback in less than one second (ES.4) is necessary. Fast feedback controls the cycle between humans and AI agents.

### 2.2 Users

| Actor | Need |
|-------|------|
| **Human developer** | Safe and fast code with AI help that works with the language. |
| **AI agent** | Standard errors, small code summaries, precise change tools, and stable commands. |
| **Attacker or bad AI** | Must not get file, network, or command access from bad code. |
| **Language creator** | Clear basic product (a pure `.oo` compiler) and clear future goals. |

### 2.3 Results if omitted

If openOODA adds AI tools later, the AI tools become optional plugins. The security permissions become optional. The Executive Summary statement becomes false. The project (a pure `.oo` compiler and AI tools) will fail to meet the DESIGN goals.

## 3. Related work

### 3.1 Human and AI programming research

- **Peng et al. (2023):** *The Impact of AI on Developer Productivity*. A controlled test. The test group finished a task 55.8% faster with Copilot.
- **Imai (2022):** *Is GitHub Copilot a Substitute for Human Pair-programming?* A real-world test of Copilot against humans. Shows faster work but varying code quality.
- **Ma, Wang, et al. (2023):** *Is AI the better programming partner?* A CMU study. Shows mixed results for quality, speed, and user happiness.
- **Bird et al.:** *Taking Flight with Copilot*. Shows AI as a programming partner in industry.
- **Zhou et al. (2025):** Documents real errors from Copilot users. Shows errors like bad APIs and bad security. Shows why languages need security and machine data.

### 3.2 Editor tools for agents

- **LSP and DAP systems:** Standard editor tools that do not lock users to one editor (DESIGN Section 5.7).
- **Rust, Go, and Swift code outlines:** These make code data smaller. But they are not made for AI agents.
- **Code creation research:** Creates code from rules. This relates to the DESIGN goal to create code from rules. This is still experimental for systems code.

### 3.3 Similar systems languages

Rust, Zig, and Carbon are for human programmers. They focus on compiler safety. They do not focus on AI agent workflows. openOODA is different because it needs two things: systems speed and AI programming with strict security.

## 4. Design rationale for openOODA

In openOODA, AI-native means a complete system, not a chatbot:

| Layer | DESIGN feature | Function in AI-native system |
|-------|----------------|------------------------------|
| Diagnose | JSON errors and precise code change suggestions (Section 2.1) | The agent fixes code without reading the full file. |
| Compress | Data summaries (`ooda outline` / `ooda reflect`) (Section 2.2) | Decreases code data by 85 to 90 percent. |
| Edit | Precise code changes (`patch replace_fn`) (Section 2.2b) | Gives agents a small area to write code. |
| Specify | Code rules (`requires` / `ensures`) (Section 1.2) | Gives goals that humans and agents can check. |
| Synthesize | Goal-based compiling (Section 2.3) | Future goal: write code from rules automatically. |
| Contain | Security sandbox (Section 3.1, ES.2) | Stops bad input and output (I/O) automatically. |
| Verify | Code tests and self-testing (ES.3) | Tests code continuously in the background. |
| Loop | Very fast feedback (ES.4) | Keeps the workflow fast and interactive. |

**Compiler connection:** A pure `.oo` compiler means agents and humans use the same language. The language of the tool is the language of the agent.

**Security connection:** AI tools without security permissions increase risks. ES.1 and ES.2 must work together.

## 5. Threat / failure model

### Stops or decreases

- **Endless agent errors:** Machine data stops agents from guessing.
- **Data limit errors:** Code summaries decrease data size.
- **Bad code access:** The compiler stops unauthorized file or network access.

### Does not stop

- **Bad logic:** The compiler allows bad logic if the types are correct. You must use tests to find bad logic.
- **Human tricks:** A person can make bad choices when they review agent code.
- **Data leaks:** The language cannot control the AI model data.
- **Code creation errors:** The system cannot guarantee that automatic code is correct.

### System failure risks

- We claim the language is AI-native, but we only supply a basic language with an AI manual.
- We make the code easy for agents, but hard for humans to read.
- We release AI code creation without tests. This makes the compiler a random code generator.

## 6. Alternatives considered

| Alternative | Why it fails |
|-------------|--------------|
| **Add Copilot to C or Rust** | No language security permissions. The agent struggles with complex code rules. |
| **Agent-only language** | Does not meet hardware and speed goals (ES.6). |
| **Math-only formal language** | Too slow for fast workflows. Agents need fast checks, not slow math proofs. |
| **Editor plugin only** | Locks users to one editor. Background agents cannot use it. |
| **Add AI tools later** | The project is already made for agents. Delaying AI tools causes extra work later. |

## 7. Product reality (alpha honesty)

**PM.md Executive Summary — AI-native systems language: `partial`.**

| DESIGN claim | Alpha product status |
|--------------|----------------------|
| AI-native goal | **Yes** — We have product identity, agent tools, and a pure `.oo` compiler. |
| `ooda outline` and `ooda reflect` | **Done** (parse only). |
| Precise `patch replace_fn` | **Done** (line range and node ID). |
| JSON errors and code fix suggestions | **Partial** (JSON errors work; full auto-fix is missing). |
| Goal-based compiling (AI inside) | **Not started**. |
| Global software testing | **Not started**. |
| Pure compiler and command line tool | **Done** (alpha version). We do not use Rust. |
| Release version | `v0.183.0-alpha`. **Beta is not ready** (`ooda/bootstrap/BETA.md`). |

Summary: openOODA is a systems language with real AI agent tools. It is not a complete AI system yet. Do not say that automatic code creation or global testing are finished.

## 8. Open research questions

1. What is the smallest stable data standard (JSON schema) that we can use for the beta release?
2. How do we show security rules to agents so they write correct code on the first attempt?
3. Can small data summaries supply enough information for large code changes?
4. How do we measure the agent success rate in openOODA against other languages?
5. When do we need human tests (DESIGN Section 5.6) instead of fully automatic AI tests?

## 9. Acceptance criteria

### To upgrade to a stronger `partial` status or beta status

- [ ] Document the agent command line tools (outline, reflect, patch, json-errors) with test data.
- [ ] Show security rules and code rules in the agent error data.
- [ ] Do not claim automatic code creation until a test version works.

### To upgrade to `done` status

- [ ] Make precise code fix suggestions that agents can use fully.
- [ ] Complete the automatic code creation with verification, or cancel it with approval.
- [ ] Measure the agent workflow on compiler tasks. Confirm that no security errors occur.

## 10. References

1. openOODA, *DESIGN.md* — Executive Summary; Section 2 AI-Native Tooling. `spec/DESIGN.md`.
2. openOODA, *PM.md* — Executive summary progress rows. Monorepo root.
3. S. Peng et al., "The Impact of AI on Developer Productivity: Evidence from GitHub Copilot," arXiv:2302.06590, 2023. https://arxiv.org/abs/2302.06590
4. S. Imai, "Is GitHub Copilot a Substitute for Human Pair-programming? An Empirical Study," IEEE/ACM ICSE Companion, 2022. https://ieeexplore.ieee.org/document/9793778
5. Q. Ma et al., "Is AI the better programming partner? Human-Human Pair Programming vs. Human-AI Pair Programming," 2023. https://www.cs.cmu.edu/~sherryw/assets/pubs/2023-pair.pdf
6. C. Bird et al., "Taking Flight with Copilot," *Communications of the ACM*. https://cacm.acm.org/practice/taking-flight-with-copilot/
7. X. Zhou et al., "Exploring the problems, their causes and solutions of AI pair programming," *Journal of Systems and Software* / ScienceDirect, 2025.
8. Microsoft Research and GitHub Copilot documents.
9. openOODA RFC 0001, Capability-Based Security Model. `spec/rfcs/0001-capability-security.md`.
10. Related papers: RP-2.1, RP-2.2, RP-2.2b, RP-2.3, RP-2.4; RP-ES.2 through ES.4.

---

## Conflicts with other DESIGN items

- **Section 2.3 vs Section 3 / ES.2:** AI-generated code must not get automatic security permissions. The compiler must check AI code and human code with the same rules.
- **Section 2.3 vs Section 4.3.2:** AI compiling and testing stop identical builds. You must put AI generation and testing outside the production build path.
- **Section 5.1 vs an AI inside the compiler:** An AI inside the compiler stops offline builds. The AI must be an optional service. It must not be part of the basic product.

---

*Series: [Research papers index](./README.md). Template: [TEMPLATE.md](./TEMPLATE.md).*
