# RP-ES.3: Self-testing language surface

| Field | Value |
|-------|--------|
| **Paper ID** | `RP-ES.3` |
| **DESIGN.md** | Executive Summary |
| **Status** | `draft` |
| **PM.md row** | `ES.3` |
| **Product mapping** | **Partial** — Verifies integer domain fuzzing. This does not tell the full contract proof story. |

## 1. Why this is in DESIGN.md

The Executive Summary specifies that OODA is **self-testing**. This claim connects to DESIGN §1 and §3:

- **Mathematical contracts** — The keywords `requires` and `ensures` set the boundaries for behavior.
- **Automated contract fuzzer** — The command `ooda test --fuzz` makes edge cases to break contracts.
- **Global hive-mind fuzzing** (§2.4) — The system changes contracts collaboratively overnight.
- **Human-in-the-loop testing** (§5.6) — Humans verify the actions of agents.

“Self-testing” means that verification is a language feature, not only an external test. Contracts put specifications next to the code. The tools must test these specifications. This is necessary for AI programming (ES.1). Agents write code faster than humans can write tests. Thus, the language must provide checkable rules.

## 2. Problem statement

### 2.1 The specification gap

Traditional systems development separates three items:

1. Code (C/Rust).
2. Tests (these are optional and often incomplete).
3. Specifications (documents, tickets, or nothing).

AI pair programming makes this gap larger. Agents write more code but use fewer examples. Unit tests that use only a few values do not test agent code well.

### 2.2 What self-testing must provide

| Property | Why |
|----------|-----|
| **Colocated specifications** | `requires` and `ensures` stay with the functions that agents change. |
| **Executable checks** | Debug builds use contracts as assertions. |
| **Generative tests** | Fuzz testing finds errors that humans do not write. |
| **Fail-closed domains** | The system gives an error for unsupported contract types. It does not show a false pass. |
| **Deterministic caps** | Without `&TimeCap` or `&RandCap`, the logic is reproducible (DESIGN §3.2). |

### 2.3 Users

| Actor | Need |
|-------|------|
| Human author | Write the rules once. Find errors continuously. |
| AI agent | Get contract failures immediately in the OODA loop. |
| CI / hive fuzz | Search for errors overnight. |
| Adversary | Cannot easily find untested edge cases. |

## 3. Related work

### 3.1 Design by Contract

- **Bertrand Meyer** started **Design by Contract (DbC)** with the Eiffel language. He used preconditions, postconditions, and class invariants as executable rules. See *Object-Oriented Software Construction*; IEEE Computer “Applying ‘Design by Contract’” (1992). https://www.eiffel.com/values/design-by-contract/
- This concept connects to **Hoare logic**.
- This concept influences JML (Java), Spec#, ACSL (C), Ada, and Clojure.

### 3.2 Property-based testing and fuzzing

- **Claessen and Hughes (2000),** *QuickCheck: a lightweight tool for random testing of Haskell programs* (ICFP). They used properties as executable functions over random inputs. https://dl.acm.org/doi/10.1145/351240.351266
- **Nelhage,** “Property-Based Testing Is Fuzzing”. This paper connects property-based testing and fuzzing. https://blog.nelhage.com/post/property-testing-is-fuzzing/
- Industrial fuzzing (AFL, libFuzzer, Honggfuzz) finds crashes. Contracts add semantic checks to find incorrect logic.
- **QuickChick and proof assistants** use tests to help formal proofs.

### 3.3 Formal verification adjacent

- Dafny, F*, Liquid Haskell, and Rust HABIT use contracts to make proofs.
- The design of openOODA is practical. It uses contracts and fuzzing first. Full proofs will come later (Verifiable Web of Code §5.2).

## 4. Design rationale for openOODA

Self-testing is the **Orient and Decide** step of the OODA loop:

```
Observe (edit code) → Orient (check types, caps, and contracts) → Decide (accept or fix) → Act (apply patch or run)
```

### 4.1 Layered story

| Layer | Mechanism | Status intent |
|-------|-----------|---------------|
| Syntax | `requires` / `ensures` keywords | Partial product |
| Runtime assertion | The system runs contracts in debug mode. It removes them for performance (SPEC). | Design goal |
| Local fuzz | `ooda test --fuzz` | Partial (Int domain) |
| Global fuzz | Hive-mind P2P (§2.4) | Not started |
| Human oracle | `hitl` / `verify_human` (§5.6) | Not started |
| Proof | Formal solver on packages (§5.2) | Not started |

### 4.2 Why integrated testing is better than external testing

- Agents see contracts in the same file that they patch (`replace_fn`).
- Caps let the system fuzz pure functions without file systems or networks.
- JSON error messages show which contract failed.

### 4.3 Interaction with ES.1 / ES.2

- AI agents write a large quantity of code but do not focus on correctness.
- Pure functions are good for fuzzing. They do not have unpredictable inputs (after Time and Rand caps exist).

## 5. Threat and failure model

### Prevents and mitigates

- Errors when agents change pure logic.
- Poor test coverage when you use real fuzz domains instead of simple examples.
- False confidence from passed tests when contracts are empty.

### Does not prevent

- **Incorrect contracts** (specification errors). The fuzzer checks the code against a bad rule.
- **Full functional correctness** without mathematical proofs.
- **Resource exhaustion** from continuous fuzzing. This needs limits on time and cycles (DESIGN §3.4).
- **Side effects** with wide caps. Fuzzing can cause damage if you do not use sandboxes.

### Failure modes

- The system claims to be self-testing when it only has basic tests.
- The fuzzer reports a pass on unsupported domains. The product policy must fail-closed.

## 6. Alternatives considered

| Alternative | Why insufficient |
|-------------|------------------|
| **External test frameworks only** | Agents do not easily edit specifications with the code. |
| **Types alone** | Types cannot check complex logic like `sorted(result)`. |
| **Full formal verification** | This is too slow for AI loops and requires expert knowledge. |
| **Crash-only fuzzing** | This does not find incorrect logic. |
| **Runtime contracts only** | This does not generate enough test inputs. |

## 7. Product reality (alpha honesty)

**PM.md — Self-testing: `partial`.**  
**1.2 Mathematical contracts: `partial`.** The system uses simple `requires` on native code. It uses `ensures` on native code.  
**3.6 Automated contract fuzzer: `partial`.** The system only fuzzes integers. It fails safely on other types. Read `ooda/bootstrap/FUZZ_DEFER.md`.

| Claim | Reality |
|-------|---------|
| `ooda test` and verify rails | Present |
| `ooda test --fuzz` command | Yes (integer domain only) |
| Python on critical fuzz path | **No** |
| Full parsed contracts for fuzzing | **No** (uses fixture markers like `FUZZ_DOMAIN`) |
| Pure `.oo` fuzzer | Incomplete |
| Hive-mind, human-in-the-loop, solver | **Not started** |

**Honest summary:** The Alpha version has basic self-testing for integers. It does not have full contract proofs or global fuzzing.

## 8. Open research questions

1. How do we make test data for strings and complex types without Python?
2. When must contracts be proofs, fuzzing rules, or debug checks?
3. How do we stop empty contracts (`ensures true`) from passing tests?
4. How do we use mutation testing with agent code changes?
5. How can hive-mind fuzzing share errors without sharing private source code?

## 9. Acceptance criteria (for PM status promotion)

### Partial to broader partial

- [ ] Enforce `ensures` on product code for a documented subset.
- [ ] Add one more fuzz domain (for example, Boolean or String), or make a permanent fail-closed policy.
- [ ] Make contract error messages stable for agents (JSON).

### Executive Summary self-testing to done (release definition)

- [ ] Make contracts and local fuzzing a documented product feature.
- [ ] Do not pass unsupported fuzz types silently.
- [ ] Freeze incomplete items (hive-mind, human testing, full proofs) for future updates.

## 10. References

1. openOODA, *DESIGN.md* §1 Mathematical Contracts; §3.6 Automated Contract Fuzzer; §2.4 Hive-Mind Fuzzing; §5.6 HITL.
2. B. Meyer, “Applying ‘Design by Contract’,” *IEEE Computer*, 1992. https://pages.mtu.edu/~aebnenas/teaching/spring2010/cs3141/readings/meyerPDF.pdf
3. Eiffel Software, Design by Contract overview. https://www.eiffel.com/values/design-by-contract/
4. K. Claessen and J. Hughes, “QuickCheck: a lightweight tool for random testing of Haskell programs,” ICFP 2000. https://dl.acm.org/doi/10.1145/351240.351266
5. N. Nelhage, “Property-Based Testing Is Fuzzing,” 2017. https://blog.nelhage.com/post/property-testing-is-fuzzing/
6. C. A. R. Hoare, “An Axiomatic Basis for Computer Programming,” *CACM*, 1969.
7. openOODA `ooda/bootstrap/FUZZ_DEFER.md`.
8. Related: RP-1.2, RP-3.6, RP-2.4, RP-5.6, RP-ES.1.

---

## Conflicts with other DESIGN items

- **§3.2 Time and entropy sandboxing against realistic fuzzing:** Full determinism prevents tests on real clocks. You must inject fake `&TimeCap` data.
- **§4 performance against §5 security:** If you remove `ensures` in production, you remove a runtime safety check. Shadow-state reversion (§3.10) is a different solution, but it is not implemented.
- **§2.4 Hive-mind against §5.2 zero-trust packages:** Shared fuzz data can become an attack channel if bad actors make malicious test cases.

---

*Series: [Research papers index](./README.md). Template: [TEMPLATE.md](./TEMPLATE.md).*
