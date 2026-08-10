# RP-4.3.1: Cross-language LTO

| Field | Value |
|-------|--------|
| **Paper ID** | `RP-4.3.1` |
| **DESIGN.md** | §4 Targets — Advanced Toolchains → Cross-Language LTO |
| **Status** | `draft` |
| **PM.md row** | `4.3.1` (**not-started**) |
| **Product mapping** | Not implemented. It requires an LLVM-class IR that is shared with C++ and Rust. |

## 1. Why this is in DESIGN.md

DESIGN.md §4:

> **Cross-Language LTO:** You link directly with C++ and Rust. The LLVM backend optimizes them together. There is no FFI performance decrease.

Foreign Function Interface (FFI) usually stops inlining and cross-module IPO. Each side sees a hidden external symbol. **Link-Time Optimization (LTO)** keeps the IR until link time. Then, the optimizer can inline and specialize code across translation units. **Cross-language LTO** does this across rustc and clang bitcode boundaries.

For openOODA, the goal is: You call a Rust cryptography crate or a C++ physics engine. You do not lose performance. You do not pretend that C ABIs are fast at `-O0`.

## 2. Problem statement

### 2.1 FFI problems

Classic C ABI calls:

- Stop the inlining of small wrappers.
- Cause data spills and ABI changes.
- Stop devirtualization and constant propagation across the boundary.
- Cause "rewrite it in one language" rules.

### 2.2 DESIGN problems with capabilities

§6.3: C/C++ FFI is a planned capability breach (`&UnsafeFFICap`). LTO **does not** give back capability tracking inside foreign IR. When you optimize across the boundary, you can **inline unsafe foreign code into openOODA functions**. This increases the trusted area of a single code generation unit.

The problem: You must get more performance. But, you must not show foreign unsafety as "pure openOODA."

## 3. Related work

### 3.1 LLVM LTO / ThinLTO

LLVM can wait to optimize until link time. **ThinLTO** works better for large projects than full LTO. ThinLTO uses summary-based cross-module imports.

### 3.2 Rust and C/C++ cross-language LTO

The Rust project and the LLVM blog show **linker-plugin LTO**. You compile Rust with `-C linker-plugin-lto`. You compile C/C++ with the correct clang LTO. The linker plugin optimizes a mixed graph. You must have **compatible LLVM versions** for rustc and clang. This is difficult to do. Red Hat tools show that shared LLVM packages help.

Mozilla and other companies used cross-language ThinLTO for large codebases like Firefox.

### 3.3 Limitations

- Languages that do not use LLVM (like Go and many virtual machines) need different methods.
- Debug information and sanitizers make LTO complex.
- Reproducible builds must use fixed toolchains (§4.3.2).
- Hot reload (§4.2) and LTO do not work well together. Specialized code is harder to change.

## 4. Design rules for openOODA

### 4.1 Prerequisite: LLVM production path

Cross-language LTO comes after §4.1.2. Backend-C and gcc can do **gcc LTO within C**. This includes `chs_rt` and generated C. But, this is **not** a true Rust bitcode merge. You must compile everything with the same LTO type.

The planned steps:

1. **Same-language LTO:** You compile openOODA emit-C modules and runtime with `-flto`.
2. **clang LTO:** You compile openOODA LLVM emit and C.
3. **Cross-language LTO:** You use rustc and clang plugin LTO for specific dependencies.

### 4.2 Zero FFI penalty 

"Zero" is a marketing word. The real goals are:

- **No extra abstraction**. You get what mono-language LTO gets for the same IR.
- You inline small leaf functions from C into openOODA hot loops.

You still have costs: unsafe boundary review, build complexity, and toolchain pins.

### 4.3 Capability tracking

- You **must** mark functions that use cross-language LTO with non-openOODA translation units. You mark them with `&UnsafeFFICap` (or similar) at the openOODA source boundary. You do this even if the call is inlined later.
- Optional: Use a linker plugin deny-list for functions with secret data (this is for research).

### 4.4 Self-host purity

The product compiler is only `.oo`. LTO is a **link instruction** for **user applications**. LTO is not a reason to use a Rust host compiler for `oodac` again.

## 5. Threat and failure model

| Issue | Risk |
|-------|------|
| You inline foreign undefined behavior into openOODA code. | You get incorrect code or memory corruption. You blame the wrong part. |
| Toolchain versions do not match. | You get silent incorrect code or a plugin crash. |
| Link times increase. | You slow down the OODA loop if you use this on every development build. |
| Supply chain risk. | You have more LLVM parts to manage. |

**What this does not do:** It does not give memory safety inside C++ or Rust. Rust helps on its side. C does not.

## 6. Alternatives considered

| Alternative | Verdict |
|-------------|---------|
| **Accept FFI performance decrease** | Simple. This is good for rare calls. |
| **Rewrite dependencies in openOODA** | Pure. But the ecosystem grows slowly. |
| **Use gcc LTO only (C world)** | This is a good temporary step for Backend-C. |
| **Make a full custom IPO** | This is making things again. Do not do this. |
| **Use cross-language ThinLTO** | This is the DESIGN target. Do this after the LLVM floor. |

## 7. Product reality (alpha status)

**PM.md `4.3.1` = not-started.**

- There is no linker-plugin LTO instruction in the product scripts.
- The LLVM path is only **smoke**. It is not for production.
- Backend-C links with normal gcc. LTO flags are not a product feature.
- The DESIGN text "zero FFI penalty" is a **goal**.

## 8. Open research questions

1. Compare default **development** profiles (no LTO) to **release** profiles (ThinLTO).
2. How do you mark FFI that is "LTO-safe" versus opaque FFI?
3. How does this work with polymorphic or metamorphic binaries (§3.11, §6.1)?
4. How do you distribute the openOODA equivalent of Rust rlibs as bitcode?
5. What is the CI cost of sanitizers and LTO?

## 9. Acceptance criteria (for PM status promotion)

### not-started → smoke

- [ ] Write the instructions: openOODA LLVM bitcode + C file, ThinLTO link, and one observed inlining (optimization remarks).
- [ ] Write the fixed toolchain versions in the document.

### smoke → partial

- [ ] Add the user command flag `--lto thin|full|off`.
- [ ] Make sure capabilities are still necessary on FFI entry points.
- [ ] Show a benchmark with a clear performance increase on a small test.

### partial → done

- [ ] Support this matrix: clang and openOODA. The rustc plugin path is optional.
- [ ] Make reproducible LTO notes with §4.3.2.
- [ ] Change the DESIGN text from absolute "zero" if necessary.

## 10. References

1. LLVM Blog: "Closing the gap: cross-language LTO between Rust and C/C++" (2019). https://blog.llvm.org/2019/09/closing-gap-cross-language-lto-between.html
2. rustc book: linker-plugin LTO. https://doc.rust-lang.org/rustc/linker-plugin-lto.html
3. Red Hat Developer: cross-language LTO with toolsets. https://developers.redhat.com/blog/2020/03/18/cross-language-link-time-optimization-using-red-hat-developer-tools
4. ThinLTO (Clang docs). https://clang.llvm.org/docs/ThinLTO.html
5. openOODA: `DESIGN.md` §4, §6.3; `PM.md` 4.3.1; `RP-4.1.2`.

---

*Series: [Research papers index](./README.md). Related: [RP-4.1.2 LLVM](./RP-4-1-2-production-llvm.md), [RP-6.3 Caps vs FFI](./RP-6-3-tension-caps-vs-ffi.md).*
