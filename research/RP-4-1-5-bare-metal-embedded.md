# RP-4.1.5: Bare-metal embedded (`#![no_std]`)

| Field | Value |
|-------|--------|
| **Paper ID** | `RP-4.1.5` |
| **DESIGN.md** | §4 Targets — Bare-Metal Embedded (`#![no_std]`) |
| **Status** | `draft` |
| **PM.md row** | `4.1.5` (**not-started**) |
| **Product mapping** | No embedded or `no_std` product path; aspirational |

## 1. Purpose in DESIGN.md

DESIGN.md §4 specifies:

> **Bare-Metal Embedded (`#![no_std]`):** This replaces OS capabilities with hardware constraints, such as `&GpioPin4`, for IoT.

The executive summary states the language scales from embedded hardware to global networks. The capability model is not complete if it describes only OS files and sockets. For embedded systems, the language must replace `&FsCap` with **hardware resource tokens**, such as `&GpioPin4`, `&Uart0`, and DMA channels.

The `#![no_std]` notation is a familiar signal. It does not mean that openOODA uses the Rust standard library structure. It specifies a core language and a freestanding runtime with no POSIX assumptions.

## 2. Problem statement

### 2.1 Missing embedded support results

| Stakeholder | Problem |
|-------------|------|
| IoT and firmware | Users must switch from openOODA to C or Rust for microcontrollers. |
| Capability model | Capabilities are not complete if they model only OS system calls. |
| `std::core` logic (§5.4) | We cannot show that code runs anywhere if we do not have a freestanding profile. |
| Safety-critical systems | We lose the domain where static capabilities and contracts are most necessary. |

### 2.2 Embedded constraints

- **No OS** (or thin RTOS): There is no glibc, no process model, and limited heap memory.  
- **Memory limits:** Flash and RAM budgets are in kilobytes or megabytes.  
- **Startup sequence:** You must use a custom `Reset` function, `main` function, linker scripts, and interrupt vectors.  
- **I/O operations:** You must use MMIO registers, not a `read_file` function.  
- **Panic conditions:** You must use aborts, LEDs, or semihosting. You cannot use stack unwinding through libc.

## 3. Related work

### 3.1 Rust `no_std` ecosystem

The Rust division into `core`, `alloc`, and `std` is an industry standard:

- Use `#![no_std]` and `#![no_main]` for freestanding binaries.  
- Use PAC or HAL crates, embedded-hal traits, and RTIC or Embassy async on bare-metal systems.  
- RTOS integration is optional.

The Embedded Rust Book and the awesome-embedded-rust list give information about this software stack.

### 3.2 Zephyr RTOS

**Zephyr** is an embedded RTOS that uses C. It supports many boards, device trees, and Rust applications. It operates between bare-metal systems and full Linux systems. It supplies scheduling, drivers, and networking stacks. Documents show that RTOS abstractions are better than custom bare-metal systems when complexity increases.

Future openOODA options: You can make a pure freestanding system, or you can use Zephyr as an OS layer that supplies capabilities.

### 3.3 Other systems

- **Tock OS:** A capability-oriented embedded OS written in Rust. It has a strong connection to openOODA capabilities.  
- **C with FreeRTOS or bare metal:** This is the most common combination in the industry.  
- **WASM on microcontrollers:** This is a new and small field.

### 3.4 Capability hardware tokens

Existing concepts include hardware object capabilities, seL4-style capabilities, and the Tock grant/capsule model. In DESIGN, `&GpioPin4` is an **object-capability** concept. It gives an unforgeable right to use a part of a peripheral.

## 4. Design rationale for openOODA

### 4.1 Profile division

| Profile | Memory allocation | Capabilities | Runtime |
|---------|-------------------|--------------|---------|
| `std` or hosted | Full | OS capabilities | Backend-C or future LLVM |
| `no_std` freestanding | Optional arena | Hardware capabilities | Freestanding runtime |
| `no_std` with RTOS | RTOS heap | Mixed | Zephyr or Tock integration |

Pure logic in `std::core` must compile in a freestanding mode to align with §5.4.

### 4.2 Capability replacement

```text
Hosted:    fn log(f: &FsCap, ...)
Embedded:  fn blink(led: &GpioPin4, ...)
```

The compiler rejects GPIO operations if the function does not have the correct capability token. This uses the same default-deny rule as the file system.

### 4.3 Backend effects

A bare-metal system requires more than Backend-C with the `-ffreestanding` flag. You can use these methods:

1. Create freestanding C code, a linker script, and crt0. This is a practical first step.
2. Use LLVM embedded targets, such as `thumbv7em-none-eabihf`.
3. Create custom machine code in the future.

The Runtime ABI v0 (which includes `println`, FS, and env) does not apply to most embedded systems. We must create a **Runtime ABI-embedded v0** with stub functions.

### 4.4 Contracts and MaxCycles

Embedded systems require `#[MaxCycles]` and worst-case execution time (WCET) limits. Static loop boundaries are necessary for interrupt handlers.

## 5. Threat and failure model

### 5.1 Protections

- Prevents the accidental use of OS APIs on a microcontroller. The code will not compile.
- Prevents peripheral register operations if the capability token is missing.
- Prevents the inclusion of a large hosted standard library in firmware images.

### 5.2 Limitations

- Does not prevent incorrect MMIO programming, electrical damage, or incorrect DMA addresses if the capability control is too broad.
- Does not prevent hardware faults, electromagnetic interference, or bit flips. You must use ECC and hardware watchdogs.
- Does not prevent supply-chain risks from vendor HALs if you use FFI.

### 5.3 Syntax risks

The `#![no_std]` notation can confuse users. They might think that Rust syntax is valid in openOODA. When you write the SPEC, you must use a clear **profile attribute**, such as `#![profile(freestanding)]`, or a build target, such as `--target thumb-...`.

## 6. Alternatives considered

| Alternative | Decision |
|-------------|----------|
| Hosted-only language | Rejected. This goes against DESIGN ES.6. |
| Always use Zephyr | Rejected. Zephyr is too large for the smallest microcontrollers. It is good for mid-tier devices. |
| Only output freestanding C | Accepted as a practical minimum viable product (MVP). |
| WASM embedded | Rejected. It offers an interesting sandbox, but it does not have bare-metal performance. |
| Copy the Rust embedded ecosystem | Rejected. This is a different language. We only use their ideas. |

## 7. Current status

**PM.md `4.1.5` status is not-started.**

- The current runtime requires a hosted POSIX surface (for example, `chs_rt` for FS, print, and process).  
- There is no `no_std` profile flag, no GPIO capabilities, and no linker-script path in the product.  
- The Backend-C and gcc self-host system operates in Linux userspace.

You must not claim IoT readiness in alpha communications.

## 8. Open research questions

1. **Capability control level:** Should we use pins, ports, buses, or DMA channels?  
2. **Interrupt model:** How does this compare to fearless concurrency (§5.3)?  
3. **Memory allocation:** Can we use an optional `AllocCap<N>` on embedded arenas?  
4. **Testing procedures:** How do we perform host-side unit tests of the pure core and hardware-in-the-loop (HIL) tests on hardware?  
5. **Panic and OOM policies:** What is the policy for panics and out-of-memory errors without the standard library?  
6. **Polymorphic binaries:** How does this relate to polymorphic binaries (§3.11)? We will probably disable them because of microcontroller flash wear.

## 9. Acceptance criteria

### From not-started to smoke

- [ ] The freestanding profile builds a blink program or a semihosting print program for one board or a QEMU machine.  
- [ ] The freestanding profile rejects hosted file system APIs.  
- [ ] You document the linker and flash steps.

### From smoke to partial

- [ ] The compiler statically enforces at least one hardware capability type.  
- [ ] The CI system tests the `std::core` subset on a freestanding profile.  
- [ ] You add notes about memory budgets.

### From partial to done

- [ ] You write a multi-board or multi-architecture policy.  
- [ ] You write a SPEC section for the freestanding ABI.  
- [ ] You write an accurate support matrix that shows what the system does not cover.

## 10. References

1. The Embedded Rust Book. https://rust-embedded.github.io/book/
2. awesome-embedded-rust. https://github.com/rust-embedded/awesome-embedded-rust
3. Zephyr Project — Rust language support documents. https://docs.zephyrproject.org/latest/develop/languages/rust/index.html
4. Zephyr migration from bare metal. https://zephyrproject.org/why-and-how-to-migrate-from-bare-metal-to-zephyr-rtos/
5. openOODA documents: `DESIGN.md` §4 and §5.4; `PM.md` row 4.1.5; `bootstrap/RUNTIME_ABI_v0.md` (the hosted baseline).

---

*Series: [Research papers index](./README.md). Related documents: [RP-5.4 stdlib core vs os](./RP-5-4-stdlib-core-vs-os.md), [RP-3.1 Caps](./RP-3-1-unified-capability-sandboxing.md).*
