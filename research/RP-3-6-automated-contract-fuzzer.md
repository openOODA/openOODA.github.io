# RP-3.6: Automated Contract Fuzzer

**Abstract**

This paper presents the theoretical architecture of the openOODA automated contract fuzzer. The system connects design-by-contract rules with high-speed artificial intelligence (AI) iterations. Contracts without tests become useless comments. This system continuously tests functions to find inputs that satisfy preconditions but break postconditions. This process gives immediate feedback to the Observe, Orient, Decide, Act (OODA) loop. The architecture uses property-guided tests that read abstract syntax tree (AST) properties. The system supports multiple data types and controls execution capabilities to ensure safety.

**1. Introduction**

Section 3 of the openOODA DESIGN document requires a continuous test engine. The engine must make test cases that break `requires` (precondition) and `ensures` (postcondition) contracts. The automated contract fuzzer performs this essential task. 

If programmers do not test contracts, they develop incorrect confidence in the software. Simple unit tests do not find the edge values that contracts must manage. Furthermore, when an AI repairs code, local unit tests can pass while important mathematical properties fail. Pure functions provide excellent targets for random tests. The fuzzer connects the theoretical contracts to continuous validation tests. 

The primary users of this system are programmers who write algebraic properties, AI agents that propose repairs, and continuous integration systems. The central research question asks how to build a fuzzer that understands types and capabilities, reads the AST, and completes tests in less than one second. This rapid response time is critical for the AI generation cycle.

**2. Related Work**

The system builds upon the concepts of property-based testing and coverage-guided fuzzing. Tools like QuickCheck introduced random generation and input shrinking. Shrinking is an essential operation. AI agents need the smallest possible counterexamples to understand why an operation fails. Industrial tools like Hypothesis and the Rust `proptest` library show the value of property tests in production code. 

Coverage-guided fuzzers, such as AFL and libFuzzer, find crashes and memory errors. However, these tools usually lack a strong semantic oracle. In the openOODA architecture, the contract operates as the oracle. A successful test requires more than a non-crash state. The function must also satisfy its `ensures` statement after execution. Other systems, like Eiffel AutoTest and smart contract fuzzers, successfully use contracts as oracles. Symbolic execution tools like KLEE find complex execution paths, but they operate too slowly for the fast OODA loop.

**3. Architecture and Methodology**

**3.1. Contract Extraction**

The architecture relies on the contract as the primary oracle. The fuzzer reads the abstract syntax tree (AST) to identify functions. It specifically looks for functions that contain `requires` and `ensures` statements. This static analysis step occurs before any dynamic execution begins. The system extracts the parameter types from the function signature.

**3.2. Data Generation and Filtering**

The system generates random candidate inputs for the correct data types. It uses type-aware generators to create numbers, strings, and complex data structures. After generation, the system filters out inputs that do not satisfy the `requires` condition. The system discards these invalid inputs immediately. The fuzzer only executes the target function with valid inputs. 

**3.3. Execution and Verification**

The fuzzer executes the target function. It captures the return values and any state changes. Finally, it checks two conditions. First, it ensures that the function does not crash. Second, it verifies that the `ensures` condition evaluates to true. If both conditions hold, the test passes.

**3.4. Shrinking and Diagnostics**

If a test fails, the system immediately shrinks the input. The shrink operation systematically reduces the size of the input to find the smallest value that causes the failure. The fuzzer writes a JSON diagnostic file containing this minimal counterexample. AI agents read this file to repair the code. The loop of failure, repair, and test occurs rapidly. 

**3.5. Capability Control**

The architecture manages functions with side effects through strict capability limits. Functions receive an injected file system capability. This capability only permits access to a specific temporary directory. The system uses deterministic time and random capabilities to ensure reproducible results. The architecture also limits memory allocation and processor execution cycles. These limits prevent dangerous operations on the host computer. They also stop infinite loops during the test process.

**3.6. Distributed Hive-Mind Integration**

The local contract fuzzer works in conjunction with the distributed hive-mind system. The local fuzzer operates continuously on the developer machine. It verifies the immediate AI repairs. The hive-mind operates globally and asynchronously. The local fuzzer sends interesting test data and edge cases to the hive-mind. The local system receives new, optimized mutation strategies in return.

**4. Threat and Failure Model**

The fuzzer architecture targets specific developer errors. It finds false `ensures` statements and off-by-one boundary errors. It also identifies preconditions that are too strong and postconditions that are too weak. 

However, the theoretical model has specific limitations. The system does not inherently find deep stateful protocol errors. These errors require sequential property-based tests. The system cannot invent correct specifications if the programmer writes the wrong mathematical property. Furthermore, inefficient data generators can cause a denial of service during testing. The strict execution limits on cycles prevent this denial of service from freezing the host system.

**5. Conclusion**

The openOODA automated contract fuzzer provides a complete theoretical system for continuous property validation. The architecture successfully combines AST-based contract extraction, type-aware data generation, and strict capability limits. This integrated design allows AI agents to receive immediate, safe, and minimized counterexamples. The system transforms static, unverified contracts into active, continuously verifiable properties.

**6. References**

1. Claessen, K., & Hughes, J. (2000). *QuickCheck: a lightweight tool for random testing of Haskell programs.* ICFP.
2. Zalewski, M. *American Fuzzy Lop (AFL)*; AFL++ documentation.
3. LLVM *libFuzzer* design documentation; Google OSS-Fuzz.
4. Hypothesis documentation (modern PBT practice).
5. Eiffel AutoTest; JML-based contract testing literature.
6. Echidna / Foundry invariant testing; Wake property-based Solidity fuzzer.
7. Cadar et al. KLEE — symbolic execution.
8. openOODA: `openOODA/DESIGN.md` Section 3, Section 1.2, Section 2.4.

---

*Series: [Research papers index](./README.md). Template: [TEMPLATE.md](./TEMPLATE.md).*
