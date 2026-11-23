#include "ast.h"
#include "parser.tab.h"
#include <stdio.h>
#include <stdlib.h>

int yyparse(void);
int yylex(void);
void yyrestart(FILE *input_file);
extern FILE *yyin;
extern int lexical_error;
extern int yylineno;
extern ASTNode *syntax_tree;

static FILE *spool_stdin(void) {
    FILE *temporary = tmpfile();
    if (!temporary) { perror("tmpfile"); return NULL; }
    int ch;
    while ((ch = getchar()) != EOF) {
        if (fputc(ch, temporary) == EOF) {
            perror("writing temporary input");
            fclose(temporary);
            return NULL;
        }
    }
    rewind(temporary);
    return temporary;
}

int main(int argc, char **argv) {
    if (argc > 2) {
        fprintf(stderr, "Usage: %s [source-file]\n", argv[0]);
        return EXIT_FAILURE;
    }

    int close_input = 0;
    if (argc == 2) {
        yyin = fopen(argv[1], "r");
        if (!yyin) { perror(argv[1]); return EXIT_FAILURE; }
        close_input = 1;
    } else {
        yyin = spool_stdin();
        if (!yyin) return EXIT_FAILURE;
        close_input = 1;
    }

    /* Pass 1: consume the complete input with the lexer only. */
    int token;
    while ((token = yylex()) != 0) {
        if (token == IDENTIFIER || token == INTEGER_LITERAL || token == FLOAT_LITERAL)
            free(yylval.text);
        if (lexical_error) break;
    }

    if (lexical_error) {
        fprintf(stderr, "\nLexical analysis failed. Parsing was not started.\n");
        if (close_input) fclose(yyin);
        return EXIT_FAILURE;
    }

    puts("[OK] Lexical analysis succeeded.");

    /* Pass 2: rewind the same input and let Bison parse it. */
    if (fseek(yyin, 0, SEEK_SET) != 0) {
        fprintf(stderr, "Could not rewind input.\n");
        if (close_input) fclose(yyin);
        return EXIT_FAILURE;
    }
    yyrestart(yyin);
    yylineno = 1;

    if (yyparse() == 0) {
        puts("\n[OK] Syntax analysis succeeded.\n");
        puts("========== ABSTRACT SYNTAX TREE ==========");
        ast_print(syntax_tree);
        ast_free(syntax_tree);
        if (close_input) fclose(yyin);
        return EXIT_SUCCESS;
    }

    fprintf(stderr, "\nSyntax analysis failed.\n");
    if (close_input) fclose(yyin);
    return EXIT_FAILURE;
}

void yyerror(const char *message) {
    fprintf(stderr, "Syntax error at line %d: %s\n", yylineno, message);
}
