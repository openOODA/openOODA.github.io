# TP-em-power: E-M ranking model (physics lens)

| Field | Value |
|-------|--------|
| **Paper ID** | `TP-em-power` |
| **TOOLS.md** | § E-M — physics (always) |
| **Status** | `draft` |
| **Series** | Process / agent-ops |

## 1. Why this is in TOOLS.md

Every agent turn must **rank and act**. The E-M (effectiveness / “power”) lens forces a single decision:

\[
P_s = V \cdot \frac{T - D_{\mathrm{drag}}}{W_{\mathrm{mass}}}
\]

| Symbol | Meaning in openOODA |
|--------|---------------------|
| \(V\) | Tempo — small ships, fast true fail |
| \(T\) | Thrust — capability locked by **quality tests** |
| \(D_{\mathrm{drag}}\) | Lies, ceremony (same spirit as high \(S\)) |
| \(W_{\mathrm{mass}}\) | Duplicate logic, residual bulk, monofiles |

**Always-on Act rule:** raise \(T\), cut drag/weight, protect \(V\), drive \(S\downarrow\) and \(O\downarrow\).

## 2. Problem statement

Without a ranking model, agents either thrash long tails or ship untested “thrust.” E-M is a **mnemonic control law**, not a measured SI power rating.

## 3. Related work

- **Control theory / OODA:** Boyd’s loop prioritizes tempo of correct decisions over peak force.  
- **Pareto / power-law prioritization:** Focus on vital few tasks (Juran’s vital few; software 80/20 practice).  
  - https://lawsofsoftwareengineering.com/laws/pareto-principle/  
- **SRE velocity vs reliability:** Error budgets balance innovation thrust against reliability drag.  
  - https://sre.google/workbook/error-budget-policy/  
- **Activation energy / catalysts (chemistry metaphor):** Cheap true-green tests lower barrier to correct ships; fixtures amortize later reactions.

## 4. Rationale for openOODA process

| E-M act | openOODA example |
|---------|------------------|
| Raise \(T\) | Ship behavior **with** pass+fail fixtures |
| Cut drag | Kill soft-pass, dual-engine theater |
| Cut mass | Split >256-line files; delete dead host surface |
| Protect \(V\) | Top ≤5 this turn; no monorepo thrash fan-out |

Chemistry under E-M (not a separate pick): activation energy, catalyst fixtures, purify before grow.

## 5. Limits of the science analogy

- Not electromagnetic power; units are not physical.  
- Formula is **qualitative ranking**, not optimizable continuous control.  
- Over-focus on \(V\) without \(T\) produces false greens (high drag).

## 6. Alternatives

| Alternative | Why E-M wins for agents |
|-------------|-------------------------|
| Backlog grooming alone | No honesty term |
| Story points | No test-thrust coupling |
| Only \(S\) | \(S\) measures; E-M **ranks action** |

## 7. Product / process reality

- Enforced in TOOLS “Always on” + Decide→Act→Lock.  
- Complements entropy \(S\): \(S\) is the scoreboard; E-M is the play call.  
- DESIGN architecture is **not** edited by E-M (TOOLS protocol).

## 8. Open questions

1. Should \(P_s\) ever be numeric, or stay qualitative?  
2. How to score “research paper progress” vs entropy ships without punishing vision work?

## 9. Acceptance criteria

- [ ] Agents cite E-M when picking top ≤5.  
- [ ] No ship that raises drag without residual honesty.

## 10. References

1. Google SRE — Error Budget Policy. https://sre.google/workbook/error-budget-policy/  
2. Pareto principle in software engineering. https://lawsofsoftwareengineering.com/laws/pareto-principle/  
3. openOODA `ooda/TOOLS.md` — E-M section.  
4. Boyd OODA literature (see also RP-1-1 design research paper).

---
*Series: [README.md](./README.md).*
