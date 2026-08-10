# DOC-floor-chs: FLOOR.md and CHS.md bootstrap fences

| Field | Value |
|-------|--------|
| **Paper ID** | `DOC-floor-chs` |
| **Subject document(s)** | `bootstrap/FLOOR.md`, `bootstrap/CHS.md` |
| **Status** | `draft` |
| **Series** | Documentation system (`DOC-*`) |

## 1. Why this document exists

FLOOR.md is backend policy (Backend-C today). CHS.md is the compiler-host language subset for self-host. Together they freeze the chicken-egg bootstrap surface.

## 2. Problem statement

Self-hosting dies when host subset and backend float. Agents invent IR targets mid-bootstrap.

## 3. Related work (university + commercial)

- Language bootstrap literature (Rust stages, OCaml, Go, Scheme).
- Profile/tier specs (WASM profiles, Java SE subsets).
- Portable C as pragmatic IR/floor.
- See RP-4-x Backend-C product floor.

## 4. Rationale for openOODA

CHS = allowed self-host surface; FLOOR = how native code is produced; DESIGN §4 = long-term multi-target north star.

## 5. Limits and failure modes

CHS can lag product growth. FLOOR is not “C forever.” Seed binary remains outside pure .oo (explicit TCB).

## 6. Alternatives considered

Wiki-only, issue-tracker-only, single mega-README, or oral tradition — all fail multi-agent continuity or honesty. Prefer git-versioned markdown with clear roles.

## 7. Reality (honesty)

Backend-C + seed is alpha product path. FLOOR/CHS are active control docs.

## 8. Open questions

1. Version CHS with releases?
2. F3 second backend criteria only in FLOOR?

## 9. Acceptance criteria

- [ ] Bootstrap docs cite FLOOR/CHS.
- [ ] PM 4.x matches FLOOR claims.

## 10. References

1. ooda/bootstrap/FLOOR.md, CHS.md
2. RP-4-x; https://adr.github.io/

---
*Index: [README.md](./README.md). DESIGN research: [../README.md](../README.md). TOOLS research: [../tools/README.md](../tools/README.md).*
