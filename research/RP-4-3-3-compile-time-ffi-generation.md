# RP-4.3.3: Compile-time FFI generation

| Field | Value |
|-------|--------|
| **Paper ID** | `RP-4.3.3` |
| **DESIGN.md** | §4 Targets — Compile-Time FFI Generation; §6.3 Capability vs FFI |
| **Status** | `draft` |
| **PM.md row** | `4.3.3` (**not-started**) |
| **Product mapping** | No `import "C" "header.h"` automatic generator. Host residual FFI is not the DESIGN feature. |

## 1. Why this is in DESIGN.md

DESIGN.md §4 says:

> **Compile-Time FFI Generation:** `import "C" "sqlite3.h"` generates safe openOODA wrappers automatically at compile time.

Systems languages must operate with the C ABI ecosystem (libc, SQLite, OS APIs, vendor SDKs). Hand-written bindings decay over time. The DESIGN requires header-driven generation at compile time. This is similar to Rust bindgen and Go cgo. Section 6.3 requires these bindings to stay as an explicit capability breach (`&UnsafeFFICap`).

"Safe wrappers" means that the wrappers have correct memory layout, correct types at the openOODA surface, and capability gates. It does not mean that C code becomes safe in memory.

## 2. Problem statement

### 2.1 Without automatic FFI

- Engineers do not use useful libraries, or they copy unstable extern declarations.
- AI agents create incorrect signatures (hallucinated FFI).
- Changes in upstream headers cause undefined behavior (UB).

### 2.2 With simple automatic FFI

- The compiler pulls all system headers into the trusted compute base.
- Macros, bitfields, inline functions, and platform `#ifdef` commands make the code too complex.
- Generated APIs can show raw pointers that avoid ARC and capability limits.
- Compile times increase too much because clang parses very large headers.

## 3. Related work

### 3.1 Rust bindgen

The **rust-bindgen** tool reads C/C++ headers with libclang. It creates Rust `extern "C"` blocks and tests for layout. You usually run it from `build.rs`.
Advantages: It is automatic and makes tests for structure sizes and alignments.
Limits: C++ support is not complete. Macros need lists of approved items. Unsafe code stays unsafe.

### 3.2 Go cgo

The **cgo** tool lets Go code import a special `"C"` package. This package has comments with C declarations and headers. The toolchain makes the connection code.
Advantages: The user experience is simple (`import "C"`).
Limits: It has problems with portability (`CGO_ENABLED`), larger binary files, and cross-compilation. Users sometimes prefer code written only in Go.

### 3.3 Other generators

- **cbindgen**: Converts Rust code to C headers.
- **SWIG**: Connects many languages, but is older technology.
- **Zig** `@cImport`: Uses clang at compile time. It gave the idea for the openOODA `import "C"` syntax.

### 3.4 Safety wrappers literature

"Safe FFI" layers usually include:

- Opaque handles, not raw pointers.
- Explicit ownership for memory release (free/drop).
- Translation of null pointers and error codes to `Result` types.
- Lists of dangerous functions to block (for example, `system`, `gets`).

## 4. Design rationale for openOODA

### 4.1 Syntax and pipeline

```text
import "C" "sqlite3.h"  // DESIGN sketch
        │
        ▼
  read header (libclang or openOODA parser)
        │
        ▼
  generate .oo externs and wrapper functions
        │
        ▼
  each wrapper needs &UnsafeFFICap (§6.3)
        │
        ▼
  Backend-C/LLVM links with -lsqlite3
```

### 4.2 What "safe" means here

| Guarantee | In scope? |
|-----------|-----------|
| Correct ABI types for the supported C subset | Yes |
| Layout tests and static assertions | Yes |
| Capability token required at function call | Yes |
| Stop buffer overflow inside SQLite | **No** (foreign code) |
| Mark all foreign data returns as untrusted automatically | Should be **Yes** |

### 4.3 Lists of approved items

The production configuration must have these settings:

```text
ffi.allow = ["sqlite3_open_v2", "sqlite3_prepare_v2", ...]
ffi.header_search = [...]
ffi.deny_varargs = true
```

The generator must block all items by default for large headers.

### 4.4 Backend-C synergy

Generated wrappers can output as C prototypes and openOODA call sites. These link with the current gcc process. This does not need LLVM initially. But, a parser based on clang can add a tool dependency, similar to bindgen.

### 4.5 Agent ergonomics

A small summary of generated bindings helps AI agents (Section 2.2). If a header fails to parse, the JSON error must be precise (Section 2.1).

## 5. Threat and failure model

| Threat | Mitigation |
|--------|------------|
| Import of the full Windows.h file | Use lists of approved items; use modular headers. |
| Bypass of capability with a raw pointer export | Wrappers must not export raw operations without `UnsafeFFICap`. |
| Macro errors | Use clang to expand macros; reject macros that do not parse. |
| Malicious header injection in the supply chain | Check hashes of headers; store headers locally (vendoring). |
| Confused deputy attack | The system still needs capabilities for file system and network, even if C can do system calls. |

**§6.3 reminder:** FFI is a tracked break of the sandbox. It is not a loophole.

## 6. Alternatives considered

| Alternative | Verdict |
|-------------|---------|
| **Only hand-written bindings** | This is slow and causes errors. |
| **Only cgo-style preamble** | The user experience is good, but it still needs a generator. |
| **Bind only a stable subset (C ABI JSON)** | This is safer, but less automatic. |
| **WASM Component imports** | This uses a different ecosystem. |
| **Full C++ interop** | We postpone this. C++ headers are much more difficult. |

## 7. Product reality (alpha honesty)

**PM.md row `4.3.3` is not-started.**

- The product does not have an `import "C" "….h"` pipeline.
- Residual host symbols and optional `OODA_WITH_HOST_FFI` paths (see FLOOR/ABI notes) are **not** DESIGN compile-time generation.
- Linking the C runtime (`chs_rt`) is the basic implementation. It is not user-facing bindgen.
- The tension paper about Capabilities vs FFI applies when we finish this work.

## 8. Open research questions

1. Should we use the **libclang** dependency, or a pure `.oo` parser for a C subset?
2. How do we find ownership rules (for example, `*mut` requires memory release)?
3. How do we process functions with variable arguments and callbacks (function pointers that go into openOODA)?
4. How do we create openOODA types for structures that have padding?
5. How does static taint (`#[Secret]`) work with data returned from FFI?
6. Is the SQLite demonstration the correct path for acceptance?

## 9. Acceptance criteria (for PM status promotion)

### From not-started to smoke

- [ ] A small header (for example, `add.h`) creates a wrapper that the code can call.
- [ ] The call site typechecks only if `&UnsafeFFICap` is present.
- [ ] Backend-C links the code and runs correctly.

### From smoke to partial

- [ ] Demonstrate a list of approved items, layout checks, and `Result` error translation.
- [ ] The generator stops safely when it finds code it does not support.
- [ ] Provide documentation for the clang tool requirement **or** the pure subset parser.

### From partial to done

- [ ] The `sqlite3.h` path from DESIGN operates correctly for a basic subset.
- [ ] Define the SPEC grammar for `import "C"`.
- [ ] Add capability taint and clear error messages for incorrect use.

## 10. References

1. rust-bindgen. https://github.com/rust-lang/rust-bindgen
2. Go cgo command docs. https://pkg.go.dev/cmd/cgo
3. Practical bindgen/cgo interop writeups. For example: https://blog.arcjet.com/calling-rust-ffi-libraries-from-go/
4. openOODA: `DESIGN.md` §4, §6.3; `PM.md` 4.3.3; `RP-6.3`; `bootstrap/STATIC_CAPS.md`.

---

*Series: [Research papers index](./README.md). Related: [RP-6.3 Caps vs FFI](./RP-6-3-tension-caps-vs-ffi.md), [RP-4.x Backend-C](./RP-4-x-backend-c-product-floor.md).*
