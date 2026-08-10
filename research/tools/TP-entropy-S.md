# TP-entropy-S: Trust entropy \(S = U+D+F+W+O\)

| Field | Value |
|-------|--------|
| **Paper ID** | `TP-entropy-S` |
| **TOOLS.md** | § Entropy \(S\) — thermodynamics (always measure) |
| **Status** | `draft` |
| **Series** | Process / agent-ops |

## 1. Why this is in TOOLS.md

TOOLS.md needs a **single integer proxy for trust-surface disorder**: untested claims, dual-engine lies, fail-open holes, hand-waves, and oversize files. Thermodynamics supplies the metaphor of **entropy export**: quality tests and fail-closed residuals should lower disorder. The formula is operational, not laboratory physics.

\[
S = U + D + F + W + O
\]

## 2. Problem statement

Without a shared score, agents and humans ship **false greens**: features claimed without fail rails, soft-pass residuals, and monofile bloat. Token-burning thrash rises because no one can rank “fix honesty” against “add feature.” The problem is **epistemic debt**, not only code debt.

## 3. Related work (university + commercial)

- **Information theory / reliability culture:** Shannon entropy measures uncertainty of a distribution; openOODA’s \(S\) is a **deliberately crude additive proxy** for untrustworthy claims—not a probability mass.  
- **Google SRE error budgets:** Reliability is budgeted; burning the budget freezes feature work until trust recovers. False greens are the software analog of unmeasured outages.  
  - Google SRE Workbook: error budget policy — https://sre.google/workbook/error-budget-policy/  
  - Embracing risk / SLO framing — https://sre.google/sre-book/embracing-risk/  
- **Fail-closed security engineering:** Critical paths refuse ambient success without proof (capability systems, verified boot literature).  
- **Technical debt metrics:** Industry trackers (Sonar, code coverage gates) count *code* smells; \(S\) counts *trust* smells (\(U,F,W\)) plus modularity (\(O\)).

## 4. Rationale for openOODA process

openOODA’s product culture is fail-closed residuals + pure product path. \(S\) operationalizes that culture for **agent turns**:

| Term | Trust failure mode | openOODA act |
|------|-------------------|--------------|
| \(U\) | Untested claim | Add pass+fail fixture before claiming |
| \(D\) | Dual-engine disagreement | Align pure path; drop dual lies |
| \(F\) | Fail-open / soft-pass | Fail-closed residual docs + tests |
| \(W\) | Hand-wave “done” | Residual honesty smoke |
| \(O\) | File > 256 lines | Split plan + `check_file_lines.sh` |

**Ship rule:** feature that raises \(S\) or \(O\) without plan fails the entropy test. Splits that drop \(O\) are first-class progress.

## 5. Limits of the science analogy

- Not thermodynamic entropy; no state space or Boltzmann constant.  
- Integer sum is **ordinal, not cardinal** precision—do not optimize \(S\) to theater.  
- \(D\) may shrink as dual-engine product path dies—redefine or retire when pure path is sole truth.  
- Coverage tools can game \(U\); prefer behavioral pass+fail fixtures over line coverage vanity.

## 6. Alternatives considered

| Alternative | Why weaker for openOODA |
|-------------|-------------------------|
| Code coverage % only | Misses soft-pass and residual lies |
| Story points / velocity | Ignores trust |
| Bug count alone | Reactive; \(S\) is proactive claim hygiene |
| Full formal verification always | Too expensive per turn; \(S\) ranks work |

## 7. Product / process reality (honesty)

- Line lock \(O\): **enforced** via `scripts/check_file_lines.sh` (target O=0).  
- Residual honesty rails exist (`residual_honesty_smoke`, fail-closed product).  
- Dual-engine \(D\): may be **legacy term** if product is pure-only—TOOLS should stay aligned with current product.  
- Report format still references PROGRESS pins; prefer **PM.md / SPRINT.md** for pin reports now.

## 8. Open questions

1. Should \(D\) be redefined or removed post pure-path monopoly?  
2. Weighting: should \(F\) critical-path items count >1?  
3. Auto-compute \(U\) from residual docs vs manual count?

## 9. Acceptance criteria

- [ ] Agents report \(S\) components on ship without inventing precision.  
- [ ] \(O\) always from checker.  
- [ ] Document maps \(S\) to PM residual docs, not DESIGN feature claims.

## 10. References

1. Google SRE Workbook — Error Budget Policy. https://sre.google/workbook/error-budget-policy/  
2. Google SRE Book — Embracing Risk. https://sre.google/sre-book/embracing-risk/  
3. openOODA `ooda/TOOLS.md` — Entropy \(S\) definition.  
4. openOODA `bootstrap/SPLIT_PLAN.md`, `scripts/check_file_lines.sh`.

---
*Series: [README.md](./README.md).*
