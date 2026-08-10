# RP-4.x: Backend-C Architecture

## Abstract

This document proposes the C programming language as a theoretical backend target for a self-hosting compiler system. A self-hosting systems language requires a fundamental method to compile source code and communicate with the host operating system. We propose Backend-C to serve as this primary foundation. This theoretical design removes the need for complex toolchains or interpreters during the initial bootstrap phase. This document details the proposed backend architecture, the bootstrap sequence, and the security boundaries that isolate the C code from the primary language logic.

## 1. Introduction

The design of a self-hosting compiler requires a careful selection of backend targets. Complex compiler systems often use LLVM, WebAssembly, or custom Just-In-Time (JIT) execution engines. These engines introduce significant complexity and external dependencies. A robust compiler must possess the capability to bootstrap itself from a minimal set of tools.

To resolve this challenge, we present a theoretical C backend (Backend-C) as the primary foundation. This backend operates as an intermediate representation layer. The compiler translates the high-level source code into standard C text. A standard system compiler then compiles this text into a native executable program. This theoretical procedure ensures that the compiler can operate on any computer that provides a standard C compiler.

The use of C as a portable assembly language is an established technique. Many academic compilers utilize this method. It provides immediate access to existing optimizers, debuggers, and system libraries. Most importantly, it removes the dependency on external language hosts.

## 2. Architecture and Methodology

The proposed Backend-C architecture consists of three distinct phases. The first phase is the emit phase. In this phase, the compiler reads the verified abstract syntax tree and generates C code. This process maps high-level operations directly to standard C structures.

The second phase is the runtime environment. The runtime contains a minimal layer of C code. This code provides the Application Binary Interface (ABI). It handles the communication between the compiled program and the host operating system. It manages fundamental functions such as memory allocation and system calls.

The third phase is the link phase. Build scripts start the system compiler. The system compiler compiles the generated C text and the runtime code together. This final step creates the native binary file. The system enforces strict package boundaries. These boundaries ensure that the compiler frontend does not depend on the C generation logic.

The theoretical bootstrap procedure relies completely on this Backend-C architecture. The system uses a trusted seed binary. A user starts a basic shell script. This script uses the system C compiler to build the new compiler from its C source form. When this procedure completes, the new compiler can compile the original source code. This mechanism guarantees a clean start without complex package managers.

## 3. Threat and Failure Analysis

The use of a C backend introduces specific risks. The C language does not guarantee memory safety. Errors in the runtime code can cause incorrect system behavior. The proposed design decreases this risk by keeping the runtime layer extremely small.

Another risk is the dependence on a specific C compiler implementation. The backend writes standard, strictly compliant C code to ensure compatibility with different compilers. The system also uses static capability checks. These checks isolate the runtime code from the pure language logic.

The Backend-C design provides essential capabilities. It creates native binary files. It permits debugging with standard tools. It supports the primary self-hosting procedure. The theoretical limits of this method include the lack of Link Time Optimization (LTO) across different languages. It also lacks features for hot-code reloading.

## 4. Conclusion

Backend-C provides a stable and reliable theoretical foundation for a self-hosting compiler. It meets the strict requirement for a self-hosted bootstrap procedure without the use of complex external tools. The strict separation of the emit phase, the runtime, and the link phase creates a highly modular architecture. This method relies on a C compiler, but it successfully establishes a clean, self-sufficient build environment. The system maintains strict boundaries to control the inherent risks of the C language. Backend-C serves as the primary theoretical mechanism to make native execution and complete project self-hosting possible.

---
*Series index: [README.md](./README.md).*
