%code requires {
#include "ast.h"
}

%{
#include "ast.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int yylex(void);
void yyerror(const char *message);
extern int yylineno;
extern FILE *yyin;
ASTNode *syntax_tree = NULL;

static ASTNode *node1(const char *name, ASTNode *a) {
    ASTNode *n = ast_new(name); ast_add_child(n, a); return n;
}
static ASTNode *node2(const char *name, ASTNode *a, ASTNode *b) {
    ASTNode *n = ast_new(name); ast_add_child(n, a); ast_add_child(n, b); return n;
}
static ASTNode *node3(const char *name, ASTNode *a, ASTNode *b, ASTNode *c) {
    ASTNode *n = ast_new(name); ast_add_child(n, a); ast_add_child(n, b); ast_add_child(n, c); return n;
}
static ASTNode *node4(const char *name, ASTNode *a, ASTNode *b, ASTNode *c, ASTNode *d) {
    ASTNode *n = ast_new(name); ast_add_child(n, a); ast_add_child(n, b);
    ast_add_child(n, c); ast_add_child(n, d); return n;
}
static ASTNode *binary(const char *op, ASTNode *a, ASTNode *b) {
    return node2(op, a, b);
}
%}

%define parse.error detailed
%union {
    char *text;
    ASTNode *node;
}

%token INT FLOAT DOUBLE CHAR SHORT LONG VOID
%token IF ELSE WHILE FOR RETURN BREAK CONTINUE
%token <text> IDENTIFIER INTEGER_LITERAL FLOAT_LITERAL
%token EQ NE LE GE AND OR INC DEC ADD_ASSIGN SUB_ASSIGN MUL_ASSIGN DIV_ASSIGN
%token INVALID

%type <node> program statement_list statement simple_statement declaration type_specifier
%type <node> assignment expression logical_or logical_and equality relational
%type <node> additive multiplicative unary postfix primary optional_expression
%type <node> for_initializer

%left OR
%left AND
%left EQ NE
%left '<' '>' LE GE
%left '+' '-'
%left '*' '/' '%'
%right '!' UMINUS

%start program

%%

program
    : /* empty */                 { $$ = ast_new("Program"); syntax_tree = $$; }
    | statement_list              { $$ = $1; syntax_tree = $$; }
    ;

statement_list
    : statement                    { $$ = ast_new("Program"); ast_add_child($$, $1); }
    | statement_list statement     { ast_add_child($1, $2); $$ = $1; }
    ;

statement
    : simple_statement             { $$ = $1; }
    | WHILE '(' expression ')' simple_statement
                                   { $$ = node2("WhileLoop", $3, $5); }
    | FOR '(' for_initializer ';' optional_expression ';' optional_expression ')' simple_statement
                                   { $$ = node4("ForLoop", $3, $5, $7, $9); }
    ;

/* Deliberately restricted: loop bodies are simple statements, not other loops or blocks. */
simple_statement
    : declaration                  { $$ = $1; }
    | assignment ';'               { $$ = $1; }
    | expression ';'               { $$ = node1("ExpressionStatement", $1); }
    | ';'                          { $$ = ast_new("EmptyStatement"); }
    ;

declaration
    : type_specifier IDENTIFIER ';'
                                   { $$ = node2("Declaration", $1, ast_leaf("Identifier", $2)); free($2); }
    | type_specifier IDENTIFIER '=' expression ';'
                                   { $$ = node3("InitializedDeclaration", $1, ast_leaf("Identifier", $2), $4); free($2); }
    ;

type_specifier
    : INT                          { $$ = ast_new("Type: int"); }
    | FLOAT                        { $$ = ast_new("Type: float"); }
    | DOUBLE                       { $$ = ast_new("Type: double"); }
    | CHAR                         { $$ = ast_new("Type: char"); }
    | SHORT                        { $$ = ast_new("Type: short"); }
    | LONG                         { $$ = ast_new("Type: long"); }
    | VOID                         { $$ = ast_new("Type: void"); }
    ;

assignment
    : IDENTIFIER '=' expression   { $$ = node2("Assignment (=)", ast_leaf("Identifier", $1), $3); free($1); }
    | IDENTIFIER ADD_ASSIGN expression
                                   { $$ = node2("Assignment (+=)", ast_leaf("Identifier", $1), $3); free($1); }
    | IDENTIFIER SUB_ASSIGN expression
                                   { $$ = node2("Assignment (-=)", ast_leaf("Identifier", $1), $3); free($1); }
    | IDENTIFIER MUL_ASSIGN expression
                                   { $$ = node2("Assignment (*=)", ast_leaf("Identifier", $1), $3); free($1); }
    | IDENTIFIER DIV_ASSIGN expression
                                   { $$ = node2("Assignment (/=)", ast_leaf("Identifier", $1), $3); free($1); }
    ;

for_initializer
    : /* empty */                 { $$ = ast_new("NoInitializer"); }
    | type_specifier IDENTIFIER   { $$ = node2("ForDeclaration", $1, ast_leaf("Identifier", $2)); free($2); }
    | type_specifier IDENTIFIER '=' expression
                                   { $$ = node3("ForInitializedDeclaration", $1, ast_leaf("Identifier", $2), $4); free($2); }
    | assignment                  { $$ = $1; }
    ;

optional_expression
    : /* empty */                 { $$ = ast_new("Omitted"); }
    | expression                  { $$ = $1; }
    | assignment                  { $$ = $1; }
    ;

expression
    : logical_or                  { $$ = $1; }
    ;
logical_or
    : logical_and                 { $$ = $1; }
    | logical_or OR logical_and   { $$ = binary("||", $1, $3); }
    ;
logical_and
    : equality                    { $$ = $1; }
    | logical_and AND equality    { $$ = binary("&&", $1, $3); }
    ;
equality
    : relational                  { $$ = $1; }
    | equality EQ relational      { $$ = binary("==", $1, $3); }
    | equality NE relational      { $$ = binary("!=", $1, $3); }
    ;
relational
    : additive                    { $$ = $1; }
    | relational '<' additive     { $$ = binary("<", $1, $3); }
    | relational '>' additive     { $$ = binary(">", $1, $3); }
    | relational LE additive      { $$ = binary("<=", $1, $3); }
    | relational GE additive      { $$ = binary(">=", $1, $3); }
    ;
additive
    : multiplicative              { $$ = $1; }
    | additive '+' multiplicative { $$ = binary("+", $1, $3); }
    | additive '-' multiplicative { $$ = binary("-", $1, $3); }
    ;
multiplicative
    : unary                       { $$ = $1; }
    | multiplicative '*' unary   { $$ = binary("*", $1, $3); }
    | multiplicative '/' unary   { $$ = binary("/", $1, $3); }
    | multiplicative '%' unary   { $$ = binary("%", $1, $3); }
    ;
unary
    : postfix                     { $$ = $1; }
    | '-' unary %prec UMINUS      { $$ = node1("Unary (-)", $2); }
    | '!' unary                   { $$ = node1("Unary (!)", $2); }
    | '+' unary                   { $$ = node1("Unary (+)", $2); }
    ;
postfix
    : primary                     { $$ = $1; }
    | primary INC                 { $$ = node1("Postfix (++)", $1); }
    | primary DEC                 { $$ = node1("Postfix (--) ", $1); }
    ;
primary
    : IDENTIFIER                  { $$ = ast_leaf("Identifier", $1); free($1); }
    | INTEGER_LITERAL             { $$ = ast_leaf("Integer", $1); free($1); }
    | FLOAT_LITERAL               { $$ = ast_leaf("Float", $1); free($1); }
    | '(' expression ')'          { $$ = node1("Parenthesized", $2); }
    ;

%%

/* Four-child helper is defined after the grammar to keep loop construction clear. */
