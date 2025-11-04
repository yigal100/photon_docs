# Lexical Analysis Specification

This document defines the lexical analysis phase of the Phaser compiler, detailing token types, lexical rules, and implementation requirements.

This is a **compiler implementation document**. For language design and user-facing features, see the **[docs/](../docs/)** directory.

## Overview

The lexer transforms source text into a stream of tokens, handling:

- Token recognition and classification
- Source position tracking for error reporting
- Comment processing and whitespace handling
- String and numeric literal parsing
- Keyword identification

## Token Types

### Core Token Categories

```rust
#[derive(Debug, Clone, PartialEq)]
pub enum TokenType {
    // Literals
    IntegerLiteral(IntegerValue),
    FloatLiteral(f64),
    StringLiteral(String),
    CharLiteral(char),
    BooleanLiteral(bool),
  
    // Identifiers and Keywords
    Identifier(String),
    Keyword(Keyword),
  
    // Operators
    Operator(Operator),
  
    // Delimiters
    Delimiter(Delimiter),
  
    // Special
    Newline,
    Eof,
  
    // Comments (preserved for documentation tools)
    LineComment(String),
    BlockComment(String),
}

#[derive(Debug, Clone, PartialEq)]
pub enum IntegerValue {
    Int8(i8), Int16(i16), Int32(i32), Int64(i64), Int128(i128),
    UInt8(u8), UInt16(u16), UInt32(u32), UInt64(u64), UInt128(u128),
    Isize(isize), Usize(usize),
    Untyped(u128), // For literals without explicit type
}
```

### Keywords

```rust
#[derive(Debug, Clone, PartialEq)]
pub enum Keyword {
    // Control Flow
    If, Else, Match, While, For, Loop, Break, Continue, Return,
  
    // Declarations
    Fn, Let, Mutable, Const, Static, Type, Struct, Enum, Trait, Impl,
  
    // Modules and Visibility
    Module, Use, Public, Private, Extern, Self_, Super, Final,
  
    // Types
    Int8, Int16, Int32, Int64, Int128, Isize,
    UInt8, UInt16, UInt32, UInt64, UInt128, Usize,
    F32, F64, Bool, Char, Str,
  
    // Memory and Safety

    Unsafe, Ref, Move, 
  
    // Async/Await
    // Async, Await,
  
    // Meta-programming
    Meta,
  
    // Literals
    True, False,
  
    // Special
    Where, As, In, Virtual,
}
```

### Operators

```rust
#[derive(Debug, Clone, PartialEq)]
pub enum Operator {
    // Arithmetic
    Plus, Minus, Star, Slash, Percent,
  
    // Comparison
    Equal, NotEqual, Less, Greater, LessEqual, GreaterEqual,
  
    // Logical
    And, Or, Not,
  
    // Bitwise
    BitAnd, BitOr, BitXor, LeftShift, RightShift,
  
    // Assignment
    Assign,
    PlusAssign, MinusAssign, StarAssign, SlashAssign, PercentAssign,
    BitAndAssign, BitOrAssign, BitXorAssign, LeftShiftAssign, RightShiftAssign,
  
    // Special
    Arrow,        // ->
    FatArrow,     // =>
    DoubleColon,  // ::
    Dot,          // .
    DotDot,       // ..
    DotDotDot,    // ...
    Question,     // ?
    At,           // @
}
```

### Delimiters

```rust
#[derive(Debug, Clone, PartialEq)]
pub enum Delimiter {
    LeftParen, RightParen,       // ( )
    LeftBracket, RightBracket,   // [ ]
    LeftBrace, RightBrace,       // { }
    Comma, Semicolon, Colon,     // , ; :
}
```

## Token Structure

```rust
#[derive(Debug, Clone, PartialEq)]
pub struct Token {
    pub token_type: TokenType,
    pub span: Span,
    pub leading_trivia: Vec<Trivia>,
    pub trailing_trivia: Vec<Trivia>,
}

#[derive(Debug, Clone, PartialEq)]
pub struct Span {
    pub start: Position,
    pub end: Position,
    pub source_id: SourceId,
}

#[derive(Debug, Clone, PartialEq)]
pub struct Position {
    pub line: u32,    // 1-based
    pub column: u32,  // 1-based
    pub offset: u32,  // 0-based byte offset
}

#[derive(Debug, Clone, PartialEq)]
pub enum Trivia {
    Whitespace(String),
    LineComment(String),
    BlockComment(String),
}
```

## Lexical Rules

### Identifiers

- Start with letter or underscore
- Followed by letters, digits, or underscores
- Case-sensitive
- Cannot be keywords (use raw identifiers `@keyword` for edge cases)
- TODO: extend to support unicode and emojis

```
identifier := [a-zA-Z_][a-zA-Z0-9_]*
raw_identifier := r#[a-zA-Z_][a-zA-Z0-9_]*
```

### Integer Literals

```
decimal := [0-9][0-9_]*
hexadecimal := 0[xX][0-9a-fA-F][0-9a-fA-F_]*
binary := 0[bB][01][01_]*
octal := 0[oO][0-7][0-7_]*

integer_suffix := (i8|i16|i32|i64|i128|isize|u8|u16|u32|u64|u128|usize)?
integer_literal := (decimal|hexadecimal|binary|octal) integer_suffix
```

### Float Literals

```
decimal_float := [0-9][0-9_]* \. [0-9][0-9_]* exponent?
                | [0-9][0-9_]* exponent

exponent := [eE][+-]?[0-9][0-9_]*
float_suffix := (f32|f64)?
float_literal := decimal_float float_suffix
```

### String Literals

```
string_literal := " string_content* "
string_content := escape_sequence | [^"\\]

escape_sequence := \\ ( n | t | r | \\ | " | ' | 0 | x[0-9a-fA-F]{2} | u{[0-9a-fA-F]{1,6}} )
```

Supported escape sequences:

- `\n` - newline
- `\t` - tab
- `\r` - carriage return
- `\\` - backslash
- `\"` - double quote
- `\'` - single quote
- `\0` - null character
- `\x##` - ASCII character (hex)
- `\u{######}` - Unicode character (hex)

### Character Literals

```
char_literal := ' char_content '
char_content := escape_sequence | [^'\\]
```

### Comments

line_comment := // [^\n]* \n?
block_comment := /* (block_comment | [^*] | \*[^/])* */
Block comments can be nested.

## Lexer Implementation Requirements

### Error Handling

The lexer must produce `PhaserResult<Token>` and handle:

```rust
#[derive(Debug, Clone, PartialEq)]
pub enum LexError {
    UnexpectedCharacter { char: char, position: Position },
    UnterminatedString { start: Position },
    UnterminatedBlockComment { start: Position },
    InvalidEscapeSequence { sequence: String, position: Position },
    InvalidNumericLiteral { literal: String, position: Position },
    InvalidUnicodeEscape { escape: String, position: Position },
    IntegerOverflow { literal: String, position: Position },
}
```
### Position Tracking

- Maintain accurate line/column information
- Handle different line ending styles (LF, CRLF, CR)
- Track byte offsets for efficient source mapping
- Support Unicode characters correctly

### Performance Considerations

- Use efficient string scanning techniques
- Minimize allocations during tokenization
- Consider using string interning for identifiers
- Implement lookahead efficiently for multi-character operators

### Trivia Handling

- Preserve whitespace and comments as trivia
- Attach trivia to appropriate tokens
- Support documentation comment extraction
- Handle mixed whitespace/comment sequences

## Integration with Parser

The lexer provides a token stream interface:

```rust
pub trait TokenStream {
    fn next_token(&mut self) -> PhaserResult<Token>;
    fn peek_token(&mut self) -> PhaserResult<&Token>;
    fn current_position(&self) -> Position;
    fn is_at_end(&self) -> bool;
}
```
## Testing Requirements

### Unit Tests Required

- All token types recognition
- All escape sequences
- Numeric literal parsing (all bases and suffixes)
- Error conditions and recovery
- Position tracking accuracy
- Unicode handling
- Nested comment parsing
- Trivia attachment correctness

### Test Cases

```phaser
// Basic tokens
let x = 42;
fn main() -> i32 { return 0; }

// Numeric literals
0x1A2B_u32
0b1010_1010_i8
123.456_f64
1e-10_f32

// String literals
"Hello, world!"
"Line 1\nLine 2"
"Unicode: \u{1F680}"

// Comments
// Line comment
/* Block comment */
/* Nested /* comment */ */
```
## Future Extensions

- Raw string literals: `r"no escapes here"`
- Byte string literals: `b"bytes"`
- Format string literals: `f"Hello {name}"`
- Custom numeric literal suffixes for user types
