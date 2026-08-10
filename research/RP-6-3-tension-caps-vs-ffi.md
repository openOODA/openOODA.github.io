# RP-6.3: Tension: capability sandbox vs C/C++ FFI

| Field | Value |
|-------|--------|
| **Paper ID** | `RP-6.3` |
| **DESIGN.md** | §6 Tensions |
| **Status** | `draft` |
| **PM.md row** | `6.3` |
| **Product mapping** | Caps **partial** (static + magic tokens); compile-time FFI **not-started**; `&UnsafeFFICap` residual |
| **Related DESIGN** | `3.1` (unified capability sandboxing), `4.3.3` (compile-time FFI generation), `4.3.1` (cross-language LTO), SPEC §10 |
| **Sibling papers** | [RP-3-1](./RP-3-1-unified-capability-sandboxing.md), [RP-4-3-3](./RP-4-3-3-compile-time-ffi-generation.md) |
| **Product residual** | `ooda/bootstrap/STATIC_CAPS.md`, `CAPS_MATRIX.md` |

## 1. Why this is in DESIGN.md

DESIGN §6 states:

> Because C/C++ code has no capability tracking and can execute arbitrary syscalls, any openOODA function that invokes Compile-Time FFI must explicitly demand an `&UnsafeFFICap` in its parameter list. The capability taint-tracking treats the FFI boundary as a deliberate, statically tracked sandbox breach.

| Goal | DESIGN claim | Tension |
|------|--------------|---------|
| **3.1 Capability sandbox** | Default-deny I/O; effects only via `&FsCap`, `&NetCap`, … | Pure OODA code cannot ambiently touch the world |
| **4.3.3 / SPEC FFI** | Import C headers / call `.so` / zero-cost interop | C can `open`, `connect`, `exec`, scribble memory — **outside** the cap lattice |

Without an **explicit breach token**, “capability-secure language” becomes a lie the moment `sqlite3_open` is linked. With too heavy a breach model, **no one can use libc ecosystems**, and the language fails adoption.

This paper defines how openOODA can stay **honest**: FFI is allowed, but it is a **named, tainting, auditable** sandbox hole.

## 2. Problem statement

### What breaks if we omit the boundary

| Omission | Consequence |
|----------|-------------|
| Ambient `extern "C"` | Any dependency reintroduces ambient authority; 3.1 is theater |
| Cap-checked OODA wrapping ambient C that still does I/O | False sense of safety (“I passed only FsCap” while C opens sockets) |
| No taint from FFI returns | Foreign pointers / buffers smuggle unchecked authority into pure code |
| Ban all FFI | No SQLite, no OS APIs beyond hand-written runtime, no migration path |

### Users / adversaries

- **App developer:** must call mature C libraries.  
- **Library author:** wants to offer safe wrappers.  
- **Agent runtime:** must run untrusted AI-generated `.oo` **without** giving it raw FFI.  
- **Adversary:** plant a crate that uses FFI to bypass `&NetCap` checks.

### Core invariant (policy)

```
pure_ooda_effects ⊆ granted_caps
ffi_call            ⇒ requires &UnsafeFFICap (or narrower FFI cap family)
post_ffi_values     ⇒ tained / untrusted until explicitly endorsed
```

**Authority only flows through capabilities.** FFI is a capability (the right to leave the model), not a free compiler feature.

## 3. Related work

### Object-capability security

- **Object-capability model** (Miller et al., E language, Agoric) — authority is reference possession; no ambient authority.  
- **WASI / capability-oriented WASI** — host grants explicit rights to Wasm modules (files, sockets) rather than full POSIX ambient.  
- **openOODA product caps** — process-local magic tokens for sealed ops (`STATIC_CAPS.md`); not yet unforgeable object-caps.

### Safe languages + unsafe foreign code

- **Rust `unsafe` + FFI** — foreign calls are `unsafe`; safe wrappers must uphold invariants. Does **not** by itself stop C from making syscalls.  
  See Rust books / “Unsafe Rust and FFI” training materials.
- **In-process isolation for FFI** — research systems (e.g. Sandcrust-style process isolation, SDRaD-FFI) sandbox untrusted native code so memory corruption cannot freely reach the safe side.  
  arXiv example: *Friend or Foe Inside? Exploring In-Process Isolation…* <https://arxiv.org/html/2306.08127v2>
- **Vale “Fearless FFI”** — sandbox native dependencies (Wasm/subprocess) + module capability direction.  
  <https://verdagon.dev/blog/fearless-ffi>
- **CHERI** — hardware capabilities bound pointers; helps even when C is in-process; complementary to language caps.  
  <https://cheri-alliance.org/discover-cheri/rust-and-cheri/>

### Auto-generated bindings

- **bindgen (Rust), cgo, Zig `@cImport`** — parse headers → bindings; safety still manual.  
- DESIGN 4.3.3 aims at `import "C" "sqlite3.h"` with optional inferred contracts — **ergonomics**, not a security proof.

### Real-world sandbox escapes (motivation)

- Autonomous agents probing package proxies / evaluation sandboxes show that **any allowed egress** becomes the attack surface; FFI is permanent egress from the cap model. Treat it with the same seriousness as network egress.

## 4. Design rationale for openOODA

### 4.1 Cap ladder including breach

| Cap | Authority |
|-----|-----------|
| *(none)* | Pure computation (`std::core`) |
| `&FsCap` / `&NetCap` / `&SysCap` / `&EnvCap` | Sealed product ops only |
| `&TimeCap` / `&RandCap` | Nondeterminism (3.2) |
| `&AllocCap<…>` | Heap budget (3.3) |
| **`&UnsafeFFICap`** | **Leave the OODA effect model** — call foreign code |
| Future: `&FfiCap<LibId>` / `&FfiCap<SymbolSet>` | Attenuated FFI (optional evolution) |

DESIGN’s single `&UnsafeFFICap` is the **honest minimum**. Product may later subdivide without changing the principle.

### 4.2 Static rules (target)

1. **Any** `extern "C"` call, `import "C"`, or link-seam to non-OODA object code requires `&UnsafeFFICap` in the **calling function’s** parameter list (or a carrier that is itself FFI-tainted).  
2. **Transitive taint:** a function that calls an FFI-using function without re-exporting the breach must still demand the cap (or be rejected).  
3. **Wrapper pattern:**

   ```ooda
   // Illustrative — not product syntax frozen
   fn sqlite_open(path: Str, ffi: &UnsafeFFICap) -> Result[Db] {
       // generated or hand bindings may run here
   }

   fn app_open(path: Str, fs: &FsCap, ffi: &UnsafeFFICap) -> Result[Db] {
       // Even if path was validated with fs, foreign open is still FFI authority
       sqlite_open(path, ffi)
   }
   ```

4. **Main / agent injectors** decide who receives `&UnsafeFFICap`. Untrusted plugins get **none**.  
5. **Compile-time FFI generation (4.3.3)** must **auto-insert** the cap requirement on generated wrappers — never emit ambient externs.

### 4.3 Taint on values crossing the boundary

| Direction | Policy |
|-----------|--------|
| OODA → C (args) | Document ownership; no secret raw pointers without 3.5 rules |
| C → OODA (returns) | Treat as **untrusted**: bounds unknown, aliasing unknown; prefer copy into ARC-managed buffers |
| C retains OODA heap | Forbidden without explicit pin API (future) |

Optional **stronger modes** (research):

- **Process isolate** foreign libs (RPC/FFI bridge).  
- **Wasm sandbox** for “foreign” logic when source available.  
- **CHERI / hardware** when deploying on suitable silicon.

### 4.4 Interaction with product Backend-C

Alpha **already** lowers to C and links `chs_rt`. That is **runtime implementation**, not user-level FFI:

| Surface | Cap model |
|---------|-----------|
| Sealed ops → `chs_rt_*` | Cap args + `oo_cap_require` |
| User `extern "C"` to libfoo | **Must** be `&UnsafeFFICap` when feature exists |
| Compiler-emitted libc for codegen | Trusted TCB; not user authority |

Do not conflate **implementation language of the runtime** with **user FFI authority**.

### 4.5 Cross-language LTO (4.3.1)

LTO that inlines C++/Rust into OODA (or reverse) can **erase** the visible call boundary while **preserving** the syscall authority of foreign code. Policy:

- LTO is an optimization over a program that **already** declared `&UnsafeFFICap`.  
- Inlining does not remove the need for the cap on the logical foreign effect.  
- Prefer **opt-in LTO units** listed in a manifest for audit (SBOM of breach).

## 5. Threat / failure model

### Prevents (when enforced)

| Threat | Mitigation |
|--------|------------|
| Accidental ambient C I/O from “safe” modules | No FFI without cap in signature |
| AI agent imports helper that shells out via C | Agent binary never holds `&UnsafeFFICap` |
| Review blindness | Cap appears in type; outline/reflect show breach |
| Silent 4.3.3 codegen | Generated wrappers demand cap |

### Does **not** prevent

| Residual | Why |
|----------|-----|
| Malicious code that **has** `&UnsafeFFICap` | Cap is real authority |
| Memory corruption from C affecting OODA process | In-process FFI shares address space unless isolated |
| Magic-token forge in hostile binary | Alpha caps are not crypto object-caps (`STATIC_CAPS.md`) |
| Kernel bugs | Caps are userspace policy |

### Failure modes

1. **Cap dilution** — too many modules take `&UnsafeFFICap` “just in case” → model collapses to ambient. Mitigate with lint + attenuations.  
2. **False wrappers** — “safe” API hides FFI without threading the cap (must be hard error).  
3. **Runtime without static** — only dynamic checks → agents skip types. Need static as primary.

## 6. Alternatives considered

| Alternative | Verdict | Notes |
|-------------|---------|-------|
| **Ban user FFI forever** | Reject | Ecosystem suicide |
| **Rust-style `unsafe` keyword only** | Insufficient alone | Does not model *authority* of syscalls |
| **OS seccomp / landlock only** | Complement | Good defense-in-depth; not a language-level story |
| **All I/O reimplemented in pure OODA** | Long-term ideal for std | Still need FFI for legacy |
| **`&UnsafeFFICap` (DESIGN)** | **Accept MVP** | Honest, auditable, simple |
| **Fine-grained `&FfiCap<"sqlite3">`** | Future | Better attenuation; more design work |
| **Out-of-process FFI only** | Optional harden profile | High cost; strongest isolation |
| **Trust bindgen contracts alone** | Reject | Annotations are not enforcement |

## 7. Product reality (alpha honesty)

| Layer | Status | Truth |
|-------|--------|-------|
| **3.1 Caps** | **partial** | Static check + runtime magic tokens for sealed FS/Sys/Env/Net(`fetch`) |
| **Unforgeable object caps** | not claimed | Process-local integers |
| **4.3.3 Compile-time FFI** | **not-started** | No `import "C"` header pipeline |
| **`&UnsafeFFICap`** | **not-started** | DESIGN policy only; not in check_caps matrix |
| **User ambient libc** | residual risk | Backend-C runtime is TCB; user extern surface not productized |
| **6.3** | **not-started** | No engineered breach tracking |

### Alpha-safe claims

- Sealed ops without cap **fail closed** on the pure path (see `CAPS_MATRIX.md`).  
- **Do not claim** that linking arbitrary C is capability-safe.  
- When FFI lands: ship **`&UnsafeFFICap` in the same milestone** as the first user-facing extern — never one without the other.

### Bootstrapping note

Self-host uses C as **emit target**. That does not grant compiled user programs unrestricted FFI. The compiler TCB is separate from the **user authority graph**.

## 8. Open research questions

1. Cap family: one `UnsafeFFICap` vs per-library / per-symbol attenuation?  
2. How to type **callbacks** from C into OODA (re-entry, caps re-entry)?  
3. Should FFI-tainted data be a **type qualifier** (like `#[Secret]` dual)?  
4. Can 4.3.3 infer `requires` bounds that *reduce* need for raw FFI over time?  
5. Interaction with **biometric / high-assurance caps** — can FFI ever coexist with `&SysCap<RequireBiometric>` in one function?  
6. Wasm target (4.1.4): host imports as caps vs WASI mapping?

## 9. Acceptance criteria (for PM status promotion)

### `not-started` → `partial`

- [ ] Grammar/type for `&UnsafeFFICap` (or equivalent) in checker.  
- [ ] Any user `extern` / FFI call without cap → **hard check error** + fixture.  
- [ ] `outline`/`reflect` show FFI breach in compressed API.  
- [ ] Docs: runtime C (`chs_rt`) vs user FFI distinction.

### → `done` (relative to alpha)

- [ ] 4.3.3 generated wrappers **always** thread UnsafeFFICap.  
- [ ] Sample: SQLite or libm wrapper with explicit cap; agent fixture **denied** without cap.  
- [ ] Optional lint: “UnsafeFFICap used in N modules” budget for releases.  
- [ ] SBOM / manifest lists FFI-using packages for Web of Code (5.2) future.

## 10. References

1. openOODA `spec/DESIGN.md` §3.1, §4.3.3, §6; `spec/SPEC.md` §10.  
2. openOODA `PM.md` rows 3.1, 4.3.3, 6.3.  
3. `ooda/bootstrap/STATIC_CAPS.md`, `CAPS_MATRIX.md`.  
4. Object-capability security (Miller; E / Agoric literature).  
5. Rust unsafe/FFI practice — e.g. Microsoft Rust training ch.14.  
6. Isolation for foreign code: arXiv:2306.08127 — <https://arxiv.org/html/2306.08127v2>  
7. Vale Fearless FFI — <https://verdagon.dev/blog/fearless-ffi>  
8. CHERI + safe languages — <https://cheri-alliance.org/discover-cheri/rust-and-cheri/>  
9. Sibling papers: [RP-3-1](./RP-3-1-unified-capability-sandboxing.md), [RP-4-3-3](./RP-4-3-3-compile-time-ffi-generation.md).

---

*Series: [Research papers index](./README.md). Template: [TEMPLATE.md](./TEMPLATE.md). Conflicts index: [CONFLICTS.md](./CONFLICTS.md).*
