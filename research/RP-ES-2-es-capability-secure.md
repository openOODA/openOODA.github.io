# Capability-Secure by Construction in Systems Languages

## Abstract
Standard operating systems and language interfaces provide ambient authority. This authority allows any code within a process to access system resources. This creates significant vulnerabilities to supply-chain attacks and artificial intelligence-generated code. This paper presents a capability-secure architecture for the openOODA programming language. The system denies input and output access by default. Functions must receive explicit capability tokens to interact with the network, file system, or execution environment. This architecture prevents ambient authority attacks. It also provides a secure foundation for automated code generation.

## 1. Introduction
Modern software relies heavily on third-party dependencies and artificial intelligence-generated code. Standard operating systems give ambient authority to processes. Any code inside the process can execute file operations or network requests. The system permits this if the host process has permission. The system does not check which specific library initiated the operation.

This design causes severe security problems. Hidden malicious code in a dependency operates with the full permissions of the application. Incorrectly generated code can accidentally open network connections or overwrite files. Furthermore, modules with high permissions often act as confused deputies. They perform restricted work for callers that possess low permissions.

To mitigate this, a language must be capability-secure by construction. A capability is an unforgeable token. This token identifies a resource and permits specific operations on it. A module has authority only if it explicitly holds the token. The system must enforce a default-deny policy. It must allow for the attenuation of permissions. It must also prevent sandboxed code from regaining ambient authority.

## 2. Related Work
The concept of capabilities originated in the 1960s to control permissions in multiprogrammed computations. Later work extensively examined hardware and software capability designs. Modern operating systems implement these concepts practically. Capsicum combines capabilities with UNIX. It uses file descriptors as capabilities and disables global names. The Zircon kernel in Fuchsia isolates processes automatically. It requires explicit handles for access. Hardware projects like CHERI use capability pointers to ensure memory and permission safety.

At the language level, object-capability languages encapsulate permissions within object references. The WebAssembly component model uses capability handles for host resources. Other systems reduce ambient authority but often lack full integration into the language's type system. openOODA integrates capabilities directly into the language type system and call graph. It enforces library rules during compilation.

## 3. Architecture and Methodology
The capability architecture requires explicit tokens for any input or output operation. A pure function cannot perform external operations. A function must declare a token in its signature to perform an operation. Examples include a file system capability or a network capability.

The system supports various capabilities. These include tokens for time and randomness. These tokens ensure predictable code execution. Memory limit tokens and execution cycle tokens prevent resource exhaustion. Biometric system capabilities provide the highest level of security. Unsafe foreign function interface tokens permit deliberate connections to external C or C++ code.

Integrating capabilities at the language level solves problems that external containers cannot address. Containers are too broad. They cannot restrict individual functions. Furthermore, generated code still possesses ambient authority inside the container. Language capabilities with runtime seals stop malicious code. They perfectly separate pure logic from operating system interactions.

This architecture interacts deeply with other system features. The compiler rejects generated code that attempts ambient access. This stops prompt-injection attacks. Tokens make pure functions easy to test. Resources like time and randomness are strictly controlled. If memory corruption occurs, the default-deny rules limit the potential damage.

## 4. Threat and Failure Model
This capability system prevents dependencies from accessing files, networks, or environments without explicit tokens. It prevents accidental ambient access in pure logic modules. It mitigates confused deputy attacks by enforcing argument flow. It completely prevents malicious generated code from stealing data. The compiler does not grant the generated code the necessary tokens.

The system does not prevent logic errors when a function uses a valid token incorrectly. It does not prevent kernel or runtime errors that operate below the capability checks. It does not prevent side-channel attacks between tasks. Software runtime seals do not protect against an attacker who fully controls the memory address space. True token security requires hardware support or cryptography. Furthermore, escapes through foreign function interfaces can bypass checks. They must be strictly gated by an unsafe token.

## 5. Discussion
We evaluated several alternative security models. Ambient authority with optional sandbox tags fails. Programmers easily forget the tags. Effect rows without tokens cannot easily share or reduce specific permissions. Relying solely on operating system capabilities prevents the compiler from verifying library rules statically. Implementing full cryptographic object capabilities initially is too complex. Runtime seals provide immediate product value. Identity-based access control models do not work well for untrusted packages and autonomous code.

Open research questions remain. We must determine how to transition from software magic tokens to native operating system handles. This must occur without breaking the pure self-hosting compiler. We must design syntax to ergonomically attenuate permissions for specific file paths and network hosts. We must ensure that asynchronous threads can transmit capability tokens safely. They must not accidentally create ambient authority. Finally, we must explore how verifiable package manifests interact with runtime capability tokens.

## 6. Conclusion
Capability-secure by construction is a necessary property for modern systems programming. openOODA neutralizes supply-chain attacks. It provides a safe environment for artificial intelligence code generation. It achieves this by eliminating ambient authority and requiring explicit tokens for all external operations. Integrating these checks directly into the language's type system ensures verifiable, fine-grained security. The compiler enforces this security at compile time.

## 7. References
1. J. B. Dennis and E. C. Van Horn, "Programming Semantics for Multiprogrammed Computations," Communications of the ACM, 1966.
2. H. M. Levy, Capability-Based Computer Systems, Digital Press, 1984.
3. R. N. M. Watson et al., "Capsicum: practical capabilities for UNIX," USENIX Security, 2010.
4. Fuchsia documentation, "Secure" principle and Zircon capabilities.
