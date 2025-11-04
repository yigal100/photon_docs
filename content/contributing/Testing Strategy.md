# Testing Strategy

This document outlines the comprehensive testing strategy for the Phaser compiler, covering all phases of the [[Compilation Pipeline]] and ensuring robust [[Error Handling]] throughout the development process.

This is a **compiler implementation document**. For language design and user-facing features, see the **[docs/](../docs/)** directory.

## Testing Philosophy

The Phaser compiler testing strategy follows these core principles:
- **Comprehensive Coverage**: Every compilation phase must have thorough test coverage
- **Error-First Testing**: Test error conditions before success paths
- **Incremental Validation**: Each phase can be tested independently
- **Real-World Scenarios**: Include practical examples from [[Language Examples]]
- **Performance Awareness**: Monitor compilation speed and memory usage

## Test Organization

### Directory Structure

```
tests/
├── unit/                    # Unit tests for individual components
│   ├── lexer/              # Lexical analysis tests
│   ├── parser/             # Syntactic analysis tests
│   ├── analysis/           # Semantic analysis tests
│   ├── comptime/           # Compile-time evaluation tests
│   └── codegen/            # Code generation tests
├── integration/            # End-to-end compilation tests
├── regression/             # Regression test suite
├── performance/            # Performance benchmarks
├── fixtures/               # Test data and sample programs
│   ├── valid/              # Valid Phaser programs
│   ├── invalid/            # Programs with known errors
│   └── edge_cases/         # Boundary condition tests
└── tools/                  # Testing utilities and helpers
```

## Phase-Specific Testing

### Lexer Testing

**Test Categories**:
- Token recognition accuracy
- Source position tracking
- Error detection and recovery
- Unicode handling
- Comment processing

```rust
#[cfg(test)]
mod lexer_tests {
    use super::*;
    
    #[test]
    fn test_basic_tokens() {
        let source = "let x = 42;";
        let mut lexer = Lexer::new(source);
        
        assert_token!(lexer.next_token(), Keyword(Let));
        assert_token!(lexer.next_token(), Identifier("x"));
        assert_token!(lexer.next_token(), Operator(Assign));
        assert_token!(lexer.next_token(), IntegerLiteral(42));
        assert_token!(lexer.next_token(), Delimiter(Semicolon));
        assert_token!(lexer.next_token(), Eof);
    }
    
    #[test]
    fn test_string_literals() {
        let test_cases = vec![
            (r#""hello""#, "hello"),
            (r#""hello\nworld""#, "hello\nworld"),
            (r#""unicode: \u{1F680}""#, "unicode: 🚀"),
            (r#"r"raw string""#, "raw string"),
        ];
        
        for (input, expected) in test_cases {
            let mut lexer = Lexer::new(input);
            if let Ok(Token { token_type: TokenType::StringLiteral(value), .. }) = lexer.next_token() {
                assert_eq!(value, expected);
            } else {
                panic!("Expected string literal for input: {}", input);
            }
        }
    }
    
    #[test]
    fn test_error_recovery() {
        let source = "let x = 42\n let y = 'unterminated";
        let mut lexer = Lexer::new(source);
        
        // Should successfully parse first line
        assert_token!(lexer.next_token(), Keyword(Let));
        assert_token!(lexer.next_token(), Identifier("x"));
        assert_token!(lexer.next_token(), Operator(Assign));
        assert_token!(lexer.next_token(), IntegerLiteral(42));
        
        // Should recover and continue after error
        assert_token!(lexer.next_token(), Keyword(Let));
        assert_token!(lexer.next_token(), Identifier("y"));
        
        // Should report error for unterminated string
        let result = lexer.next_token();
        assert!(result.is_err());
        assert_matches!(result.unwrap_err().kind, ErrorKind::Lexical(LexicalError::UnterminatedString { .. }));
    }
}
```

### Parser Testing

**Test Categories**:
- AST construction correctness
- Operator precedence and associativity
- Error recovery strategies
- Syntax validation

```rust
#[cfg(test)]
mod parser_tests {
    use super::*;
    
    #[test]
    fn test_expression_parsing() {
        let source = "1 + 2 * 3";
        let ast = parse_expression(source).unwrap();
        
        // Should parse as: 1 + (2 * 3)
        assert_matches!(ast, Expression::Binary(BinaryExpression {
            left: box Expression::Literal(LiteralExpression::Integer(1)),
            operator: BinaryOperator::Add,
            right: box Expression::Binary(BinaryExpression {
                left: box Expression::Literal(LiteralExpression::Integer(2)),
                operator: BinaryOperator::Multiply,
                right: box Expression::Literal(LiteralExpression::Integer(3)),
            }),
        }));
    }
    
    #[test]
    fn test_function_parsing() {
        let source = r#"
            fn add(a: i32, b: i32) -> i32 {
                return a + b;
            }
        "#;
        
        let ast = parse_function(source).unwrap();
        
        assert_eq!(ast.name.name, "add");
        assert_eq!(ast.parameters.len(), 2);
        assert_eq!(ast.parameters[0].pattern, Pattern::Identifier("a"));
        assert_matches!(ast.return_type, Some(Type::Primitive(PrimitiveType::I32)));
    }
    
    #[test]
    fn test_error_recovery() {
        let source = r#"
            fn broken_function( {
                let x = 42;
            }
            
            fn valid_function() {
                let y = 24;
            }
        "#;
        
        let result = parse_program_with_recovery(source);
        
        // Should have errors but still parse the valid function
        assert!(result.has_errors());
        assert_eq!(result.program.items.len(), 1); // Only valid function
        assert_matches!(result.program.items[0], Item::Function(_));
    }
}
```

### Semantic Analysis Testing

**Test Categories**:
- Name resolution
- Type checking
- Borrow checking
- Scope validation

```rust
#[cfg(test)]
mod analysis_tests {
    use super::*;
    
    #[test]
    fn test_type_checking() {
        let source = r#"
            fn main() {
                let x: i32 = 42;
                let y: f64 = 3.14;
                let z = x + y; // Type error
            }
        "#;
        
        let result = analyze_program(source);
        
        assert!(result.has_errors());
        assert_matches!(
            result.errors[0].kind,
            ErrorKind::Type(TypeError::TypeMismatch { .. })
        );
    }
    
    #[test]
    fn test_borrow_checking() {
        let source = r#"
            fn main() {
                let mut x = vec![1, 2, 3];
                let y = &x;
                x.push(4); // Error: cannot borrow as mutable
                println!("{:?}", y);
            }
        "#;
        
        let result = analyze_program(source);
        
        assert!(result.has_errors());
        assert_matches!(
            result.errors[0].kind,
            ErrorKind::Type(TypeError::LifetimeError { .. })
        );
    }
    
    #[test]
    fn test_name_resolution() {
        let source = r#"
            fn main() {
                let x = unknown_variable; // Error
                let y = known_function(); // OK
            }
            
            fn known_function() -> i32 {
                42
            }
        "#;
        
        let result = analyze_program(source);
        
        assert!(result.has_errors());
        assert_matches!(
            result.errors[0].kind,
            ErrorKind::Semantic(SemanticError::UndefinedVariable { .. })
        );
    }
}
```

### Compile-time Evaluation Testing

**Test Categories**:
- Constant evaluation
- Meta-programming execution
- Resource limit enforcement
- Deterministic behavior

```rust
#[cfg(test)]
mod comptime_tests {
    use super::*;
    
    #[test]
    fn test_const_evaluation() {
        let source = r#"
            const fn factorial(n: u32) -> u32 {
                if n <= 1 { 1 } else { n * factorial(n - 1) }
            }
            
            const FACT_5: u32 = factorial(5);
            
            fn main() {
                assert_eq!(FACT_5, 120);
            }
        "#;
        
        let result = evaluate_comptime(source).unwrap();
        
        let fact_5_value = result.comptime_values.get("FACT_5").unwrap();
        assert_eq!(fact_5_value.as_u32(), 120);
    }
    
    #[test]
    fn test_meta_code_generation() {
        let source = r#"
            meta {
                for i in 0..3 {
                    @generate_function(format!("func_{}", i));
                }
            }
        "#;
        
        let result = evaluate_comptime(source).unwrap();
        
        assert_eq!(result.generated_code.len(), 3);
        assert!(result.generated_code.iter().any(|item| item.name == "func_0"));
        assert!(result.generated_code.iter().any(|item| item.name == "func_1"));
        assert!(result.generated_code.iter().any(|item| item.name == "func_2"));
    }
    
    #[test]
    fn test_resource_limits() {
        let source = r#"
            const fn infinite_loop() -> u32 {
                loop {} // Should hit iteration limit
            }
            
            const VALUE: u32 = infinite_loop();
        "#;
        
        let result = evaluate_comptime(source);
        
        assert!(result.is_err());
        assert_matches!(
            result.unwrap_err().kind,
            ErrorKind::Comptime(ComptimeError::InfiniteLoop { .. })
        );
    }
}
```

### Code Generation Testing

**Test Categories**:
- Correct code generation
- Optimization verification
- Target-specific output
- Debug information

```rust
#[cfg(test)]
mod codegen_tests {
    use super::*;
    
    #[test]
    fn test_basic_code_generation() {
        let source = r#"
            fn add(a: i32, b: i32) -> i32 {
                a + b
            }
        "#;
        
        let result = generate_code(source, TargetConfig::default()).unwrap();
        
        // Verify generated code contains expected patterns
        assert!(result.output.contains("add"));
        assert!(result.output.contains("i32"));
    }
    
    #[test]
    fn test_optimization() {
        let source = r#"
            fn main() -> i32 {
                let x = 2 + 3; // Should be optimized to 5
                return x;
            }
        "#;
        
        let result = generate_code(source, TargetConfig {
            optimization_level: OptimizationLevel::Speed,
            ..Default::default()
        }).unwrap();
        
        // Verify constant folding occurred
        assert!(result.output.contains("5"));
        assert!(!result.output.contains("2 + 3"));
    }
}
```

## Integration Testing

### End-to-End Compilation

```rust
#[cfg(test)]
mod integration_tests {
    use super::*;
    
    #[test]
    fn test_complete_compilation() {
        let source = include_str!("../fixtures/valid/hello_world.ph");
        
        let mut compiler = Compiler::new(CompilerConfig::default());
        let result = compiler.compile_string(source).unwrap();
        
        assert!(result.is_success());
        assert!(!result.output.is_empty());
        
        // Verify executable can be run
        let exit_code = execute_generated_code(&result.output).unwrap();
        assert_eq!(exit_code, 0);
    }
    
    #[test]
    fn test_multi_file_compilation() {
        let files = vec![
            ("main.ph", include_str!("../fixtures/valid/main.ph")),
            ("lib.ph", include_str!("../fixtures/valid/lib.ph")),
        ];
        
        let mut compiler = Compiler::new(CompilerConfig::default());
        let result = compiler.compile_files(files).unwrap();
        
        assert!(result.is_success());
        verify_linking_correctness(&result);
    }
}
```

### Error Propagation Testing

```rust
#[test]
fn test_error_propagation() {
    let test_cases = vec![
        ("lexer_error.ph", ErrorKind::Lexical(_)),
        ("parser_error.ph", ErrorKind::Syntax(_)),
        ("type_error.ph", ErrorKind::Type(_)),
        ("comptime_error.ph", ErrorKind::Comptime(_)),
    ];
    
    for (file, expected_error_kind) in test_cases {
        let source = load_test_file(file);
        let result = compile_with_error_recovery(source);
        
        assert!(result.has_errors());
        assert_matches!(result.errors[0].kind, expected_error_kind);
    }
}
```

## Performance Testing

### Compilation Speed Benchmarks

```rust
#[cfg(test)]
mod performance_tests {
    use super::*;
    use criterion::{black_box, criterion_group, criterion_main, Criterion};
    
    fn bench_lexer_performance(c: &mut Criterion) {
        let large_source = generate_large_source_file(10000); // 10k lines
        
        c.bench_function("lexer_large_file", |b| {
            b.iter(|| {
                let mut lexer = Lexer::new(black_box(&large_source));
                while lexer.next_token().is_ok() {}
            })
        });
    }
    
    fn bench_parser_performance(c: &mut Criterion) {
        let complex_ast = generate_complex_program();
        
        c.bench_function("parser_complex_program", |b| {
            b.iter(|| {
                parse_program(black_box(&complex_ast))
            })
        });
    }
    
    fn bench_full_compilation(c: &mut Criterion) {
        let realistic_program = load_realistic_program();
        
        c.bench_function("full_compilation", |b| {
            b.iter(|| {
                let mut compiler = Compiler::new(CompilerConfig::default());
                compiler.compile_string(black_box(&realistic_program))
            })
        });
    }
    
    criterion_group!(
        benches,
        bench_lexer_performance,
        bench_parser_performance,
        bench_full_compilation
    );
    criterion_main!(benches);
}
```

### Memory Usage Testing

```rust
#[test]
fn test_memory_usage() {
    let large_program = generate_large_program(1000); // 1000 functions
    
    let initial_memory = get_memory_usage();
    
    let mut compiler = Compiler::new(CompilerConfig::default());
    let _result = compiler.compile_string(&large_program).unwrap();
    
    let peak_memory = get_peak_memory_usage();
    let final_memory = get_memory_usage();
    
    // Verify memory usage is reasonable
    assert!(peak_memory - initial_memory < 100_000_000); // < 100MB
    assert!(final_memory - initial_memory < 10_000_000);  // < 10MB after cleanup
}
```

## Test Utilities and Helpers

### Custom Assertion Macros

```rust
macro_rules! assert_token {
    ($result:expr, $expected:pat) => {
        match $result {
            Ok(Token { token_type: $expected, .. }) => {},
            Ok(token) => panic!("Expected {:?}, got {:?}", stringify!($expected), token.token_type),
            Err(e) => panic!("Expected token, got error: {:?}", e),
        }
    };
}

macro_rules! assert_error {
    ($result:expr, $error_pattern:pat) => {
        match $result {
            Err(PhaserError { kind: $error_pattern, .. }) => {},
            Err(e) => panic!("Expected error matching {:?}, got {:?}", stringify!($error_pattern), e.kind),
            Ok(v) => panic!("Expected error, got success: {:?}", v),
        }
    };
}
```

### Test Data Generators

```rust
pub fn generate_large_source_file(lines: usize) -> String {
    let mut source = String::new();
    
    for i in 0..lines {
        source.push_str(&format!("let var_{} = {};\n", i, i));
    }
    
    source
}

pub fn generate_complex_program() -> String {
    include_str!("../fixtures/complex_program_template.ph")
        .replace("{{FUNCTION_COUNT}}", "100")
        .replace("{{STRUCT_COUNT}}", "50")
}
```

## Continuous Integration

### Test Automation

```yaml
# .github/workflows/test.yml
name: Test Suite

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Setup Rust
        uses: actions-rs/toolchain@v1
        with:
          toolchain: stable
      
      - name: Run unit tests
        run: cargo test --lib
      
      - name: Run integration tests
        run: cargo test --test integration
      
      - name: Run performance benchmarks
        run: cargo bench
      
      - name: Check test coverage
        run: cargo tarpaulin --out xml
      
      - name: Upload coverage
        uses: codecov/codecov-action@v1
```

### Quality Gates

- **Minimum test coverage**: 90% for core compiler phases
- **Performance regression threshold**: 5% slowdown triggers investigation
- **Memory usage limits**: No more than 2x increase in memory usage
- **Error message quality**: All error messages must include actionable suggestions

## Test Maintenance

### Regular Test Reviews

- **Monthly**: Review test coverage reports and identify gaps
- **Per release**: Update test fixtures with new language features
- **Quarterly**: Performance benchmark review and baseline updates
- **Annually**: Complete test suite architecture review

### Test Documentation

Each test file should include:
- Purpose and scope documentation
- Test case descriptions
- Expected behavior specifications
- Maintenance notes and update procedures

This comprehensive testing strategy ensures the Phaser compiler maintains high quality, performance, and reliability throughout its development lifecycle.