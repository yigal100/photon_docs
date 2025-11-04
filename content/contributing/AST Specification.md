# Abstract Syntax Tree Specification

This document defines the Abstract Syntax Tree (AST) structure for the Phaser programming language, detailing node types, relationships, and implementation requirements.

This is a **compiler implementation document**. For language design and user-facing features, see the **[docs/](../docs/)** directory.

## Overview

The AST represents the syntactic structure of Phaser programs after parsing. It serves as the primary data structure for semantic analysis, compile-time evaluation, and code generation phases.

## Design Principles

- **Immutable by default**: AST nodes should be immutable after construction
- **Rich source information**: Every node tracks its source location
- **Type-safe representation**: Use Rust's type system to prevent invalid AST structures
- **Visitor pattern support**: Enable easy traversal and transformation
- **Memory efficient**: Minimize allocations and use appropriate data structures

## Core AST Types

### Base Node Structure

```rust
#[derive(Debug, Clone, PartialEq)]
pub struct AstNode<T> {
    pub kind: T,
    pub span: Span,
    pub id: NodeId,
}

pub type NodeId = u32;

#[derive(Debug, Clone, PartialEq)]
pub struct Span {
    pub start: Position,
    pub end: Position,
    pub source_id: SourceId,
}
```

### Program Structure

```rust
#[derive(Debug, Clone, PartialEq)]
pub struct Program {
    pub items: Vec<Item>,
    pub span: Span,
}

#[derive(Debug, Clone, PartialEq)]
pub enum Item {
    Function(FunctionItem),
    Struct(StructItem),
    Enum(EnumItem),
    Trait(TraitItem),
    Impl(ImplItem),
    TypeAlias(TypeAliasItem),
    Const(ConstItem),
    Static(StaticItem),
    Module(ModuleItem),
    Use(UseItem),
    Extern(ExternItem),
    Meta(MetaItem),
}

#[derive(Debug, Clone, PartialEq)]
pub struct Visibility {
    pub kind: VisibilityKind,
    pub span: Span,
}

#[derive(Debug, Clone, PartialEq)]
pub enum VisibilityKind {
    Public,
    Private,
    Restricted(Path), // pub(crate), pub(super), etc.
}
```

### Functions

```rust
#[derive(Debug, Clone, PartialEq)]
pub struct FunctionItem {
    pub visibility: Option<Visibility>,
    pub is_async: bool,
    pub is_unsafe: bool,
    pub name: Identifier,
    pub generics: Option<Generics>,
    pub parameters: Vec<Parameter>,
    pub return_type: Option<Type>,
    pub where_clause: Option<WhereClause>,
    pub body: Option<Block>,
    pub span: Span,
}

#[derive(Debug, Clone, PartialEq)]
pub struct Parameter {
    pub pattern: Pattern,
    pub type_annotation: Type,
    pub span: Span,
}

#[derive(Debug, Clone, PartialEq)]
pub struct Generics {
    pub params: Vec<GenericParam>,
    pub span: Span,
}

#[derive(Debug, Clone, PartialEq)]
pub struct GenericParam {
    pub name: Identifier,
    pub bounds: Vec<TypeBound>,
    pub default: Option<Type>,
    pub span: Span,
}
```

### Types

```rust
#[derive(Debug, Clone, PartialEq)]
pub enum Type {
    Primitive(PrimitiveType),
    Array(ArrayType),
    Slice(SliceType),
    Tuple(TupleType),
    Pointer(PointerType),
    Reference(ReferenceType),
    Function(FunctionType),
    Path(PathType),
    ImplTrait(ImplTraitType),
    Inferred(InferredType),
}

#[derive(Debug, Clone, PartialEq)]
pub enum PrimitiveType {
    I8, I16, I32, I64, I128, Isize,
    U8, U16, U32, U64, U128, Usize,
    F32, F64,
    Bool, Char, Str,
}

#[derive(Debug, Clone, PartialEq)]
pub struct ArrayType {
    pub element_type: Box<Type>,
    pub size: Expression,
    pub span: Span,
}

#[derive(Debug, Clone, PartialEq)]
pub struct ReferenceType {
    pub lifetime: Option<Lifetime>,
    pub is_mutable: bool,
    pub referent_type: Box<Type>,
    pub span: Span,
}

#[derive(Debug, Clone, PartialEq)]
pub struct FunctionType {
    pub is_unsafe: bool,
    pub abi: Option<Abi>,
    pub parameter_types: Vec<Type>,
    pub return_type: Option<Box<Type>>,
    pub span: Span,
}
```

### Expressions

```rust
#[derive(Debug, Clone, PartialEq)]
pub enum Expression {
    Literal(LiteralExpression),
    Path(PathExpression),
    Binary(BinaryExpression),
    Unary(UnaryExpression),
    Call(CallExpression),
    MethodCall(MethodCallExpression),
    Index(IndexExpression),
    Field(FieldExpression),
    Tuple(TupleExpression),
    Array(ArrayExpression),
    Struct(StructExpression),
    Block(Block),
    If(IfExpression),
    Match(MatchExpression),
    Loop(LoopExpression),
    While(WhileExpression),
    For(ForExpression),
    Break(BreakExpression),
    Continue(ContinueExpression),
    Return(ReturnExpression),
    Closure(ClosureExpression),
    Async(AsyncExpression),
    Await(AwaitExpression),
    Try(TryExpression),
    Meta(MetaExpression),
    Comptime(ComptimeExpression),
}

#[derive(Debug, Clone, PartialEq)]
pub struct BinaryExpression {
    pub left: Box<Expression>,
    pub operator: BinaryOperator,
    pub right: Box<Expression>,
    pub span: Span,
}

#[derive(Debug, Clone, PartialEq)]
pub enum BinaryOperator {
    // Arithmetic
    Add, Subtract, Multiply, Divide, Modulo,
    
    // Comparison
    Equal, NotEqual, Less, Greater, LessEqual, GreaterEqual,
    
    // Logical
    LogicalAnd, LogicalOr,
    
    // Bitwise
    BitwiseAnd, BitwiseOr, BitwiseXor, LeftShift, RightShift,
    
    // Assignment
    Assign,
    AddAssign, SubtractAssign, MultiplyAssign, DivideAssign, ModuloAssign,
    BitwiseAndAssign, BitwiseOrAssign, BitwiseXorAssign,
    LeftShiftAssign, RightShiftAssign,
    
    // Range
    Range, RangeInclusive,
}

#[derive(Debug, Clone, PartialEq)]
pub struct CallExpression {
    pub callee: Box<Expression>,
    pub arguments: Vec<Expression>,
    pub span: Span,
}

#[derive(Debug, Clone, PartialEq)]
pub struct IfExpression {
    pub condition: Box<Expression>,
    pub then_block: Block,
    pub else_block: Option<Box<Expression>>, // Can be another if or block
    pub span: Span,
}

#[derive(Debug, Clone, PartialEq)]
pub struct MatchExpression {
    pub scrutinee: Box<Expression>,
    pub arms: Vec<MatchArm>,
    pub span: Span,
}

#[derive(Debug, Clone, PartialEq)]
pub struct MatchArm {
    pub pattern: Pattern,
    pub guard: Option<Expression>,
    pub body: Expression,
    pub span: Span,
}
```

### Statements

```rust
#[derive(Debug, Clone, PartialEq)]
pub enum Statement {
    Expression(ExpressionStatement),
    Let(LetStatement),
    Item(Item),
}

#[derive(Debug, Clone, PartialEq)]
pub struct ExpressionStatement {
    pub expression: Expression,
    pub has_semicolon: bool,
    pub span: Span,
}

#[derive(Debug, Clone, PartialEq)]
pub struct LetStatement {
    pub is_mutable: bool,
    pub pattern: Pattern,
    pub type_annotation: Option<Type>,
    pub initializer: Option<Expression>,
    pub span: Span,
}

#[derive(Debug, Clone, PartialEq)]
pub struct Block {
    pub statements: Vec<Statement>,
    pub expression: Option<Box<Expression>>,
    pub span: Span,
}
```

### Patterns

```rust
#[derive(Debug, Clone, PartialEq)]
pub enum Pattern {
    Wildcard(WildcardPattern),
    Identifier(IdentifierPattern),
    Literal(LiteralPattern),
    Tuple(TuplePattern),
    Struct(StructPattern),
    Enum(EnumPattern),
    Reference(ReferencePattern),
    Slice(SlicePattern),
    Or(OrPattern),
}

#[derive(Debug, Clone, PartialEq)]
pub struct IdentifierPattern {
    pub is_ref: bool,
    pub is_mutable: bool,
    pub name: Identifier,
    pub subpattern: Option<Box<Pattern>>,
    pub span: Span,
}

#[derive(Debug, Clone, PartialEq)]
pub struct StructPattern {
    pub path: Path,
    pub fields: Vec<StructPatternField>,
    pub has_rest: bool,
    pub span: Span,
}

#[derive(Debug, Clone, PartialEq)]
pub struct StructPatternField {
    pub name: Identifier,
    pub pattern: Option<Pattern>,
    pub span: Span,
}
```

### Data Structures

```rust
#[derive(Debug, Clone, PartialEq)]
pub struct StructItem {
    pub visibility: Option<Visibility>,
    pub name: Identifier,
    pub generics: Option<Generics>,
    pub fields: StructFields,
    pub where_clause: Option<WhereClause>,
    pub span: Span,
}

#[derive(Debug, Clone, PartialEq)]
pub enum StructFields {
    Named(Vec<StructField>),
    Tuple(Vec<TupleField>),
    Unit,
}

#[derive(Debug, Clone, PartialEq)]
pub struct StructField {
    pub visibility: Option<Visibility>,
    pub name: Identifier,
    pub field_type: Type,
    pub span: Span,
}

#[derive(Debug, Clone, PartialEq)]
pub struct EnumItem {
    pub visibility: Option<Visibility>,
    pub name: Identifier,
    pub generics: Option<Generics>,
    pub variants: Vec<EnumVariant>,
    pub where_clause: Option<WhereClause>,
    pub span: Span,
}

#[derive(Debug, Clone, PartialEq)]
pub struct EnumVariant {
    pub name: Identifier,
    pub data: EnumVariantData,
    pub discriminant: Option<Expression>,
    pub span: Span,
}

#[derive(Debug, Clone, PartialEq)]
pub enum EnumVariantData {
    Unit,
    Tuple(Vec<TupleField>),
    Struct(Vec<StructField>),
}
```

### Meta-programming

```rust
#[derive(Debug, Clone, PartialEq)]
pub struct MetaItem {
    pub visibility: Option<Visibility>,
    pub body: Block,
    pub span: Span,
}

#[derive(Debug, Clone, PartialEq)]
pub struct MetaExpression {
    pub directive: MetaDirective,
    pub span: Span,
}

#[derive(Debug, Clone, PartialEq)]
pub enum MetaDirective {
    Include(IncludeDirective),
    Generate(GenerateDirective),
    Conditional(ConditionalDirective),
    Custom(CustomDirective),
}

#[derive(Debug, Clone, PartialEq)]
pub struct ComptimeExpression {
    pub expression: Box<Expression>,
    pub span: Span,
}
```

### Literals

```rust
#[derive(Debug, Clone, PartialEq)]
pub enum LiteralExpression {
    Integer(IntegerLiteral),
    Float(FloatLiteral),
    String(StringLiteral),
    Char(CharLiteral),
    Boolean(BooleanLiteral),
}

#[derive(Debug, Clone, PartialEq)]
pub struct IntegerLiteral {
    pub value: u128,
    pub suffix: Option<IntegerSuffix>,
    pub base: IntegerBase,
    pub span: Span,
}

#[derive(Debug, Clone, PartialEq)]
pub enum IntegerBase {
    Decimal,
    Hexadecimal,
    Binary,
    Octal,
}

#[derive(Debug, Clone, PartialEq)]
pub enum IntegerSuffix {
    I8, I16, I32, I64, I128, Isize,
    U8, U16, U32, U64, U128, Usize,
}
```

### Utility Types

```rust
#[derive(Debug, Clone, PartialEq)]
pub struct Identifier {
    pub name: String,
    pub span: Span,
}

#[derive(Debug, Clone, PartialEq)]
pub struct Path {
    pub segments: Vec<PathSegment>,
    pub is_absolute: bool,
    pub span: Span,
}

#[derive(Debug, Clone, PartialEq)]
pub struct PathSegment {
    pub name: Identifier,
    pub generics: Option<GenericArgs>,
    pub span: Span,
}

#[derive(Debug, Clone, PartialEq)]
pub struct Lifetime {
    pub name: String,
    pub span: Span,
}
```

## AST Construction

### Builder Pattern

```rust
pub struct AstBuilder {
    next_node_id: NodeId,
}

impl AstBuilder {
    pub fn new() -> Self {
        Self { next_node_id: 0 }
    }
    
    pub fn next_id(&mut self) -> NodeId {
        let id = self.next_node_id;
        self.next_node_id += 1;
        id
    }
    
    pub fn binary_expr(
        &mut self,
        left: Expression,
        op: BinaryOperator,
        right: Expression,
        span: Span,
    ) -> Expression {
        Expression::Binary(BinaryExpression {
            left: Box::new(left),
            operator: op,
            right: Box::new(right),
            span,
        })
    }
    
    // Additional builder methods...
}
```

## AST Traversal

### Visitor Pattern

```rust
pub trait AstVisitor<T = ()> {
    fn visit_program(&mut self, program: &Program) -> PhaserResult<T>;
    fn visit_item(&mut self, item: &Item) -> PhaserResult<T>;
    fn visit_expression(&mut self, expr: &Expression) -> PhaserResult<T>;
    fn visit_statement(&mut self, stmt: &Statement) -> PhaserResult<T>;
    fn visit_pattern(&mut self, pattern: &Pattern) -> PhaserResult<T>;
    fn visit_type(&mut self, ty: &Type) -> PhaserResult<T>;
    
    // Default implementations that traverse children
    fn walk_program(&mut self, program: &Program) -> PhaserResult<T> {
        for item in &program.items {
            self.visit_item(item)?;
        }
        Ok(T::default())
    }
    
    // Additional walk methods...
}

pub trait AstMutVisitor<T = ()> {
    fn visit_program_mut(&mut self, program: &mut Program) -> PhaserResult<T>;
    fn visit_item_mut(&mut self, item: &mut Item) -> PhaserResult<T>;
    // ... mutable visitor methods
}
```

## Error Handling

```rust
#[derive(Debug, Clone, PartialEq)]
pub enum AstError {
    InvalidNodeStructure { node_id: NodeId, message: String },
    MissingRequiredChild { parent_id: NodeId, child_type: String },
    TypeMismatch { expected: String, found: String, span: Span },
    CircularReference { node_id: NodeId },
}
```

## Memory Management

- Use `Box<T>` for recursive structures to prevent infinite size
- Use `Vec<T>` for collections of child nodes
- Consider using `Rc<T>` or `Arc<T>` for shared references when needed
- Implement `Clone` efficiently using reference counting where appropriate

## Testing Requirements

### Unit Tests

- AST node construction and field access
- Visitor pattern implementation
- Builder pattern functionality
- Span and position tracking
- Memory usage and clone behavior

### Integration Tests

- Round-trip parsing and pretty-printing
- AST transformation correctness
- Large program handling
- Error propagation through visitor pattern

## Future Extensions

- **AST Macros**: Support for procedural macros that operate on AST
- **Incremental Parsing**: Support for partial AST updates
- **Serialization**: Support for AST serialization/deserialization
- **Source Maps**: Enhanced source mapping for generated code
- **Type Annotations**: Optional type information attached to expressions