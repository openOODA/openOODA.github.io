# RP-4.2: Native hot-code reloading

| Field | Value |
|-------|--------|
| **Paper ID** | `RP-4.2` |
| **DESIGN.md** | §4 Targets — Native Hot-Code Reloading |
| **Status** | `draft` |
| **PM.md row** | `4.2` (**not-started**) |
| **Product mapping** | Not implemented. It needs a VM or runtime. The current `run` command does not use this runtime. |

## 1. Context from DESIGN.md

DESIGN.md §4 states:

> **Native Hot-Code Reloading:** The JIT VM can swap new ASTs into the running process. This lets developers edit code without losing the active application state.

Hot reload is a feature for **long-lived** processes. Examples include game loops, agent workers, local daemons, and embedded sessions. With AST patching (§2.1, §2.2b `replace_fn`), the process is:
1. An agent patches a function.
2. The VM swaps the bytecode or AST.
3. The system keeps the current state.
4. The process continues.

**Critical dependency:** DESIGN links hot reload to the **JIT VM**. The current alpha product does **not** have a JIT VM. The `ooda run` command uses **native Backend-C**. This document treats hot reload as justified by DESIGN. Native AOT hot reload is a different and harder problem than VM swap.

## 2. Problem statement

Without hot reload, the system has these problems:

1. **Restart penalty:** You lose in-memory state, open connections, and agent context.
2. **Slow agent loops:** Every patch causes a full rebuild and execution (Backend-C). This occurs even if you only change one function body.
3. **Rigid live systems:** You cannot apply supervised upgrades (like Erlang). High-availability goals are not possible.

With naive hot reload, the system has these problems:

1. **ABI skew:** New code can expect different struct layouts.
2. **In-flight frames:** Old code remains on the execution stack.
3. **Capability forgery:** Reloaded code can increase access rights if you do not check the types again.
4. **State migration:** You must migrate state manually. It does not happen automatically.

## 3. Related work

### 3.1 Erlang/OTP hot code loading

Erlang is the standard for **production** hot upgrades. Two versions of a module can exist at the same time. Processes migrate when the next call occurs. The `code_change` callbacks manage the state. Developers must use strict versioning and upgrade paths. Elixir uses the same BEAM capabilities.

### 3.2 Java HotSwap

JVM debugger HotSwap only lets you change the **method body**. You need external tools (like DCEVM or HotSwapAgent) to add fields or methods. These limits occur because optimized JIT code connects tightly to class layout. A system cannot optimize runtimes if it allows you to swap everything.

### 3.3 Live coding and dynamic languages

Common Lisp, Smalltalk, Clojure, and game engine scripts allow you to redefine code interactively. Systems languages often use plugins (like `.so` files via `dlopen`) with a strict ABI.

### 3.4 Native plugin reload

You can load new shared objects with `dlopen` or `LoadLibrary`. This works for C ABIs, but it removes whole-program optimization. It needs stable interfaces. Global process state remains difficult to change. Cross-language LTO (§4.3.1) conflicts with hot reload of leaf objects.

## 4. Design rationale for openOODA

### 4.1 Preferred model: VM-first

This model aligns with the DESIGN text:

```text
check + typecap ──► bytecode module
                      │
running VM  ◄── swap function or module at safe point
   heap and state retained
```

- We reuse the bytecode engine (§4.1.1).
- Safe points occur between agent loop turns, at a yield, or when a message arrives (§5.3).
- The system must reject the swap if the AST patch fails type checks or capability checks.

### 4.2 Integration with surgical patch

The command `ooda patch --replace-fn` edits the source code. The hot reload pipeline is:

1. Patch the source code or receive an AST difference.
2. Check the function again in the module context.
3. Make bytecode for that function.
4. Publish the function atomically into the VM function table.
5. Optional: Keep old versions for in-flight calls.

### 4.3 Native Backend-C path

For AOT native code, the rules are:

- Reload the **dynamic library** of the patched module only.
- The system does **not** do a zero-copy AST swap.
- Changes to struct layouts need a full restart.
- You must run `requires` contracts again on entry after the swap.

This is a **different feature**. Do not call it DESIGN "JIT VM" reload.

### 4.4 Capabilities and security

A reload must not do these things:

- Grant new sealed capabilities that the process manifest does not list.
- Go around `#[Secret]` sinks.
- Accept unauthenticated network modules. All modules need §5.2 verification.

## 5. Threat and failure model

| Threat | Mitigation |
|--------|------------|
| Malicious patch during operation | Require authentication. Run checks. Validate capabilities again. |
| Type confusion after layout change | Reject reloads that change layouts, or use version schemas. |
| Split brain (old and new logic active) | Use version gates. Allow only one writer to publish. |
| Resource leaks from old code | Use Automatic Reference Counting (ARC) and a strict module unload policy. |

The system **does not prevent**:
- Logical errors in the new code.
- Existing data corruption in the heap.
- Attackers with full process write access. (These attackers can modify memory directly).

## 6. Alternatives considered

| Alternative | Verdict |
|-------------|---------|
| **Restart-only** | The current product does this. It does not meet DESIGN goals. |
| **Erlang-level OTP** | Ideal for the long term, but requires a very large runtime. |
| **Java-like body-only** | A practical first step for the VM. |
| **Always dlopen** | Not good for a pure self-host system. |
| **Container redeploy** | This is an operations task. It does not improve the language developer experience. |

## 7. Current product status

**PM.md `4.2` = not-started.**

| DESIGN assumption | Actual product |
|-------------------|----------------|
| The **JIT VM** swaps code. | There is **no product JIT VM**. The bytecode is only an interpreter test. |
| The `ooda run` command keeps the process and swaps the AST. | The `ooda run` command does a **native build and execute** every time. |
| The system keeps live state during edits. | This feature is **not available**. |

**Wording problem:** DESIGN §4.2 speaks as if the §4.1.1 JIT already operates. The product must have a VM engine first. Until then, hot reload is blocked or we must design it again for native code.

The `replace_fn` patch **does** work for **files on disk**. It does not work for a live process image.

## 8. Open research questions

1. Should we use single or dual versions for modules? (Like the Erlang 2-version rule).
2. How do safe points operate with MaxCycles and shadow-state (§3.10)?
3. How does this interact with temporal memory (§3.8)? Do we use rollback or new code?
4. What is the agent protocol? (For example: LSP incremental compile and reload notification).
5. Do we require a REPL or daemon base?
6. What are the formal rules to define which AST nodes we can hot-swap?

## 9. Acceptance criteria (for status change)

### From not-started to smoke

- [ ] A running bytecode process can replace **one pure function body** and continue.
- [ ] A failed check stops the swap. The process continues to run.
- [ ] If the engine is an interpreter and not a JIT, the documents state this clearly.

### From smoke to partial

- [ ] The system can swap at the module level. It has a state migration hook or it explicitly rejects the swap.
- [ ] The system checks capabilities again during a swap.
- [ ] There is a test suite for in-flight calls.

### From partial to done

- [ ] The system supports multi-module applications. It documents limits for layouts and threads.
- [ ] The DESIGN text changes if the engine is not a JIT.
- [ ] We identify the optional native-dlopen path as a separate item.

## 10. References

1. Erlang/OTP hot code loading practice: https://underjord.io/how-i-use-erlang-hot-code-updates.html
2. Elixir hot reloading guides: https://blog.appsignal.com/2021/07/27/a-guide-to-hot-code-reloading-in-elixir.html
3. Java HotSwap limits: https://www.jrebel.com/blog/java-hotswap-guide; HotswapAgent: https://github.com/HotswapProjects/HotswapAgent
4. openOODA: `DESIGN.md` §4; `PM.md` 4.2; `RP-4.1.1`; product `patch`/`replace_fn` versus process image.

---

*Series: [Research papers index](./README.md). Related: [RP-4.1.1 Bytecode VM](./RP-4-1-1-development-bytecode-vm.md), [RP-2.2b replace_fn](./RP-2-2b-surgical-patch-replace-fn.md).*
