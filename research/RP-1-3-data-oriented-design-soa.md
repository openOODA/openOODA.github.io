# RP-1.3: Data-oriented design & SoA layout

| Field | Value |
|-------|--------|
| **Paper ID** | `RP-1.3` |
| **DESIGN.md** | §1 Language |
| **Status** | `draft` |
| **PM.md row** | `1.3` |
| **Product mapping** | **not-started** — no first-class SoA / zero-copy language features in product; ordinary structs/lists only |

## 1. Why this is in DESIGN.md

DESIGN.md §1:

> **Data-Oriented Design (DOD) & Layout:** First-class support for Struct-of-Arrays (SoA) memory layouts to guarantee CPU cache-locality, and native zero-copy serialization for parsing network packets at zero CPU cost.

openOODA is a **systems** language. Performance requires more than low asymptotic complexity. It requires attention to **hardware reality**. This includes cache lines, prefetching, SIMD-friendly layouts, and I/O boundaries. The commercial game industry uses DOD and SoA to solve the performance problems of object-oriented design. Zero-copy serialization applies this concept to networks. Do not pay CPU cost to reshape bytes that have the correct form.

This item is in DESIGN for these reasons:

1. You must not treat language layout as an afterthought.
2. AI-generated code can target **declared** layouts. It will not invent accidental AoS.
3. Capability-secure networking still uses **line-rate-friendly** parsing. (Read §5 to understand "zero CPU cost" claims).

## 2. Problem statement

### 2.1 Hardware problem

Modern CPUs stall when they wait for memory. When you transform large homogeneous datasets (like particles or packets), use:

- Contiguous fields that you use together (SoA or hybrid AoSoA),
- Predictable strides,
- Minimal pointer chasing,
- Alignment for vector units.

Classic OOP/AoS (`struct Entity { pos, vel, hp, ai*; } entities[]`) pulls cold fields into the cache. This decreases memory bandwidth.

### 2.2 Language problem

If SoA is only a manual discipline:

- Agents and humans regress to AoS.
- Refactors to SoA are invasive and do not have types.
- Serialization formats are different from in-memory layouts. This causes extra data copies.

### 2.3 What breaks if omitted

- openOODA cannot compete as a systems language with layout control.
- Compiler self-host and runtime hot paths can become cache-unfriendly.
- Zero-copy network claims become marketing without a type-system.

### 2.4 Users

| Actor | Stake |
|-------|--------|
| Game / simulation / media | Frame time, entity throughput |
| Network / embedded | Packet parse/serialize cost, no_std buffers |
| Compiler authors (self-host) | Token/AST/IR tables as SoA candidates |
| AI agents | Need declarative layout, not folklore |

## 3. Related work

### 3.1 Data-oriented design (industry)

- **Mike Acton** (then Insomniac Games), CppCon 2014 keynote *Data-Oriented Design and C++*: canonical commercial articulation—“the transformation of data is the only purpose of any program”; understand data and hardware first. https://cppcon.org/third-keynote-2014/ ; talk commonly referenced: https://www.youtube.com/watch?v=rX0ItVEVjHc
- **Noel Llopis**, “Data-Oriented Design (Or Why You Might Be Shooting Yourself in The Foot With OOP)” — early game-industry essay popularizing DOD framing.
- **Richard Fabian**, *Data-Oriented Design* (book) — extended treatment used in industry teaching.
- Academic/industry survey angle: Bayliss et al., “Developing Games with Data-Oriented Design,” ACM (2022) discusses DOD’s commercial-game origins and pedagogy. https://dl.acm.org/doi/10.1145/3524494.3527626

### 3.2 ECS and commercial engines

- **Entity–Component–System** architectures as a *common* (not exclusive) DOD application: components stored in contiguous arrays keyed by entity id.
- **Unity DOTS** (Data-Oriented Technology Stack): ECS + Jobs + Burst; commercial push to SoA-like component storage and cache-aware jobs. GDC/Unity presentations on “Connecting the DOTS.”
- **Unreal Mass / Niagara**, custom AAA engine entity systems (Insomniac, etc.): production evidence that layout-conscious design ships at scale.
- **Bevy (Rust)**, **Flecs (C)**, **EnTT**: open-source ECS with archetype/SoA storage strategies—useful design patterns even if openOODA does not mandate ECS.

### 3.3 Language and compiler support

- **Jai** (Jon Blow) and game-oriented languages: culture of explicit layout and compile-time introspection.
- **Zig**: `packed`/`extern` structs, explicit alignment; comptime for generating layouts.
- **Rust**: `repr(C)`, bytemuck/zerocopy crates, columnar ecosystems; no first-class SoA keyword—library discipline.
- **ISP C / AoSoA** literature in HPC and graphics (structure-of-arrays vs array-of-structures tradeoffs; SIMD).
- **Apache Arrow / Cap’n Proto / FlatBuffers / rkyv**: zero-copy or near-zero-copy serialization ecosystems—industrial proof that “parse as load” is viable when formats are designed for it.

### 3.4 Cache and performance foundations

- Hennessy & Patterson-style memory hierarchy reasoning; mechanical sympathy literature (Martin Thompson et al.) in low-latency systems.
- Game Programming Patterns — “Data Locality” chapter (Bob Nystrom) as accessible presentation: https://gameprogrammingpatterns.com/data-locality.html

## 4. Design rationale for openOODA

### 4.1 First-class SoA (aspirational surface)

DESIGN-level intent (not product syntax yet) is that developers can declare columnar layouts, e.g. conceptually:

- A record type with storage strategy `soa` vs `aos`,
- Or explicit `SoA[T]` / table types with field vectors,
- Iteration APIs that expose field slices for hot loops.

Goals:

- Typechecker knows field vectors’ lengths stay coupled.
- Backend can emit contiguous stores and optional SIMD.
- Reflect/outline can show layout for agents.

### 4.2 Zero-copy serialization

Read "Native zero-copy serialization for parsing network packets at zero CPU cost" as follows:

- **Goal:** APIs where validated buffers operate as typed structures. You do not make per-field deserialize copies.
- **Honest physics:** Validation, checksums, and capability checks cost CPU cycles. "Zero CPU" means **no redundant copy or transform**. It does not mean zero CPU cycles.

Fit with capabilities: When you parse untrusted network bytes, you still need `&NetCap` or buffer capabilities. Zero-copy must not cause type confusion.

### 4.3 Self-host and stdlib

Compiler IR and runtime structures are good SoA candidates. The standard library split between `core` and `os` (RP-5.4) must keep pure table algorithms in `core`.

### 4.4 AI-native angle

Agents optimize what the language can express. A first-class layout declaration provides a **promptable** intent (for example, "use SoA for particles"). This is better than hoping the AI outputs manual C-style arrays.

## 5. Threat / failure model

### 5.1 What DOD/SoA help prevent

- Systematic cache thrash from AoS defaults in hot loops.
- Hidden copies at protocol boundaries when zero-copy views exist.
- Unreviewable “optimization folklore” without types.

### 5.2 What they do not prevent

- **Wrong hot/cold split** (SoA of the wrong fields).
- **Random access / entity deletion** pathologies (fragmentation, indirection tables).
- **Safety bugs**: SoA does not stop OOB, UAF, or missing caps.
- **Security**: zero-copy of hostile packets without validation is a vulnerability factory.
- **Small data**: SoA can be slower or harder for tiny structs.

### 5.3 Failure modes specific to language design

| Risk | Notes |
|------|-------|
| SoA + ARC/GC | Reference counting per element vs per column—policy needed (conflict with 3.7) |
| SoA + async / concurrent mutation | False sharing, aliasing; needs fearless concurrency story (5.3) |
| Zero-copy + lifetime | Views must not outlive buffers; temporal memory (3.8) complicates history |
| Over-ECS-ifying | Acton-style DOD ≠ mandatory ECS framework |

## 6. Alternatives considered

| Alternative | Assessment |
|-------------|------------|
| **Library-only SoA** | Viable MVP; DESIGN wants first-class for guarantees and agent clarity |
| **Only ECS framework in std** | Too opinionated; DOD is broader than ECS |
| **Always AoS + optimizer magic** | SROA/SIMD help but don’t fix large entity tables alone |
| **GPU-only path for bulk data** | Important (4.1.3) but not a substitute for CPU SoA |
| **Manual C interop for hot paths** | Breaks caps/self-host story if overused (6.3) |

**Staged approach recommended:** library patterns → language annotations → full SoA types + zero-copy codec derive.

## 7. Product reality (alpha honesty)

**PM.md `1.3` status: `not-started`.**

| Feature | Reality |
|---------|---------|
| First-class SoA types / storage qualifiers | **Absent** |
| Language-level zero-copy packet views | **Absent** |
| Ordinary `struct`, `List`, strings | **Present** (AoS-ish / general-purpose) |
| Manual DOD in user code | Always possible in any language; not a product feature |
| SIMD / GPU backends for bulk transform | GPU **not-started**; not SoA-specific |

Do **not** imply that Backend-C performance work equals DOD support. Cache-locality "guarantees" in DESIGN are **goals**. They are not compiler invariants today.

## 8. Open research questions

1. What SoA surface is **minimal** (annotations vs new kinds vs table DSL) for openOODA’s complexity budget?
2. How do SoA tables interact with **ARC/RAII** and move semantics without per-field refcount disasters?
3. Can zero-copy views be **capability-aware** (e.g. read-only packet cap) and bounds-checked without killing throughput?
4. Should compiler IR dogfood SoA early as the forcing function?
5. How to teach agents when SoA hurts (sparse, highly branching logic)?
6. Relation to **holographic persistence** (4.4): can columnar layouts persist without full rewrite?

## 9. Acceptance criteria (for PM status promotion)

### not-started → smoke

- [ ] Written layout RFC + at least one example lowering to C arrays of fields.
- [ ] One corpus sample demonstrating SoA declaration and field iteration.
- [ ] Documented non-goals (full Unity DOTS clone is out of scope).

### smoke → partial

- [ ] Product syntax parsed + typechecked for SoA (or equivalent table type).
- [ ] Backend-C emit for a supported fragment; measurable locality demo optional but desirable.
- [ ] Safety: no unchecked OOB in generated accessors.

### partial → done (MVP)

- [ ] Stable SoA MVP in language + std patterns.
- [ ] Zero-copy **buffer view** MVP for a defined binary schema (even if not full “packet at zero cost”).
- [ ] Rails for pass/fail; reflect metadata for layout; no DESIGN overclaim beyond MVP.

## 10. References

1. Acton, M. “Data-Oriented Design and C++.” CppCon 2014 keynote. Announcement: https://cppcon.org/third-keynote-2014/ ; video commonly at https://www.youtube.com/watch?v=rX0ItVEVjHc
2. Llopis, N. “Data-Oriented Design (Or Why You Might Be Shooting Yourself in The Foot With OOP).” *Games from Within* (industry essay).
3. Fabian, R. *Data-Oriented Design*. https://www.dataorienteddesign.com/
4. Nystrom, R. “Data Locality.” *Game Programming Patterns*. https://gameprogrammingpatterns.com/data-locality.html
5. Bayliss, J. D., et al. “Developing Games with Data-Oriented Design.” FDG ’22. https://dl.acm.org/doi/10.1145/3524494.3527626
6. Unity Technologies — DOTS / ECS documentation and GDC talks (“Connecting the DOTS”).
7. Apache Arrow: https://arrow.apache.org/ ; Cap’n Proto: https://capnproto.org/ ; FlatBuffers: https://flatbuffers.dev/
8. Schoener, S. “Data Oriented Design – An Interpretation.” https://blog.s-schoener.com/2019-06-09-data-oriented-design/ (critical synthesis of Acton et al.)
9. openOODA `spec/DESIGN.md` §1; monorepo `PM.md` row `1.3`.

## Conflicts with other DESIGN items

| Conflict | Description | Resolution direction |
|----------|-------------|----------------------|
| **1.3 vs 3.7 ARC/RAII** | Columnar GC/RC is non-trivial | Prefer owning tables of POD/value types first; shared objects as indices into arenas |
| **1.3 vs 3.8 temporal memory** | History per cell vs per column | Optional journaling layers; don’t bake into default SoA |
| **1.3 vs 3.3 heap quotas** | Large tables need alloc caps | Table alloc through `&AllocCap`; grow policies explicit |
| **1.3 vs 5.3 concurrency** | Parallel iteration over columns | Borrow/typestate or jobs model later; document data races as out-of-scope for MVP |
| **1.3 vs 1.1 speed (compile)** | Layout generics/comptime codegen can slow builds | Keep MVP monomorphic emit; generate code carefully |
| **1.3 vs 1.5 typestate** | Entity lifecycle vs column presence | Components as optional columns or sparse sets; typestate on handles |
| **1.3 vs 4.4 holographic persistence** | Persistence format may force copies | Align on-disk columnar format with in-memory SoA where possible |
| **1.3 vs 6.3 FFI** | C APIs often AoS | Explicit convert at boundary; don’t silent-alias layouts |
| **“Zero CPU” wording** | Conflicts with validation/security honesty | Interpret as zero **redundant copy**; always validate untrusted input |

---

*Series: [Research papers index](./README.md). Template: [TEMPLATE.md](./TEMPLATE.md).*
