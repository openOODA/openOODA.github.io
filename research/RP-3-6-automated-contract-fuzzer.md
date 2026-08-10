# RP-3.6: Automated contract fuzzer

| Field | Value |
|-------|--------|
| **Document ID** | `RP-3.6` |
| **DESIGN.md** | Section 3: Safety — Automated Contract Fuzzer |
| **Status** | `draft` |
| **PM.md row** | `3.6` |
| **Product mapping** | **partial**. Only the **Integer-domain** operates. Other types cause a fail-closed status (`FUZZ_DEFER.md`). |

## 1. Reason for inclusion in DESIGN.md

Section 3 of DESIGN.md states:

> The `ooda test --fuzz` engine operates continuously. It tries to make test cases that mathematically break your `requires` and `ensures` contracts.

openOODA combines **design-by-contract** (Section 1.2 `requires` and `ensures`) with **high-speed AI iterations**. Contracts that you do not test become useless comments. An automated contract fuzzer:

1. Looks for inputs that agree with `requires` but do not agree with `ensures` or runtime assertions.
2. Gives data to the OODA loop. The steps are: fail, repair, and test again. This occurs in less than a second if possible.
3. Adds to human testing (Section 5.6) and hive-mind fuzzing (Section 2.4).

This tool does not only do generic coverage tests. It does **property-guided** tests that use the contracts in the code.

## 2. Problem statement

### Results when you do not test contracts

| Problem | Result |
|-----|--------|
| You do not test contracts. | You have incorrect confidence in `ensures`. |
| You only do simple unit tests. | You do not find the edge values that the contracts must manage. |
| AI repairs the code. | Local tests pass, but properties do not pass. |
| Functions are pure. | These functions are excellent for random tests, but you do not use them. |

### Users

- Programmers who make libraries and write algebraic properties.
- AI agents that propose code repairs. These repairs must obey the contracts.
- Continuous Integration (CI) tests that must pass before you merge code (Section 5.2).

### Primary research question

How do we change from an **integer-domain** test environment to a full contract fuzzer? This fuzzer must understand types and capabilities. It must read the Abstract Syntax Tree (AST). It must use only `.oo` files and no Python files on the main path. It must complete tests in the short time that OODA requires.

## 3. Related work

### 3.1 Property-based testing

- **QuickCheck:** Does random generation and shrinking. This is the model for contract testing.
- **Hypothesis, ScalaCheck, fscheck, rapidcheck:** These are industrial tools for property-based testing.
- **Erlang PropEr / QuickCheck:** The telecommunications industry uses these large tools.
- **Rust `proptest`:** A modern property-based test tool for systems languages.

Lesson: **Shrinking** is as important as generation if you want AI agents to use the failures.

### 3.2 Coverage-guided fuzzing

| Tool | Domain |
|------|--------|
| **AFL and AFL++** | Fuzz tests for binary mutations. These tools use coverage feedback. |
| **libFuzzer** | In-process tests with LLVM sanitizers. |
| **Honggfuzz and libAFL** | Modern test engines. |
| **OSS-Fuzz** | Continuous fuzz testing for many projects at a large scale. |
| **ClusterFuzz** | Distributed fuzz testing infrastructure. |

These tools find crashes and sanitizer errors. Contracts require an **oracle**. The oracle is the `ensures` statement or the properties. A non-crash is not sufficient.

### 3.3 Contract and semantic fuzzing

- **Eiffel AutoTest:** Uses contracts as oracles.
- **Java JMLOK and JML tools:** Uses design-by-contract testing.
- **Smart contract fuzzers:** Examples are Echidna, Foundry, and Wake. These tools use **properties and hostile inputs** on stateful systems.
- **Symbolic execution:** KLEE and SAGE. These are heavy tools. They are good for finding the path that breaks a contract.

### 3.4 Grammar-aware generation

- **Peach, Domato, LangFuzz:** These tools make structured inputs.
- **AST mutators for compilers:** These are important for testing the oodac compiler.
- In openOODA, Section 2.4 hive-mind does distributed mutations during the night. Section 3.6 is the local contract engine.

## 4. Design rationale for openOODA

### 4.1 The oracle uses contracts

```text
fn abs(x: Int) -> Int
  requires true
  ensures result >= 0

// Fuzzer: get a random x. Stop if requires is false. Report failure if ensures is false.
```

Procedure:

1. Find the functions that have contracts or fuzz markers.
2. Make candidate inputs for the correct data type.
3. Remove inputs that do not pass `requires`.
4. Run the function with limits on capabilities and resources.
5. Make sure that `ensures` is true and the function does not panic.
6. Shrink the input that caused the failure. Write a JSON diagnostic file for the AI agents.

### 4.2 Reason to start with integers

Integers have these properties:

- They have clear boundaries (0, 1, -1, minimum, maximum).
- They are easy to sample.
- They are easy to shrink.
- They connect directly to the Backend-C `long long` type.

Rule: If we use many data types without correct generators, the result is worse than a fail-closed status.

### 4.3 Fuzzing with capability limits

Functions with side effects require:

- An injected `FsCap` that only permits access to the temporary directory.
- `TimeCap` and `RandCap` to make results reproducible (Section 3.2).
- `AllocCap` to limit memory (Section 3.3).
- `MaxCycles` to limit execution time (Section 3.4).

If you do not limit capabilities, the tests are dangerous to the host computer or you cannot repeat the tests.

### 4.4 Relation to hive-mind (Section 2.4)

| 3.6 Contract fuzzer | 2.4 Hive-mind |
|---------------------|---------------|
| Operates locally with property oracles. | Operates distributed during the night. |
| Used in developer CI and the agent loop. | Uses a shared set of mutations. |
| Must send test data up. | Must get interesting test data. |

### 4.5 Product procedure

Refer to `ooda/bootstrap/FUZZ_DEFER.md`:

- The Command Line Interface (CLI) uses `ooda test --fuzz` without limits.
- The pure bash procedure is `ooda_fuzz_pure.sh` for `// FUZZ_DOMAIN: int`.
- The markers are `FUZZ_TARGET`, `FUZZ_REQUIRES`, and `FUZZ_ENSURES`. These are written in the tests. The AST does not parse contracts yet.
- Other data types cause a fail-closed error.

## 5. Threat and failure model

### What the fuzzer finds

- False `ensures` statements on pure integer functions.
- Off-by-one errors and sign errors that contracts say they prevent.
- `Requires` statements that are too strong. `Ensures` statements that are too weak. The fuzzer reports these well.

### What the fuzzer does not find

| Problem | Notes |
|-----|-------|
| Multi-type errors and structural errors. | This is a product limitation. |
| Stateful protocol errors. | This requires sequential property-based tests. |
| Deep paths from coverage data. | The tool is not an AFL-class tool yet. |
| Specification errors. | The fuzzer cannot invent correct specifications if you wrote the wrong property. |
| Errors from time or random numbers. | This requires Section 3.2. |

### Dangers

- Fuzz tests with side effects and no limits cause damage to the host computer. You must use a sandbox.
- Bad generators cause a Denial of Service (DoS) in the fuzzer. You must use `MaxCycles` on the generator.

## 6. Alternatives considered

| Alternative | Consequence |
|-------------|----------|
| **Use only unit tests** | This is not sufficient for properties. |
| **Use AFL on the binary file** | The contract oracle is weak unless the test includes the `ensures` statement. |
| **Do full symbolic execution** | The cost is high. The OODA speed is poor. |
| **Use a Python Hypothesis test forever** | This stops pure self-hosting. Python remains only for non-fuzz verification. |
| **Use unlimited multi-type random tests** | This causes noise and unreliable tests. The shrink operation is difficult. |
| **Claim continuous global tests in DESIGN** | That is Section 2.4 and its infrastructure, not Section 3.6 alone. |

## 7. Product status

**PM.md `3.6`: partial.** Milestone **M3: PARTIAL** (Only the Integer domain operates).

| Claim | Reality |
|-------|---------|
| CLI `--fuzz` operates. | **Yes** |
| Python operates on the `--fuzz` main path. | **No**. The system uses a pure bash Integer path. |
| Domain | **`// FUZZ_DOMAIN: int` only** |
| Multiple types and parameters | **Fail-closed** |
| The AST reads `requires` and `ensures`. | **No**. The tests use comment markers. |
| `fuzz_gen.oo` is in oodac. | **No**. It is not on the product path. |
| Fuzz tests obey capability limits. | **No**. This is not the full product status. |
| `ensures` operates on native general code. | **Residual**. Simple `requires` operates partially on native code. |

Official documents:

- `ooda/bootstrap/FUZZ_DEFER.md`
- `ooda/bootstrap/BUILD_OUT.md` (M3 notes)
- Tests: `fixtures/fuzz_int_domain.oo`, `fuzz_int_fail.oo`
- Scripts: `scripts/ooda_fuzz_pure.sh`, `ooda_test_verify.sh`

**Do not claim:** We have a full multi-type native contract fuzzer. Do not claim that we continuously break all contracts.

### When to claim "full native fuzzer"

1. The main path has no Rust code and no Python code *(Integer: complete)*.
2. The explicit domain has pass rails and fail rails *(Integer: complete)*.
3. Tests with side effects use a sandbox that obeys capabilities.
4. The system supports more types and parameters without Python code.
5. Honesty tests agree with the documents.

## 8. Open research questions

1. **Generator language:** Do we use pure `.oo` strategies or a built-in `Arbitrary` typeclass?
2. **Shrinking algorithms:** How do we shrink complex types and strings so agents can use them?
3. **Coverage feedback:** How do we get this without LLVM on the Backend-C layer?
4. **Stateful rules:** How do we do setup, operations, and checks for modules with capabilities?
5. **Integration with Section 1.2:** How do we get fuzz rules from the AST `requires` and `ensures` statements and stop using comment markers?
6. **Corpus sharing:** How do we share data with the Section 2.4 hive-mind format?
7. **Flake control:** How do we make tests reproducible when we use Section 3.2 capabilities?

## 9. Acceptance criteria

### partial to stronger partial

- [ ] Add multiple parameters for pure Integers (example: 2 to 3 arguments) with shrink operation.
- [ ] Make the AST read contracts for simple `requires` and `ensures` on pure functions. Do not use markers.
- [ ] Make a JSON counterexample file for agent repair tools.
- [ ] Add a default `MaxCycles` and timeout for each iteration.

### partial to completed

- [ ] Add domains: Integer, Boolean, String (with limits), and simple structures.
- [ ] Keep the fail-closed status for types that the system does not support. Do not skip silently.
- [ ] Make a test harness that obeys capabilities for temporary directory effects.
- [ ] Make sure the pure `.oo` or product path has no Python code when you use `--fuzz`.
- [ ] Add pass and fail rails for each domain. Make sure honesty tests are green.
- [ ] Document the relation to the hive-mind (import and export data).

## 10. References

1. Claessen, K., & Hughes, J. (2000). *QuickCheck: a lightweight tool for random testing of Haskell programs.* ICFP.
2. Zalewski, M. *American Fuzzy Lop (AFL)*; AFL++ documentation.
3. LLVM *libFuzzer* design documentation; Google OSS-Fuzz.
4. Hypothesis documentation (modern PBT practice).
5. Eiffel AutoTest; JML-based contract testing literature.
6. Echidna / Foundry invariant testing; Wake property-based Solidity fuzzer (commercial smart-contract practice).
7. Cadar et al. KLEE — symbolic execution.
8. openOODA: `spec/DESIGN.md` Section 3, Section 1.2, Section 2.4; `PM.md` 3.6, M3; `ooda/bootstrap/FUZZ_DEFER.md`, `BUILD_OUT.md`.

---

*Series: [Research papers index](./README.md). Template: [TEMPLATE.md](./TEMPLATE.md).*
