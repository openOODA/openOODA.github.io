# RP-4.2: Native Hot-Code Reloading for High-Availability Virtual Machines

## Abstract
This paper discusses native hot-code reloading for long-lived system processes. A Just-In-Time (JIT) virtual machine can swap a new Abstract Syntax Tree (AST) into a running process. This code swap lets developers edit programs without losing the active application state. Without hot-code reloading, a system must restart. A restart causes the system to lose in-memory state and close active network connections. This paper examines the problems of basic hot-code reloading. It presents a theoretical design for a secure virtual machine model. The design ensures security and maintains system capabilities during a code swap.

## 1. Introduction
Hot-code reloading is a necessary feature for long-lived processes. Examples of these processes include game loops, agent workers, and local system daemons. A developer must be able to change code quickly. Every code patch usually causes a full system rebuild and execution restart. This slow process occurs even if the developer only changes one small function body.

Without hot-code reloading, a system cannot apply supervised software upgrades. High-availability system goals become impossible to reach. However, basic hot-code reloading causes other problems. New code can expect different memory layouts for data structures. Old code can remain on the active execution stack. Reloaded code can increase access rights if the system does not check the security types again. A system must manage state changes carefully to avoid fatal errors.

## 2. Background and Related Work
Other programming languages use different methods to solve code replacement problems. Erlang uses two versions of a module at the same time. The active processes migrate to the new version when the next function call occurs. Java uses debugging tools to change the method body during execution. Common Lisp and Smalltalk allow developers to redefine code interactively. Systems languages often use dynamic library plugins with a strict programming interface. Native hot-code reloading combines these concepts into a secure virtual machine model.

## 3. Architecture and Methodology
The primary model for native hot-code reloading uses a virtual machine. The virtual machine swaps the executable code at a safe point. Safe points occur between agent loop turns, at a thread yield, or when a new system message arrives.

The hot-code reload pipeline follows a strict execution sequence. First, the system receives an AST difference from the developer. Second, the system checks the new function again in the active module context. Third, the system creates bytecode for that new function. Finally, the system publishes the function atomically into the virtual machine function table. The system must reject the code swap if the AST patch fails type checks or capability checks.

## 4. Implementation Design
For Ahead-Of-Time (AOT) native code, the system must reload the dynamic library of the patched module. The system does not do a zero-copy AST swap in this mode. Changes to data structure layouts require a full system restart. The system cannot safely map old data to new data formats automatically. The system must run all security contracts again on entry after the code swap.

## 5. Security Considerations
Security is a primary concern for hot-code reloading operations. A reload must not grant new capabilities that the initial process manifest does not list. A reload must not go around established security sinks. The system must verify all new modules before it accepts them.

The system must reject reloads that change memory layouts. This rule prevents type confusion attacks. The system must use version control gates. These gates ensure that only one developer or process can publish new code at one time. The system uses strict module unload policies. These policies prevent memory resource leaks from old code versions.

## 6. Conclusion
Native hot-code reloading improves the developer experience. It also enables high-availability systems. The virtual machine model provides a safe and secure way to swap executing code. The system must enforce strict checks during the swap process. These checks prevent capability forgery and memory allocation errors. The architectural design allows developers to edit code without losing the active application state. This capability is essential for modern, long-lived computer processes.
