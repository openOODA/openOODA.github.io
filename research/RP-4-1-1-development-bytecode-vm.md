# RP-4.1.1: Development bytecode VM

| Field | Value |
|-------|--------|
| **Paper ID** | `RP-4.1.1` |
| **DESIGN.md** | Section 4 Targets — Multi-Target Engine Architecture → Development JIT (`ooda run`) |
| **Status** | `draft` |
| **PM.md row** | `4.1.1` (**partial**) |
| **Product mapping** | Interpreter tests exist. The product `ooda run` uses **native Backend-C**. It does not use a VM. |

## 1. Reason for inclusion in DESIGN.md

Section 4 of DESIGN.md specifies a **Development JIT** procedure:

> **Development JIT (`ooda run`):** Fast execution in less than one millisecond with an internal bytecode VM.

The design goal is clear. The OODA-loop procedure (Section 1) requires the fastest possible edit, validate, and run cycle. A bytecode virtual machine (VM) gives fast startup times and portable semantics. It is also a good environment for future features (such as hot-code reloading in Section 4.2, cycle quotas, and sandboxes). You do not have to wait for a full native optimization procedure.

This document explains why a bytecode execution layer is necessary in DESIGN.md. It shows the difference between an **interpreter** and a **JIT** compiler. It also documents the difference between the planned "JIT" in DESIGN.md and the current product. The current product uses interpreter tests and a permanent native `run` command.

## 2. Problem statement

### 2.1 Problems without a fast internal procedure

| Stakeholder | Failure mode |
|-------------|--------------|
| **Human developer** | Each small change causes delays for output, link, and execution operations. Feedback times are longer than the goals of one second or one millisecond. |
| **AI agent** | Small patch cycles (Sections 2.1–2.2) stop because of link times. Agents fail because of time limits. |
| **Security and limits** | It is difficult to add tools to native binaries for MaxCycles, pure-function replay, and time or entropy limits. You need a host that controls the instruction stream. |
| **Hot reload (Section 4.2)** | It is easy to change ASTs in an active procedure in a VM. It is difficult to restart a full procedure for a gcc-linked binary. |

### 2.2 Definitions: JIT, interpreter, and bytecode VM

The software industry mixes three different items:

1. **Tree-walk interpreter**: Reads AST nodes. This is slow and simple.
2. **Bytecode VM (interpreter)**: Compiles code to small opcodes. Runs opcodes in a loop (for example, CPython).
3. **JIT (Just-In-Time) compiler**: Changes frequently used bytecode into native machine code during operation (for example, V8, JVM HotSpot, LuaJIT, PyPy).

DESIGN.md writes, “Development **JIT** … via a built-in **bytecode VM**.” This sentence mixes item 2 and item 3. A bytecode VM can be an interpreter only. A JIT compiler is an optional second step. To be correct for openOODA:

- **DESIGN.md goal**: Bytecode and a future JIT compiler. This will give operation times of less than one millisecond and good continuous speed.
- **Current product (alpha)**: Bytecode **interpreter** tests exist (M6 partial). The product `ooda run` is **not** that VM.

## 3. Related work

### 3.1 Bytecode VMs as the standard middle layer

Bytecode is a portable intermediate format. A system can interpret bytecode faster than source code or an AST. Bytecode is less expensive to make than machine code. Systems usually compile source code to bytecode one time. Then, they execute the bytecode on a virtual instruction set architecture (ISA). This ISA uses a stack or registers.

- **CPython** compiles code to stack bytecode and interprets it. It is **not** a JIT compiler. (Other versions, like PyPy, add a tracing JIT compiler).
- **Lua** uses a register-based bytecode VM. **LuaJIT** adds a fast interpreter and a tracing JIT compiler to that model.
- **JVM and V8** use bytecode (or a similar format) as the input for multi-level interpretation and JIT compilation.

Engineers agree on this rule: A good bytecode interpreter is much faster than a basic AST interpreter. A JIT compiler is the next step when performance data shows a need for the complex design.

### 3.2 Differences between interpreters and JIT compilers

| Property | Bytecode interpreter | JIT compiler |
|----------|----------------------|--------------|
| Initial startup time | Excellent | Not as good (must compile and prepare) |
| Maximum data speed | Acceptable to good | Almost native speed on used paths |
| Cost to make | Moderate | High (complex interactions) |
| Consistent results | Easy to control | Can be inconsistent because of data collection |
| Sandbox and cycle counts | Easy (in the operation loop) | Needs safety points and special tools |
| Live replacement | Easy at function or module borders | Difficult after the system optimizes machine code |

For **development** targets, initial startup time and consistent results are more important than maximum calculation speed. This matches the OODA-loop priority of openOODA.

### 3.3 Good design patterns to copy

- **Multi-level execution** (JVM, V8): Start with the interpreter. Improve frequently used code later.
- **Register bytecode** (Lua, many new VMs): Uses fewer stack operations than stack machines.
- **Direct threading or computed goto** operation (LuaJIT, many C VMs): Decreases prediction errors when the system operates opcodes.
- **Separate development and production engines** (DESIGN.md multi-target): Use the interpreter for `run` commands and tests. Use AOT or LLVM for the final software release.

## 4. Design reasons for openOODA

### 4.1 Function in the multi-target architecture

```text
.oo ──► oodac frontend (lex/parse/check)
              │
              ├─► Backend-C (product floor today) ──► gcc ──► native
              ├─► Bytecode emit + VM  (DESIGN dev path; partial smoke)
              ├─► LLVM IR emit       (smoke)
              └─► WASM emit          (smoke)
```

The bytecode VM is the test environment for semantics:

- **Capability-aware execution**: The VM checks capabilities again at sealed calls in the operation loop. This adds to the static check.
- **Contracts**: The `requires` and `ensures` commands can stop an operation without killing the procedure. The host must control the frames to do this.
- **Fuzz and pure domains**: The VM does consistent replays without operating system time differences when the system denies `TimeCap` or `RandCap`.
- **Hot-code reloading (Section 4.2)**: The system can replace function bodies or modules. The system keeps the heap graph if the ABI rules do not change.

### 4.2 Interactions with the OODA-loop and agents

Agents use `check`, `patch --replace-fn`, and short `run` cycles. A VM does these tasks:

1. Loads data from an AST or a bytecode cache.
2. Starts in less than 1 millisecond for small programs.
3. Sends JSON diagnostic data when an error occurs.

This VM increases the number of agent cycles per second. Native Backend-C is correct and is the path for **self-hosting**. The VM is the path for **low latency**. It does not replace production binaries.

### 4.3 Definition of "less than one millisecond"

Operation times of less than one millisecond are possible for **very small** scripts on an active procedure (daemon or REPL). A full initial startup of a multi-module compiler for self-hosting will take more than one millisecond on all engines. Read the DESIGN.md document to mean an *interactive unit of work*, not a *full fixed_point*.

## 5. Threat and failure model

### 5.1 Threats that a bytecode VM prevents

| Threat | Defense mechanism |
|--------|-------------------|
| Uncontrolled CPU use in unverified code | `MaxCycles` or a fuel counter in the operation loop |
| Inconsistent tests | Deny the wall-clock or entropy if capabilities are not present |
| Agent runaway loops | Strict cycle limits and memory limits on the host |
| Unknown semantic changes compared to native code | Shared frontend and standard tests across all backends |

### 5.2 Threats that a bytecode VM does not prevent

- Memory errors **inside** the VM host, if the host uses C or unsafe code.
- Side channels, if the same procedure mixes verified and unverified users without separation.
- Supply-chain attacks on the **seed** code that builds the VM.
- Statements that claim "JIT performance" when only an interpreter is available.

### 5.3 Failure modes of the text in DESIGN.md

If we advertise a "Development JIT" but we only supply interpreter tests (or a native-only `run`), it is a failure of **documentation integrity**. Use these terms instead:

- Write "Development bytecode interpreter (`ooda run --engine bc`)" for the available software path.
- Write "Optional multi-level JIT" as a separate item for the future.

## 6. Alternative options

| Alternative option | Advantages | Disadvantages | Decision |
|--------------------|------------|---------------|----------|
| **AST tree-walk only** | Fastest to build | Too slow. MaxCycles counting is difficult. | Do not use as the only engine. |
| **Always native (Backend-C only)** | Simple product description. Available now. | Link time delays. Weak hot-reload ability. | **Minimum product** for run or self-host. Does not meet full DESIGN.md goals. |
| **Interpreter now, JIT compiler later** | Honest. Incremental. | DESIGN.md text claims "JIT" incorrectly. | **Preferred engineering path**. |
| **Full JIT compiler first** | Maximum speed | High cost. Inconsistent results. Delayed release. | Do not use for the alpha version. |
| **Wasmtime-as-dev-VM** | Uses an available, mature engine. | Goes against the host language and purity policy. Adds a large dependency. | Optional for the future. Do not use for the first pure `.oo` release. |
| **Cranelift or LLVM JIT only** | Good code generation. | Too heavy for an edit loop of less than one millisecond. Slow initial startup. | Better to use for the production optimization path. |

## 7. Product reality for the alpha version

**PM.md row `4.1.1` = partial.**

| Claim | Reality (v0.183.x-alpha class) |
|-------|--------------------------------|
| DESIGN.md: Development **JIT** | **Goal**. A product JIT compiler is not available. |
| DESIGN.md: Bytecode VM for `ooda run` | **Difference**. The product `ooda run` is a **native build and execute** process. It uses Backend-C (emit-c, gcc, and `chs_rt`). Permanent product choice: `run` does not use the interpreter. |
| Bytecode interpreter | **Tests only** (`bc_*.oo`, M6 PARTIAL). This is an interpreter. It is not a JIT compiler. |
| Self-host or fixed_point | **Backend-C only**. |

### 7.1 Text conflicts in DESIGN.md

| Phrase in DESIGN.md | Correct text for PM.md and README.md |
|---------------------|--------------------------------------|
| "Development **JIT** (`ooda run`)" | "Development **bytecode interpreter** (optional engine). The product `ooda run` uses **native Backend-C** until we change the engine." |
| "Fast execution in less than one millisecond with an internal bytecode VM" | "Target time limit for small programs on a bytecode engine. This limit does not apply to a full self-host rebuild." |

See also: `ooda/README.md` ("Host interpreter: Permanent product choice: `ooda run` = native only"), `bootstrap/P4_DROPS.md`, and `PM.md` M6.

**Section 7 rule**: Do not describe the product `ooda run` as a JIT compiler or as the DESIGN.md bytecode VM. Wait until the tests and CLI semantics change on purpose.

## 8. Open research questions

1. **Register bytecode or stack bytecode** for the openOODA CHS surface (lists, strings, and sealed capabilities)? Which option is easier to translate from the checked AST?
2. **Shared Runtime ABI** with Backend-C (`RUNTIME_ABI_v0.md`): Can the VM call the same `oo_*` functions without a duplication of semantics?
3. **Daemon mode** for times of less than one millisecond: Can we keep `oodac` active and only compile changed modules? (This connects to LSP in Section 5.7).
4. **When to use a JIT compiler:** What are the limit metrics (loop iterations, agent batch size) that make the complex design necessary?
5. **Capability tokens in the VM:** Should we use local magic tokens for the procedure, or cryptographic object-caps at the operation sites?
6. **Semantic parity test suite:** What is the smallest group of tests that must match Backend-C, LLVM tests, and WASM tests?

## 9. Acceptance criteria to change PM status

### 9.1 From partial to done (interpreter product path)

- [ ] Add a documented engine selector (for example, `ooda run --engine bc|native`). Unrecognized values must cause a **fail-closed** condition.
- [ ] Ensure that the bytecode generation and interpretation cover the CHS test group. This is the same test group that we use for Backend-C parity.
- [ ] Add cycle or fuel counting for pure integer loops.
- [ ] Add a note to README.md and DESIGN.md: The available software uses an "interpreter", not a "JIT". A JIT compiler is a future goal.
- [ ] Add a continuous integration (CI) test for bytecode tests. This test must not require a JIT compiler.

### 9.2 From done to JIT (only if DESIGN.md keeps the word "JIT")

- [ ] Build a minimum of one level that generates native code for frequently used functions, **or** change DESIGN.md to remove the word "JIT".
- [ ] Write a consistency policy for the JIT compiler. (Set this to off by default for tests).

Until you complete these criteria, you must correct the documentation text. Do not write about features that do not exist.

## 10. References

1. Nurkiewicz, T. "JIT: bytecode, interpreters and compilers." Around IT in 256 bytes, 2020. https://nurkiewicz.com/2020/10/jit.html  
2. "Bytecode Compilation: Under the Hood in Different Programming Languages." Medium overview of bytecode vs JIT. https://thamizhelango.medium.com/bytecode-compilation-under-the-hood-in-different-programming-languages-b42267255324  
3. Stack Exchange: tree-based interpreter vs bytecode VM trade-offs. https://langdev.stackexchange.com/questions/1607/what-are-the-pros-cons-of-a-tree-based-interpreter-vs-a-bytecode-vm-based-interp  
4. CPython / PyPy / LuaJIT comparison literature (interpreter vs tracing JIT). For example: https://kipp.ly/p/jits-impls  
5. openOODA: `spec/DESIGN.md` Section 4; monorepo `PM.md` 4.1.1 / M6; `ooda/README.md`; `ooda/bootstrap/FLOOR.md`; `ooda/bootstrap/P4_DROPS.md`.

---

*Series: [Research papers index](./README.md). Template: [TEMPLATE.md](./TEMPLATE.md). Related references: [RP-4.x Backend-C product floor](./RP-4-x-backend-c-product-floor.md), [RP-4.2 Hot-code reloading](./RP-4-2-native-hot-code-reloading.md).*
