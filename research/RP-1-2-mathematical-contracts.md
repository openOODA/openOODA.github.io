# RP-1.2: Mathematical contracts (requires/ensures)

| Field | Value |
|-------|--------|
| **Paper ID** | `RP-1.2` |
| **DESIGN.md** | §1 Language |
| **Status** | `draft` |
| **PM.md row** | `1.2` |
| **Product mapping** | **partial** — simple `requires` lowered on native Backend-C; `ensures` and complex requires residual; not full DbC/proof story |

## 1. Why this is in DESIGN.md

DESIGN.md §1:

> **Mathematical Contracts:** Preconditions (`requires`) and postconditions (`ensures`) are first-class language keywords that mathematically bound function behavior, forming the foundation for local fuzzing and global verification.

Contracts connect openOODA’s AI tools to its safety engine:

- Intent-driven compilation (DESIGN §2.3) builds code from contracts.
- The automated fuzzer (DESIGN §3.6) tests contracts.
- Shadow-state reversion (DESIGN §3.10) stops actions that break `ensures`.
- Narrative diagnostics (DESIGN §5.5) explain contract failures as stories.
- Hive-mind fuzzing (DESIGN §2.4) proves or breaks contracts at night.

Without `requires` and `ensures`, these tools do not share a specification. This paper explains why we use contracts as language keywords. It examines previous work and shows the current product status.

## 2. Problem statement

### 2.1 What breaks without contracts

1. **Unstated intent.** Types alone do not show value limits or relations (`result >= a`). AI agents write code that type-checks but ignores unwritten rules.
2. **Fuzzing without oracle.** A fuzzer needs a failure rule. A simple `assert` in a test does not connect to the public interface.
3. **No path to proof.** Systems with only tests cannot become static verifiers later.
4. **Incomplete security.** Capabilities ask "can this call the network?" Contracts ask "does it keep the data correct?"

### 2.2 Users

| Actor | Need |
|-------|------|
| Human | Executable documentation; fail-fast at boundaries |
| AI agent | Spec for synthesis and for accepting/rejecting patches |
| Fuzzer | Machine-checkable oracles (`requires` filter inputs; `ensures` judges outputs) |
| Verifier (future) | Proof obligations |
| Adversary | Tries to violate postconditions after entry (contracts + caps + fuzz cooperate) |

### 2.3 Scope of “mathematical”

DESIGN says “mathematically bound.” The product must show these steps:

| Level | Meaning |
|-------|---------|
| L0 | Parsed and reflected only |
| L1 | Runtime checks on simple expressions (current partial) |
| L2 | Multi-type/runtime-complete contracts + fuzz |
| L3 | Static proof of subset (SPARK-like) |
| L4 | Full formal verification integration |

Alpha targets L1 and plans to reach L2. We do not claim L3 or higher yet.

## 3. Related work

### 3.1 Design by Contract — Meyer and Eiffel

- **Bertrand Meyer**, *Object-Oriented Software Construction* (1st ed. 1988; 2nd ed. 1997): definitive treatment of Design by Contract (DbC)—preconditions, postconditions, class invariants; reliability as correctness + robustness.
- **Meyer, “Applying ‘Design by Contract’”**, *IEEE Computer*, 1992: contracts as obligations between client and supplier; widely cited industrial framing.
- **Eiffel**: first-class assertions in the language; runtime monitoring with configurable levels; culture of contracts-as-design.

Lessons for openOODA: Language keywords are better than library macros. Inheritance rules are important if object-oriented features grow. Runtime checks affect performance.

### 3.2 Spec# and Code Contracts (Microsoft Research / .NET)

- **Spec#**: C#-based research language with method contracts in the signature; verification via Boogie/Z3-class backends. Overview: Barnett, Leino, Schulte, *The Spec# Programming System: An Overview* (CASSIS 2004).
- **Code Contracts** (.NET): language-agnostic `Contract.Requires` / `Ensures` API; static checker + runtime rewriter. Project page: https://www.microsoft.com/en-us/research/project/code-contracts/
- Industrial lesson: Adding contracts to an old ecosystem only works partially. Not everyone uses static verification. But runtime contracts are still useful.

### 3.3 SPARK / Ada

- **Ada 2012** contracts: pre/postconditions and type invariants in the standard language.
- **SPARK**: provable Ada subset; contracts are proof obligations discharged by GNATprove / SMT; used in high-assurance industrial systems (avionics, rail, security).
- AdaCore materials on contract-based programming and safe/secure guidelines: https://www.adacore.com/blog/the-case-for-contracts ; SPARK documentation and training books from AdaCore.

Lesson: A language subset and good tools make mathematical proofs real. You do not need to prove the full language to get value.

### 3.4 Other systems

- **JML** (Java Modeling Language), **ACS L** / Frama-C for C, **Whiley**, **Dafny**, **Liquid Haskell**, **Prusti** (Rust): specification languages and verifiers with varying integration cost.
- **Property-based testing** (QuickCheck et al.): related oracle idea without static proof—maps to DESIGN’s fuzzer.

### 3.5 Empirical notes

Studies show that developers usually write simple contracts. This supports our plan to start with simple `requires` statements. We do not need to wait for complex logic.

## 4. Design rationale for openOODA

### 4.1 First-class keywords

EBNF (product/spec) includes:

```text
Precondition  ::= "requires" Expression ;
Postcondition ::= "ensures" Expression ;
```

Keywords let you:

- Parse and export contract text uniformly.
- Compile code without reading comments.
- Add static analysis tools later.

### 4.2 Role in the AI loop

1. A human or AI writes `requires` and `ensures`.
2. A human or AI writes the code body.
3. The compiler creates runtime checks.
4. The fuzzer makes inputs that pass `requires` and tries to break `ensures`.
5. Diagnostics tell you which rule failed.

### 4.3 Interaction with capabilities

Contracts do not replace capabilities. A function can use `requires buf.len() > 0` and still need `&FsCap` to write data. Authority and correctness are separate. We might add security rules to contracts later.

### 4.4 Expression language conservatism

Alpha limits the expressions that the compiler accepts:

- Use pure predicates with no side effects.
- Do not use I/O in contracts.
- Define clear rules for `result` before you use `ensures`.

## 5. Threat / failure model

### 5.1 What contracts prevent (when enforced)

- Silent API errors.
- Code changes that break postconditions.
- AI code generation without a specification.
- Missing rules for function fuzzing.

### 5.2 What they do not prevent

- **Wrong contracts**: Bad specifications make bad checks.
- **Incomplete compilation**: The product can parse `ensures` but not run it.
- **Data races**: Contracts do not check heap or concurrency problems.
- **Malicious code**: Bad modules can remove contracts.
- **Side effects**: Contracts can have side effects if you allow them.

### 5.3 Failure modes

| Failure | Mitigation |
|---------|------------|
| Checks disabled in production | Explicit build modes; security-critical always-on subset |
| Pathologically expensive predicates | Restrict language; budgets; pure only |
| Contracts diverge across backends | Shared lowering tests; fail-closed when not lowered |
| Fuzzer only Int-domain | Document fail-closed multi-type residual (`FUZZ_DEFER.md`) |

## 6. Alternatives considered

| Alternative | Why rejected / deferred |
|-------------|-------------------------|
| **Library `assert` only** | Not reflective; not in function signature; AI and fuzz can’t rely on structured export |
| **Comment annotations** (`// @requires`) | Fragile; not EBNF-first; poor tooling |
| **Dependent types only** (no runtime DbC) | Higher barrier; still need executable oracles for fuzz; gradual ladder preferred |
| **External spec files** (ACSL-style separate) | Split-brain with AI agents editing one file |
| **Full SPARK-level proof in v0** | Not credible for alpha self-host language; adopt later on a subset |
| **Code Contracts-style pure library API** | Possible interop later; DESIGN wants keywords for readability and first-class status |

## 7. Product reality (alpha honesty)

**PM.md `1.2` status: `partial`.**

| Surface | Status |
|---------|--------|
| Lexer/parser keywords `requires` / `ensures` | **Present** (`token_emit`, EBNF) |
| `ooda reflect` exports contract text | **Partial/done** for metadata (see `OUTLINE_REFLECT.md`) |
| Native Backend-C **simple `requires`** (e.g. `IDENT OP lit\|ident`) runtime lower | **Shipped** rails (`c_emit_contract.oo`, corpus pass/fail, `contracts_native_smoke.sh`) |
| Complex `requires` | **Residual** (not fully lowered) |
| `ensures` runtime on native | **Residual** — incomplete; do not claim full postconditions |
| Static proof of contracts | **not-started** |
| Multi-type contract fuzz | **partial** only Int pure domain — see RP-3.6 / `FUZZ_DEFER.md` |
| Intent-driven blank body synthesis | **not-started** (RP-2.3) |

From `ooda/bootstrap/BUILD_OUT.md` (product residual language):

> Residual: **ensures** + complex requires not lowered (bodies still emit; no false claim of full contracts)

Honesty: The **partial** status is correct. "Mathematical contracts" is a plan, not a finished verifier.

## 8. Open research questions

1. What is the smallest expression set for contracts that covers most rules without a theorem prover?
2. How should `ensures` name the result and old values across different backends?
3. When should a contract failure stop the program, return an error, or just show a message?
4. Can contracts check world effects (like file length) without breaking language purity?
5. What rules apply if openOODA adds interfaces with contracts?
6. How do we label contracts as proved, runtime-checked, or trusted?

## 9. Acceptance criteria (for PM status promotion)

### partial → stronger partial

- [ ] Documented grammar of **lowerable** `requires` / `ensures` forms; anything outside fail-closed or explicitly “reflect-only.”
- [ ] Rails: pass corpus for supported forms; fail corpus for syntax/violations; smoke scripts green.
- [ ] `ensures` simple forms lowered on native **or** explicit residual tracker with no user-facing overclaim.
- [ ] Reflect + outline stay in sync with parsed contracts.

### done (language-level DbC MVP)

- [ ] The product backend supports runtime contracts for the pure fragment.
- [ ] Active backends have the same features or documented limits.
- [ ] The fuzzer uses the same fragment for integer domains.
- [ ] Diagnostics show which rule failed.
- [ ] The system does not ignore enforced rules.

We will do proof-carrying tasks later.

## 10. References

1. Meyer, B. *Object-Oriented Software Construction*, 2nd ed. Prentice Hall, 1997. (DbC chapters; PDF materials often hosted via author site: https://bertrandmeyer.com/ )
2. Meyer, B. “Applying ‘Design by Contract’.” *IEEE Computer*, 25(10), 1992. https://dl.acm.org/doi/10.1109/2.161279 (PDF mirrors e.g. https://www.kth.se/social/files/59526bfb56be5b4f17000807/meyer-92-contracts.pdf )
3. Eiffel Software — Design by Contract overview: https://www.eiffel.com/values/design-by-contract/
4. Barnett, M., Leino, K. R. M., Schulte, W. “The Spec# Programming System: An Overview.” CASSIS 2004. https://www.microsoft.com/en-us/research/publication/the-spec-programming-system-an-overview/ (see also CACM Spec# experience pieces)
5. Microsoft Research — Code Contracts: https://www.microsoft.com/en-us/research/project/code-contracts/
6. AdaCore — contract-based programming in Ada/SPARK: https://www.adacore.com/blog/the-case-for-contracts
7. AdaCore — SPARK user guidance / safe & secure guidelines: https://learn.adacore.com/ (SPARK / Ada courses)
8. Schiller, T. W., et al. “Case Studies and Tools for Contract Specifications.” ICSE 2014. https://homes.cs.washington.edu/~mernst/pubs/contract-specifications-icse2014.pdf
9. openOODA `spec/DESIGN.md` §1; `ooda/ooda.ebnf` Precondition/Postcondition; `ooda/bootstrap/BUILD_OUT.md`, `FUZZ_DEFER.md`, `OUTLINE_REFLECT.md`; monorepo `PM.md` row `1.2`.

## Conflicts with other DESIGN items

| Conflict | Description | Resolution direction |
|----------|-------------|----------------------|
| **1.2 vs 1.1 (speed)** | Runtime checks and analysis slow loops | Simple pure predicates; optional levels; fuzz out-of-band |
| **1.2 vs 2.3 telepathic AST** | Synthesis needs rich contracts; verifier must not rubber-stamp | Contracts required for blank-body; multi-oracle (types+caps+fuzz) |
| **1.2 vs 3.6 fuzzer** | Fuzzer residual domains undercut “mathematical” claim | Fail-closed markers; expand domains deliberately |
| **1.2 vs 3.10 shadow-state** | Speculative exec needs precise `ensures` semantics | Define evaluation model (pure, no alloc side effects) first |
| **1.2 vs 3.1 caps** | Users may confuse authority and correctness | Orthogonal type-system axes; docs and diags separate codes |
| **1.2 vs 3.7 ARC / 3.8 temporal memory** | Postconditions about memory history are hard | Restrict MVP contracts to pure value properties |
| **1.2 vs 6.3 FFI** | C code ignores contracts | `&UnsafeFFICap` + no assumed contracts across FFI unless wrappers restate them |
| **1.2 vs 4.3.2 reproducible builds** | Nondeterministic contract evaluation forbidden | Pure contract fragment only |

---

*Series: [Research papers index](./README.md). Template: [TEMPLATE.md](./TEMPLATE.md).*
