# RP-4.1.4: Direct WebAssembly

## Abstract

WebAssembly is a portable compilation target. The openOODA compiler emits WebAssembly directly. This direct compilation gives openOODA complete control over capability semantics. It also provides precise control over binary size. WebAssembly provides strong sandbox isolation. This isolation protects the system from untrusted code. This paper presents the architecture for direct WebAssembly emission. It examines the WebAssembly System Interface. It demonstrates the mapping of openOODA capabilities to the WebAssembly System Interface.

## Introduction

The openOODA compiler compiles code directly to WebAssembly. The compiler avoids intermediate compilation to C. WebAssembly operates safely in web browsers. It also operates safely in edge computing environments. A direct WebAssembly target eliminates the requirement for a C compiler. This elimination increases software portability. WebAssembly solves many portability problems. It uses a linear memory model. It uses structured control flow. The WebAssembly System Interface provides standard interfaces for host capabilities. These capabilities include file systems, clocks, and network sockets.

## Architecture

The architecture maps the linear memory model to openOODA lists and strings. It maps host imports to system input and system output. The openOODA capability model controls the language semantics. The WebAssembly System Interface controls the host interactions. Both models enforce strict capability boundaries. The openOODA system denies access by default. The WebAssembly System Interface also denies access by default.

The compiler targets two primary profiles. The first profile supports web browsers. Browsers often lack the full WebAssembly System Interface. They import JavaScript code to provide host capabilities. The second profile supports edge environments and command line interfaces. These environments provide robust WebAssembly System Interface implementations.

The WebAssembly memory safety boundary protects the host environment. It protects the host against untrusted modules. Developers distribute software easily across different platforms. Auditors analyze the import surface clearly. However, the system does not prevent bugs in the WebAssembly execution engine. The host can mistakenly grant excessive access. This excessive access can cause a confused deputy attack. Shared hosts remain vulnerable to side channels.

The WebAssembly Component Model governs how binaries bundle and link. The Component Model defines strict WebAssembly System Interface interfaces. Software components can replace environment imports dynamically. This replacement supports long-term software packaging and deployment.

## Methodology

The compiler emits the WebAssembly text format directly. The system executes this format in a WebAssembly runtime. The openOODA static capabilities map directly to WebAssembly System Interface rights. For example, the time capability maps to WebAssembly System Interface clocks. The random capability maps to WebAssembly System Interface random numbers. Pure core code requires no external imports except linear memory.

The system maps the string and list application binary interface within linear memory. The system aligns this mapping with the guest memory allocator design. The capability mapping requires precise alignment between openOODA and the WebAssembly System Interface. The compiler uses a custom emission package. Direct text emission remains highly efficient. It produces lightweight and fast compilation cycles.

## Conclusion

Direct WebAssembly emission provides significant benefits for openOODA. It provides ultimate portability and strict isolation. It successfully removes the dependency on a C compiler. The precise mapping of openOODA capabilities to the WebAssembly System Interface is critical. This mapping ensures robust system security. The complete theoretical system demonstrates a secure, portable, and efficient compilation architecture.

## References

1. Wasmtime documentation: https://docs.wasmtime.dev/
2. Bytecode Alliance Component Model and WASI roadmap articles: https://bytecodealliance.org/articles/the-road-to-component-model-1-0
3. Component Model book (Wasmtime): https://component-model.bytecodealliance.org/running-components/wasmtime.html
4. WASI and Component Model status surveys: https://eunomia.dev/blog/2025/02/16/wasi-and-the-webassembly-component-model-current-status/

---
*Series index: [README.md](./README.md).*
