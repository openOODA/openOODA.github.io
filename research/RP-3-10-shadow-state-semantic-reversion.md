# RP-3.10: Shadow-state semantic reversion

| Field | Value |
|-------|--------|
| **Paper ID** | `RP-3.10` |
| **DESIGN.md** | Section 3 Safety — Shadow-State Semantic Reversion |
| **Status** | `draft` |
| **PM.md row** | `3.10` |
| **Product mapping** | **not-started** |
| **Conflicts** | Fights **1.1** OODA performance (duplicate work). Overlaps **3.8** temporal and STM. Look at Conflicts section. |

## 1. Why this is in DESIGN.md

DESIGN.md Section 3 says:

> **Shadow-State Semantic Reversion:** Important modules run some instructions early in a virtual state. If a change breaks a rule, the system stops the code. This occurs before the CPU writes the change to the main memory.

This function makes rules strong when data changes. It does not find errors after the data is bad. It guesses, checks rules, and then keeps or deletes the data. If the compiler cannot prove a rule, the shadow execution gives a safety check for important modules.

It is between:
- **3.6 fuzzing** (offline test to break rules)
- **3.8 temporal** (recover after bad data is kept)
- hardware **speculative execution** (guesses for speed).

## 2. Problem statement

### 2.1 What breaks without it

| Problem | Result |
|-----|-------------|
| Rules are only for test | Production code removes checks. Bad code operates. |
| Checks occur after a change | Other threads see illegal data states. |
| Agent Act mutates global structures | The system cannot recover from bad data writes. |
| High security modules | They need an option to cancel. |

### 2.2 Stakeholders

| User | Need |
|-------|------|
| **Module creator** | Safe data changes for rules |
| **AI agent** | Safe tests of the Act step |
| **Performance owner** | Must not do all work two times (1.1) |
| **Attacker** | Finds secret data during guesses |

### 2.3 Semantic target

For an area `S` with an end rule `E`:

1. Run `S` against a shadow memory.
2. Check `E` on the shadow data.
3. If `E` is true and has no error, keep the shadow data in main memory.
4. If not true, delete the shadow data. Do not change main memory. Send an error.

## 3. Related work

### 3.1 Transactional memory

- **Herlihy and Moss (1993)** — Hardware transactional memory.
- **Software Transactional Memory (STM)** — Shavit and Touitou. Harris and others.
- **HTM in standard CPUs** — Hardware transactions that can stop. 

**Mapping:** The shadow-state is similar to a transaction. Its validity condition is the openOODA `ensures` rule.

### 3.2 Speculative execution

- **CPU speculative execution** — Performance function. Transient execution attacks show that it leaks data.
- **Speculative execution in distributed systems** — Nightingale and others.
- **Speculator / multi-layer speculation** — Wester and others.

**Mapping:** The openOODA shadow-state is explicit software speculation. It uses semantic stop conditions. It must not leak shadow data.

### 3.3 Dual execution

- **N-Variant systems** — Multiple variants check each other.
- **MVEE** — Compare system calls across variants.

**Mapping:** Dual execution can make a shadow as a second variant. It is strong but uses many resources.

### 3.4 Software patterns

- Copy-on-write systems and software transactional data structures.
- Supervisor trees.

## 4. Design rationale for openOODA

### 4.1 When shadow-state applies

It is not global. Use it for:

- Modules with the `#[shadow]` or `critical` tag.
- Functions with complex rules.
- Agent tool sandboxes.
- Shared data mutations.

Normal code runs at full speed. Critical code uses resources for safety.

### 4.2 Implementation strategies

| Strategy | Idea | Cost | Strength |
|----------|------|------|----------|
| **A. STM buffer** | Log changes. Keep if rules are true. | Medium | Good for heap objects |
| **B. Dual process** | Run early in child process. | High | Strong isolation |
| **C. Page COW (`mmap`)** | OS page protection. | Medium-High | Simple but large |
| **D. HTM** | Hardware transaction. | Low-Medium | Limits on capacity |
| **E. Pure functional shadow** | Compute values. Bind later. | Low | Needs pure code |

### 4.3 Commit protocol

```text
enter_shadow(S)
  run code. write to shadow memory.
  if trap occurs, stop shadow and send error.
  if rule is false, stop shadow and send error.
  if external effect occurs, deny or hold the effect.
  commit_shadow()  // write to main memory
exit
```

**External effects:** The system must not use the network or disk until commit.

### 4.4 Relation to other leaves

| Leaf | Relation |
|------|----------|
| **1.2 Contracts** | The rule is the commit condition |
| **3.8 Temporal** | Shadow stops bad data. Temporal fixes data after commit |
| **3.1 Caps** | Shadow must not do I/O |
| **3.5 Secret** | Shadow must not leak data |
| **3.9 CFI** | Shadow runtime needs CFI |
| **1.1 Speed** | Primary conflict. Look at Conflicts section |

## 5. Threat model

### 5.1 Prevents

| Issue | Mitigation |
|-------|------------|
| Bad intermediate state | Never committed |
| Partial updates | Transactional commit |
| Agent trial mutations | Stop cleanly |

### 5.2 Does not prevent

| Issue | Notes |
|-------|-------|
| Weak rules | Rule design problem |
| Data leakage | Needs constant-time policies |
| HTM/STM livelock | Needs retry limits |
| Non-shadow modules | Unprotected |
| Always-true rules | Rules must be strong |

### 5.3 Failure policy

- Stop. Do not commit. Send error to caller.
- Retry with a limit.
- A rule error is recoverable.

## 6. Alternatives considered

| Alternative | Decision | Why |
|-------------|----------|-----|
| Always-on STM | **Reject** | Bad for performance |
| Static proof only | **Insufficient** | Cannot do all checks |
| Temporal rollback only | **Complement** | Finds bad state after it occurs |
| Kill task only | **Fallback** | Loses fine control |
| Dual machine speculation | **Too heavy** | Not good for default use |

## 7. Product reality

**PM.md `3.10`: not-started.**

| Item | Status |
|------|--------|
| Shadow runtime | **not-started** |
| STM integration | **not-started** |
| Commit rules | **not-started** |
| Effect buffering | **not-started** |
| Side-channel policy | **not-started** |
| Performance budgets | **not-started** |

No module currently runs early with a stop function.

## 8. Open research questions

1. What is the size of the shadow? Function, block, or region?
2. How far early does it run?
3. How does it work with arrays?
4. Can the backend make efficient write logs?
5. Must the shadow of secret data run alone?
6. Can shadows contain other shadows?
7. How to manage concurrent stops?

## 9. Acceptance criteria

### not-started to smoke

- [ ] System reads the tag.
- [ ] Demo shows that a failed rule does not change memory.
- [ ] A true rule writes to memory.

### smoke to partial

- [ ] System denies I/O inside shadow.
- [ ] System permits nested shadows.
- [ ] System measures overhead.

### partial to done

- [ ] Product uses shadow on a critical path.
- [ ] System limits retries.
- [ ] System tests with 3.8 temporal feature.

## 10. References

1. openOODA `spec/DESIGN.md` Section 3.
2. openOODA `PM.md` row 3.10.
3. Herlihy and Moss.
4. Harris and others.
5. Nightingale and others.
6. Wester and others.
7. Literature on speculative execution.
8. Cox and others.
9. STM surveys.

---

## Conflicts

### Conflict A — **3.10 fights 1.1 OODA loop speed**

**Nature of the conflict**

The shadow-state duplicates work. It adds write tasks. It makes the system slow. This fights the goal of high speed for agent loops.

**Always-on:** This uses too much CPU. It is bad for speed.

**Proposed solutions**

| ID | Solution | Effect on 1.1 |
|----|----------|----------------|
| **S1. Strict opt-in** | Only critical modules | Fast default path |
| **S2. Static discharge** | Skip shadow if compiler proves rule | Zero runtime delay |
| **S3. Pure-value shadow** | Use functional compute | Cheap for pure code |
| **S4. Sampled shadow** | Ghost only in test | Fast in production |
| **S5. Async dual** | Shadow on other CPU core | Hides delay |
| **S6. Fuel budget** | Set limits | Stops infinite loops |
| **S7. Tiered profiles** | Different modes | Aligns with dual-engine |

**Recommended policy**

1. Do not use shadow-state as default.
2. Try to prove rules first.
3. Use for agent sandboxes first.
4. Make a performance limit.
5. You must do benchmarks before you mark this done.

### Conflict B — Shadow vs temporal (3.8)

Both revert data.
**Solution:** Shadow stops a bad commit. Temporal recovers from a bad commit. Use shadow for rules. Use temporal for panics.

### Conflict C — Shadow vs ARC (3.7)

Stopped shadow must remove memory safely.
**Solution:** Delete shadow memory on stop. Do not link main memory to shadow memory.

### Conflict D — Side channels vs secrets (3.5)

**Solution:** Deny shadow for secret data unless isolated. Record the risk.

### Conflict E — Shadow vs metamorphic code (3.11)

**Solution:** Stop code changes during shadow region. Or, shadow only data.

---

*Series: [Research papers index](./README.md). Template: [TEMPLATE.md](./TEMPLATE.md).*
