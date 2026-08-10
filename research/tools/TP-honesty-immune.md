# TP-honesty-immune: Honesty budget & immune rail

| Field | Value |
|-------|--------|
| **Paper ID** | `TP-honesty-immune` |
| **TOOLS.md** | § Optional second — Honesty budget + immune rail |
| **Status** | `draft` |
| **Series** | Process / agent-ops |

## 1. Why this is in TOOLS.md

Default **second tool** when hunting lies. Trust is framed as:

\[
\text{Trust} \propto \frac{\text{true signals}}{\text{false greens} + \text{untested claims}}
\]

Directly attacks \(U, D, F, W\) in entropy \(S\).

## 2. Problem statement

False greens destroy agent and human OODA loops: they teach the wrong model of the product. “Immune” fail fixtures reject non-self (wrong behavior) the way negative selection rejects pathogens.

## 3. Related work

- **Google SRE error budgets:** Budget false reliability; freeze change when budget is burned.  
  - https://sre.google/workbook/error-budget-policy/  
  - https://sre.google/sre-book/embracing-risk/  
- **Property-based / contract testing:** Generators find counterexamples to claimed invariants.  
- **Negative selection / immune algorithms (AIS literature):** Fail cases as non-self detectors (metaphor only).  
- **openOODA residual honesty smokes:** Explicit anti-soft-pass probes in product rails.

## 4. Rationale for openOODA process

| Science act | openOODA act |
|-------------|--------------|
| Immune / negative selection | Fail fixtures reject non-self |
| Error budget ≈ 0 for *claims* | No accumulating false greens on critical paths |
| Entropy export | True fail+pass should lower \(S\) |

**Never install non-truth to look done.**

## 5. Limits

- Biological immune systems are not software CI.  
- SRE error budgets allow *some* unreliability; openOODA **claim** budget is stricter (fail-closed residuals).  
- Over-testing theater can raise ceremony drag (\(D_{\mathrm{drag}}\) in E-M).

## 6. Alternatives

| Alternative | Why weaker |
|-------------|------------|
| Coverage % gates alone | Miss soft-pass semantics |
| Manual QA only | Doesn’t scale to agents |
| “Trust the author” | Fails AI co-author threat model |

## 7. Product / process reality

- Fail-closed product residuals: **real culture**.  
- `residual_honesty_smoke` and related rails: **present**.  
- Full dual-engine \(D\) may be obsolete—keep immune rail, update terms.

## 8. Open questions

1. Formalize “critical path” for \(F\) counting?  
2. Auto-generate fail fixtures from residual docs?

## 9. Acceptance criteria

- [ ] Default second tool when \(U/F/W\) suspected.  
- [ ] No soft-pass banners in product smokes.

## 10. References

1. Google SRE Workbook — Error Budget Policy. https://sre.google/workbook/error-budget-policy/  
2. Google SRE Book — Embracing Risk. https://sre.google/sre-book/embracing-risk/  
3. openOODA `TOOLS.md`, residual honesty rails.

---
*Series: [README.md](./README.md).*
