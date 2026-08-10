# RP-5.7: Universal native LSP

| Field | Value |
|-------|--------|
| **Paper ID** | `RP-5.7` |
| **DESIGN.md** | §5 Ecosystem |
| **Status** | `draft` |
| **PM.md row** | `5.7` |
| **Product mapping** | **not-started** |

## 1. Reason for inclusion in DESIGN.md

DESIGN.md Section 5 states:

> The compiler runs as a background daemon in less than one millisecond. It uses the open Language Server Protocol (LSP). You can connect it to Neovim, CLI-based AI agents, Cursor, or other environments. You are not locked to one editor.

The openOODA project requires a fast path that does not use a proprietary IDE plugin. LSP connects editors and language tools. We make the native compiler serve LSP to get these results:

1. **One set of rules** for CLI `ooda check` and IDE error markers.
2. **Agent portability** for Cursor, Neovim tools, and headless agents.
3. **Self-host purity** to write the LSP daemon in `.oo`, not Rust.

## 2. Problem statement

### 2.1 The cost of editor lock-in

Language teams often release official VS Code extensions that use private protocols. This causes:

- New implementations for Neovim, Emacs, and JetBrains.
- Different software bugs in different editors.
- Excluded agents, because many agents use LSP or CLI instead of private protocols.

### 2.2 The cost of two frontends

A separate analysis engine has high costs. For example, `rust-analyzer` and `rustc` require much code and years of work. Sometimes they use different rules. But, a standard `rustc` compiler is too slow for IDE users.

The openOODA project needs interactive feedback in less than one second. Our goal is less than one millisecond. To do this, we must use shared file systems and incremental queries. We must not do a full compile for each keystroke.

### 2.3 Users

- Human users of Neovim, VS Code, Cursor, and Helix.
- Headless AI agents that control diagnostics and code changes.
- Continuous Integration (CI) systems that use the same daemon.

## 3. Related work

### 3.1 Standards

- **Language Server Protocol (LSP)**: Uses JSON-RPC over stdio or TCP. It supports diagnostics, completion, hover, rename, and code actions.
- **Build Server Protocol and debug adapters**: Tool protocols that we can add later.

### 3.2 Architecture literature

The rust-analyzer documents give good examples:

- "Three Architectures for a Responsive IDE": Shows the differences between a reused compiler, a separate analyzer, and a hybrid system.
- "The Heart of a Language Server" (2023): Explains laziness. The system only analyzes what the user interface needs. It does not do a full check for each keystroke.
- Incremental query engines: Use a dependency graph of calculations to save time.

Other related work includes incremental parsing, interactive typechecking, and IDE-oriented compilers. openOODA already uses tree-sitter for syntax highlight.

### 3.3 Commercial systems

| System | Approach | Result |
|--------|----------|----------|
| **rust-analyzer** | Separate incremental frontend | Excellent IDE, but requires dual maintenance. |
| **Roslyn (C#)** | Compiler-as-platform APIs | Batch and IDE share the same components. |
| **clangd** | clang-based LSP | Reuses the real parser and semantics. |
| **gopls** | Dedicated Go LSP written in Go | Fits well in a self-hosted ecosystem. |
| **typescript-language-server** | Compiler services | Shares rules with `tsc`. |
| **Pyright / Pylance** | Fast, specialized checkers | Gives speed, but does not use full CPython rules. |

**The openOODA plan:** We will use compiler libraries to power the LSP. We will use laziness. We will write the host in `.oo`.

### 3.4 Product baseline

The file `cli/main.oo` rejects the command `ooda lsp`. We have tree-sitter and VS Code TextMate grammar for syntax, but not for semantic LSP. We use JSON diagnostics from `ooda check --json-errors` as the first payload for `textDocument/publishDiagnostics`.

## 4. Design rules for openOODA

### 4.1 Goals

| Goal | Description |
|------|---------|
| Universal | Supports any LSP client. No editor lock-in. |
| Native | Uses a compiled daemon, not a Python bridge. |
| Pure | Uses a `.oo` implementation. |
| Shared rules | Uses the same core as the CLI. |
| Agent-first | Maps codes and code actions to a patch. |
| Fast | Uses incremental updates. Records the time budget for each request. |

### 4.2 Proposed architecture

```text
┌─────────────────────────────────────────┐
│  LSP front (JSON-RPC, stdio)  .oo       │
├─────────────────────────────────────────┤
│  Session / virtual file system          │
├─────────────────────────────────────────┤
│  Query engine                           │
├─────────────────────────────────────────┤
│  oodac check core (same as CLI)         │
└─────────────────────────────────────────┘
```

- **Phase 0 (Smoke):** When a file opens or changes, run the current check. Map the result to an LSP Diagnostic.
- **Phase 1 (Daemon):** Keep parsed modules in memory. Delete them when the file changes.
- **Phase 2 (Queries):** Add symbol index, hover, and goto definition from a shared layer.
- **Phase 3 (Actions):** Apply patches as a WorkspaceEdit.

### 4.3 Capabilities for the daemon

The LSP process reads the workspace. The product must do these things:

- Give an explicit file system capability (`&FsCap`) for the workspace.
- Stop network access by default.
- Use a workspace trust model like VS Code.

We must use self-host purity. An LSP in a different language will ignore our capability rules for plugins.

### 4.4 The sub-millisecond goal

The design documents promise feedback in less than one millisecond. The research paper separates these claims:

| Claim | Reality |
|-------------|-------------|
| Marketing design | A goal for small files and cache hits. |
| Product alpha | Less than one second is a success. Less than one millisecond is not required. |
| Measurement | We measure p50 and p95 latency in CI. |

Do not stop the approval of RP-5.7 if global times are more than one millisecond.

### 4.5 Feature priority

1. Diagnostics (JSON codes)
2. Document symbols and outline
3. Hover information
4. Goto definition
5. Contextual completion
6. Code actions and rename
7. Formatting

## 5. Threat and failure model

### 5.1 What the design prevents

- Editor lock-in.
- Different rules, because the wrapper shares the check core.
- Agents that cannot operate without an IDE.

### 5.2 What the design does not prevent

- Malicious workspace files that attack the daemon. We need capabilities and a sandbox.
- Slow performance on very large repositories if we do not use incremental work.
- Clients that do not use LSP and run unsafe commands.

### 5.3 Failure modes

| Mode | Solution |
|------|------------|
| Dual engine drift | Share libraries. Test CLI diagnostics against LSP diagnostics. |
| Full compile for each keystroke | Use debounce and cache. Then use queries. |
| Pure `.oo` is too slow | Profile the code. Add native extensions later if necessary. Do not rewrite in Rust. |
| Too many features | Release diagnostics first. |

## 6. Examined alternatives

| Alternative | Decision |
|-------------|---------|
| **VS Code-only extension** | Rejected. This causes editor lock-in. |
| **Tree-sitter only** | Rejected. Syntax highlight is not sufficient. |
| **Separate analyzer in Rust** | Rejected. This violates the purity rule. |
| **Batch compile only** | Rejected. This gives a bad user experience. |
| **WASM LSP in browser only** | Rejected. This is a good extra, but not a native daemon. |

## 7. Product status

The PM.md file shows that row `5.7` is **not-started**.

| Component | Status |
|-------|-------|
| `ooda lsp` | Rejected on CLI. |
| Semantic daemon | None. |
| Syntax grammar | Tree-sitter and VS Code TextMate exist. |
| JSON diagnostics CLI | Almost done. We will use this for the future LSP. |
| Outline | Done for parse only. We will map this to LSP symbols later. |

## 8. Open research questions

1. Should we use a shared library or a separate binary in the same repository?
2. How can we show capability signatures in hover messages without too much text?
3. How do we do incremental deletion for multi-root workspaces?
4. Should agents use LSP or CLI JSON for patch loops?
5. Can we stream narrative diagnostics as related information in LSP diagnostics?
6. What is the memory limit for a daemon that always runs on a laptop?

## 9. Acceptance criteria

### From not-started to smoke

- [ ] The command `ooda lsp` uses LSP initialize and publishes diagnostics for one open file.
- [ ] We document that it works with at least one editor, for example, Neovim.
- [ ] It is a pure `.oo` binary. It does not use a Rust host.

### From smoke to partial

- [ ] It uses incremental or debounced `didChange` without a process restart.
- [ ] It matches `documentSymbol` with `ooda outline`.
- [ ] It keeps diagnostic codes in the LSP `code` field.
- [ ] Tests show that CLI diagnostics match LSP diagnostics.

### From partial to done

- [ ] It supports hover and goto definition for local symbols.
- [ ] It supports at least one code action from fix hints.
- [ ] We document the workspace `FsCap` policy.
- [ ] We measure the latency. The p95 time must be less than one second on a test project.
- [ ] It does not require a proprietary editor protocol.

## 10. References

1. Language Server Protocol specification.
2. The rust-analyzer blog.
3. Salsa incremental computation framework documentation.
4. Roslyn compiler-as-a-service design documents.
5. Architecture notes for gopls and clangd compilation database models.
6. The tree-sitter project.
7. openOODA DESIGN Section 5 LSP.

---

*Series: [Research papers index](./README.md). Template: [TEMPLATE.md](./TEMPLATE.md).*
