# RP-1.4: First-class AST macros

## Abstract
This paper presents the design of first-class Abstract Syntax Tree macros in the openOODA language. The compiler allows standard functions to execute during compile time. These functions rewrite the Abstract Syntax Tree. This approach provides powerful metaprogramming capabilities while maintaining native readability.

## 1. Introduction
Systems languages require metaprogramming to generate repetitive code, embed domain-specific checks, and configure systems. Without native macros, developers must use external code generators. External generators break the capability model and reduce system purity. Manual code duplication reduces the speed of the development loop and introduces errors.

Traditional macro systems use string generation or token manipulation. These approaches produce untyped code and obscure errors. Separate macro languages increase the cognitive load for developers. They also reduce the effectiveness of artificial intelligence agents. The openOODA language solves these problems. It uses ordinary functions that operate directly on the Abstract Syntax Tree during compile time.

## 2. Architecture
The architecture defines macros as standard functions that accept and return Abstract Syntax Tree values. The system enforces a strict phase separation. The compile-time host environment remains distinct from the runtime target environment. The compiler treats syntax tree nodes as data.

The system executes macros within a sandboxed interpreter. Compile-time functions cannot access the file system or network without explicit capabilities. This restriction prevents supply-chain attacks during the build process. The macro expansion must remain deterministic. The same source code always produces the same expanded output.

The compiler traces the expansion process. It generates metadata that maps the expanded code back to the original macro invocation. This diagnostic data helps artificial intelligence agents understand the generated code.

## 3. Methodology
The methodology ensures that macro authors write standard openOODA code. The macro system uses quasi-quote syntax to construct new tree nodes. It propagates source spans to maintain accurate error reporting. The system bounds the execution time of macros. This limit preserves the speed of the development loop.

The design separates compile-time macros from edit-time surgical patches. Patches modify the source files directly. Macros expand code inside the compiler pipeline. The design also separates macros from probabilistic code synthesis. Macros must perform deterministic, pure transformations.

## 4. Conclusion
First-class Abstract Syntax Tree macros provide a safe and readable metaprogramming system. They allow libraries to extend the language syntax without modifying the compiler. By operating on structured data within a capability-secure sandbox, the system enables powerful code generation without compromising security or compile speed.
