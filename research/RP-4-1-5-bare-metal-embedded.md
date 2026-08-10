# RP-4.1.5: Bare-metal embedded (`#![no_std]`)

| Field | Value |
|-------|--------|
| **Paper ID** | `RP-4.1.5` |
| **DESIGN.md** | §4 Targets — Bare-Metal Embedded (`#![no_std]`) |

## Abstract

This paper describes the bare-metal embedded environment for openOODA. The openOODA language scales from embedded hardware to global networks. The capability model is incomplete if it describes only operating system files and sockets. Embedded systems replace operating system capabilities with hardware resource tokens. These tokens include general-purpose input/output pins, universal asynchronous receiver-transmitters, and direct memory access channels. A freestanding runtime removes all portable operating system interface assumptions. This paper presents a complete theoretical architecture for a freestanding openOODA environment.

## Introduction

The openOODA architecture specifies a bare-metal embedded target. This target replaces operating system capabilities with hardware constraints. The capability model operates effectively on microcontrollers. If a model only uses system calls, it is incomplete.

Users do not need to switch from openOODA to C or Rust for microcontrollers. OpenOODA code operates correctly on freestanding systems. Safety-critical systems require static capabilities and strict contracts. 

Embedded systems operate with strict constraints. They do not have a full operating system. They have limited flash memory and random-access memory. They require a custom startup sequence. They use memory-mapped input/output registers. They manage panic conditions without stack unwinding. The openOODA embedded architecture addresses these constraints directly.

## Architecture and Methodology

### Related Work

The Rust programming language divides its ecosystem into core, allocation, and standard libraries. Freestanding binaries use a `no_std` attribute. Zephyr is an embedded real-time operating system. It operates between bare-metal systems and full Linux systems. Zephyr supplies scheduling, drivers, and networking stacks. Tock OS is a capability-oriented embedded operating system. It has a strong connection to openOODA capabilities.

Existing concepts include hardware object capabilities and the Tock capsule model. The `&GpioPin4` capability is an object-capability concept. It provides an unforgeable right to use a specific part of a peripheral.

### Design Rationale

The openOODA profile divides into three groups. The hosted profile uses a full operating system and memory allocation. The freestanding profile uses hardware capabilities and an optional memory arena. The mixed profile uses a real-time operating system heap and mixed capabilities.

Pure logic in the standard core compiles in a freestanding mode. The compiler rejects hardware operations if a function does not have the correct capability token. This function uses the same default-deny rule as the file system.

The bare-metal system architecture employs a custom backend. It uses freestanding C code, a linker script, and a basic runtime initialization. The standard runtime application binary interface does not apply to embedded systems. The system provides an embedded application binary interface with stub functions.

Embedded systems require worst-case execution time limits. Static loop boundaries guarantee these limits for interrupt handlers.

### Threat and Failure Model

The design gives several protections. It prevents the accidental use of operating system application programming interfaces on a microcontroller. It prevents peripheral register operations if the capability token is missing. It prevents the inclusion of a large hosted standard library in firmware images.

The design has theoretical limitations. It does not prevent incorrect memory-mapped input/output programming or electrical damage. It does not prevent hardware faults or electromagnetic interference. It does not prevent supply-chain risks from vendor hardware abstraction layers.

The `no_std` notation can confuse users. Users might think that Rust syntax is valid in openOODA. The specification uses a clear profile attribute to designate the embedded target.

### Architecture Implementation Alternatives

The architecture avoids a hosted-only language model. The architecture avoids a mandatory Zephyr layer because Zephyr is too large for the smallest microcontrollers. The architecture uses freestanding C code for maximum compatibility. The architecture avoids WebAssembly for embedded systems because WebAssembly lacks bare-metal performance. The architecture avoids a full copy of the Rust embedded ecosystem to maintain independence.

## Conclusion

The bare-metal embedded profile is a necessary component of the openOODA architecture. It replaces operating system capabilities with hardware tokens. It provides a default-deny security model for microcontrollers.

The theoretical model introduces several areas for subsequent research. These areas include the capability control level and the interrupt model comparison to fearless concurrency. Subsequent research includes the design of an optional memory allocation capability for embedded arenas. It includes testing procedures for pure core and hardware-in-the-loop environments. It includes policies for panics and out-of-memory errors. It includes the evaluation of polymorphic binaries on microcontroller flash memory.

## References

1. The Embedded Rust Book. https://rust-embedded.github.io/book/
2. awesome-embedded-rust. https://github.com/rust-embedded/awesome-embedded-rust
3. Zephyr Project — Rust language support documents. https://docs.zephyrproject.org/latest/develop/languages/rust/index.html
4. Zephyr migration from bare metal. https://zephyrproject.org/why-and-how-to-migrate-from-bare-metal-to-zephyr-rtos/

---

*Series: [Research papers index](./README.md). Related documents: [RP-5.4 stdlib core vs os](./RP-5-4-stdlib-core-vs-os.md), [RP-3.1 Caps](./RP-3-1-unified-capability-sandboxing.md).*
