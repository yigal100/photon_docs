# Compiler Code Organization

This document outlines the physical code organization strategy for the Phaser compiler implementation, emphasizing maintainability, clear API boundaries, and modular design.

## Implementation Principles

### 1. File Size Limits

**800 Lines of Code Maximum per File**

Based on software engineering research:
- Andrew Ciccarelli recommends **500 LOC** for optimal maintainability
- DZone "Rule of 30" suggests **900 LOC** (30 methods × 30 lines)
- PMD static analysis defaults to **1000 LOC** per class
- **800 LOC** provides the sweet spot for readability and maintainability

**Benefits**:
- Better code review experience
- Easier debugging and maintenance
- Improved code quality and design
- Supports effective testing strategies

### 2. API Boundary Design

**Interface-First Architecture**:
- Every compilation phase exposes a well-defined interface
- Interfaces support WASM compilation for modularity
- Capability-based security for controlled side effects
- Support for dynamic loading and plugin architectures

### 3. Phase Isolation

**Strict Separation**:
- Each phase operates independently
- Clear input/output contracts
- No cross-phase dependencies except through public APIs
- Enables incremental compilation and caching

## Physical File Structure

```
src/
├── lib.rs                  # Public API (< 200 LOC)
├── main.rs                 # CLI driver (< 100 LOC)
├── common/                 # Shared utilities
│   ├── mod.rs             # Module interface (< 100 LOC)
│   ├── result.rs          # PhaserResult<T> definition (< 200 LOC)
│   ├── span.rs            # Source location tracking (< 300 LOC)
│   ├── source.rs          # Source file management (< 400 LOC)
│   ├── diagnostics.rs     # Error reporting (< 500 LOC)
│   ├── phase.rs           # Phase interface trait (< 200 LOC)
│   └── capabilities.rs    # Capability definitions (< 300 LOC)
├── lexer/                 # Phase 1: Lexical Analysis
│   ├── mod.rs             # Public interface (< 150 LOC)
│   ├── token.rs           # Token definitions (< 400 LOC)
│   ├── scanner.rs         # Core scanning logic (< 600 LOC)
│   ├── literals.rs        # Literal parsing (< 500 LOC)
│   ├── keywords.rs        # Keyword recognition (< 200 LOC)
│   ├── unicode.rs         # Unicode handling (< 400 LOC)
│   └── errors.rs          # Lexical error types (< 300 LOC)
├── parser/                # Phase 2: Syntactic Analysis
│   ├── mod.rs             # Public interface (< 150 LOC)
│   ├── grammar/           # Grammar implementation
│   │   ├── mod.rs         # Grammar interface (< 100 LOC)
│   │   ├── expressions.rs # Expression parsing (< 700 LOC)
│   │   ├── statements.rs  # Statement parsing (< 600 LOC)
│   │   ├── types.rs       # Type parsing (< 500 LOC)
│   │   ├── patterns.rs    # Pattern parsing (< 400 LOC)
│   │   ├── items.rs       # Item parsing (< 800 LOC)
│   │   └── precedence.rs  # Operator precedence (< 300 LOC)
│   ├── ast/               # AST definitions
│   │   ├── mod.rs         # AST interface (< 100 LOC)
│   │   ├── nodes.rs       # Core node types (< 600 LOC)
│   │   ├── expressions.rs # Expression nodes (< 700 LOC)
│   │   ├── statements.rs  # Statement nodes (< 400 LOC)
│   │   ├── types.rs       # Type nodes (< 500 LOC)
│   │   ├── patterns.rs    # Pattern nodes (< 400 LOC)
│   │   ├── visitors.rs    # Visitor patterns (< 600 LOC)
│   │   └── builder.rs     # AST builder utilities (< 500 LOC)
│   ├── recovery.rs        # Error recovery strategies (< 500 LOC)
│   └── errors.rs          # Syntax error types (< 400 LOC)
├── analysis/              # Phase 3: Semantic Analysis
│   ├── mod.rs             # Public interface (< 150 LOC)
│   ├── resolver/          # Name resolution
│   │   ├── mod.rs         # Resolver interface (< 100 LOC)
│   │   ├── scopes.rs      # Scope management (< 600 LOC)
│   │   ├── names.rs       # Name resolution logic (< 700 LOC)
│   │   ├── imports.rs     # Import resolution (< 500 LOC)
│   │   └── modules.rs     # Module resolution (< 600 LOC)
│   ├── checker/           # Type checking
│   │   ├── mod.rs         # Checker interface (< 100 LOC)
│   │   ├── types.rs       # Type checking logic (< 800 LOC)
│   │   ├── inference.rs   # Type inference (< 700 LOC)
│   │   ├── constraints.rs # Constraint solving (< 600 LOC)
│   │   ├── unification.rs # Type unification (< 500 LOC)
│   │   └── generics.rs    # Generic type handling (< 600 LOC)
│   ├── borrow/            # Borrow checking
│   │   ├── mod.rs         # Borrow checker interface (< 100 LOC)
│   │   ├── lifetimes.rs   # Lifetime analysis (< 700 LOC)
│   │   ├── ownership.rs   # Ownership tracking (< 600 LOC)
│   │   ├── regions.rs     # Memory regions (< 500 LOC)
│   │   └── flow.rs        # Control flow analysis (< 600 LOC)
│   ├── symbols.rs         # Symbol table management (< 600 LOC)
│   ├── dependencies.rs    # Dependency analysis (< 400 LOC)
│   └── errors.rs          # Semantic error types (< 500 LOC)
├── comptime/              # Phase 4: Compile-time Evaluation
│   ├── mod.rs             # Public interface (< 150 LOC)
│   ├── evaluator/         # Expression evaluation
│   │   ├── mod.rs         # Evaluator interface (< 100 LOC)
│   │   ├── values.rs      # Compile-time values (< 500 LOC)
│   │   ├── expressions.rs # Expression evaluation (< 700 LOC)
│   │   ├── functions.rs   # Function evaluation (< 600 LOC)
│   │   ├── constants.rs   # Constant folding (< 400 LOC)
│   │   └── builtins.rs    # Built-in functions (< 500 LOC)
│   ├── meta/              # Meta-programming
│   │   ├── mod.rs         # Meta interface (< 100 LOC)
│   │   ├── sandbox.rs     # WASM sandbox (< 600 LOC)
│   │   ├── generation.rs  # Code generation (< 700 LOC)
│   │   ├── directives.rs  # Meta directives (< 500 LOC)
│   │   └── templates.rs   # Template system (< 600 LOC)
│   ├── limits.rs          # Resource limits (< 300 LOC)
│   ├── cache.rs           # Comptime caching (< 400 LOC)
│   └── errors.rs          # Comptime error types (< 400 LOC)
└── codegen/               # Phase 5: Code Generation
    ├── mod.rs             # Public interface (< 150 LOC)
    ├── backends/          # Code generation backends
    │   ├── mod.rs         # Backend interface (< 100 LOC)
    │   ├── llvm/          # LLVM backend
    │   │   ├── mod.rs     # LLVM interface (< 100 LOC)
    │   │   ├── context.rs # LLVM context (< 400 LOC)
    │   │   ├── module.rs  # Module generation (< 600 LOC)
    │   │   ├── types.rs   # Type mapping (< 500 LOC)
    │   │   ├── values.rs  # Value generation (< 700 LOC)
    │   │   ├── functions.rs # Function generation (< 600 LOC)
    │   │   └── debug.rs   # Debug info generation (< 500 LOC)
    │   ├── wasm/          # WebAssembly backend
    │   │   ├── mod.rs     # WASM interface (< 100 LOC)
    │   │   ├── module.rs  # WASM module generation (< 600 LOC)
    │   │   ├── types.rs   # WASM type mapping (< 400 LOC)
    │   │   └── runtime.rs # WASM runtime support (< 500 LOC)
    │   └── native/        # Native backend
    │       ├── mod.rs     # Native interface (< 100 LOC)
    │       ├── assembly.rs # Assembly generation (< 800 LOC)
    │       ├── linking.rs # Linking support (< 400 LOC)
    │       └── relocations.rs # Relocation handling (< 300 LOC)
    ├── optimization/      # Optimization passes
    │   ├── mod.rs         # Optimization interface (< 100 LOC)
    │   ├── constant_fold.rs # Constant folding (< 400 LOC)
    │   ├── dead_code.rs   # Dead code elimination (< 500 LOC)
    │   ├── inlining.rs    # Function inlining (< 600 LOC)
    │   └── peephole.rs    # Peephole optimizations (< 400 LOC)
    ├── debug.rs           # Debug information (< 400 LOC)
    └── errors.rs          # Codegen error types (< 300 LOC)
```

## Core Interface Definitions

### Phase Interface

```rust
// src/common/phase.rs
pub trait CompilerPhase {
    type Input: Serialize + DeserializeOwned;
    type Output: Serialize + DeserializeOwned;
    type Config: Serialize + DeserializeOwned;
    type Error: Into<PhaserError>;
    
    fn execute(&mut self, input: Self::Input, config: Self::Config) -> PhaserResult<Self::Output>;
    fn phase_name(&self) -> &'static str;
    fn version(&self) -> Version;
    
    // WASM support
    fn as_wasm_module(&self) -> PhaserResult<WasmModule>;
    fn from_wasm_module(module: WasmModule) -> PhaserResult<Self>;
}
```

### Capability System

```rust
// src/common/capabilities.rs
pub trait Capability: Send + Sync {
    fn capability_name(&self) -> &'static str;
}

pub trait FileSystemCapability: Capability {
    fn read_file(&self, path: &Path) -> PhaserResult<String>;
    fn write_file(&self, path: &Path, content: &str) -> PhaserResult<()>;
    fn list_directory(&self, path: &Path) -> PhaserResult<Vec<PathBuf>>;
}

pub trait NetworkCapability: Capability {
    fn fetch_url(&self, url: &str) -> PhaserResult<String>;
}

pub struct CapabilitySet {
    capabilities: HashMap<TypeId, Box<dyn Capability>>,
}

impl CapabilitySet {
    pub fn get<T: Capability + 'static>(&self) -> Option<&T> {
        self.capabilities.get(&TypeId::of::<T>())
            .and_then(|cap| cap.as_any().downcast_ref::<T>())
    }
}
```

## Module Organization Patterns

### 1. Interface-First Design

Each module starts with a clear public interface:

```rust
// src/lexer/mod.rs
pub use self::token::{Token, TokenType, Span};
pub use self::scanner::Lexer;
pub use self::errors::LexicalError;

mod token;
mod scanner;
mod literals;
mod keywords;
mod unicode;
mod errors;

pub struct LexerPhase {
    config: LexerConfig,
}

impl CompilerPhase for LexerPhase {
    type Input = SourceFile;
    type Output = TokenStream;
    type Config = LexerConfig;
    type Error = LexicalError;
    
    fn execute(&mut self, input: Self::Input, config: Self::Config) -> PhaserResult<Self::Output> {
        let mut lexer = Lexer::new(input, config);
        lexer.tokenize()
    }
    
    fn phase_name(&self) -> &'static str { "lexer" }
    fn version(&self) -> Version { Version::new(1, 0, 0) }
}
```

### 2. Error Handling Patterns

Consistent error handling across all modules:

```rust
// src/lexer/errors.rs
#[derive(Debug, Clone, PartialEq)]
pub enum LexicalError {
    UnexpectedCharacter { char: char, position: Position },
    UnterminatedString { start: Position },
    InvalidEscape { sequence: String, position: Position },
    // ... other error variants
}

impl From<LexicalError> for PhaserError {
    fn from(error: LexicalError) -> Self {
        PhaserError::new(ErrorKind::Lexical(error))
            .with_suggestions(error.suggestions())
            .with_help_text(error.help_text())
    }
}
```

### 3. Testing Organization

Each module includes comprehensive tests:

```rust
// src/lexer/scanner.rs
#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_basic_tokens() {
        // Test implementation
    }
    
    #[test]
    fn test_error_recovery() {
        // Error recovery tests
    }
    
    #[test]
    fn test_unicode_handling() {
        // Unicode tests
    }
}
```

## Build and Development Tools

### Cargo Configuration

```toml
# Cargo.toml
[package]
name = "phaser-compiler"
version = "0.1.0"
edition = "2021"

[dependencies]
# Zero external dependencies by design

[dev-dependencies]
criterion = "0.5"  # For benchmarking

[[bin]]
name = "phaser"
path = "src/main.rs"

[lib]
name = "phaser_compiler"
path = "src/lib.rs"

[[bench]]
name = "compilation_benchmarks"
harness = false
```

### Development Scripts

```bash
#!/bin/bash
# scripts/check_file_sizes.sh
# Enforce 800 LOC limit

find src -name "*.rs" | while read file; do
    lines=$(wc -l < "$file")
    if [ $lines -gt 800 ]; then
        echo "WARNING: $file has $lines lines (exceeds 800 LOC limit)"
    fi
done
```

## Performance Considerations

### Memory Management
- Use `Box<T>` for recursive structures
- Implement `Clone` efficiently with reference counting where needed
- Consider using arena allocation for AST nodes

### Compilation Speed
- Lazy evaluation where possible
- Efficient string interning for identifiers
- Parallel compilation of independent modules

### Caching Strategy
- Phase-level caching for incremental compilation
- Persistent caching across compiler invocations
- Dependency-aware cache invalidation

## WASM Integration

### Module Compilation
Each phase can be compiled to a WASM module:

```rust
// src/common/wasm.rs
pub struct WasmModule {
    bytes: Vec<u8>,
    exports: HashMap<String, WasmExport>,
}

impl WasmModule {
    pub fn compile_phase<P: CompilerPhase>(phase: &P) -> PhaserResult<Self> {
        // Compile phase to WASM
    }
    
    pub fn instantiate<P: CompilerPhase>(&self) -> PhaserResult<P> {
        // Instantiate phase from WASM
    }
}
```

### Plugin System
Support for dynamically loaded compiler phases:

```rust
// src/common/plugins.rs
pub struct PluginManager {
    loaded_phases: HashMap<String, Box<dyn CompilerPhase>>,
}

impl PluginManager {
    pub fn load_phase(&mut self, name: &str, source: PluginSource) -> PhaserResult<()> {
        match source {
            PluginSource::Wasm(module) => {
                let phase = WasmModule::instantiate(module)?;
                self.loaded_phases.insert(name.to_string(), Box::new(phase));
            }
            PluginSource::Native(library) => {
                // Load native shared library
            }
        }
        Ok(())
    }
}
```

This organization provides a maintainable, extensible foundation for the Phaser compiler while adhering to research-backed best practices for code organization and software engineering.