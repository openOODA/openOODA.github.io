# RP-4.3.2: Deterministic reproducible builds

| Field | Value |
|-------|--------|
| **Paper ID** | `RP-4.3.2` |
| **DESIGN.md** | Section 4 Targets — Deterministic Reproducible Builds; Section 6.1 Tension with metamorphic binaries |
| **Status** | `draft` |
| **PM.md row** | `4.3.2` (**not-started**) |
| **Product mapping** | Fixed-point digests for self-host stages exist. Full multi-machine reproducible product builds are **not** claimed. |

## 1. Why this is in DESIGN.md

DESIGN.md Section 4 states:

> **Deterministic Reproducible Builds:** Sandboxed compilation makes sure that byte-for-byte hashes are identical on all machines.

Section 6.1 states:

> Compilation makes a byte-for-byte deterministic hash on the disk. The polymorphic metamorphism only occurs dynamically in the RAM.

Reproducibility is a control for the supply chain. Independent parties rebuild from the source code and compare the hashes. This detects compromised toolchains or continuous integration (CI) systems. The verifiable web of code (Section 5.2) and the cryptographic integrity of openOODA require deterministic artifacts on the disk. This is necessary even if the runtime metamorphism randomizes the images in the RAM (Section 3.11).

## 2. Problem statement

Sources of non-determinism (from the Reproducible Builds taxonomy):

| Source | Example |
|--------|---------|
| Timestamps | `__DATE__`, archive modification times, tar headers |
| File order | Directory read order in link lines |
| Randomness | Build IDs that affect ASLR, embedded random temporary names |
| Environment | `CFLAGS`, locale, umask, user IDs, group IDs |
| Unstable algorithms | Hash iteration order, parallel writes with race conditions |
| Toolchain float | Differences in patch levels for gcc or clang |

Without control, you cannot attest the `oodac` self-host and user releases.

## 3. Related work

### 3.1 Reproducible Builds project

The **Reproducible Builds** project (reproducible-builds.org) standardizes practices. It uses the **`SOURCE_DATE_EPOCH`** environment variable. Tools embed a fixed timestamp instead of the current time. Distributions (such as Debian) continuously rebuild packages and track failures.

### 3.2 Bazel and hermetic builds

**Bazel** emphasizes hermeticity, declared dependencies, and deterministic outputs for many language rules. There are some exceptions. The FAQ notes that Java and C++ are reproducible when the toolchains are stable. Content-addressed caching needs deterministic actions.

### 3.3 Other systems

- **Guix and Nix** — These make environments with bit-reproducible packages.
- **Gitian and in-toto** — These provide multi-party build attestation.
- **Go** — Uses `-trimpath`.
- **Rust** — Uses path remapping.
- **gcc** — Has `SOURCE_DATE_EPOCH` support.

### 3.4 What "sandboxed compilation" means in industry

Sandboxed compilation is not only seccomp. It requires **fixed inputs** (sources, flags, toolchain), a **normalized environment**, **stable ordering**, and **path remapping**. Path remapping prevents local checkout paths from leaking into the binaries.

## 4. Design rationale for openOODA

### 4.1 Layers of determinism

```text
L0  Source tree and lock or pin (BOOTSTRAP_PIN, seeds)
L1  Compiler pure function: the same AST makes the same emit text
L2  Host tools: gcc or clang flags, SOURCE_DATE_EPOCH
L3  Packaging: tar or zip order, gzip timestamps
L4  Runtime metamorphism (explicitly not on disk) — Section 6.1
```

For release artifacts, the DESIGN "sandboxed compilation" must cover L1 to L3.

### 4.2 Interaction with Backend-C

The product today:

- Pure emit-C must make **stable C text** from a stable AST.
- gcc can still embed non-determinism if you do not fix the flags and environment.
- `fixed_point.sh` proves that **stage-1 is equal to stage-2** digests for the self-host. It does not prove that **machine A is equal to machine B**.

### 4.3 Tension with metamorphic binaries (Section 6.1)

The DESIGN already resolves this tension: **disk artifacts are deterministic; RAM artifacts can morph**. Research must ensure:

- Hashes for release tarballs are stable.
- The immune-system mutation occurs **after** the load operation. It does not occur in the published bytes.
- The CI checks that the morph code is not in the artifact path by accident.

### 4.4 Capabilities and purity

The build sandbox must **deny network access** by default. It must not download plugins during compilation. This aligns with the capability ethos. The compile-time `&NetCap` is only for explicit, intent-driven features (Section 2.3). These features are residual.

## 5. Threat and failure model

### Helps detect or prevent

- A compromised CI that makes a backdoored `oodac` when the source code is clean. This requires an independent rebuild to match.
- Path leakage or fingerprinting of the build machines.
- Silent changes in the toolchain between developers.

### Does not prevent

- The same malicious toolchain on all machines that rebuild.
- Hardware implants.
- Backdoors in the source code. Reproducibility keeps the backdoors.
- Tests that are not deterministic. For example, tests that use the wall clock without `TimeCap`.

## 6. Alternatives considered

| Alternative | Verdict |
|-------------|---------|
| **Best-effort only** | Not sufficient for the vision in Section 5.2. |
| **Full Nix or Guix port** | Strong, but too heavy for the alpha release. |
| **Bazelize monorepo** | Possible in the future, but not necessary to start. |
| **Record-and-replay builds** | Complements the base, but needs determinism first. |
| **Trust only signed releases** | Necessary, but not sufficient. |

## 7. Product reality (alpha honesty)

**PM.md row 4.3.2 is not-started** for a complete reproducible-builds program.

| Existing strength | Gap |
|-------------------|-----|
| Fixed-point self-host digests | Not a proof for multi-machine reproducible builds. |
| Release `.sha256` sidecars | Attest the published bytes, but do not attest the rebuild sameness. |
| Pure `.oo` path reduces host-language changes | Still depends on gcc and the seed. |
| BOOTSTRAP_PIN | Pins the seed, but does not provide a full hermetic gcc. |

Do **not** claim Debian-grade reproducibility for the openOODA alpha release.

## 8. Open research questions

1. **Minimum flag set** for gcc determinism on the product link line.
2. Should emit-C normalize the temporary identifiers?
3. Bitcode versus object reproducibility for the future LLVM path.
4. How to gate the metamorphic runtime so that CI artifact builds never enable it.
5. Software Bill of Materials (SBOM) and in-toto layout for the releases.
6. Cross-architecture reproducible matrices (x86_64 first).

## 9. Acceptance criteria (for PM status promotion)

### not-started to smoke

- [ ] Two clean containers with the same pin and source code have the same `sha256` hash for `oodac`, **or** there is a documented single intentional difference.
- [ ] The product release script path honors `SOURCE_DATE_EPOCH`.

### smoke to partial

- [ ] There is a documented hermetic environment (locale, umask, PATH).
- [ ] The CI job fails if there is a mismatch.
- [ ] There is a policy for path remapping and `__FILE__`.

### partial to done

- [ ] There are public rebuild instructions for the last release.
- [ ] Section 6.1 tests: the disk hash is stable with the morph feature compiled in, but the feature is inactive on the disk.
- [ ] There is a user guide for reproducible application builds.

## 10. References

1. Reproducible Builds project. https://reproducible-builds.org/
2. `SOURCE_DATE_EPOCH` specification and documentation. https://reproducible-builds.org/docs/source-date-epoch/
3. Wikipedia: Reproducible builds overview. https://en.wikipedia.org/wiki/Reproducible_builds
4. Bazel FAQ (determinism and reproducibility). https://bazel.build/about/faq
5. Conan blog: deterministic C/C++ builds. https://blog.conan.io/2019/09/02/Deterministic-builds-with-C-C++.html
6. openOODA: `DESIGN.md` Section 4 and Section 6.1; `PM.md` row 4.3.2; `scripts/fixed_point.sh`; release checksums.

---

*Series: [Research papers index](./README.md). Related: [RP-6.1 Metamorphic vs deterministic](./RP-6-1-tension-metamorphic-vs-deterministic.md), [RP-5.2 Web of code](./RP-5-2-verifiable-web-of-code.md).*
