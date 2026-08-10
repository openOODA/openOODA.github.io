# Documentation-system research papers (`DOC-*`)

These papers justify **why openOODA keeps specific markdown control documents**
(DESIGN, PM, SPRINT, TOOLS, residuals, …).

They are **not** product feature papers (`RP-*`) and **not** process-lens papers (`TP-*`).

| Series | Path | Question |
|--------|------|----------|
| DESIGN features | [`../README.md`](../README.md) | Why is this **in the language**? |
| TOOLS process | [`../tools/README.md`](../tools/README.md) | Why do we **work** this way? |
| **Doc system (this)** | `research/meta/` | Why does this **document** exist? |

## Papers (14)

| ID | Document | Paper |
|----|----------|-------|
| DOC-system-triad | DESIGN · PM · SPRINT overview | [DOC-system-triad.md](./DOC-system-triad.md) |
| DOC-design | `DESIGN.md` | [DOC-design.md](./DOC-design.md) |
| DOC-pm | `PM.md` | [DOC-pm.md](./DOC-pm.md) |
| DOC-sprint | `SPRINT.md` | [DOC-sprint.md](./DOC-sprint.md) |
| DOC-tools | `TOOLS.md` | [DOC-tools.md](./DOC-tools.md) |
| DOC-beta | `bootstrap/BETA.md` | [DOC-beta.md](./DOC-beta.md) |
| DOC-residual-pattern | Residual honesty docs | [DOC-residual-pattern.md](./DOC-residual-pattern.md) |
| DOC-floor-chs | `FLOOR.md` + `CHS.md` | [DOC-floor-chs.md](./DOC-floor-chs.md) |
| DOC-product-readme | Product `README.md` | [DOC-product-readme.md](./DOC-product-readme.md) |
| DOC-org-hygiene | `ORG_PRODUCT_HYGIENE.md` | [DOC-org-hygiene.md](./DOC-org-hygiene.md) |
| DOC-rfc-spec | `spec/` DESIGN/SPEC/RFCs | [DOC-rfc-spec.md](./DOC-rfc-spec.md) |
| DOC-research-series | Research series itself | [DOC-research-series.md](./DOC-research-series.md) |
| DOC-stubs-retired | `PROGRESS.md` / `PROJECT.md` stubs | [DOC-stubs-retired.md](./DOC-stubs-retired.md) |
| DOC-ops-control | DEBT_HANDOFF · RELEASE_CHECKLIST · SPLIT_PLAN · SHUTDOWN_RESUME | [DOC-ops-control.md](./DOC-ops-control.md) |

## Status

All listed papers are **`draft`** (2026-08-09).

Optional later: install README, site-only pages, QA probes — extend this index when they become stable control surfaces.

## Filing map (where docs live → which paper)

| Location | Control docs | Paper |
|----------|--------------|-------|
| `ooda/DESIGN.md`, `spec/DESIGN.md` | Vision | DOC-design, DOC-system-triad |
| monorepo `PM.md` | Progress vs DESIGN | DOC-pm |
| monorepo `SPRINT.md` | Cycle board | DOC-sprint |
| `ooda/TOOLS.md` | Process protocol | DOC-tools (+ `TP-*`) |
| `ooda/bootstrap/*RESIDUAL*`, `FUZZ_DEFER`, … | Honesty pins | DOC-residual-pattern |
| `bootstrap/FLOOR.md`, `CHS.md` | Bootstrap fences | DOC-floor-chs |
| `bootstrap/BETA.md` | Beta gates | DOC-beta |
| `ooda/README.md` | Public honesty | DOC-product-readme |
| monorepo `ORG_PRODUCT_HYGIENE.md` | Org purity story | DOC-org-hygiene |
| `spec/` + `rfcs/` | Normative evolution | DOC-rfc-spec |
| `docs/research/` | Research corpus | DOC-research-series |
| monorepo stubs | Retired PROGRESS/PROJECT | DOC-stubs-retired |
| bootstrap ops + session | Handoff / release / split / resume | DOC-ops-control |
