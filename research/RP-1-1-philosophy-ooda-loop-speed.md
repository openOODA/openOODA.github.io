# RP-1.1: Philosophy of speed (OODA loop)

## Abstract
This paper presents the philosophy of speed in the openOODA language. The design centers on the Observe, Orient, Decide, Act (OODA) loop. It combines sub-millisecond compile times with rich metadata to ensure the fastest possible feedback cycle. This cycle connects human intent, machine generation, and compiler validation.

## 1. Introduction
The openOODA language engineers its foundation around the OODA loop. Loop tempo serves as the primary design rule. The system evaluates every feature by its effect on this loop. We classify features as loop enablers or loop taxes. The system does not view features in isolation.

Without this philosophy, feature creep expands compile times. Features like contracts and macros add checks that slow the edit-compile-test cycle. As a result, the language loses its advantage over dynamic languages. Furthermore, human and machine speeds diverge. Humans tolerate slow compiles, but artificial intelligence agents fail if they must wait. The agents require a fast loop to operate.

## 2. Architecture
The architecture separates development and production environments into a dual loop system. The tactical loop focuses on development. It provides sub-millisecond validation through a fast backend. The strategic loop focuses on production. It targets peak performance across multiple environments. The design ensures that slow production features do not delay tactical feedback.

The system provides metadata for orientation. The compiler generates diagnostic data, structural outlines, and reflection data. This metadata makes machine orientation incremental and structured. A traditional compiler with only text errors forces agents to read the entire program again. This action wastes time and processing tokens.

The system integrates with other architectural pillars. It provides direct tools for agents to observe and act. It supports mathematical contracts that make decisions checkable without destroying the compile tempo. It performs static capability checks incrementally.

## 3. Methodology
We derive our methodology from military theory and software engineering. John R. Boyd designed the original OODA loop as a decision cycle under uncertainty. The side that cycles faster and understands better gains the advantage. In openOODA, the observation phase involves reading source code and metadata. The orientation phase involves understanding the program model. The decision phase involves selecting a patch plan. The action phase involves applying a surgical patch and recompiling.

Software engineering applies similar concepts through short feedback cycles. Live programming environments decrease the time from observation to action. Fast systems languages balance safety checks with compile times.

## 4. Conclusion
The philosophy of speed ensures that openOODA remains effective for artificial intelligence agents. The design enforces strict time limits for the OODA loop. The system provides structured metadata to improve orientation quality. This approach prevents the language from becoming too slow for automated use.

---
*Series index: [README.md](./README.md).*
