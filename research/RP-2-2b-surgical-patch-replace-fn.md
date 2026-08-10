# RP-2.2b: Surgical Function Replacement

**Abstract**
This paper presents a theoretical framework for surgical function replacement in the openOODA system. Artificial intelligence agents require safe, constrained mechanisms to modify source code. Traditional whole-file write operations introduce severe security and correctness risks. This architecture introduces a fail-closed tool that atomizes edits at the function level. This design enforces the principle of least privilege for automated code mutations. It prevents widespread corruption and ensures mathematical contract integrity during the action phase of the agent loop.

## 1. Introduction

The surgical modification of Abstract Syntax Trees (AST) requires precise tools. In the openOODA architecture, agents operate through a continuous feedback loop. The diagnostic phase provides structured observation data. The action phase requires a safe mechanism to apply corrections. Agents use a fail-closed tool to rewrite source code at the function level. This tool does not evaluate shell commands or overwrite the entire file.

Whole-file agent writes fail consistently in systems languages. They cause the drift of unrelated functions, which silently damages capability and contract requirements. Partial writes or system crashes during edits corrupt source files. When language models execute shell commands directly, they introduce severe injection vulnerabilities and reduce portability. Furthermore, simple search and replace operations frequently mismatch targets. They duplicate anchors or select incorrect function overloads. Most dangerously, these open modifications lack immediate revalidation. Consequently, a supposedly fixed code segment can still fail theoretical checks.

Agents need a constrained editor designed as an Application Programming Interface (API). This editor must utilize a small command vocabulary, safe file paths, atomic replacement guarantees, and explicit failure messages. The design thesis relies on the principle of least privilege for edits. The default tool for agents can change only one named function per operation. It cannot modify the broader file system.

## 2. Related Work

Commercial and open-source agent editing formats vary significantly. Some systems use complete file search and replace with unified diffs. Other systems use dedicated exact match operations. Some environments implement structured create, update, and delete diffs directly through tool harnesses. Development reports from recent years show that artificial intelligence models fail at different rates depending on the format. Developers must validate code completely after every patch application.

Classical automated program repair modifies abstract syntax trees by inserting or replacing statements. Refactoring engines in modern languages show that structural edits provide superior reliability. However, the concept that syntax tree edits outperform text modifications remains uncommon in production agent systems. Most production agents still use text operations with limited structural constraints.

Safe tool usage provides security at the operational level. This mechanism operates separately from internal language capabilities. The tool utilizes the principle of least privilege. It only permits function replacement and rejects all unknown operations. If a malicious model attempts to execute a shell command through the JSON schema, the tool rejects it safely. Few languages provide a native patch interface that enforces function-level granularity, utilizes a JSON operation protocol, sandboxes file paths, guarantees atomic writes, and prevents execution of new code during the patch phase.

## 3. Architecture and Methodology

The theoretical product interface defines a strict operational command. The patch engine accepts a specific file, the target function name, and the replacement body. It can process commands directly through the command line or via JSON standard input. The tool fails closed when it encounters an unknown operation. It never executes the replacement body text. The system strictly enforces path rules. It rejects traversal attempts and confines all operations to relative paths within the current directory. It performs all writes atomically.

Function replacement represents the highest priority operational mode. This mode restricts risk to localized areas. Line-range replacement creates high potential for incorrect usage. True node identifier replacement provides optimal precision but requires mathematically stable identifiers across parsing sessions. Function insertion and deletion change the overall API surface. Whole-file replacement presents extreme risk of damage and remains discouraged for automated agents. Function-level changes match the fundamental operational patterns of coding agents. This granularity also perfectly matches the data provided by structural outline commands.

This action tightly couples with the earlier phases of the agent loop. The outline command allows the agent to select a target name. The reflection command identifies the mathematical contracts and security capabilities that the agent must preserve. The model proposes a replacement body. The patch tool executes the function replacement. Finally, the validation tool generates diagnostic errors to continue the cycle. The policy maintains existing contract requirement and guarantee text during a replacement. The system replaces only the core body. This ensures that contracts remain statically verified.

The threat model incorporates extensive mitigations. The system rejects path traversal and confines operations to the current directory. It allows only the function replacement operation to prevent command smuggling. Atomic replacement prevents partial writes. The tool never executes patched code to prevent accidental execution. Single-name replacement limits silent multi-function damage. The validation engine, rather than the patch tool, manages unsafe foreign function interface calls.

Residual failures remain possible. The language structure requires complex disambiguation if multiple functions share a name. Textual replacement engines can break nested structures if brace balancing fails. Careless replacement can delete critical mathematical contracts if the operation encompasses the signature block. The file can change between the outline and patch phases. Finally, the tool will write malicious body content if proposed. Subsequent validation and testing must detect these malicious insertions. The patch mechanism is not a general refactoring engine. It does not provide security boundaries for multi-tenant software as a service. It does not replace the execution sandbox for running code.

## 4. Conclusion

Surgical function replacement provides a vital security layer for autonomous coding operations. This theoretical architecture replaces dangerous whole-file writes with constrained, atomic function replacements. This methodology aligns with the principle of least privilege. Future research must address stable node identifiers across formatting changes, transaction mechanisms for multi-function replacements, and cryptographic attestation for automated modifications.

---
*Series index: [README.md](./README.md).*
