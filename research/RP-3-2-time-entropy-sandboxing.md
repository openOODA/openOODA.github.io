# Time and Entropy Sandboxing for Deterministic Systems

## Abstract

This paper presents a theoretical capability-based architecture for time and entropy management in systems programming. Programs often read the system clock or generate random numbers. These actions break equational reasoning, testing, and deterministic builds. They also permit timing attacks and hidden side channels. We propose a theoretical design where the system clock and random number generators are not ambiently available. Instead, the programming language requires explicit capability tokens to access these resources. This design guarantees that functions remain mathematically pure by default. It also ensures that testing is fully deterministic and builds are reproducible.

## 1. Introduction

Time and entropy are ambient effects. They cause severe problems in software engineering. When functions call standard time or random functions, they break mathematical purity. This impurity invalidates equational reasoning, compiler optimizations, and formal proofs. Furthermore, ambient time and entropy cause unreliable tests. Branches that depend on the time of day behave differently across environments. Builds embed timestamps in artifacts, which stops reproducible compilation. Random number dependencies cause fuzzing failures that developers cannot replay.

From a security perspective, ambient time and entropy present severe risks. Malicious code can use the wall clock to create timing oracles or hidden side channels. Attackers can use random number generators to implement anti-analysis techniques.

Our core research question is how to provide necessary time and entropy for systems programs while keeping code pure and replayable by default. Systems require time for timeouts, unique identifiers, and cryptography. Decision systems need stable execution runs that developers can replay. Fuzzing methods and rollback tools require that all non-determinism comes from explicit inputs, not from a hidden environment. The theoretical architecture must not treat operating system clocks as ambient mathematical objects.

## 2. Related Work

### 2.1 Purity and Effects

Academic languages use various methods to control effects. Haskell uses a specific monad where time and random number generation exist explicitly. Purity is a strict type property. Other functional languages use effect rows or algebraic effects. In these systems, time and random values act as handlers that tests can swap. Verification languages use effect annotations to limit entropy sources in cryptographic code.

### 2.2 Deterministic Replay and Hermetic Builds

Industry tools record and replay non-determinism. They capture system calls and random events. Build systems sandbox the build environment. They ban undeclared inputs because timestamps and random data cause common hermeticity bugs. Reproducible build projects actively remove clocks and entropy from compiled artifacts. Research systems virtualize time and entropy for operating system containers.

### 2.3 Capability-Based Systems

Some operating systems treat clocks and entropy as kernel services. Programs invoke them via capabilities, not ambiently. WebAssembly requires explicit imports for clock and random functions. Web browsers separate standard random functions from cryptographic random functions. They also put high-resolution time behind security headers to stop side-channel attacks.

### 2.4 Testing Practices

Property-based testing assumes a deterministic test function. Ambient random generation breaks the shrinking of test cases. Snapshot tests require stable clocks or clock injection. Game engines achieve deterministic replay by using a fixed time step and a seeded random number generator.

## 3. Architecture and Methodology

### 3.1 Capability Tokens as Effect Parameters

The theoretical architecture uses capabilities as effect tokens. A function needs a time capability token to read the wall clock, the monotonic clock, or high-resolution timers. A function needs a random capability token for any random number generator interface. We separate the standard core library from these effects. The core library does not provide access to the clock or the random number generator. The operating system library provides access only if the program holds the correct capability tokens.

For example, a logging function takes a time capability to record the event time. A function that generates a unique identifier takes a random capability. A simple addition function takes no capabilities and remains pure. This makes the addition function easy to test and fuzz.

### 3.2 Determinism Modes

The architecture operates in different determinism modes depending on the context. In a production environment, the system uses the real operating system clock and a cryptographic random number generator. In test and fuzzing modes, a test harness injects a virtual timeline and a seeded random number generator. This ensures perfect replayability. During a build process, the compiler uses a frozen time epoch and a fixed seed, or it bans time and entropy entirely.

This design means that tests are completely deterministic. The test mode injects deterministic capabilities. Production code receives real entropy through the capability tokens.

### 3.3 Interaction with System Features

This capability architecture interacts deeply with other system features. For security, high-resolution time combined with secret branches creates a side channel. A security policy can ban time capabilities in secret contexts. For fuzzing, the test harness injects a specific random capability for the system under test. The fuzz generator uses a separate random number generator. For reproducible builds, the compiler cannot read ambient time unless the build policy grants a time capability.

### 3.4 Theoretical Implementation Rules

The theoretical implementation uses static seal names for builtin functions. At runtime, a program must pass the correct capability token. A runtime harness selects either an operating system backend or a virtual backend for these operations. A system can optionally log non-deterministic events for debugging purposes. This is similar to record and replay tools.

## 4. Threat Model and Security

### 4.1 Prevented Vulnerabilities

This architecture prevents accidental impurity in pure libraries. It eliminates flaky tests caused by clock and random number variations. It stops silent non-reproducible builds caused by standard libraries. It also defeats simple anti-fuzzing techniques that do not declare a random capability.

### 4.2 Security Limitations

The architecture does not prevent hardware timing channels. Cache timing variations still exist without a language clock. Foreign function interfaces can bypass the sandbox. For example, external code can call the system clock without a capability token. The architecture also cannot fix a poor quality entropy source provided by a kernel. Distributed systems still face clock skew problems. Furthermore, purity is relative to the declared effects, not absolute physical properties.

### 4.3 Failure Modes

The architecture accounts for specific failure modes. Distributed agents experience clock skew. The system needs a virtual time capability for each logical actor. Cryptographic misuse is a risk if a developer uses a test random capability in production. The system uses type distinctions to separate secure and insecure random capabilities. Deadlocks can occur if a system pauses for external input while holding time-sensitive locks.

## 5. Alternatives Considered

We considered purity by convention and linters. This is insufficient for generated code and fails open. We considered virtualizing time globally. This breaks real servers and requires complex mode switching. We considered allowing the clock everywhere but banning it in explicitly pure functions. This makes impurity the default. Our design requires purity by default. We considered thread-local random number generators without capabilities. This creates hidden global state and breaks replay mechanisms. Finally, we considered depending on an external sandbox. However, code runs outside the build system, so we require language-level enforcement.

## 6. Open Research Questions

Several open questions remain for future research in this theoretical model.
First, researchers must determine if the system needs a single capability or separate capabilities for wall time, monotonic time, and processor cycles.
Second, researchers must decide whether to use a single random capability or split it to prevent test seeds from entering cryptographic functions.
Third, researchers must analyze how asynchronous timeouts interact with time capabilities and maximum execution cycles.
Fourth, researchers must design a record and replay format that logs non-determinism without creating excessively large traces.
Fifth, researchers must resolve how runtime code mutation interacts with entropy. This ensures mutation does not pollute deterministic builds.
Finally, researchers must find ways to sandbox high-resolution hardware timers that bypass standard libraries.

## 7. Conclusion

Sandboxing time and entropy through capability tokens provides a robust theoretical foundation for systems programming. By requiring explicit capability tokens, the language guarantees that functions are pure by default. This capability-based architecture enables fully deterministic testing, reproducible builds, and reliable fuzzing. It eliminates hidden side channels and forces developers to declare their use of non-deterministic resources. While challenges remain with foreign function interfaces and hardware timers, explicit effect management is necessary for secure and replayable software systems.

---
*Series index: [README.md](./README.md).*
