# Capability Sandboxing Versus Foreign Function Interfaces

## Abstract

This paper explores the tension between capability-based security and foreign function interfaces (FFI). Safe programming languages track capabilities to control side effects. However, foreign code (C or C++) does not track capabilities. Foreign code can execute any system call. This behavior breaks the capability model. We propose a theoretical architecture for the openOODA language. This architecture requires an explicit capability, called `UnsafeFFICap`, for any foreign function call. This requirement makes the FFI boundary a deliberate and auditable breach of the sandbox. Our design allows necessary interoperability. It also maintains the integrity of the capability model.

## 1. Introduction

Modern secure languages use object-capability models. These models prevent functions from causing ambient side effects. For example, a function can read a file only if it receives a file capability. However, real-world applications must interact with existing C and C++ libraries. These foreign libraries do not obey capability rules. A C library can open network sockets without explicit capabilities. 

A tension occurs when a safe language calls an unsafe foreign function. If a language bans foreign functions, it prevents practical software development. If a language allows foreign functions silently, it destroys its security guarantees. This paper presents a theoretical architecture to resolve this tension. We introduce an explicit, trackable capability for foreign function calls.

## 2. Problem Statement

The integration of capability-based security with unconstrained foreign code creates significant risks. The compiler must track the boundary. If it does not, any foreign dependency can reintroduce ambient authority. This gives developers a false sense of safety. A developer might pass only a file capability to a function. The underlying C code can still open network connections.

Foreign functions can return pointers or buffers. These values can smuggle unchecked authority into pure code. 

Different users have different needs. Application developers must call mature C libraries. Library authors want to offer safe wrappers around these libraries. Agent runtimes must execute untrusted code safely. Runtimes cannot give untrusted code raw access. Adversaries attempt to plant malicious code. They use FFI to bypass network capability checks. 

The core invariant must state that pure effects remain a subset of granted capabilities. A foreign function call must require an explicit capability. Data that crosses the boundary must be treated as tainted. The system must explicitly endorse this data before use.

## 3. Related Work

Object-capability security removes ambient authority. Systems like the E language use explicit rights. Capability-oriented WebAssembly (WASI) grants explicit rights to modules. 

Safe languages often mark foreign calls as unsafe. For example, Rust uses the `unsafe` keyword. However, this keyword does not stop C code from making system calls. 

Research systems explore in-process isolation. They sandbox untrusted native code. This prevents memory corruption. The Vale language introduces "Fearless FFI" using module capabilities. Hardware mechanisms like CHERI use hardware capabilities to bound pointers. These hardware systems complement language-level capabilities. 

## 4. Architecture and Methodology

We design a capability ladder. This ladder explicitly models the foreign function breach. Pure computation requires no capabilities. Sealed operations require specific capabilities, such as `FsCap` or `NetCap`. Nondeterminism requires a `TimeCap`. 

We introduce `UnsafeFFICap`. This capability allows a function to leave the effect model. It allows the function to call foreign code. 

The architecture enforces strict static rules. Any link to non-OODA object code requires `UnsafeFFICap`. The calling function must include it in its parameter list. This taint is transitive. A function that calls a foreign function must also demand the capability. 

Wrapper functions must explicitly declare the capability. Main programs decide which modules receive `UnsafeFFICap`. Untrusted plugins receive no capabilities. Code generators must automatically insert the capability requirement into generated wrappers.

Data crossing the boundary requires strict handling. Data passed to C must have documented ownership. Data returned from C is untrusted. The system prefers to copy this data into managed buffers.

Cross-language link-time optimization (LTO) can erase the visible call boundary. However, LTO must not remove the capability requirement. The logical foreign effect remains.

## 5. Threat Model and Failure Modes

This architecture prevents accidental ambient input and output from safe modules. It stops untrusted agent binaries from importing unsafe helpers. The capability requirement makes the sandbox breach visible during code review.

However, this model does not prevent a malicious module from misusing `UnsafeFFICap`. It assumes the module holds the capability. It does not stop memory corruption from C from affecting the safe process. It also cannot prevent kernel bugs.

Failure modes include capability dilution. Too many modules might require `UnsafeFFICap` just in case. If so, the model collapses back to ambient authority. We must mitigate this with linting tools. Another failure mode is false wrappers. A safe API must not hide foreign calls without threading the capability.

## 6. Alternative Designs

We considered several alternatives. Banning user FFI forever is impractical. Relying only on an `unsafe` keyword is insufficient. It does not model the authority of system calls. Operating system mechanisms like seccomp provide good defense. However, they do not solve the language-level tracking problem.

Reimplementing all input and output in pure code is a long-term goal. Legacy systems still require FFI. The `UnsafeFFICap` design provides an honest and auditable solution. Future work may explore fine-grained capabilities per library.

## 7. Open Research Questions

Several open questions remain for future research. We must determine if a single capability is sufficient. We might need specific capabilities for each library. We must establish typing rules for callbacks from C code. We need to decide if tainted data requires a specific type qualifier. Finally, we must understand how this capability interacts with high-assurance capabilities.

## 8. Conclusion

The tension between capability sandboxing and FFI requires explicit architectural design. Silent foreign function calls destroy the security model. By introducing `UnsafeFFICap`, we make the boundary deliberate and visible. This architecture allows necessary interoperability. It maintains strict control over system authority.

## 9. References

- Miller, M. S. (2006). Robust Composition: Towards a Unified Approach to Access Control and Concurrency Control.
- CHERI Alliance. (2023). Discover CHERI: Rust and CHERI.
- Vale. (2023). Fearless FFI.
- In-Process Isolation Research. (2023). Friend or Foe Inside? Exploring In-Process Isolation. arXiv:2306.08127v2.

---
*Series index: [README.md](./README.md).*
