# Phaser Metaprogramming Model

This document outlines the high-level model for the compile-time metaprogramming capabilities of the Phaser language. This model represents a powerful and flexible vision for the language's metaprogramming features, integrated into the [[Compilation Pipeline]].

See also: [[Grammar Specification]] for syntax details.

## Core Components & Ideas

Phaser design philosophy is [Multi-stage Programming (MSP)](https://en.wikipedia.org/wiki/Multi-stage_programming)

### The `meta` Layer

The model introduces a `meta` layer, a distinct layer of code that is executed at compile time. This `meta` code uses the same base syntax as the regular Phaser code, allowing for a consistent and familiar developer experience.

### Sand-boxed Execution

All `meta` code runs within a secure **WASM (WebAssembly) sandbox**. This sandbox has a well-defined interface, referred to as a **WASM 'world'**, which grants access to specific capabilities. This approach prevents uncontrolled side effects and ensures the safety and stability of the compilation process.

### Controlled Side Effects

The `meta` layer can perform side effects, such as I/O operations, but only through the capabilities provided by the sandbox. For example, file I/O would be mediated by the compiler, which could treat the output as diagnostics, generated assets, or other forms of structured output, rather than allowing direct access to the host filesystem.

## Meta-programming Capabilities

### Code Generation

`meta` code can generate new code using a quasi-quoting or template-based mechanism. This allows for the type-safe and programmatic construction of code at compile time. This is a powerful feature for reducing boilerplate and creating domain-specific language (DSL) extensions.

### Library Re-usability

The `meta` environment is powerful enough to run standard Phaser libraries. This promotes code reuse between the compile-time and runtime layers, allowing developers to leverage the same libraries for both Meta-programming and application logic.

### Meta-Object Protocol (MOP)

The Meta-Object Protocol (MOP) is a first-class, fundamental part of the Phaser language. The language's own features, such as the behavior of `struct`s or even `async/await`, are intended to be implemented using the MOP.

The MOP provides the ability to inspect and transform the Abstract Syntax Tree (AST) of the code, allowing for deep customization of the language's semantics. This makes the language incredibly flexible and extensible, blurring the line between the compiler and the user's code.

A key example of the MOP's power is the ability to implement `async/await` as a library. This would involve the MOP providing the capabilities to:

- **Inspect** the body of a function.
- **Transform** the function's body into a state machine.
- **Manage** the `await` points within the function.

This approach of using the MOP to define the language itself is a form of "dogfooding" that leads to a highly extensible and powerful language design.
