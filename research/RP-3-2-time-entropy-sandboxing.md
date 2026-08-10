# RP-3.2: Time & entropy sandboxing

| Field | Value |
|-------|--------|
| **Paper ID** | `RP-3.2` |
| **DESIGN.md** | §3 Safety — Time & Entropy Sandboxing |
| **Status** | `draft` |
| **PM.md row** | `3.2` |
| **Product mapping** | **not-started** |

## 1. Why this is in DESIGN.md

DESIGN.md §3 states:

> Code cannot read the system clock or generate random numbers without `&TimeCap` and `&RandCap`, guaranteeing functions are mathematically pure and testing is 100% deterministic.

Together with §3.1 capability sandboxing, time and entropy are the two ambient effects that cause the most problems:

1. **Purity** — Functions that call `now()` or `rand()` break equational reasoning, caching, and contract proofs.
2. **Replay / determinism** — They cause unreliable tests, non-reproducible builds (§4.3.2), and fuzz failures that you cannot replay.
3. **Security** — They permit timing oracles, incorrect RNG use, and anti-analysis techniques in malicious code.

The openOODA loop needs stable runs that you can replay. Fuzzing methods (§2.4, §3.6) and rollback tools assume that non-determinism comes from inputs, not the environment.

## 2. Problem statement

### What breaks without it

| Failure | Example |
|---------|---------|
| Flaky tests | `if now() % 2 == 0` branches differently in CI |
| Unreproducible builds | timestamps embedded in artifacts; “works on my machine” |
| Non-replayable fuzz crashes | RNG-dependent bug cannot be minimized |
| False purity | Optimizer or proof assumes purity; clock read invalidates |
| Hidden side channels | Secret-dependent branches + clock → timing leak (ties to §3.5) |

### Users

- **Compiler / proof tools** — They need a closed set of effects for `requires`/`ensures` and MaxCycles (§3.4).
- **Test harness** — It injects fixed `TimeCap`/`RandCap` schedules to ensure determinism.
- **Security auditor** — The auditor must see entropy use in the signature, not hidden in libc.
- **Adversary** — An adversary uses the wall-clock or RNG as a covert channel or to stop fuzzing.

### Core research question

How do we give enough time and entropy for systems programs (timeouts, UUIDs, crypto) while making code pure and replayable by default? We must not claim that OS clocks are mathematical objects.

## 3. Related work

### 3.1 Purity and effects (academic)

- **Haskell `IO` / `ST`:** The language passes the world state. Time and RNG exist in IO. Purity is a type property, not a suggestion.
- **PureScript / Elm:** These use effect rows with explicit `Effect` / `Cmd`.
- **Koka / Frank / Effekt:** These use algebraic effects. `time` and `random` act as handlers. Tests swap these handlers.
- **F\* / Low\*:** These use effect annotations for verification. Crypto code limits entropy sources.

### 3.2 Deterministic replay and hermetic builds (industry + research)

- **rr (Mozilla), Undo, TTD (Microsoft):** These tools record and replay nondeterminism (syscalls, RDTSC, RNG).
- **Bazel / Nix hermeticity:** These tools sandbox builds and ban undeclared inputs. Timestamps and `/dev/urandom` cause common hermeticity bugs.
- **Reproducible Builds project:** This project removes clocks and entropy from artifacts.
- **DetTrace / deterministic Linux containers (research):** These systems virtualize time and entropy for containers.

### 3.3 Capability-flavored time/RNG

- **KeyKOS/EROS/seL4:** Clocks and entropy are kernel services. You invoke them via capabilities, not ambiently.
- **WASI:** `clock_*` and `random_get` are explicit imports. An embedding system can replace them.
- **CloudABI:** This system has no ambient time. You pass resources in.
- **Web browser:** Browsers separate `crypto.getRandomValues` and `Math.random`. They put high-resolution time behind COOP/COEP to sandbox entropy and time for Spectre.

### 3.4 Testing practice

- **Property-based testing (QuickCheck):** Shrinking assumes a deterministic test function. Ambient RNG breaks this shrinking.
- **Golden tests / snapshot tests:** These tests require stable clocks or clock injection.
- **Game engines / sims:** The industry standard for replay uses a fixed-timestep and seeded RNG.

## 4. Design rationale for openOODA

### 4.1 Caps as effect tokens

```text
fn log_line(t: &TimeCap, msg: String)
fn uuid_v4(r: &RandCap) -> Uuid
fn hash_password(r: &RandCap, pw: String) -> Hash  // salt from RandCap
fn add(a: Int, b: Int) -> Int   // no caps → pure; fuzzer-friendly
```

- You need `&TimeCap` to read the wall clock, monotonic clock, or TSC-class APIs.
- You need `&RandCap` for any CSPRNG or insecure RNG API. (We will split this later: `&SecureRandCap` vs test RNG).
- `std::core` does not give access to clock/RNG. `std::os` gives access if you have caps.

### 4.2 Determinism modes

| Mode | TimeCap | RandCap | Use |
|------|---------|---------|-----|
| Production | OS clock / VDSO | OS CSPRNG | real systems |
| Test / fuzz | virtual timeline | seeded LCG or recorded stream | replay |
| Build | frozen epoch or banned | banned or fixed seed | §4.3.2 |

DESIGN says “100% deterministic testing”. This means the test mode injects deterministic caps. It does not mean production has no entropy.

### 4.3 Interaction with other items

| Item | Link |
|------|------|
| 3.1 Unified caps | Same check/runtime seal story |
| 3.4 MaxCycles | Time ≠ cycles; wall-clock timeouts need TimeCap, CPU bound needs MaxCycles |
| 3.5 Secret | High-res time + secret branches = side channel; policy may ban TimeCap in secret contexts |
| 3.6 Fuzzer | Injected RandCap for SUT; separate RNG for *generator* |
| 4.3.2 Reproducible builds | Compiler must not read ambient time without build TimeCap policy |
| 6.1 Metamorphic vs deterministic | Runtime polymorphism must not reintroduce ambient entropy into *build* artifacts |

### 4.4 Implementation sketch (not product yet)

1. Static seal names: `now`, `unix_time`, `random`, `rand_bytes`, …
2. Runtime: Pass the cap. The test harness selects an OS-backed or virtual backend.
3. Record/replay log: This is optional for debugging (like rr).

## 5. Threat / failure model

### Prevents

- Accidental impurity in “pure” libraries.
- Flaky tests caused by clock/RNG in the System Under Test (SUT).
- Silent non-reproducible builds from the language standard library.
- Simple anti-fuzz techniques (`if rand() ...`) that do not declare RandCap.

### Does not prevent

| Gap | Notes |
|-----|-------|
| Hardware timing channels | Cache/timing still exist without language clock |
| FFI ambient time | `gettimeofday` via C without cap—needs §6.3 |
| Kernel entropy quality | Language cannot fix bad `/dev/urandom` |
| Logical clocks vs wall clocks | Distributed systems still hard |
| DESIGN overclaim “mathematically pure” | Purity is *relative to declared effects*, not absolute physics |

### Failure modes to design for

- **Clock skew in distributed agents** — We need a virtual TimeCap for each logical actor.
- **Crypto misuse** — Someone might use a test RandCap in production. (We need a type distinction or lint tool).
- **Deadlock with biometric + time** — The system pauses for FaceID while holding time-sensitive locks (ties to 3.1).

## 6. Alternatives considered

| Alternative | Decision |
|-------------|----------|
| **Purity by convention / linters** | Insufficient for AI-generated code; not fail-closed |
| **Always virtualize time globally** | Breaks real servers; must be mode-switched |
| **Allow clock, ban only in `#[pure]`** | Opt-in purity is ambient-by-default; DESIGN wants default pure |
| **Thread-local RNG without caps** | Hidden global state; breaks replay |
| **Depend on Bazel sandbox alone** | Language still callable outside Bazel; dual enforcement wanted |
| **Monotonic-only without wall clock** | Incomplete; logs and TLS need wall or injected time |

## 7. Product reality (alpha honesty)

**PM.md `3.2`: not-started.**

| Claim | Alpha |
|-------|-------|
| `&TimeCap` / `&RandCap` types | **not present** as product surface |
| Static seal on clock/RNG builtins | **not-started** |
| Deterministic test harness injection | **not-started** (fuzz uses its own LCG for *inputs*, not SUT caps) |
| Reproducible build clock policy | **not-started** (PM 4.3.2 not-started) |

Related partial work: Capability mechanisms for Fs/Sys/Env/Net (3.1) can extend. There is no time/entropy sealed table yet.

**Honesty rule:** Do not claim “functions are mathematically pure” in product marketing until we seal Time/Rand and cap FFI.

## 8. Open research questions

1. **Clock lattice:** Do we need one cap or three for wall, monotonic, and CPU cycles?
2. **Secure vs insecure randomness:** Do we use a single `RandCap` or split it to prevent test seeds in crypto?
3. **Async timeouts:** Does `sleep` consume TimeCap and MaxCycles?
4. **Record/replay format:** How do we log nondeterminism for agent-bisect without large traces?
5. **Interaction with metamorphic binaries (3.11):** Runtime code mutation needs entropy. It must not pollute deterministic builds or pure tests.
6. **VDSO / RDTSC:** Backend-C compiled code can read time without libc. It needs a compiler barrier or OS sandbox.

## 9. Acceptance criteria (for PM status promotion)

### not-started → partial

- [ ] Sealed static check for at least `now`/`unix_time` and `random`/`rand_bytes` (or product-named equivalents)
- [ ] Runtime require of TimeCap/RandCap magic or opaque tokens on Backend-C path
- [ ] Pass/fail fixtures: pure fn cannot call them; with cap can
- [ ] Test harness mode: fixed seed RandCap + frozen or stepped TimeCap; one replay rail

### partial → done

- [ ] std::core has zero clock/RNG; std::os documents caps
- [ ] Fuzz and verify paths inject deterministic caps by default
- [ ] Build policy document: ambient time/entropy banned or stubbed for release artifacts
- [ ] FFI path cannot call ambient time without UnsafeFFICap (with 6.3)

## 10. References

1. Peyton Jones, S. (ed.). *Haskell 2010 Language Report* — IO and purity.
2. Claessen, K., & Hughes, J. (2000). *QuickCheck: a lightweight tool for random testing of Haskell programs.* ICFP.
3. Bazel hermeticity documentation (bazel.build); Reproducible Builds project.
4. O’Callahan, R., et al. *rr: lightweight recording & deterministic debugging.*
5. Watson et al. Capsicum; WASI clock/random APIs; CloudABI.
6. Shapiro et al. EROS; seL4 capability invocation model.
7. DetTrace and related deterministic container research.
8. openOODA: `spec/DESIGN.md` §3 (Time & Entropy), §4.3.2; `PM.md` 3.2, 4.3.2; related `RP-3-1`, `RP-3-6`.

---

*Series: [Research papers index](./README.md). Template: [TEMPLATE.md](./TEMPLATE.md).*
