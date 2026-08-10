# DOC-ops-control: Ops handoff, release, split, session docs

| Field | Value |
|-------|--------|
| **Paper ID** | `DOC-ops-control` |
| **Subject document(s)** | `bootstrap/DEBT_HANDOFF.md`, `bootstrap/RELEASE_CHECKLIST.md`, `bootstrap/SPLIT_PLAN.md`, monorepo `SHUTDOWN_RESUME.md` |
| **Status** | `draft` |
| **Series** | Documentation system (`DOC-*`) |

## 1. Why these documents exist

Not every control surface is vision, progress, or sprint board. Ops control docs freeze **cross-session continuity**, **release discipline**, **file-size policy**, and **debt transfer** so multi-agent work survives shutdowns without inventing process mid-flight.

| Doc | Role |
|-----|------|
| `DEBT_HANDOFF.md` | Known debt packages for the next agent/owner |
| `RELEASE_CHECKLIST.md` | Ship steps before a version tag |
| `SPLIT_PLAN.md` | How to keep source under ≤256 lines |
| `SHUTDOWN_RESUME.md` | Session state: tip, blockers, next Act |

## 2. Problem statement

Agents die mid-turn. Humans pause for days. Without handoff artifacts:

- debt is rediscovered as “new” bugs (entropy **W**),
- releases skip purity/residual gates,
- monofiles grow past modularity limits,
- resume re-explores what SPRINT already knew.

SPRINT holds cycle truth; these docs hold **transferable** truth at different cadences.

## 3. Related work (university + commercial)

- **Incident handoff / runbooks** (SRE) — state + next action, not narrative dumps. https://sre.google/sre-book/managing-incidents/
- **Release checklists** — commercial CD gates; separate eligibility from authority (see also DOC-beta).
- **Modularization plans** — extract method / split file policies in maintainability literature; openOODA hard-caps lines (TOOLS ≤256).
- **Session notes / standup artifacts** — short continuity over full postmortems.

## 4. Rationale for openOODA

| Doc | Cadence | Owns |
|-----|---------|------|
| DEBT_HANDOFF | After depth landings | Packaged residual + owner intent |
| RELEASE_CHECKLIST | Pre-tag | Commands, residual honesty, pin |
| SPLIT_PLAN | When near 256 | Target splits, not redesign |
| SHUTDOWN_RESUME | End of session | Tip, WIP, do-not-touch |

Relationship to triad:

- **DESIGN** — never rewritten by handoff docs.
- **PM** — residual index may point at handoff packages.
- **SPRINT** — tip/M-table; SHUTDOWN_RESUME must not disagree for long.
- **TOOLS** — power law and ≤256 need SPLIT_PLAN as concrete policy.

## 5. Limits and failure modes

- Handoffs become novels → agents skip them (violate ASD-STE100 / power law).
- RELEASE_CHECKLIST soft-passes residuals → fake release readiness.
- SPLIT_PLAN without mechanical enforcement → monofiles re-grow.
- SHUTDOWN_RESUME stale after resume → worse than none if trusted blindly.

## 6. Alternatives considered

- **Only SPRINT.md** — overloads sprint board; debt depth and release steps drown M-table.
- **Only git log / issues** — multi-agent continuity fails without curated “next Act.”
- **Oral tradition** — zero transfer across sessions.
- Prefer short, role-specific markdown under bootstrap/monorepo.

## 7. Reality (honesty)

Present as living process docs (2026-08). Quality varies with last author discipline. Not CI-enforced. Beta tag authority remains owner-only (BETA.md), not RELEASE_CHECKLIST alone.

## 8. Open questions

1. Should DEBT_HANDOFF be required by TOOLS when entropy **W** (waste) is high?
2. Auto-generate SHUTDOWN_RESUME tip SHA from SPRINT pin?
3. CI fail if any owned `.oo` exceeds 256 without SPLIT_PLAN entry?

## 9. Acceptance criteria

- [ ] Each ops doc states its single job in the first section.
- [ ] No ops doc claims product feature `done` (that is PM).
- [ ] SHUTDOWN_RESUME tip matches SPRINT or is explicitly “stale.”
- [ ] RELEASE_CHECKLIST links residual honesty and BETA gates.

## 10. References

1. https://sre.google/sre-book/managing-incidents/
2. Sibling papers: [DOC-sprint.md](./DOC-sprint.md), [DOC-beta.md](./DOC-beta.md), [DOC-tools.md](./DOC-tools.md)

## Conflicts with other docs / series

**SHUTDOWN_RESUME vs SPRINT tip** → SPRINT is board of record for cycle; resume must re-pin if drift.
**DEBT_HANDOFF vs residual `*RESIDUAL*.md`** → residual = deep technical truth; handoff = transfer package pointing at residuals.
**RELEASE_CHECKLIST vs BETA.md** → checklist prepares; owner cuts beta.

---
*Index: [README.md](./README.md).*
