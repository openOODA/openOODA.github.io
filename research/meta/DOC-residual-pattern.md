# DOC-residual-pattern: Residual honesty documents

| Field | Value |
|-------|--------|
| **Paper ID** | `DOC-residual-pattern` |
| **Subject document(s)** | `ARC_M2_RESIDUAL.md`, `FUZZ_DEFER.md`, `P4_DROPS.md`, `AUDIT_RESIDUAL.md`, … |
| **Status** | `draft` |
| **Series** | Documentation system (`DOC-*`) |

## 1. Why this document exists

A residual is deliberately incomplete or unsafe to claim. Residual markdown pins what is not done, rebuild commands, and anti-claims so agents cannot soft-pass.

## 2. Problem statement

Without residual files, partial work is remembered as complete. Entropy U/F/W explodes. DESIGN leaves need deep “not yet” truth longer than a SPRINT line.

## 3. Related work (university + commercial)

- Product “limitations” sections (commercial docs).
- SRE deferred reliability work.
- Fail-closed security documentation.
- Living documentation — residuals must update when closed (Martraire).

## 4. Rationale for openOODA

Pattern: status · shipped subset · still residual · rebuild · related paths. Index from PM residual table.

## 5. Limits and failure modes

Too many residual files → unread. Must link from PM. Closing requires test + PM flip.

## 6. Alternatives considered

Wiki-only, issue-tracker-only, single mega-README, or oral tradition — all fail multi-agent continuity or honesty. Prefer git-versioned markdown with clear roles.

## 7. Reality (honesty)

Core honesty culture; residual_honesty_smoke guards some claims.

## 8. Open questions

1. Naming standard *_RESIDUAL.md only?
2. Auto-list from directory glob into PM?

## 9. Acceptance criteria

- [ ] Every deep partial/residual PM item points at a residual or README section.
- [ ] No soft-pass fixed without residual update.

## 10. References

1. https://www.infoq.com/articles/book-review-living-documentation/
2. ooda/bootstrap residual set; TOOLS entropy F,W

---
*Index: [README.md](./README.md). DESIGN research: [../README.md](../README.md). TOOLS research: [../tools/README.md](../tools/README.md).*
