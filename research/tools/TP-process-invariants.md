# TP-process-invariants: Always-on process constraints

| Field | Value |
|-------|--------|
| **Paper ID** | `TP-process-invariants` |
| **TOOLS.md** | § Always on (not chosen) |
| **Status** | `draft` |
| **Series** | Process / agent-ops |

## 1. Why this is in TOOLS.md

Some rules are **not optional tools**—they are invariants of every turn:

| Rule | Science cousin | Meaning |
|------|----------------|---------|
| **E-M** | Physics / flight | Rank + Act every turn |
| **Entropy \(S\)** | Thermodynamics | Score trust disorder |
| **≤256 lines** | Materials / modularity | File hard cap |
| **Power law** | Math / Pareto | Top ≤5 this turn |
| **DESIGN** | — | Architecture only from DESIGN |
| **Tests+code** | Biology / immune | Pass+fail with behavior |
| **No hand-waves** | Chemistry / purity | Unfinished → fail-closed |
| **`.oo` product** | — | No new Rust-only product surface |
| **Feedback** | Control / OODA | Shorten observe→signal |
| **ASD-STE100** | Linguistics | Controlled technical English |

## 2. Problem statement

Optional frameworks get skipped under pressure. Invariants prevent **silent culture decay**: monofiles, host creep, untested claims, DESIGN freelancing.

## 3. Related work

- **Modular size / microservices & file caps:** Cognitive load and reviewability; openOODA’s 256-line lock is a hard modularity gate (`check_file_lines.sh`).  
- **Pareto prioritization:** Limit WIP to vital few.  
  - https://lawsofsoftwareengineering.com/laws/pareto-principle/  
- **Fail-closed security & purity cultures:** Prefer refuse over ambient success.  
- **Controlled languages (ASD-STE100):** Reduce ambiguity in technical writing.  
  - https://www.asd-ste100.org/  
  - https://en.wikipedia.org/wiki/Simplified_Technical_English  
- **Immune-inspired testing:** Negative selection via fail fixtures (see TP-honesty-immune).

## 4. Rationale for openOODA process

Invariants protect:

1. **Product purity** (`.oo` + thin C + seed)  
2. **Agent editability** (≤256 lines)  
3. **Trust** (tests+code, no hand-waves, \(S\))  
4. **Architecture discipline** (DESIGN-only language changes)  
5. **Tempo** (power law ≤5, feedback)

## 5. Limits

- 256 is a **policy constant**, not a universal optimum.  
- Power law can starve important long-tail residual work—pair with PM.md full checklist.  
- STE100 is a writing aid; not a substitute for residual honesty docs.

## 6. Alternatives

| Alternative | Why weaker |
|-------------|------------|
| Soft guidelines only | Agents ignore under thrash |
| Unlimited WIP | Little’s law WIP explosion |
| Host language “just this once” | Purity ratchet failure |

## 7. Product / process reality

- Line lock: **enforced** in product rails.  
- Pure product: **enforced** (RS_COUNT=0 gates).  
- Power law / E-M: **process**—depends on agent adherence.  
- Report-to-PROGRESS pin: **migrate to PM.md / SPRINT.md**.

## 8. Open questions

1. Should power-law “5” be configurable per agent role?  
2. Link each invariant to a residual smoke automatically?

## 9. Acceptance criteria

- [ ] TOOLS always-on table maps 1:1 to this paper’s checklist.  
- [ ] Violations of 256 / purity fail CI, not only prose.

## 10. References

1. ASD-STE100 official. https://www.asd-ste100.org/  
2. Simplified Technical English — Wikipedia. https://en.wikipedia.org/wiki/Simplified_Technical_English  
3. Pareto in software engineering. https://lawsofsoftwareengineering.com/laws/pareto-principle/  
4. openOODA `TOOLS.md`, `bootstrap/SPLIT_PLAN.md`.

---
*Series: [README.md](./README.md).*
