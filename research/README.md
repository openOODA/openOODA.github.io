# openOODA design research papers

One research paper **per DESIGN.md item** (main and sub-items).
Purpose: **justify why the item is in DESIGN.md**, with problem, prior art, and openOODA rationale.

| Doc | Role |
|-----|------|
| `openOODA/DESIGN.md` | Vision |
| monorepo `PM.md` | Progress status per item |
| monorepo `SPRINT.md` | Active engineering work |
| **this series (`RP-*`)** | Research justification per DESIGN item |
| **[tools/](./tools/README.md) (`TP-*`)** | Process research for `ooda/TOOLS.md` |
| **[meta/](./meta/README.md) (`DOC-*`)** | Why control docs exist (DESIGN/PM/SPRINT/TOOLS/…) |

## Draft status (2026-08-09)

All **49** DESIGN leaf papers are filled as **`draft`** (not stubs).  
Cross-design fights and owner decisions: **[CONFLICTS.md](./CONFLICTS.md)**.

Promote individually: `draft` → `review` → `accepted` after human read.

## Status of papers

Baseline: all leaf papers are **`draft`**. Promote to `review` → `accepted` after human review. New DESIGN leaves start as `planned` stubs from TEMPLATE.md.

## Template

Copy [TEMPLATE.md](./TEMPLATE.md) only if adding a new DESIGN leaf; prefer the pre-created stub for each ID.

## Index (by DESIGN.md)

| ID | Title | DESIGN | Paper |
|----|-------|--------|-------|
| `ES.1` | AI-native systems language | Executive Summary | [RP-ES-1-es-ai-native-systems-language.md](./RP-ES-1-es-ai-native-systems-language.md) |
| `ES.2` | Capability-secure by construction | Executive Summary | [RP-ES-2-es-capability-secure.md](./RP-ES-2-es-capability-secure.md) |
| `ES.3` | Self-testing language surface | Executive Summary | [RP-ES-3-es-self-testing.md](./RP-ES-3-es-self-testing.md) |
| `ES.4` | Sub-second development feedback | Executive Summary | [RP-ES-4-es-subsecond-feedback.md](./RP-ES-4-es-subsecond-feedback.md) |
| `ES.5` | Zero-day defense goals | Executive Summary | [RP-ES-5-es-zero-day-defense.md](./RP-ES-5-es-zero-day-defense.md) |
| `ES.6` | Embedded to global verifiable network | Executive Summary | [RP-ES-6-es-scale-embedded-to-network.md](./RP-ES-6-es-scale-embedded-to-network.md) |
| `1.1` | Philosophy of speed (OODA loop) | §1 Language | [RP-1-1-philosophy-ooda-loop-speed.md](./RP-1-1-philosophy-ooda-loop-speed.md) |
| `1.2` | Mathematical contracts (requires/ensures) | §1 Language | [RP-1-2-mathematical-contracts.md](./RP-1-2-mathematical-contracts.md) |
| `1.3` | Data-oriented design & SoA layout | §1 Language | [RP-1-3-data-oriented-design-soa.md](./RP-1-3-data-oriented-design-soa.md) |
| `1.4` | First-class AST macros | §1 Language | [RP-1-4-first-class-ast-macros.md](./RP-1-4-first-class-ast-macros.md) |
| `1.5` | Compile-time type-state machines | §1 Language | [RP-1-5-compile-time-type-state.md](./RP-1-5-compile-time-type-state.md) |
| `2.1` | Surgical AST patching & JSON diagnostics | §2 AI tooling | [RP-2-1-surgical-ast-patching.md](./RP-2-1-surgical-ast-patching.md) |
| `2.2` | Token-minimized APIs (outline/reflect) | §2 AI tooling | [RP-2-2-token-minimized-apis.md](./RP-2-2-token-minimized-apis.md) |
| `2.2b` | Surgical patch replace_fn | §2 AI tooling | [RP-2-2b-surgical-patch-replace-fn.md](./RP-2-2b-surgical-patch-replace-fn.md) |
| `2.3` | Intent-driven compilation (telepathic AST) | §2 AI tooling | [RP-2-3-intent-driven-compilation.md](./RP-2-3-intent-driven-compilation.md) |
| `2.4` | Global hive-mind fuzzing | §2 AI tooling | [RP-2-4-global-hive-mind-fuzzing.md](./RP-2-4-global-hive-mind-fuzzing.md) |
| `3.1` | Unified capability sandboxing | §3 Safety | [RP-3-1-unified-capability-sandboxing.md](./RP-3-1-unified-capability-sandboxing.md) |
| `3.2` | Time & entropy sandboxing | §3 Safety | [RP-3-2-time-entropy-sandboxing.md](./RP-3-2-time-entropy-sandboxing.md) |
| `3.3` | Memory quotas (heap sandboxing) | §3 Safety | [RP-3-3-memory-quotas-heap-sandbox.md](./RP-3-3-memory-quotas-heap-sandbox.md) |
| `3.4` | CPU quotas (#[MaxCycles]) | §3 Safety | [RP-3-4-cpu-quotas-maxcycles.md](./RP-3-4-cpu-quotas-maxcycles.md) |
| `3.5` | Static taint tracking (#[Secret]) | §3 Safety | [RP-3-5-static-taint-secret.md](./RP-3-5-static-taint-secret.md) |
| `3.6` | Automated contract fuzzer | §3 Safety | [RP-3-6-automated-contract-fuzzer.md](./RP-3-6-automated-contract-fuzzer.md) |
| `3.7` | 0ms GC & memory safety (ARC/RAII) | §3 Safety | [RP-3-7-zero-ms-gc-arc-raii.md](./RP-3-7-zero-ms-gc-arc-raii.md) |
| `3.8` | Temporal memory (state rollback) | §3 Safety | [RP-3-8-temporal-memory-rollback.md](./RP-3-8-temporal-memory-rollback.md) |
| `3.9` | Cryptographic call-graph integrity | §3 Safety | [RP-3-9-cryptographic-call-graph-integrity.md](./RP-3-9-cryptographic-call-graph-integrity.md) |
| `3.10` | Shadow-state semantic reversion | §3 Safety | [RP-3-10-shadow-state-semantic-reversion.md](./RP-3-10-shadow-state-semantic-reversion.md) |
| `3.11` | Polymorphic metamorphic binaries | §3 Safety | [RP-3-11-polymorphic-metamorphic-binaries.md](./RP-3-11-polymorphic-metamorphic-binaries.md) |
| `4.1.1` | Development bytecode VM | §4 Targets | [RP-4-1-1-development-bytecode-vm.md](./RP-4-1-1-development-bytecode-vm.md) |
| `4.1.2` | Production LLVM backend | §4 Targets | [RP-4-1-2-production-llvm.md](./RP-4-1-2-production-llvm.md) |
| `4.1.3` | Universal GPU/NPU acceleration | §4 Targets | [RP-4-1-3-gpu-npu-acceleration.md](./RP-4-1-3-gpu-npu-acceleration.md) |
| `4.1.4` | Direct WebAssembly | §4 Targets | [RP-4-1-4-direct-webassembly.md](./RP-4-1-4-direct-webassembly.md) |
| `4.1.5` | Bare-metal embedded (no_std) | §4 Targets | [RP-4-1-5-bare-metal-embedded.md](./RP-4-1-5-bare-metal-embedded.md) |
| `4.2` | Native hot-code reloading | §4 Targets | [RP-4-2-native-hot-code-reloading.md](./RP-4-2-native-hot-code-reloading.md) |
| `4.3.1` | Cross-language LTO | §4 Targets | [RP-4-3-1-cross-language-lto.md](./RP-4-3-1-cross-language-lto.md) |
| `4.3.2` | Deterministic reproducible builds | §4 Targets | [RP-4-3-2-deterministic-reproducible-builds.md](./RP-4-3-2-deterministic-reproducible-builds.md) |
| `4.3.3` | Compile-time FFI generation | §4 Targets | [RP-4-3-3-compile-time-ffi-generation.md](./RP-4-3-3-compile-time-ffi-generation.md) |
| `4.4` | Holographic data persistence | §4 Targets | [RP-4-4-holographic-data-persistence.md](./RP-4-4-holographic-data-persistence.md) |
| `4.x` | Backend-C product floor | §4 Targets (product reality) | [RP-4-x-backend-c-product-floor.md](./RP-4-x-backend-c-product-floor.md) |
| `5.1` | 100% self-hosted ecosystem | §5 Ecosystem | [RP-5-1-self-hosted-ecosystem.md](./RP-5-1-self-hosted-ecosystem.md) |
| `5.1a` | Pure product compiler + CLI | §5 Ecosystem | [RP-5-1a-pure-product-compiler-cli.md](./RP-5-1a-pure-product-compiler-cli.md) |
| `5.2` | Verifiable web of code (zero-trust packages) | §5 Ecosystem | [RP-5-2-verifiable-web-of-code.md](./RP-5-2-verifiable-web-of-code.md) |
| `5.3` | Fearless concurrency | §5 Ecosystem | [RP-5-3-fearless-concurrency.md](./RP-5-3-fearless-concurrency.md) |
| `5.4` | Standard library philosophy (core vs os) | §5 Ecosystem | [RP-5-4-stdlib-core-vs-os.md](./RP-5-4-stdlib-core-vs-os.md) |
| `5.5` | Narrative diagnostics | §5 Ecosystem | [RP-5-5-narrative-diagnostics.md](./RP-5-5-narrative-diagnostics.md) |
| `5.6` | Human-in-the-loop (hitl) testing | §5 Ecosystem | [RP-5-6-hitl-testing.md](./RP-5-6-hitl-testing.md) |
| `5.7` | Universal native LSP | §5 Ecosystem | [RP-5-7-universal-native-lsp.md](./RP-5-7-universal-native-lsp.md) |
| `6.1` | Tension: metamorphic vs deterministic builds | §6 Tensions | [RP-6-1-tension-metamorphic-vs-deterministic.md](./RP-6-1-tension-metamorphic-vs-deterministic.md) |
| `6.2` | Tension: ARC vs temporal memory | §6 Tensions | [RP-6-2-tension-arc-vs-temporal-memory.md](./RP-6-2-tension-arc-vs-temporal-memory.md) |
| `6.3` | Tension: capability sandbox vs C/C++ FFI | §6 Tensions | [RP-6-3-tension-caps-vs-ffi.md](./RP-6-3-tension-caps-vs-ffi.md) |

## How to fill a paper

1. Open the stub for the DESIGN leaf.
2. Write §1–6 and §10 (justification + research).
3. Keep §7 honest against **PM.md** (product reality).
4. Set acceptance criteria in §9 for PM status promotion.
5. Mark paper status `draft`/`review`/`accepted` in the header table.

## Naming

`RP-<id>-<slug>.md` where `<id>` matches PM.md row IDs (e.g. `3.6`, `4.1.1`).

