#ifndef AST_H
#define AST_H

typedef struct ASTNode {
    char *label;
    struct ASTNode **children;
    int child_count;
    int child_capacity;
} ASTNode;

ASTNode *ast_new(const char *label);
ASTNode *ast_leaf(const char *kind, const char *value);
void ast_add_child(ASTNode *parent, ASTNode *child);
void ast_print(const ASTNode *root);
void ast_free(ASTNode *root);

#endif
