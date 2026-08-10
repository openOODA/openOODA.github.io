# RP-5.6: Human-in-the-loop (`hitl`) testing

| Field | Value |
|-------|--------|
| **Paper ID** | `RP-5.6` |
| **DESIGN.md** | §5 Ecosystem |
| **Status** | `draft` |
| **PM.md row** | `5.6` |
| **Product mapping** | **not-started** |

## 1. Why this is in DESIGN.md

DESIGN.md §5:

> openOODA natively supports subjective human feedback in its testing pipeline. Functions like `verify_human("Review this output")` let autonomous AI fuzzer loops pause. The loops ask for your approval through the CLI before they mark a build as a pass.

Automated tests and pure-domain fuzz tests (RP-3.6) find objective conditions well. They do not find subjective quality well. Examples of subjective quality include UX text, layout judgment, ethical rules, AI response feeling, security design, and other decisions that do not have a cheap test oracle.

The AI-native loop of openOODA writes code and changes faster than a human can write contracts. Human-in-the-loop (HITL) testing is a pause point at the language level. This pause point gives authority to humans and keeps automation active.

## 2. Problem statement

### 2.1 Oracle gap

| Property | Can automate? | Mechanism |
|----------|--------------|-----------|
| Types / caps | Yes | Compiler |
| `requires` Int domains | Partial | verify / fuzz |
| Full functional correctness | Expensive | Proofs / large tests |
| Subjective quality | **No** (usually) | Human judgment |
| Policy / ethics edge cases | Weakly | Human or external policy model |

### 2.2 Without HITL functions

Teams make ad-hoc tools: `input("ok?")` in scripts, manual QA checklists, and Slack approvals. These tools:

- Do not record as part of the test graph.
- Do not fail closed in Continuous Integration (CI). They can block CI forever.
- Do not show in package attestation (RP-5.2).
- Tell agents to skip human checks.

### 2.3 Users

- **Human reviewer** at the CLI or future UI.
- **AI fuzzer or agent** that must not approve its own work.
- **CI system** that needs stable modes (`HITL=deny|skip|record`).
- **Adversary agent** that tries to fake an approval.

## 3. Related work

### 3.1 University and Software Engineering research

- **Human-in-the-loop software engineering** and interactive test tools.
- **Metamorphic testing** and partial oracles when full oracles are not available.
- **Crowdsourced testing** and oracle problem documents in software testing research.
- **HITL for LLM-integrated software** (new 2024–2025 quality-engineering systems). These systems mix automated tests with human checks for trust and safety.

### 3.2 Industry: RLHF and evaluation

**Reinforcement Learning from Human Feedback (RLHF)** trains models from human preference data. Here are related analogies to openOODA HITL testing:

| RLHF idea | Relation to openOODA testing | **No relation** (do not claim) |
|-----------|--------------------------------------|--------------------------------|
| Human preference labels | `verify_human` pass/fail/rank | Training a reward model inside the compiler |
| Comparison data | Optional “A vs B output” review | Online RL in production files |
| Expensive human block | CI modes must batch or limit HITL | Humans label every unit test |
| Subjective opinion | Record reviewer ID and reason | Single correct truth always exists |
| Bad feedback | Authentication on approvals. Dual control for release. | HITL is magic and cannot be faked |
| RLAIF (AI feedback) | Optional second reviewer | Not a replacement for security checks |

**Important:** openOODA HITL is a **test oracle function**. It is not an RL training loop. Analogies help product design (pause, preference, audit trail). They do **not** mean that the language uses RLHF.

### 3.3 Related product patterns

- Interactive `pytest` or snapshot review (like `cargo insta` review).
- Mobile **beta review** gates.
- Code review checks (GitHub CODEOWNERS) as a process-level HITL.
- Content moderation queues as delayed human oracles.

## 4. Design rules for openOODA

### 4.1 Language function

```text
verify_human(prompt: String) -> Bool
// or more complex:
verify_human(prompt, artifact: Bytes | Path, options) -> HumanVerdict
```

Semantics:

1. Show the `prompt` and the artifact digest to a **human channel**. This channel can be CLI stdin, desktop UI, or a remote review API.
2. Stop the test task until a human gives a decision or a timeout occurs.
3. Record the decision in a test trace during packaging. The trace must be signed or append-only.
4. Agents must not call a hidden `verify_human_auto_approve` function.

### 4.2 Capability and security

| Concern | Rule |
|---------|------|
| Who can approve | `&HumanAttestationCap` or a process-tied UI cap. |
| Fake approval | CI without a terminal must fail or skip by default. No silent pass is allowed. |
| Secrets | Do not show secret artifacts. Show hidden hashes (RP-3.5). |
| Non-determinism | Mark HITL tests with `#[hitl]`. Keep them out of pure test suites unless you use a recorded replay. |

### 4.3 Modes

| Mode | Behavior |
|------|----------|
| `interactive` | Show prompt on the terminal. |
| `record` | Save human decisions to a file. |
| `replay` | Use saved decisions in CI. |
| `deny` | Fail closed if the system finds a HITL function. |
| `skip` | Explicitly skip the HITL function. The system marks the build as degraded. |

Replay does **not** mean “AI approved”. It means “human approved at commit C.”

### 4.4 Use with fuzz and hive

Autonomous fuzz loops (RP-3.6, RP-2.4) can hit subjective tests:

1. The fuzz loop runs until it needs `verify_human`.
2. The system quarantines the artifact.
3. A human session batches multiple prompts.
4. The system marks corpus promotion only after human approval.

Do not automatically make packages from HITL-pending states.

### 4.5 Agent UX

CLI JSON event:

```json
{"type":"hitl_request","id":"…","prompt":"…","artifact_sha256":"…"}
```

Agent systems show the UI. The response is:

```json
{"type":"hitl_response","id":"…","verdict":"pass","note":"…"}
```

## 5. Threat and failure model

### Prevents

- Agents that mark subjective tests as a pass without a human channel.
- A silent CI pass on HITL tests when you do not set a policy (if the default is deny).
- Loss of the audit trail for release-critical subjective tests.

### Does not prevent

- Careless humans who approve without reading.
- Reviewers who work together maliciously.
- Social engineering of reviewers with false prompts.
- The use of HITL to replace missing contracts on objective conditions.

### Failure modes

| Mode | Solution |
|------|------------|
| CI hangs forever | Use timeouts and deny mode. |
| Saved results are old | Remove results when the artifact hash changes. |
| Prompt injection through artifact | Show safe metadata. Open the raw artifact only when requested. |
| Overuse of HITL | Use a lint tool to limit the HITL count per suite. |

## 6. Alternatives considered

| Alternative | Decision |
|-------------|---------|
| **Process-only code review** | Necessary but not in-test. It misses the review of generated artifacts. |
| **Always use LLM-as-judge** | This is a useful aid, but it is not a human function. It has gaming risks. |
| **No subjective tests in the language** | This forces ad-hoc tools. Agents will skip them. |
| **Full RLHF stack in the compiler** | This is out of scope. It is at the wrong layer. |
| **Manual QA only** | This is too slow for AI-native loops. |

## 7. Product reality

From the monorepo **PM.md** row `5.6`: **not-started**.

| Part | Status |
|-------|-------|
| `verify_human` function | Not in the language surface. |
| HITL CLI protocol | Not started. |
| Record and replay | Not started. |
| Integration with `ooda test` | Residual. |
| Related existing parts | `verify` / pure Int fuzz (objective only). |

## 8. Open research questions

1. What is the smallest **attestation** format to show users which human checks ran?
2. How do we do multi-reviewer agreement (2-of-N) for high-risk publishes?
3. How do we keep HITL **accessible** (a11y) and support non-English prompts?
4. Can preference ranking (A/B) improve agent repair without causing RLHF scope creep?
5. Legal and privacy concerns: Can we store human notes next to artifacts?
6. How do we schedule fairly when many agent workers wait for one human?

## 9. Acceptance criteria

### not-started → smoke

- [ ] `verify_human` (or std test helper) stops on the terminal and accepts y/n.
- [ ] Non-terminal default must fail-closed.
- [ ] A fixture suite shows the pass and fail paths.

### smoke → partial

- [ ] Record and replay by the artifact hash.
- [ ] JSON HITL events for agents.
- [ ] `#[hitl]` (or equivalent) tag in the test runner.

### partial → done

- [ ] Capability and attestation rule for who can approve.
- [ ] Documented CI policy matrix.
- [ ] No way for an agent to self-approve in the product.
- [ ] Optional package attestation field for HITL traces.
- [ ] Written boundary doc: HITL testing is not RLHF training.

## 10. References

1. P. Christiano et al., “Deep Reinforcement Learning from Human Preferences,” 2017 (RLHF lineage—analogy only).
2. Industry explainers: AWS “What is RLHF?”; IBM Think RLHF (limitations: cost, subjectivity, adversarial humans).
3. New HITL testing systems for LLM-integrated software (quality engineering literature, 2025).
4. Snapshot review tools (e.g., insta) for human acceptance UX.
5. Software testing “oracle problem” surveys.
6. openOODA DESIGN §5 HITL; RP-2.4, RP-3.6, RP-5.2; product `verify` and fuzz rails.

---

*Series: [Research papers index](./README.md). Template: [TEMPLATE.md](./TEMPLATE.md).*
