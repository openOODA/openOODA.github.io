# RP-4.1.4: Direct WebAssembly

| Field | Value |
|-------|--------|
| **Paper ID** | `RP-4.1.4` |
| **DESIGN.md** | §4 Targets — Direct WebAssembly (`ooda build --target wasm`) |
| **Status** | `draft` |
| **PM.md row** | `4.1.4` (**smoke**) |
| **Product mapping** | WASI preview1 `.wat` emit + execute smoke when wasmtime/wasm3 present; **not** product floor |

## 1. Why this document is in DESIGN.md

DESIGN.md §4 states:

> **Direct WebAssembly (`ooda build --target wasm`):** Native WASM emission for browsers and edge environments.

WebAssembly (Wasm) is the portable compilation target for the web. WebAssembly System Interface (WASI) is the compilation target for server sandboxes. The openOODA compiler must emit Wasm directly. It must not compile code to C before it compiles to Wasm. This direct compilation lets openOODA control capability semantics and binary size.

Wasm is the primary candidate for the second backend (F3) in `FLOOR.md` and `BACKEND_F3_PREP.md` (candidate **W**). Wasm proves that openOODA can use a backend other than C. Wasm uses a CHS smoke test. It does not remove Backend-C.

## 2. Problem statement

If openOODA does not have a Wasm target:

1. **Browser and edge demonstrations** need a second language or an opaque toolchain.
2. **Sandbox isolation** is weak. Wasm and WASI give industry-standard isolation. Native code uses only operating system processes and openOODA capabilities.
3. **Software portability** is low. Users must install a C compiler on their devices to run programs across different operating systems.
4. **Backend independence** is unproven. There is no proof that the frontend can work without Backend-C.

The compiler must solve these problems:
- Map the linear memory model to openOODA lists and strings.
- Map host imports to input and output (I/O).
- Choose between the Component Model and classic modules.
- Map openOODA capabilities to WASI rights.

## 3. Related work

### 3.1 Core WebAssembly

Wasm is a compact, typed bytecode. It operates on a stack machine. It uses linear memory, tables, and structured control flow. Wasm operates safely in multi-tenant environments like browsers. Developers can predict its validation.

### 3.2 WASI (WebAssembly System Interface)

WASI makes standard interfaces for host capabilities. These capabilities include files, clocks, random numbers, and network sockets. WASI is capability-oriented. Preview1 used a witx world. **WASI 0.2 and later** use the **Component Model** with WebAssembly Interface Type (WIT) interfaces. This aligns with openOODA capabilities, which deny access by default. The capability mapping requires careful work.

### 3.3 Wasmtime and the Bytecode Alliance

**Wasmtime** is a standalone runtime for Wasm, WASI, and the Component Model. The Bytecode Alliance maintains it. Wasmtime is the default runtime for continuous integration (CI) smoke tests. Other runtimes include wasm3, Wasmer, and browser engines.

### 3.4 Component Model

The Component Model shows how Wasm binaries bundle, link, and send types across isolation boundaries. The Component Model defines WASI interfaces. Components can replace `env` imports for openOODA long-term packaging.

### 3.5 Languages targeting Wasm

Rust, C/C++, Go, AssemblyScript, and Grain compile to Wasm. Many languages use the LLVM Wasm backend. Other languages emit Wasm directly. For openOODA, "direct" means the compiler uses its own emit package. OpenOODA can use LLVM in the future.

## 4. Design rationale for openOODA

### 4.1 Second backend MVP (F3)

Data from `BACKEND_F3_PREP.md`:

- Emit an artifact for a CHS smoke test.
- Execute the artifact in wasmtime or wasm3.
- Use `--backend wasm` (the final name can change) while `--backend c` remains active.
- **Do not** require full openOODA self-hosting on Wasm immediately.

### 4.2 Capability alignment

| openOODA | WASI mapping |
|----------|------------------|
| No `FsCap` | No filesystem rights or preopens |
| `TimeCap` | `wasi:clocks` allowed or denied |
| `RandCap` | `wasi:random` |
| `NetCap` | Sockets or `wasi:http` |
| Pure `std::core` | No imports except memory |

The WASI capability model controls the **host**. The openOODA static capabilities control the language. Both models must agree.

### 4.3 Browser and WASI profiles

- **Browser:** Browsers often lack full WASI. They import JavaScript code. The Document Object Model (DOM) is not in the scope of the minimum viable product (MVP).
- **Edge and CLI:** The WASI command line is the primary smoke target.

DESIGN says "browsers and edge". This means openOODA will have **two profiles**. The initial alpha smoke test targets the edge and CLI. It emits `.wat` text and references WASI preview1.

### 4.4 Relation to the product `run` command

The `ooda run` command uses the **native Backend-C**. Wasm uses the `build --target wasm` command. Wasm does not replace the `run` command.

## 5. Threat and failure model

### Advantages

- The Wasm memory safety boundary protects against untrusted modules.
- Users can distribute software without a C compiler.
- Auditors can easily see the import surface.

### Disadvantages

- The system does not prevent bugs in the **engine** (Wasmtime).
- The host can give wide access and cause a confused deputy attack.
- Shared hosts are vulnerable to side channels and Spectre-class attacks.
- The `.wat` text emit does not equal a production binary pipeline.

### Failure modes

| Failure | Mitigation |
|---------|------------|
| Developer sells smoke emit as a product WASM run | Use `P4_DROPS.md` and PM smoke test |
| Developer tries to self-host too early | Limit F3 scope to one smoke test |
| Module bypasses capabilities through host imports | Use an import linker that denies access by default |

## 6. Alternatives considered

| Alternative | Verdict |
|-------------|---------|
| **Use clang -target wasm32 from emit-C** | This works but is not direct. It links to the C shape. |
| **Use LLVM Wasm backend from openOODA IR** | This is a strong option for the future. It is heavier than the text emit MVP. |
| **Use an interpreter in the browser** | This is a different product. |
| **Use a plugin as a native .so file only** | This misses the DESIGN goal for web and edge. |
| **Embed Wasmtime in oodac** | This is possible. It affects purity and dependency policies. |

## 7. Product reality (alpha status)

**PM.md `4.1.4` is a smoke test.** M4 WASM requires PASS and a tool environment.

| Claim | Reality |
|-------|---------|
| Product WASM run rails | **No**. This is not the permanent product floor. |
| `ooda build --target wasm` or `oodac emit-wasm` | **Emit smoke test** (WASI preview1 `.wat`). Execute the smoke test when wasmtime or wasm3 is present. |
| Full second-backend self-host | **No**. |
| Component Model or WASI 0.2 | **Not** in the product surface. |

See these documents: `P4_DROPS.md`, `README.md`, `BACKEND_F3_PREP.md`.

## 8. Open research questions

1. How do we map the **string and list ABI** in linear memory against the guest allocator design?
2. When do we move from Preview1 to WASI 0.2 component emit?
3. How does the **Wasm GC proposal** compare to openOODA ARC (host-managed versus guest)?
4. What is the shared **Runtime ABI** mapping table for called CHS symbols?
5. How can we make a browser demonstration with a Wasm and JavaScript capability bridge that is pure?
6. Which Wasm engines are deterministic for reproducible CI?

## 9. Acceptance criteria (for PM status promotion)

### smoke to partial (F3-style)

- [ ] A named backend flag executes the CHS smoke test from start to finish under wasmtime.
- [ ] The ABI mapping document maps CHS symbols to Wasm imports and runtime.
- [ ] Backend-C fixed_point operates correctly (green).
- [ ] The system fails closed if the runtime is missing. It does not give a soft OK.

### partial to done

- [ ] The documentation shows a browser **or** edge profile with examples.
- [ ] The SPEC and DESIGN documents explain the map from capabilities to WASI rights.
- [ ] The release artifact has optional Wasm demonstrations with checksums.

## 10. References

1. Wasmtime documentation: https://docs.wasmtime.dev/
2. Bytecode Alliance Component Model and WASI roadmap articles: https://bytecodealliance.org/articles/the-road-to-component-model-1-0
3. Component Model book (Wasmtime): https://component-model.bytecodealliance.org/running-components/wasmtime.html
4. WASI and Component Model status surveys: https://eunomia.dev/blog/2025/02/16/wasi-and-the-webassembly-component-model-current-status/
5. openOODA documents: `DESIGN.md` §4; `PM.md` 4.1.4 and M4; `bootstrap/P4_DROPS.md`; `bootstrap/BACKEND_F3_PREP.md`; `bootstrap/FLOOR.md`.

---

*Series: [Research papers index](./README.md). Related: [RP-4.x Backend-C](./RP-4-x-backend-c-product-floor.md), [RP-3.1 Caps](./RP-3-1-unified-capability-sandboxing.md).*
