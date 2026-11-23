%{
#include "parser.tab.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int lexical_error = 0;
int lexer_line = 1;

static char *copy_text(const char *text) {
    size_t length = strlen(text) + 1;
    char *copy = malloc(length);
    if (!copy) { perror("malloc"); exit(EXIT_FAILURE); }
    memcpy(copy, text, length);
    return copy;
}
%}

%option noyywrap
%option yylineno

DIGIT       [0-9]
LETTER      [a-zA-Z_]
IDENT       {LETTER}({LETTER}|{DIGIT})*
EXPONENT    [eE][+-]?{DIGIT}+
FLOAT       (({DIGIT}+\.{DIGIT}*|\.{DIGIT}+){EXPONENT}?|{DIGIT}+{EXPONENT})
INTEGER     {DIGIT}+

%%

"int"       { return INT; }
"float"     { return FLOAT; }
"double"    { return DOUBLE; }
"char"      { return CHAR; }
"short"     { return SHORT; }
"long"      { return LONG; }
"void"      { return VOID; }
"if"        { return IF; }
"else"      { return ELSE; }
"while"     { return WHILE; }
"for"       { return FOR; }
"return"    { return RETURN; }
"break"     { return BREAK; }
"continue"  { return CONTINUE; }

{FLOAT}     { yylval.text = copy_text(yytext); return FLOAT_LITERAL; }
{INTEGER}   { yylval.text = copy_text(yytext); return INTEGER_LITERAL; }
{IDENT}     { yylval.text = copy_text(yytext); return IDENTIFIER; }

"=="        { return EQ; }
"!="        { return NE; }
"<="        { return LE; }
">="        { return GE; }
"&&"        { return AND; }
"||"        { return OR; }
"++"        { return INC; }
"--"        { return DEC; }
"+="        { return ADD_ASSIGN; }
"-="        { return SUB_ASSIGN; }
"*="        { return MUL_ASSIGN; }
"/="        { return DIV_ASSIGN; }

[+\-*/%=<>!]=? { return yytext[0]; }
"("         { return '('; }
")"         { return ')'; }
"{"         { return '{'; }
"}"         { return '}'; }
";"         { return ';'; }
","         { return ','; }
"="         { return '='; }
"?"         { return '?'; }
":"         { return ':'; }

[ \t\r]+    { /* Ignore horizontal whitespace. */ }
\n          { /* yylineno is maintained by Flex. */ }
"//"[^\n]*  { /* Ignore single-line comments. */ }
"/*"([^*]|\*+[^*/])*"*/" { /* Ignore block comments. */ }

[0-9]+[a-zA-Z_][a-zA-Z0-9_]* {
    fprintf(stderr, "Lexical error at line %d: malformed numeric token '%s'\n", yylineno, yytext);
    lexical_error = 1;
    return INVALID;
}

. {
    fprintf(stderr, "Lexical error at line %d: unexpected character '%s'\n", yylineno, yytext);
    lexical_error = 1;
    return INVALID;
}

%%
