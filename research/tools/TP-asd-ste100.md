# TP-asd-ste100: ASD-STE100 Simplified Technical English

| Field | Value |
|-------|--------|
| **Paper ID** | `TP-asd-ste100` |
| **TOOLS.md** | Always-on — ASD-STE100 |
| **Status** | `draft` |
| **Series** | Process / agent-ops |

## 1. Why this is in TOOLS.md

All process and product writing targets **Simplified Technical English** (STE) discipline: controlled vocabulary and grammar to reduce ambiguity for humans and agents.

## 2. Problem statement

Ambiguous agent instructions and residual docs produce wrong acts, soft-pass language, and untranslatable claims. Controlled English is a **communication reliability** control.

## 3. Related work

- **ASD-STE100** — international standard for controlled technical English (aerospace heritage; Issue 9, 2025).  
  - Official: https://www.asd-ste100.org/  
  - About STE: https://www.asd-ste100.org/about_STE.html  
- **Wikipedia — Simplified Technical English.** https://en.wikipedia.org/wiki/Simplified_Technical_English  
- **Commercial checkers** — e.g. Boeing Simplified English Checker for compliance support.  
  - https://www.boeing.com/company/simplified-english-checker  

## 4. Rationale for openOODA process

- Residual honesty docs and TOOLS rules must be unambiguous.  
- Agents parse instructions poorly when prose is dense or marketing-heavy.  
- Complements fail-closed culture: clear ERR language.

## 5. Limits

- STE was built for maintenance manuals, not research papers or DESIGN vision prose.  
- Full STE compliance is hard; openOODA uses it as a **direction**, not a certified process.  
- Over-restriction can hurt precision in formal research (use STE for ops; allow denser prose in RP/TP research with definitions).

## 6. Alternatives

| Alternative | Why weaker |
|-------------|------------|
| Free prose only | Ambiguity for agents |
| Full formal specs only | High write cost |
| Emoji-first docs | Not residual-grade |

## 7. Product / process reality

- TOOLS lists STE as always-on.  
- Enforcement is **social/process**, not a CI linter today.  
- Research papers may be denser; still prefer clear structure.

## 8. Open questions

1. Add a lightweight STE lint for residual docs?  
2. Separate STE strictness for TOOLS vs DESIGN vs research?

## 9. Acceptance criteria

- [ ] TOOLS/PM/SPRINT prefer short, defined terms.  
- [ ] Soft-pass marketing banned in residual docs.

## 10. References

1. ASD-STE100 official site. https://www.asd-ste100.org/  
2. Simplified Technical English — Wikipedia. https://en.wikipedia.org/wiki/Simplified_Technical_English  
3. Boeing Simplified English Checker. https://www.boeing.com/company/simplified-english-checker  
4. openOODA `TOOLS.md`.

---
*Series: [README.md](./README.md).*
