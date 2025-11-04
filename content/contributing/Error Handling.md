# Error Handling Specification

This document defines the comprehensive error handling system for the Phaser compiler, including error types, diagnostic formatting, recovery strategies, and user experience guidelines.

This is a **compiler implementation document**. For language design and user-facing features, see the **[docs/](../docs/)** directory.

## Overview

Phaser's error handling system is designed around the `PhaserResult<T>` type and provides:
- Comprehensive error information with source locations
- Actionable error messages with suggested fixes
- Graceful error recovery for continued compilation
- Rich diagnostic output for development tools

## Core Error Types

### Result Type

```rust
pub type PhaserResult<T> = Result<T, PhaserError>;

#[derive(Debug, Clone, PartialEq)]
pub struct PhaserError {
    pub kind: ErrorKind,
    pub span: Span,
    pub message: String,
    pub suggestions: Vec<Suggestion>,
    pub related: Vec<RelatedError>,
    pub severity: Severity,
}

#[derive(Debug, Clone, PartialEq)]
pub enum Severity {
    Error,
    Warning,
    Info,
    Hint,
}

#[derive(Debug, Clone, PartialEq)]
pub struct Suggestion {
    pub message: String,
    pub replacement: Option<TextReplacement>,
    pub applicability: Applicability,
}

#[derive(Debug, Clone, PartialEq)]
pub enum Applicability {
    Automatic,      // Can be applied automatically
    Suggested,      // Likely correct, user should review
    Speculative,    // Might be correct, user must verify
}

#[derive(Debug, Clone, PartialEq)]
pub struct TextReplacement {
    pub span: Span,
    pub text: String,
}

#[derive(Debug, Clone, PartialEq)]
pub struct RelatedError {
    pub span: Span,
    pub message: String,
    pub severity: Severity,
}
```

### Error Categories

```rust
#[derive(Debug, Clone, PartialEq)]
pub enum ErrorKind {
    // Lexical errors
    Lexical(LexicalError),
    
    // Syntax errors
    Syntax(SyntaxError),
    
    // Semantic errors
    Semantic(SemanticError),
    
    // Type errors
    Type(TypeError),
    
    // Compile-time evaluation errors
    Comptime(ComptimeError),
    
    // Code generation errors
    Codegen(CodegenError),
    
    // I/O and system errors
    Io(IoError),
    
    // Internal compiler errors
    Internal(InternalError),
}
```

## Phase-Specific Errors

### Lexical Errors

```rust
#[derive(Debug, Clone, PartialEq)]
pub enum LexicalError {
    UnexpectedCharacter {
        character: char,
        expected: Option<String>,
    },
    UnterminatedString {
        quote_type: QuoteType,
        start_span: Span,
    },
    UnterminatedBlockComment {
        start_span: Span,
    },
    InvalidEscapeSequence {
        sequence: String,
        valid_sequences: Vec<String>,
    },
    InvalidNumericLiteral {
        literal: String,
        reason: NumericLiteralError,
    },
    InvalidUnicodeEscape {
        escape: String,
        reason: UnicodeEscapeError,
    },
    IntegerOverflow {
        literal: String,
        max_value: String,
    },
}

#[derive(Debug, Clone, PartialEq)]
pub enum QuoteType {
    Double,  // "
    Single,  // '
}

#[derive(Debug, Clone, PartialEq)]
pub enum NumericLiteralError {
    InvalidDigit { digit: char, base: u8 },
    EmptyExponent,
    InvalidSuffix { suffix: String },
    MissingDigits,
}
```

### Syntax Errors

```rust
#[derive(Debug, Clone, PartialEq)]
pub enum SyntaxError {
    UnexpectedToken {
        found: TokenType,
        expected: Vec<TokenType>,
    },
    MissingToken {
        expected: TokenType,
        context: String,
    },
    ExtraToken {
        token: TokenType,
    },
    InvalidExpression {
        context: String,
    },
    MismatchedDelimiter {
        opening: Delimiter,
        closing: Delimiter,
        opening_span: Span,
    },
    IncompleteExpression {
        expression_type: String,
    },
    InvalidPattern {
        pattern_context: String,
    },
    InvalidItemInContext {
        item_type: String,
        context: String,
    },
}
```

### Semantic Errors

```rust
#[derive(Debug, Clone, PartialEq)]
pub enum SemanticError {
    UndefinedVariable {
        name: String,
        similar_names: Vec<String>,
    },
    UndefinedFunction {
        name: String,
        similar_names: Vec<String>,
    },
    UndefinedType {
        name: String,
        similar_names: Vec<String>,
    },
    DuplicateDefinition {
        name: String,
        first_definition: Span,
        definition_type: String,
    },
    InvalidVisibility {
        item_type: String,
        visibility: String,
        reason: String,
    },
    CircularDependency {
        cycle: Vec<String>,
    },
    InvalidMutability {
        operation: String,
        reason: String,
    },
    UnreachableCode {
        reason: String,
    },
    MissingReturn {
        function_name: String,
        return_type: String,
    },
    InvalidBreakContinue {
        keyword: String,
        context: String,
    },
}
```

### Type Errors

```rust
#[derive(Debug, Clone, PartialEq)]
pub enum TypeError {
    TypeMismatch {
        expected: String,
        found: String,
        context: String,
    },
    CannotInferType {
        expression: String,
        suggestions: Vec<String>,
    },
    InvalidOperation {
        operation: String,
        left_type: String,
        right_type: Option<String>,
    },
    FieldNotFound {
        field_name: String,
        type_name: String,
        available_fields: Vec<String>,
    },
    MethodNotFound {
        method_name: String,
        type_name: String,
        available_methods: Vec<String>,
    },
    ArityMismatch {
        expected: usize,
        found: usize,
        function_name: String,
    },
    InvalidCast {
        from_type: String,
        to_type: String,
        reason: String,
    },
    TraitNotImplemented {
        trait_name: String,
        type_name: String,
        missing_methods: Vec<String>,
    },
    LifetimeError {
        kind: LifetimeErrorKind,
    },
}

#[derive(Debug, Clone, PartialEq)]
pub enum LifetimeErrorKind {
    BorrowedValueDoesNotLiveEnough {
        borrowed_span: Span,
        dropped_span: Span,
    },
    CannotBorrowAsMutable {
        reason: String,
    },
    UseAfterMove {
        moved_span: Span,
        used_span: Span,
    },
}
```

### Compile-time Errors

```rust
#[derive(Debug, Clone, PartialEq)]
pub enum ComptimeError {
    InfiniteLoop {
        iteration_limit: usize,
    },
    StackOverflow {
        call_depth: usize,
        function_name: String,
    },
    InvalidComptimeOperation {
        operation: String,
        reason: String,
    },
    ComptimeValueNotAvailable {
        expression: String,
        reason: String,
    },
    ResourceLimitExceeded {
        resource: String,
        limit: String,
        used: String,
    },
    SideEffectInComptimeContext {
        operation: String,
    },
    NonDeterministicBehavior {
        operation: String,
        reason: String,
    },
}
```

## Error Construction and Conversion

### Error Builder

```rust
pub struct ErrorBuilder {
    kind: ErrorKind,
    span: Span,
    message: String,
    suggestions: Vec<Suggestion>,
    related: Vec<RelatedError>,
    severity: Severity,
}

impl ErrorBuilder {
    pub fn new(kind: ErrorKind, span: Span) -> Self {
        Self {
            kind,
            span,
            message: String::new(),
            suggestions: Vec::new(),
            related: Vec::new(),
            severity: Severity::Error,
        }
    }
    
    pub fn message<S: Into<String>>(mut self, message: S) -> Self {
        self.message = message.into();
        self
    }
    
    pub fn suggestion<S: Into<String>>(mut self, message: S) -> Self {
        self.suggestions.push(Suggestion {
            message: message.into(),
            replacement: None,
            applicability: Applicability::Suggested,
        });
        self
    }
    
    pub fn suggestion_with_replacement<S: Into<String>>(
        mut self,
        message: S,
        span: Span,
        replacement: S,
        applicability: Applicability,
    ) -> Self {
        self.suggestions.push(Suggestion {
            message: message.into(),
            replacement: Some(TextReplacement {
                span,
                text: replacement.into(),
            }),
            applicability,
        });
        self
    }
    
    pub fn related<S: Into<String>>(mut self, span: Span, message: S) -> Self {
        self.related.push(RelatedError {
            span,
            message: message.into(),
            severity: Severity::Info,
        });
        self
    }
    
    pub fn severity(mut self, severity: Severity) -> Self {
        self.severity = severity;
        self
    }
    
    pub fn build(self) -> PhaserError {
        PhaserError {
            kind: self.kind,
            span: self.span,
            message: self.message,
            suggestions: self.suggestions,
            related: self.related,
            severity: self.severity,
        }
    }
}
```

### Error Conversion Traits

```rust
impl From<LexicalError> for PhaserError {
    fn from(error: LexicalError) -> Self {
        // Convert lexical error to PhaserError with appropriate message and suggestions
    }
}

impl From<SyntaxError> for PhaserError {
    fn from(error: SyntaxError) -> Self {
        // Convert syntax error to PhaserError with appropriate message and suggestions
    }
}

// Additional From implementations for each error type...
```

## Diagnostic Formatting

### Diagnostic Output

```rust
pub struct DiagnosticFormatter {
    source_map: SourceMap,
    color_config: ColorConfig,
}

impl DiagnosticFormatter {
    pub fn format_error(&self, error: &PhaserError) -> String {
        let mut output = String::new();
        
        // Error header with severity and location
        output.push_str(&self.format_header(error));
        
        // Source code snippet with highlighting
        output.push_str(&self.format_source_snippet(error));
        
        // Error message
        output.push_str(&self.format_message(error));
        
        // Suggestions
        for suggestion in &error.suggestions {
            output.push_str(&self.format_suggestion(suggestion));
        }
        
        // Related errors
        for related in &error.related {
            output.push_str(&self.format_related(related));
        }
        
        output
    }
    
    fn format_source_snippet(&self, error: &PhaserError) -> String {
        // Format source code with line numbers, highlighting, and carets
        // Example output:
        //   --> src/main.ph:5:12
        //    |
        //  5 |     let x = unknown_variable;
        //    |             ^^^^^^^^^^^^^^^^ undefined variable
        //    |
        //    = help: did you mean `known_variable`?
    }
}
```

### Example Error Output

```
error[E0425]: cannot find value `unknow_variable` in this scope
  --> src/main.ph:5:13
   |
 5 |     let x = unknow_variable;
   |             ^^^^^^^^^^^^^^^ not found in this scope
   |
help: a local variable with a similar name exists
   |
 5 |     let x = unknown_variable;
   |             ~~~~~~~~~~~~~~~~

error[E0308]: mismatched types
  --> src/main.ph:8:18
   |
 8 |     let result = add_numbers("hello", 42);
   |                  ^^^^^^^^^^^ expected `i32`, found `&str`
   |
note: function defined here
  --> src/main.ph:2:1
   |
 2 | fn add_numbers(a: i32, b: i32) -> i32 {
   | ^^^^^^^^^^^^^ ------  ------ expected `i32`
   |               |
   |               expected `i32`
```

## Error Recovery Strategies

### Parser Recovery

```rust
pub trait ErrorRecovery {
    fn recover_from_error(&mut self, error: SyntaxError) -> PhaserResult<()>;
    fn synchronize_to_statement(&mut self);
    fn synchronize_to_item(&mut self);
    fn skip_to_delimiter(&mut self, delimiter: Delimiter);
}

impl ErrorRecovery for Parser {
    fn recover_from_error(&mut self, error: SyntaxError) -> PhaserResult<()> {
        match error {
            SyntaxError::UnexpectedToken { .. } => {
                self.synchronize_to_statement();
            }
            SyntaxError::MismatchedDelimiter { .. } => {
                self.skip_to_delimiter(Delimiter::RightBrace);
            }
            _ => {
                // Default recovery strategy
                self.advance_token();
            }
        }
        Ok(())
    }
}
```

### Semantic Analysis Recovery

- Continue analysis after type errors when possible
- Use error types (`!`) to prevent cascading errors
- Maintain symbol table consistency during recovery
- Provide partial results for IDE integration

## Testing Requirements

### Error Testing Framework

```rust
#[cfg(test)]
mod error_tests {
    use super::*;
    
    #[test]
    fn test_undefined_variable_error() {
        let source = "let x = unknown_var;";
        let result = compile_source(source);
        
        assert!(result.is_err());
        let error = result.unwrap_err();
        
        assert_matches!(error.kind, ErrorKind::Semantic(SemanticError::UndefinedVariable { .. }));
        assert_eq!(error.span.start.line, 1);
        assert_eq!(error.span.start.column, 9);
        assert!(!error.suggestions.is_empty());
    }
    
    #[test]
    fn test_error_recovery() {
        let source = r#"
            fn main() {
                let x = unknown_var; // Error here
                let y = 42;          // Should still parse
            }
        "#;
        
        let result = parse_with_recovery(source);
        assert!(result.has_errors());
        assert!(result.ast.is_some()); // Should have partial AST
    }
}
```

### Error Message Quality Tests

- Verify error messages are actionable and clear
- Test suggestion quality and applicability
- Ensure consistent formatting across error types
- Validate source location accuracy
- Test error recovery effectiveness

## Integration with Development Tools

### Language Server Protocol

```rust
pub fn error_to_diagnostic(error: &PhaserError) -> lsp_types::Diagnostic {
    lsp_types::Diagnostic {
        range: span_to_range(&error.span),
        severity: Some(severity_to_lsp(error.severity)),
        code: Some(lsp_types::NumberOrString::String(error_code(&error.kind))),
        message: error.message.clone(),
        related_information: Some(
            error.related.iter()
                .map(|r| related_to_lsp(r))
                .collect()
        ),
        ..Default::default()
    }
}
```

### IDE Integration

- Provide quick fixes for common errors
- Support error highlighting and tooltips
- Enable incremental error checking
- Offer refactoring suggestions based on errors

## Performance Considerations

- Lazy error message formatting
- Efficient source location tracking
- Minimal allocation during error construction
- Fast error recovery for interactive use
- Batch error reporting for better performance