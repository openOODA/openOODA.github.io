# RP-1.5: Compile-time type-state machines

## Abstract
This paper describes the compile-time type-state machine architecture in the openOODA language. Objects transition through explicit lifecycles defined in the type system. The compiler statically proves the validity of method calls based on the current state of an object. This mechanism eliminates entire classes of logic bugs before execution.

## 1. Introduction
Protocol and resource interfaces require stateful interactions. For example, a program must open a file before reading it. It must close the file when finished. Type systems with only nominal types allow invalid operations. A program can compile a read operation on an unopened file.

Developers often forget runtime checks. Artificial intelligence agents struggle to maintain complex implicit state rules. Runtime checks detect failures late in the development cycle. Static type-state checking moves this detection to compile time. The compiler rejects invalid sequences immediately. This early rejection is critical for automated code generation.

## 2. Architecture
The architecture integrates state definitions directly into the type system. A state machine defines discrete states such as unopened, opened, and closed. The state machine defines the allowed transitions between these states.

Transition functions consume the object in its old state and return it in a new state. The current state determines the available methods. For instance, the read method exists only for the opened state. The compiler tracks the linear flow of states. It prevents operations on consumed states. It prevents operations that bypass required transitions.

The architecture combines type-state with the capability system. A capability provides the authority to access a resource. The type-state tracks the protocol state of that specific resource. A program needs both the capability and the correct state to perform an operation.

## 3. Methodology
The methodology enforces protocol correctness at compile time. When a programmer or agent writes an invalid sequence, the compiler issues an immediate rejection. The compiler provides diagnostic data that suggests the legal transitions.

The design requires strict ownership rules to maintain sound state tracking. Unrestricted aliasing allows one reference to change the state while another reference expects the old state. The system uses linear or affine types for stateful resources. A resource can have only one active state at a time. This approach ensures that the compiler can accurately predict the state at any point in the program.

## 4. Conclusion
Compile-time type-state machines provide strong guarantees for protocol correctness. By embedding lifecycle rules into the type system, the compiler prevents invalid operations without runtime overhead. This mechanism guides artificial intelligence agents toward valid code sequences. It significantly improves the reliability of systems software.

---
*Series index: [README.md](./README.md).*
