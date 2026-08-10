# TP-optional-lenses: Little, Amdahl, assembly depth, homeostasis

| Field | Value |
|-------|--------|
| **Paper ID** | `TP-optional-lenses` |
| **TOOLS.md** | § Optional second tools (batch) |
| **Status** | `draft` |
| **Series** | Process / agent-ops |

## 1. Why this is in TOOLS.md

Four optional lenses share one paper to avoid over-fragmentation:

| Lens | Formula / idea | When |
|------|----------------|------|
| **Assembly depth** | Substrate debt | Host vs `.oo`/C boundary |
| **Little’s law** | \(L = \lambda W\) | WIP / dirty locks |
| **Amdahl** | \(S = 1/((1-P)+P/s)\) | Measured hot path |
| **Homeostasis** | Reduce load, cull invasives | Overload / thrash |

## 2. Problem statement

Specialized ops-research tools help specific failures; always-on E-M+\(S\) are not enough when WIP clogs, host debt dominates, or polish hits the wrong 5% of runtime.

## 3. Related work

### Little’s law
- John D.C. Little — \(L = \lambda W\) in stable queues.  
  - https://en.wikipedia.org/wiki/Little%27s_law  
  - Columbia notes: http://www.columbia.edu/~ks20/stochastic-I/stochastic-I-LL.pdf  
- **openOODA map:** \(L\) ≈ WIP items; finish or restore to cut \(W\) and protect tempo \(V\).

### Amdahl’s law
- Gene Amdahl (1967) — speedup limited by sequential fraction.  
  - https://en.wikipedia.org/wiki/Amdahl%27s_law  
- **openOODA map:** Don’t polish tiny \(P\) while entropy \(S\) stays high.

### Assembly / substrate
- Systems boundary defects (host vs guest language) as long-run reliability debt—compare foreign-function and bootstrap literature (see RP-6-3, RP-4-x).

### Homeostasis
- Biological set-point regulation as metaphor for shedding WIP and thrash under overload (not a formal control model here).

## 4. Rationale for openOODA process

Quick pick table (TOOLS):

| Situation | Second tool |
|-----------|-------------|
| Host vs `.oo` | Assembly depth |
| WIP clog | Little |
| Hot path | Amdahl |
| Overload | Homeostasis |

## 5. Limits

- Little assumes stable system—chaotic agent thrash violates stationarity.  
- Amdahl needs measurement; guessing \(P\) is theater.  
- Homeostasis is rare; don’t use to avoid hard residual work.

## 6. Alternatives

Could be four papers; batched because each is a standard law with thin openOODA-specific surface.

## 7. Product / process reality

- Optional only (0–1 with E-M).  
- Assembly depth remains relevant while seed+C TCB exists.  
- Dual-engine wording in older TOOLS may need retirement.

## 8. Open questions

1. Auto-detect WIP \(L\) from git dirty sets?  
2. Tie Amdahl picks to real profiles in `chs_rt` / oodac?

## 9. Acceptance criteria

- [ ] Agents can name which lens and why in one line.  
- [ ] No Amdahl claim without measurement.

## 10. References

1. Little’s law — Wikipedia. https://en.wikipedia.org/wiki/Little%27s_law  
2. Little’s law notes — Columbia. http://www.columbia.edu/~ks20/stochastic-I/stochastic-I-LL.pdf  
3. Amdahl’s law — Wikipedia. https://en.wikipedia.org/wiki/Amdahl%27s_law  
4. openOODA `TOOLS.md` optional tools section.

---
*Series: [README.md](./README.md).*
