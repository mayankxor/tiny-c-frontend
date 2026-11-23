# Tiny C Front End

A small educational front end for a deliberately restricted, C-like language. It demonstrates the first two compiler phases:

1. **Lexical analysis** with Flex (`lexer.l`).
2. **Syntax analysis** with Bison (`parser.y`), which builds an Abstract Syntax Tree (AST).

The AST is printed as a Unicode tree in the terminal. This project does **not** perform semantic analysis, type checking, symbol-table construction, preprocessing, or code generation. It does not produce an executable program.

## Requirements

You need:

- GCC (or another C compiler compatible with the Makefile flags)
- GNU Make
- Flex
- GNU Bison

On Debian/Ubuntu:

```sh
sudo apt install build-essential flex bison
```

On Arch Linux:

```sh
sudo pacman -S --needed base-devel flex bison
```

## Build

Run these commands from the project directory:

```sh
make
```

This generates `parser.tab.c` and `parser.tab.h` from `parser.y`, generates `lex.yy.c` from `lexer.l`, and compiles the generated sources with `main.c` and `ast.c` into `tinycc`.

To remove generated files and the executable:

```sh
make clean
```

## Run

Pass a source file:

```sh
./tinycc examples/basic.c
```

Or provide source through standard input:

```sh
printf 'int n = 4;\nn = n * 2;\n' | ./tinycc
```

The program deliberately performs two passes over the input:

1. It runs the lexer over the entire input. If an invalid character or malformed numeric token is found, it reports a lexical error and does not invoke the parser.
2. If the lexical pass succeeds, it rewinds the input and invokes the Bison parser. If the input conforms to the grammar, the parser's AST is printed.

Example success output (format abbreviated):

```text
[OK] Lexical analysis succeeded.

[OK] Syntax analysis succeeded.

========== ABSTRACT SYNTAX TREE ==========
Program
├── InitializedDeclaration
│   ├── Type: int
│   ├── Identifier: count
│   └── Integer: 10
└── Assignment (=)
    ├── Identifier: count
    └── +
        ├── Identifier: count
        └── *
            ├── Integer: 5
            └── Integer: 2
```

The exact tree depends on the input. Binary expressions become parent nodes, so operator precedence is visible in the tree.

## Supported grammar

The grammar is intentionally small. It is designed for short snippets rather than complete C translation units. A program is a sequence of supported statements; it does not need a `main` function.

### 1. Types and declarations

Supported type keywords:

```c
int
float
double
char
short
long
void
```

Supported declaration forms:

```c
int count;
float ratio = 2.5;
double distance = 10.0;
char initial;
```

Only one identifier is allowed per declaration. Pointer, array, function, `const`, `unsigned`, and comma-separated declarations are not implemented.

### 2. Assignments

Supported assignment statements:

```c
count = 10;
count = count + 1;
count += 2;
count -= 1;
count *= 3;
count /= 2;
```

The left side must be a single identifier. Assignment is not a general expression, so chained assignments and assignments inside arithmetic expressions are not supported.

### 3. Expressions

Supported primary expressions:

- Identifiers: `count`
- Integer literals: `42`
- Floating-point literals: `3.14`, `.5`, `10.`, `1e-3`
- Parenthesized expressions: `(count + 2)`

Supported operators, from lower to higher precedence:

| Precedence | Operators |
|---|---|
| Logical OR | `||` |
| Logical AND | `&&` |
| Equality | `==`, `!=` |
| Relational | `<`, `>`, `<=`, `>=` |
| Additive | `+`, `-` |
| Multiplicative | `*`, `/`, `%` |
| Unary | unary `+`, unary `-`, `!` |
| Postfix | `++`, `--` |

The parser handles operator precedence and left associativity for the binary arithmetic and comparison operators. The project does not check whether an operation is meaningful for the operand types.

### 4. While loops

Syntax:

```c
while (condition) simple_statement
```

Example:

```c
int count = 0;
while (count < 5) count += 1;
```

### 5. For loops

Syntax:

```c
for (initializer; condition; update) simple_statement
```

The initializer may be empty, a simple declaration, or an assignment. The condition and update may be omitted. Examples:

```c
for (int i = 0; i < 5; i++) total = total + i;
for (i = 0; i < 10; i = i + 1) total += i;
for (;;) total += 1;
```

### 6. Simple statements and loop bodies

A simple statement is one of:

- A declaration
- An assignment followed by `;`
- An expression followed by `;`
- An empty statement (`;`)

**Intentional limitation:** a loop body accepts only a simple statement. Compound blocks (`{ ... }`) and nested loops are not part of this grammar. This keeps the parser small and matches the project's introductory scope.

## Lexical tokens

The lexer recognizes these keyword tokens: `int`, `float`, `double`, `char`, `short`, `long`, `void`, `if`, `else`, `while`, `for`, `return`, `break`, and `continue`.

It also recognizes:

- Identifiers beginning with an ASCII letter or underscore, followed by letters, digits, or underscores.
- Decimal integer literals.
- Decimal floating-point literals, including exponent notation.
- Arithmetic, comparison, logical, assignment, increment, and decrement operators.
- Parentheses, braces, semicolons, commas, and the `?` / `:` characters.
- Whitespace, `//` line comments, and `/* ... */` block comments.

A keyword can be recognized lexically even if it is not accepted by the parser. For example, `if`, `else`, `return`, `break`, and `continue` are tokenized but do not have syntax productions yet. Using them as statements therefore results in a **syntax error**, not a lexical error.

## Error handling

### Lexical error

An unknown character or malformed token such as `12abc` causes the lexer to report its line number. The parser is not started after a lexical failure.

Example:

```c
int value = 12;
value = value @ 3;
```

### Syntax error

A stream of valid tokens can still violate the grammar. For example:

```c
int value = ;
```

Here, every character belongs to a recognized token, but the declaration is incomplete. The lexer succeeds and Bison reports a syntax error.

## Project layout

```text
.
├── lexer.l                  # Flex lexical rules
├── parser.y                 # Bison grammar and AST construction actions
├── ast.h                    # AST node interface
├── ast.c                    # AST allocation, printing, and cleanup
├── main.c                   # Two-pass driver: lex first, parse second
├── Makefile                 # Build and clean targets
├── examples/
│   ├── basic.c
│   ├── loops.c
│   ├── invalid_lexical.c
│   └── invalid_syntax.c
└── README.md
```

## How it works internally

### Lexer (`lexer.l`)

Flex converts the regular expressions in `lexer.l` into a C scanner. The scanner returns token codes to the caller. For tokens that carry text (identifiers and numeric literals), it places a dynamically allocated copy of the matched text in `yylval.text`.

### Parser (`parser.y`)

Bison converts the grammar into an LALR parser. Each grammar production has a C action that creates an AST node or attaches existing nodes as children. For example, the production for addition creates a `+` node with the left and right operands as its children.

### AST (`ast.c`)

An AST node contains a label and a dynamically sized array of child pointers. The printer recursively visits the children and uses `├──`, `└──`, and `│` to show the hierarchy. The tree is an abstract syntax tree, not a concrete parse tree: punctuation such as semicolons and parentheses is generally omitted unless parentheses are represented as a `Parenthesized` node.

### Driver (`main.c`)

The driver runs the scanner once before parsing. This guarantees that lexical errors are reported before syntax analysis begins. It then rewinds the input, restarts the scanner, and calls `yyparse()` to construct the AST. Standard input is copied into a temporary file so that it can also be rewound for the second pass.

## Scope and known limitations

This is a teaching project, not a standards-compliant C compiler. In particular, it does not implement:

- `main`, function definitions, function calls, or function parameters
- `if` / `else` syntax, `switch`, `do` / `while`, or `goto`
- Nested loops, compound statement blocks, or general statement nesting
- Arrays, pointers, structs, unions, enums, typedefs, or storage classes
- Preprocessor directives, macros, or header files
- String and character literal values
- Hexadecimal, octal, binary, or suffixed integer literals
- Semantic checks, type checking, undeclared-variable checks, or scope rules
- Intermediate representation, assembly, or machine code generation

The lexer recognizes a few more keywords and punctuation tokens than the parser currently accepts. This is intentional: lexical recognition and grammatical acceptance are separate phases.

## Exit status

- `0`: both lexical and syntax analysis succeeded.
- Non-zero: invalid invocation, input error, lexical error, or syntax error.

## License

You may use, modify, and distribute this educational code. Add a license file if you intend to publish it under a specific open-source license.
