# DOC-tools: TOOLS.md as process protocol

| Field | Value |
|-------|--------|
| **Paper ID** | `DOC-tools` |
| **Subject document(s)** | `ooda/TOOLS.md` |
| **Status** | `draft` |
| **Series** | Documentation system (`DOC-*`) |

## 1. Why this document exists

TOOLS.md defines how agents and humans act each turn: always-on invariants (E-M, entropy S, ≤256 lines, power law, fail-closed, pure product), optional science lenses, Decide→Act→Lock. Process law, not language architecture.

## 2. Problem statement

Without process constraints, multi-agent systems optimize for appearance (soft-pass green, monofiles, host creep) and burn tokens.

## 3. Related work (university + commercial)

- Google SRE error budgets. https://sre.google/workbook/error-budget-policy/
- Little/Amdahl/VoI — see TP papers.
- ASD-STE100. https://www.asd-ste100.org/
- Deep process research: docs/research/tools/ (TP-*).

## 4. Rationale for openOODA

TOOLS ranks work and exports entropy. Does not edit DESIGN. Complements PM (status) and SPRINT (cycle).

## 5. Limits and failure modes

Science metaphors overclaim risk; dual-engine D may be stale; PROGRESS report wording should point at PM/SPRINT.

## 6. Alternatives considered

Wiki-only, issue-tracker-only, single mega-README, or oral tradition — all fail multi-agent continuity or honesty. Prefer git-versioned markdown with clear roles.

## 7. Reality (honesty)

TOOLS is product-tree process canon; TP series drafted; links to PM/SPRINT/research.

## 8. Open questions

1. Auto-report S in CI?
2. Retire D formally?

## 9. Acceptance criteria

- [ ] TOOLS links TP research and PM/SPRINT.
- [ ] Always-on rules treated as non-optional.

## 10. References

1. https://sre.google/workbook/error-budget-policy/
2. ooda/TOOLS.md; docs/research/tools/README.md

---
*Index: [README.md](./README.md). DESIGN research: [../README.md](../README.md). TOOLS research: [../tools/README.md](../tools/README.md).*
