# DOC-product-readme: Product README as public honesty surface

| Field | Value |
|-------|--------|
| **Paper ID** | `DOC-product-readme` |
| **Subject document(s)** | `ooda/README.md` (+ release notes) |
| **Status** | `draft` |
| **Series** | Documentation system (`DOC-*`) |

## 1. Why this document exists

README is the public entrypoint: install, what’s real this version, residual table, rails. Tighter honesty than DESIGN; more accessible than PM.

## 2. Problem statement

Users and agents land on README first. Overclaims (JIT, free, full fuzz) raise trust entropy immediately.

## 3. Related work (university + commercial)

- Open-source README norms (quickstart, limitations).
- Living documentation — review each release.
- Release notes as versioned delta; README as current snapshot.

## 4. Rationale for openOODA

What’s real → PM done/partial/smoke; residual table → residual docs; quickstart → FLOOR+seed; not beta → BETA.md.

## 5. Limits and failure modes

Cannot hold full DESIGN checklist. Can lag monorepo PM. Install pin must match BOOTSTRAP_PIN/site.

## 6. Alternatives considered

Wiki-only, issue-tracker-only, single mega-README, or oral tradition — all fail multi-agent continuity or honesty. Prefer git-versioned markdown with clear roles.

## 7. Reality (honesty)

Strong honesty surface for v0.183.0-alpha; keep aligned with site pin.

## 8. Open questions

1. Generate residual table from residual headers?
2. Single source for version string?

## 9. Acceptance criteria

- [ ] No beta/JIT/full-free claims without proof.
- [ ] Version matches release pin.

## 10. References

1. ooda/README.md
2. https://www.infoq.com/articles/book-review-living-documentation/

---
*Index: [README.md](./README.md). DESIGN research: [../README.md](../README.md). TOOLS research: [../tools/README.md](../tools/README.md).*
