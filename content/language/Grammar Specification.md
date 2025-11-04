# Phaser Language Grammar Specification

This document defines the formal grammar for the Phaser programming language using Extended Backus-Naur Form (EBNF).

## Notation

- `::=` defines a production rule
- `|` separates alternatives
- `()` groups elements
- `[]` indicates optional elements
- `{}` indicates zero or more repetitions
- `{...}+` indicates one or more repetitions
- `"..."` indicates literal tokens
- `'...'` indicates character literals

## Lexical Grammar

### Tokens

```ebnf
(* Identifiers *)
identifier ::= letter { letter | digit | "_" }
letter ::= "a"..."z" | "A"..."Z"
digit ::= "0"..."9"

(* Literals *)
integer_literal ::= decimal_literal | hex_literal | binary_literal | octal_literal
decimal_literal ::= digit { digit | "_" }
hex_literal ::= "0x" hex_digit { hex_digit | "_" }
binary_literal ::= "0b" binary_digit { binary_digit | "_" }
octal_literal ::= "0o" octal_digit { octal_digit | "_" }

hex_digit ::= digit | "a"..."f" | "A"..."F"
binary_digit ::= "0" | "1"
octal_digit ::= "0"..."7"

float_literal ::= decimal_literal "." decimal_literal [ exponent ]
               | decimal_literal exponent
exponent ::= ("e" | "E") ["+" | "-"] decimal_literal

string_literal ::= "\"" { string_char } "\""
string_char ::= escape_sequence | (any_char - "\"" - "\\")
escape_sequence ::= "\\" ("n" | "t" | "r" | "\\" | "\"" | "'" | "0")

char_literal ::= "'" (escape_sequence | (any_char - "'" - "\\")) "'"

(* Keywords *)
keyword ::= "fn" | "let" | "mutable" | "const" | "if" | "else" | "while" | "for"
          | "loop" | "break" | "continue" | "return" | "struct" | "enum"
          | "impl" | "trait" | "type" | "module" | "use" | "public" | "private" | "extern"
          | "unsafe" | "async" | "await" | "meta" | "macro" | "match" | "as" | "is" | "in" | "where"

(* Operators *)
operator ::= "+" | "-" | "*" | "/" | "%" | "=" | "==" | "!=" | "<" | ">"
           | "<=" | ">=" | "&&" | "||" | "!" | "&" | "|" | "^" | "<<" | ">>"
           | "+=" | "-=" | "*=" | "/=" | "%=" | "&=" | "|=" | "^=" | "<<=" | ">>="
           | "->" | "=>" | "::" | "." | ".." | "..." | "?" | "@"

(* Delimiters *)
delimiter ::= "(" | ")" | "[" | "]" | "{" | "}" | "," | ";" | ":"

(* Comments *)
line_comment ::= "//" { any_char - newline } newline
block_comment ::= "/*" { any_char | block_comment } "*/"

(* Whitespace *)
whitespace ::= " " | "\t" | "\n" | "\r"
```

## Syntactic Grammar

### Program Structure

```ebnf
program ::= { item }

item ::= function_item
       | struct_item
       | enum_item
       | trait_item
       | impl_item
       | type_alias_item
       | const_item
       | static_item
       | mod_item
       | use_item
       | extern_item
       | meta_item

visibility ::= [ "public" | "private" ]
```

### Functions

```ebnf
function_item ::= [ visibility ] [ "async" ] "fn" identifier 
                  [ generic_params ] "(" [ parameter_list ] ")" 
                  [ "->" type ] [ where_clause ] block_expression

parameter_list ::= parameter { "," parameter } [ "," ]
parameter ::= [ "mutable" ] identifier ":" type

generic_params ::= "<" generic_param { "," generic_param } [ "," ] ">"
generic_param ::= identifier [ ":" type_bounds ]

where_clause ::= "where" where_predicate { "," where_predicate } [ "," ]
where_predicate ::= type ":" type_bounds

type_bounds ::= type_bound { "+" type_bound }
type_bound ::= trait_reference | lifetime
```

### Types

```ebnf
type ::= primitive_type
       | array_type
       | slice_type
       | tuple_type
       | pointer_type
       | reference_type
       | function_type
       | path_type
       | impl_trait_type
       | inferred_type

primitive_type ::= "int8" | "int16" | "int32" | "int64" | "int128" | "isize"
                 | "uint8" | "uint16" | "uint32" | "uint64" | "uint128" | "usize"
                 | "float32" | "float64" | "bool" | "string"

array_type ::= "[" type ";" expression "]"
slice_type ::= "[" type "]"
tuple_type ::= "(" [ type { "," type } [ "," ] ] ")"
pointer_type ::= "*" [ "const" | "mutable" ] type
reference_type ::= "&" [ lifetime ] [ "mutable" ] type
function_type ::= [ "unsafe" ] [ "extern" [ abi ] ] "fn" "(" [ type_list ] ")" [ "->" type ]
path_type ::= path [ "::" "<" type_list ">" ]
impl_trait_type ::= "impl" type_bounds
inferred_type ::= "_"

type_list ::= type { "," type } [ "," ]
```

### Expressions

```ebnf
expression ::= assignment_expression

assignment_expression ::= logical_or_expression [ assignment_operator assignment_expression ]
assignment_operator ::= "=" | "+=" | "-=" | "*=" | "/=" | "%=" | "&=" | "|=" | "^=" | "<<=" | ">>="

logical_or_expression ::= logical_and_expression { "||" logical_and_expression }
logical_and_expression ::= equality_expression { "&&" equality_expression }
equality_expression ::= relational_expression { ("==" | "!=") relational_expression }
relational_expression ::= shift_expression { ("<" | ">" | "<=" | ">=") shift_expression }
shift_expression ::= additive_expression { ("<<" | ">>") additive_expression }
additive_expression ::= multiplicative_expression { ("+" | "-") multiplicative_expression }
multiplicative_expression ::= unary_expression { ("*" | "/" | "%") unary_expression }

unary_expression ::= postfix_expression
                   | "-" unary_expression
                   | "!" unary_expression
                   | "&" [ "mutable" ] unary_expression
                   | "*" unary_expression

postfix_expression ::= primary_expression { postfix_operator }
postfix_operator ::= "[" expression "]"
                   | "." identifier [ "::" "<" type_list ">" ] [ "(" [ argument_list ] ")" ]
                   | "(" [ argument_list ] ")"
                   | "?" 
                   | ".await"

primary_expression ::= literal_expression
                     | path_expression
                     | tuple_expression
                     | array_expression
                     | struct_expression
                     | block_expression
                     | if_expression
                     | match_expression
                     | loop_expression
                     | while_expression
                     | for_expression
                     | closure_expression
                     | async_block_expression
                     | unsafe_block_expression
                     | meta_expression
                     | "(" expression ")"

literal_expression ::= integer_literal | float_literal | string_literal | char_literal | "true" | "false"

path_expression ::= path [ "::" "<" type_list ">" ]
path ::= [ "::" ] identifier { "::" identifier }

argument_list ::= expression { "," expression } [ "," ]
```

### Statements

```ebnf
statement ::= expression_statement
            | let_statement
            | item_statement

expression_statement ::= expression ";"
let_statement ::= "let" [ "mutable" ] pattern [ ":" type ] [ "=" expression ] ";"
item_statement ::= item

block_expression ::= "{" { statement } [ expression ] "}"
```

### Control Flow

```ebnf
if_expression ::= "if" expression block_expression [ "else" ( block_expression | if_expression ) ]

match_expression ::= "match" expression "{" [ match_arm { "," match_arm } [ "," ] ] "}"
match_arm ::= pattern [ "if" expression ] "=>" ( expression | block_expression )

loop_expression ::= [ loop_label ] "loop" block_expression
while_expression ::= [ loop_label ] "while" expression block_expression
for_expression ::= [ loop_label ] "for" pattern "in" expression block_expression

loop_label ::= identifier ":"

break_expression ::= "break" [ loop_label ] [ expression ]
continue_expression ::= "continue" [ loop_label ]
return_expression ::= "return" [ expression ]
```

### Patterns

```ebnf
pattern ::= literal_pattern
          | identifier_pattern
          | wildcard_pattern
          | tuple_pattern
          | struct_pattern
          | enum_pattern
          | reference_pattern
          | slice_pattern

literal_pattern ::= literal_expression
identifier_pattern ::= [ "ref" ] [ "mutable" ] identifier [ "@" pattern ]
wildcard_pattern ::= "_"
tuple_pattern ::= "(" [ pattern { "," pattern } [ "," ] ] ")"
struct_pattern ::= path "{" [ struct_pattern_field { "," struct_pattern_field } [ "," ] [ ".." ] ] "}"
struct_pattern_field ::= identifier [ ":" pattern ]
enum_pattern ::= path [ "(" [ pattern { "," pattern } [ "," ] ] ")" | "{" [ struct_pattern_field { "," struct_pattern_field } [ "," ] ] "}" ]
reference_pattern ::= "&" [ "mutable" ] pattern
slice_pattern ::= "[" [ pattern { "," pattern } [ "," ] ] [ ".." [ pattern ] ] "]"
```

### Meta Programming

```ebnf
meta_item ::= "meta" "{" { meta_statement } "}"
meta_statement ::= statement | meta_directive

meta_directive ::= "@" identifier [ "(" [ argument_list ] ")" ]
meta_expression ::= "comptime" expression

comptime_block ::= "comptime" block_expression
```

### Data Structures

```ebnf
struct_item ::= [ visibility ] "struct" identifier [ generic_params ] 
                ( struct_fields | ";" ) [ where_clause ]

struct_fields ::= "{" [ struct_field { "," struct_field } [ "," ] ] "}"
              | "(" [ tuple_field { "," tuple_field } [ "," ] ] ")" ";"

struct_field ::= [ visibility ] identifier ":" type
tuple_field ::= [ visibility ] type

enum_item ::= [ visibility ] "enum" identifier [ generic_params ] 
              "{" [ enum_variant { "," enum_variant } [ "," ] ] "}" [ where_clause ]

enum_variant ::= identifier [ enum_variant_data ]
enum_variant_data ::= "(" [ tuple_field { "," tuple_field } [ "," ] ] ")"
                    | "{" [ struct_field { "," struct_field } [ "," ] ] "}"
```

## Precedence and Associativity

| Precedence | Operators | Associativity |
|------------|-----------|---------------|
| 1 (highest) | `()` `[]` `.` `?.` `.await` | Left |
| 2 | `-` `!` `&` `*` (unary) | Right |
| 3 | `*` `/` `%` | Left |
| 4 | `+` `-` | Left |
| 5 | `<<` `>>` | Left |
| 6 | `&` | Left |
| 7 | `^` | Left |
| 8 | `|` | Left |
| 9 | `==` `!=` `<` `>` `<=` `>=` | Left |
| 10 | `&&` | Left |
| 11 | `||` | Left |
| 12 | `..` `...` | Left |
| 13 | `=` `+=` `-=` `*=` `/=` `%=` `&=` `|=` `^=` `<<=` `>>=` | Right |

## Notes

- The grammar supports both expression-oriented and statement-oriented programming styles
- Meta-programming constructs are integrated at the syntactic level
- Type inference is supported through the `_` type placeholder
- The grammar is designed to be unambiguous and suitable for recursive descent parsing