# Phaser Language Documentation

This directory contains the official documentation for the Phaser programming language, focusing on language design, features, and usage patterns.

## 📋 Language Specification

### Core Design
- **[[Design Principles]]** - Fundamental principles guiding Phaser's design philosophy
- **[[Grammar Specification]]** - Complete EBNF grammar defining Phaser's syntax
- **[[language/Metaprogramming model|Metaprogramming model]]** - Compile-time metaprogramming capabilities and WASM sandbox architecture

### Programming Guide
- **[[Language Examples]]** - Comprehensive examples demonstrating Phaser syntax and features
- **[[language/Code Organization|Code Organization]]** - Recommended patterns for structuring Phaser programs

## 🎯 Document Purpose

### Language Specification
Documents that define **what Phaser is** and how it works:
- **Grammar and Syntax**: Formal definition of valid Phaser code
- **Type System**: How types work, inference, and safety guarantees
- **Metaprogramming**: Compile-time code generation and evaluation
- **Memory Model**: Ownership, borrowing, and lifetime management

### Programming Patterns
Documents that show **how to use Phaser** effectively:
- **Code Organization**: Module system, project structure, compilation units
- **Best Practices**: Idiomatic patterns and recommended approaches
- **Examples**: Real-world code demonstrating language features
- **Error Handling**: Patterns for robust error management

### Design Philosophy
Documents that explain **why Phaser** is designed the way it is:
- **Design Principles**: Core values and trade-offs
- **Comparison**: How Phaser relates to other languages
- **Evolution**: Future direction and planned features

## 🚀 Getting Started

### For Language Learners
1. **[[Design Principles]]** - Understand Phaser's philosophy
2. **[[Language Examples]]** - See practical code examples
3. **[[Grammar Specification]]** - Learn the formal syntax
4. **[[language/Code Organization|Code Organization]]** - Structure your projects

### For Language Designers
1. **[[Design Principles]]** - Core design philosophy
2. **[[language/Metaprogramming model|Metaprogramming model]]** - Advanced language features
3. **[[Grammar Specification]]** - Formal language definition

## 🔗 Cross-References

The documentation uses interconnected references to help you navigate related concepts:

- **Internal Links**: `[[Document Name]]` for Obsidian-style navigation
- **External Links**: `[Text](./path/to/doc.md)` for explicit references
- **Code Examples**: Practical demonstrations of concepts
- **Design Rationale**: Explanations of why features work as they do

## 📊 Implementation Status

🚧 **Design Phase** - These documents represent the current design vision for Phaser.

**Status Legend:**
- ✅ **Finalized** - Design is stable and ready for implementation
- 🚧 **In Progress** - Design is being refined based on feedback
- 📋 **Planned** - Feature is planned but design not yet started

**Current Status:**
- ✅ **Design Principles** - Core philosophy established
- 🚧 **Grammar Specification** - Syntax mostly defined, refinements ongoing
- 🚧 **Language Examples** - Examples being expanded and validated
- 📋 **Code Organization** - Patterns being developed
- 🚧 **Metaprogramming Model** - Architecture defined, details being refined

## 🤝 Contributing

### Language Design Contributions
- **Syntax Proposals**: Suggest improvements to language syntax
- **Feature Requests**: Propose new language features with rationale
- **Example Programs**: Contribute realistic code examples
- **Documentation**: Improve clarity and completeness of specifications

### Review Process
1. **Open an Issue** to discuss proposed changes
2. **Provide Rationale** explaining why the change improves Phaser
3. **Consider Trade-offs** and how changes affect other language aspects
4. **Update Examples** to reflect any syntax or feature changes

For compiler implementation contributions, see **[[contributing/index|Contributing Guide]]**.

## 🎯 Audience

This documentation is primarily for:
- **Language Users** learning to write Phaser programs
- **Language Designers** working on Phaser's evolution
- **Tool Builders** creating IDEs, formatters, and other language tools
- **Educators** teaching systems programming concepts