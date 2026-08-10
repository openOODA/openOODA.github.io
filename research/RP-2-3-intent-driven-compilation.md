# RP-2.3: Intent-Driven Compilation (Telepathic AST)

**Abstract**
This paper presents a theoretical framework for intent-driven compilation in the openOODA system. The software engineering process requires significant effort to write correct implementations. This architecture proposes specification-as-source. Developers write mathematical contracts and leave the function body blank. During compilation, the toolchain utilizes an embedded large language model to synthesize the optimal algorithm. The compiler formally verifies the algorithm before lowering it to machine code. This framework changes mathematical contracts from a runtime oracle to a synthesis goal.

## 1. Introduction

Writing correct systems code has a high cost. Writing precise mathematical contracts also requires significant effort. However, contracts are usually shorter and easier to review than complex implementations. If a toolchain can synthesize the implementation from the contract, developers can focus on intent and review. They do not write boilerplate code. The theoretical intent-driven compiler reads requirements, guarantees, types, and capability constraints. It generates a function body to satisfy these constraints. It verifies the code with tests, fuzzing, or Satisfiability Modulo Theories (SMT) solvers. Finally, it lowers the verified code to machine code.

The primary artificial intelligence claim in the openOODA design is specification-as-source. A developer defines the function signature and mathematical contracts but provides a blank body. The theoretical compiler initiates a synthesis process to fill the blank body with a verified algorithm.

This approach involves multiple stakeholders. Application developers desire speed and correct helper functions. Agent authors want to write contracts only and let the toolchain complete the code. Safety auditors require machine-checkable evidence and do not trust unverified generated code. Adversaries attempt to exploit this pipeline. They use prompt injection to compromise synthesis, attempt to ship unverified code, and exploit non-reproducible builds as supply-chain attacks.

Program synthesis remains exceptionally difficult. Large language models create possible programs, but they do not prove correctness. If the toolchain does not use a strict verifier, intent-driven compilation becomes merely unchecked code generation. This outcome is worse than agent-written code that a human reviews manually.

## 2. Related Work

Classical program synthesis approaches the problem through multiple avenues. Deductive synthesis constructs implementations from formal specifications. Inductive synthesis infers programs from examples. Sketching allows humans to write partial programs while a synthesizer fills the remaining holes. The blank body in openOODA operates as a sketch hole, while the contracts act as constraints.

Large language models generate code from natural language or signatures. Empirical studies highlight severe limitations in this approach. The generated code frequently contains subtle bugs and security vulnerabilities. The models demonstrate extreme sensitivity to prompt phrasing. Most importantly, the generated code lacks algorithmic correctness if not validated by tests.

An emerging pattern combines large language models with formal verification pipelines. This approach utilizes a generate, verify, and repair loop. Systems combine code generation with formal specifications and use feedback from model checking to correct errors. The synthesis community generally agrees that the language model should propose the code, while a classical verifier must strictly accept or reject it.

Verified compilers and proof-carrying code provide relevant foundations. Verified compilers, such as CompCert, compile human code with mathematical certainty, though they do not synthesize code. Proof-carrying code requires developers to ship verification evidence with the software artifacts. Intent-driven compilation must emit a certificate, such as a formal proof, a solver log, or a fuzz corpus hash. It must not emit only an abstract syntax tree.

Industrial systems compilers do not embed general language models for code generation. Current practices rely on generation in the development environment before compilation or use non-reproducible build plugins that call cloud models. The theoretical design requires an embedded model at compile time. This radical idea conflicts with the core requirement for deterministic, reproducible builds.

## 3. Architecture and Methodology

The theoretical architecture reuses existing contract and fuzzing infrastructure. The synthesis pipeline reads the types for the structural shape and the capability parameters for the effect boundary. The requirements and guarantees provide the functional intent. The blank body acts as the synthesis obligation. Tests provide an executable oracle, while future solvers will provide a proof oracle.

The recommended pipeline processes the syntax tree in strict stages. The parser identifies the synthesis hole. The system synthesizes multiple candidate algorithms. A filter discards candidates that fail the typecheck or the capability check. Another filter evaluates the remaining candidates against contract tests and fuzzing harnesses. An optional filter requires a formal proof. Finally, the toolchain commits the verified body to the syntax tree and lowers it to machine code. The compiler must never lower a blank body without an explicit policy, such as a specific compilation flag or a cached pre-synthesized body.

The system architecture presents a critical choice between an embedded model and an external sidecar. An embedded model provides a seamless user experience but breaks determinism, increases binary size, requires network access, and violates pure compiler principles. An external sidecar provides a clean trust boundary but requires an extra compilation step. The theoretical design recommends utilizing a sidecar and strict verifier to protect the pure compilation path.

The theoretical design claims to generate an optimal algorithm. However, the system must optimize for verified correctness first. Performance optimality remains a secondary concern. The system must also prefer readable code to facilitate human audits. Furthermore, the system must enforce strict capability purity. Synthesized code must not acquire capabilities implicitly. If a signature lacks a network capability, the synthesizer must not emit network calls. The signature defines the absolute maximum effect envelope.

The threat model identifies severe pipeline risks. The system must fail closed if there are no tests or proofs, preventing unverified acceptance. The toolchain must emit explicit certificates to prevent false verification claims. To maintain reproducible builds, the system must cache the synthesized source and pin the model version. The system should use local weights and hash pins to prevent supply-chain model poisoning. The synthesizer must operate in a sandbox and never read ambient files to prevent prompt injection. Linters must detect vacuous contracts to prevent specification gaming. Finally, the system must execute a static capability check on the candidate tree to prevent capability laundering.

## 4. Conclusion

Intent-driven compilation offers a revolutionary approach to systems programming. This theoretical framework demonstrates how specification-as-source can eliminate boilerplate implementation while maintaining strict mathematical correctness. The integration of language models for candidate generation, combined with rigorous formal verification, creates a robust synthesis pipeline. Future research must determine the minimal acceptable certificate for verified synthesis, refine the cache topology for global content-addressable storage, and resolve the tension between non-deterministic models and reproducible builds.
