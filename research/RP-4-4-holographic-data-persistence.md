# RP-4.4: Holographic data persistence

| Field | Value |
|-------|--------|
| **Paper ID** | `RP-4.4` |
| **DESIGN.md** | §4 Targets — Holographic Data Persistence |
| **Status** | `draft` |
| **PM.md row** | `4.4` (**not-started**) |
| **Product mapping** | Not implemented. The product does not have a transparent RAM to NVMe structural mapping. |

## 1. Reason for inclusion in DESIGN.md

DESIGN.md section 4 states:

> **Holographic Data Persistence:** A structure in RAM can map directly to a persistent, immutable Merkle tree on an NVMe drive. There is no `save()` function. If the server loses power, the exact memory state materializes upon boot. Data becomes immortal.

This is a very ambitious systems claim in section 4. It combines orthogonal persistence (single-level store) with Merkle integrity for verifiable state. This aligns with the cryptographic and zero-trust themes of openOODA.

This paper connects the idea to existing technology (memory-mapped databases, persistent memory, Merkle trees, and local-first synchronization). It carefully defines marketing terms such as "immortal," "exact memory state," and "no save()".

## 2. Problem statement

### 2.1 The classical persistence gap

Applications save data manually (with `save()`, object-relational mapping, or checkpoints). This causes failures:

- If you forget to save, you lose data.
- If you save partially, you corrupt data.
- It is difficult to migrate schemas.
- Agents must remember input/output protocols instead of pure state logic.

### 2.2 The meaning of "holographic"

We infer these intended properties from the DESIGN wording:

1. **Orthogonal persistence.** Object graphs stay durable without explicit conversion.
2. **Byte-addressable mapping.** NVMe or persistent memory acts as addressable memory space (or the system uses `mmap` to simulate it).
3. **Immutability and Merkle trees.** Versions link together as hash trees to provide integrity and synchronization.
4. **Crash continuity.** A power loss results in a consistent restore operation.

These are four separate research problems, not one software feature.

## 3. Related work

### 3.1 Memory-mapped embedded databases (LMDB)

Lightning Memory-Mapped Database (LMDB) puts a B+ tree in a memory map. Read operations can return pointers into the map with almost no copying. LMDB has ACID transactions and handles pages with copy-on-write (COW). It gives in-memory speed and disk durability if you obey its API rules. It does not support arbitrary C structures with pointers.

Lesson: The combination of `mmap`, COW pages, and strict data layouts works. Native pointers do not survive a remap operation.

### 3.2 Persistent memory hardware

Hardware like Intel Optane persistent memory (pmem) lets software use `libpmem` operations. These operations include cache flushes, memory fences, and atomic updates. The software must still manage crash consistency. Arbitrary data structures do not get this automatically. Hardware availability decreased, but the software techniques still apply to NVMe with DRAM.

### 3.3 Orthogonal persistence and single-level stores

Older operating systems and research systems tried to make primary memory and secondary storage identical. This causes problems with pointer translation, schema evolution, parallel execution, and write amplification.

### 3.4 Merkle trees and verifiable state

Merkle trees (and their variations) provide:

- Snapshots that show if someone changed them.
- Cheap proofs of inclusion.
- Synchronization through hash reconciliation.

They do not map arbitrary RAM graphs automatically. They store data in an explicit tree or key-value format.

### 3.5 Local-first synchronization

ElectricSQL is a synchronization engine for PostgreSQL. It uses partial replication and CRDT-based conflict resolution. It is not:

- A transparent mapper of process RAM to NVMe.
- A "no save()" solution for general structures in a systems language.
- A replacement for a file system or LMDB inside a language runtime.

It is useful to compare it for synchronizing application data. It is not proof that the openOODA holographic runtime exists. Other local-first systems (like Automerge or Replicache) also synchronize documents and state. They do not do OS-level orthogonal persistence.

## 4. Design rationale for openOODA

### 4.1 Language-shaped persistence

A possible openOODA design:

```text
persistent struct User { ... } 
```

The compiler restricts persistent data types:

- They cannot use raw OS pointers.
- They must use explicit handles or offsets into a managed heap area.
- They require capability tokens: `&PersistCap` to create or map them.
- They must publish a Merkle root for verification.

### 4.2 Interpretation of "no save()"

Honest definitions:

| Marketing phrase | Technical meaning |
|--------|------------------------|
| No save() | The runtime writes data continuously to a journal on NVMe or pmem. |
| No save() | The code uses an explicit `transaction { }` block, which is a commit boundary. |
| No save() | The system uses `mmap` and `msync` at safe points. |

It is false to say that a power loss perfectly restores all RAM, including CPU caches, without special hardware and flush protocols.

### 4.3 Relation to temporal memory

Temporal memory gives you a short window to undo changes in RAM. Holographic persistence makes data durable for a long time. These use different memory areas. Do not confuse them. The tension between Automatic Reference Counting (ARC) and temporal memory will also happen between ARC and persistent areas.

### 4.4 Capability model

- The system must deny arbitrary file write operations. This prevents users from bypassing the Merkle integrity check.
- Persistent graphs that contain `#[Secret]` data must encrypt that data at rest. This requires more research.

## 5. Threat and failure model

| Threat | Notes |
|--------|-------|
| Bit rot and silent disk corruption | Merkle trees help detect this, but cannot repair it alone. |
| Torn writes | You need an atomic page or transaction protocol. |
| Pointer revival undefined behavior | The compiler must prevent native pointers in persistent types. |
| Rollback attacks | The system needs signed roots or a capability to open the store. |
| "Immortal" data claims | This conflicts with the GDPR right to erasure. You need tombstone markers. |

This design does not prevent logical bugs from writing the wrong state. It does not prevent ransomware if the malware has the store capability. It does not stop side-channel attacks.

## 6. Alternatives considered

| Alternative | Verdict |
|-------------|---------|
| **Explicit serialization and files** | Realistic for the product, but not in the DESIGN. |
| **LMDB-backed persistent maps** | A strong foundation for a Minimum Viable Product (MVP). |
| **SQLite** | Very common, but has heavier semantics. |
| **Full pmem hardware dependency** | Not portable to all systems. |
| **CRDT document layer only** | Solves synchronization, not systems-level structures. |
| **External synchronization (ElectricSQL)** | Good for the ecosystem, but not for the language runtime. |

**Recommended research MVP:** Build typed persistent maps or memory areas on LMDB or custom COW pages with Merkle roots. Do not try to support "any structure in RAM."

## 7. Product reality (alpha phase)

**The PM.md status for 4.4 is "not-started."**

- The product file system uses standard `chs_rt` file APIs with capabilities. It is not holographic.
- There is no Merkle store. The process heap does not transparently remap when the system boots.
- The DESIGN text remains a goal for future research.

**Honesty rule:** You must never say that the alpha version of openOODA has immortal, automatic memory persistence. If demonstrations use LMDB through FFI, call it library persistence. Do not call it a holographic runtime.

### 7.1 Risks in the DESIGN text

| Phrase | Risk | Better alternative |
|--------|------|--------|
| "exact memory state" | Ignores CPU registers, caches, and threads. | "last consistent persistent snapshot" |
| "no save()" | Hides the commit or flush operation. | "no manual serialization; transactional durability" |
| "Data becomes immortal" | An exaggeration for legal and operations teams. | "data retains integrity-versioned durability" |
| "immutable Merkle-tree on NVMe" | Acceptable if it is true. | Keep it, but specify that an update creates a new root. |

## 8. Open research questions

1. Pointer translation (swizzling) versus offset-only heaps.
2. Schema evolution of persistent structures.
3. Multi-process shared memory maps and capability checks.
4. The correct order for encryption and Merkle hashing.
5. How this interacts with metamorphic binaries (code versus data stores).
6. The minimum specification for an MVP persistent map API.

## 9. Acceptance criteria

### 9.1 From not-started to smoke

- [ ] A persistent map (or API) survives a process restart on one operating system.
- [ ] The system verifies the integrity hash of the store when it opens the store.
- [ ] The user needs a capability token to open or create the store.

### 9.2 From smoke to partial

- [ ] The system passes a crash-consistency test (a `kill -9` command during an update does not cause silent corruption).
- [ ] The system gives the Merkle root (or hash chain root) to the user.
- [ ] The compiler forbids raw host pointers in persistent data types.

### 9.3 From partial to done

- [ ] The documentation explains the durability model (what data flushes to disk and what data does not).
- [ ] The system supports multi-structure graphs, or the DESIGN narrows its scope to simple maps.
- [ ] The specification clearly states how this system is different from local-first tools like ElectricSQL.

## 10. References

1. LMDB documentation and overview: http://www.lmdb.tech/doc/ ; https://en.wikipedia.org/wiki/Lightning_Memory-Mapped_Database
2. ElectricSQL introduction (local-first PostgreSQL synchronization) (adjacent, not equivalent): https://electric.ax/blog/2023/09/20/introducing-electricsql-v0.6
3. ElectricSQL landscape note (scope of synchronization engines): https://www.localfirst.fm/landscape/electricsql
4. Sparse Merkle and persistent tree systems (for integrity): see industry SMT articles.
5. openOODA: `DESIGN.md` sections 4, 3.8, 6.2; `PM.md` section 4.4.

---

*Series: [Research papers index](./README.md). Related: [RP-3.8 Temporal memory](./RP-3-8-temporal-memory-rollback.md), [RP-5.2 Web of code](./RP-5-2-verifiable-web-of-code.md).*
