# TP-information-value: Value of the next probe

| Field | Value |
|-------|--------|
| **Paper ID** | `TP-information-value` |
| **TOOLS.md** | § Optional second — Information value of the next probe |
| **Status** | `draft` |
| **Series** | Process / agent-ops |

## 1. Why this is in TOOLS.md

When many claims compete, pick the **smallest probe** that cuts uncertainty most—often the largest expected \(\Delta S \downarrow\) per token.

## 2. Problem statement

Agents burn tokens on large refactors before falsifying the critical claim. Value-of-information (VoI) says: pay for information only up to its expected decision value.

## 3. Related work

- **Raiffa & Schlaifer (1961)** — *Applied Statistical Decision Theory*; classical EVPI/EVSI.  
  - Discussed in modern VoI surveys, e.g. https://orbit.dtu.dk/files/184731775/297.pdf  
  - Health-policy VoI overview: https://pmc.ncbi.nlm.nih.gov/articles/PMC7612603/  
- **Bayesian decision analysis** — ISPOR VoI task force reports (decision-theoretic research value).  
  - https://www.valueinhealthjournal.com/article/S1098-3015(20)30027-9/fulltext  
- **Active learning / test prioritization** — pick tests that most reduce model uncertainty (software engineering literature).

## 4. Rationale for openOODA process

**Act:** one falsifying fixture or command; then code from that signal.

| Situation | Probe |
|-----------|--------|
| “Does free work?” | Smallest pure multi + arc_smoke, not full redesign |
| “Is dual-engine dead?” | One fixture, both paths |
| “Is residual claim stale?” | Honesty smoke grep |

## 5. Limits

- Exact EVPI rarely computable in engineering turns.  
- Use **ordinal** VoI: prefer cheap falsifiers.  
- Do not skip deep design research by over-applying “smallest probe” to vision work (PM/DESIGN papers).

## 6. Alternatives

| Alternative | Why weaker |
|-------------|------------|
| Always full suite first | High token cost |
| Always code first | High \(U\) risk |
| Random test pick | Low expected \(\Delta S\) |

## 7. Product / process reality

- Documented optional second tool.  
- Aligns with fail-closed residual culture.  
- Complements E-M: probe before heavy thrust.

## 8. Open questions

1. Can residual docs auto-suggest highest-VoI probe?  
2. Token accounting for agents?

## 9. Acceptance criteria

- [ ] Agents prefer one falsifier when \(U\) high.  
- [ ] VoI not used to skip DESIGN/PM research obligations.

## 10. References

1. Raiffa, H. & Schlaifer, R. (1961). *Applied Statistical Decision Theory*. Harvard Business School.  
2. Thöns, S. et al. — VoI classification following Raiffa & Schlaifer. https://orbit.dtu.dk/files/184731775/297.pdf  
3. Jackson et al. — VoI in health policy models. https://pmc.ncbi.nlm.nih.gov/articles/PMC7612603/  
4. openOODA `TOOLS.md`.

---
*Series: [README.md](./README.md).*
