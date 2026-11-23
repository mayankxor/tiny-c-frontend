#include "ast.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static char *duplicate(const char *s) {
    size_t n = strlen(s) + 1;
    char *copy = malloc(n);
    if (!copy) { perror("malloc"); exit(EXIT_FAILURE); }
    memcpy(copy, s, n);
    return copy;
}

ASTNode *ast_new(const char *label) {
    ASTNode *node = calloc(1, sizeof(*node));
    if (!node) { perror("calloc"); exit(EXIT_FAILURE); }
    node->label = duplicate(label);
    return node;
}

ASTNode *ast_leaf(const char *kind, const char *value) {
    size_t size = strlen(kind) + strlen(value) + 4;
    char *label = malloc(size);
    if (!label) { perror("malloc"); exit(EXIT_FAILURE); }
    snprintf(label, size, "%s: %s", kind, value);
    ASTNode *leaf = ast_new(label);
    free(label);
    return leaf;
}

void ast_add_child(ASTNode *parent, ASTNode *child) {
    if (!parent || !child) return;
    if (parent->child_count == parent->child_capacity) {
        int next = parent->child_capacity ? parent->child_capacity * 2 : 4;
        ASTNode **items = realloc(parent->children, (size_t)next * sizeof(*items));
        if (!items) { perror("realloc"); exit(EXIT_FAILURE); }
        parent->children = items;
        parent->child_capacity = next;
    }
    parent->children[parent->child_count++] = child;
}

static void print_node(const ASTNode *node, const char *prefix, int is_last, int is_root) {
    if (!node) return;
    if (is_root) printf("%s\n", node->label);
    else printf("%s%s%s\n", prefix, is_last ? "└── " : "├── ", node->label);

    size_t old_len = strlen(prefix);
    size_t extra = is_root ? 0 : 4;
    char *next = malloc(old_len + extra + 1);
    if (!next) { perror("malloc"); exit(EXIT_FAILURE); }
    memcpy(next, prefix, old_len);
    if (!is_root) memcpy(next + old_len, is_last ? "    " : "│   ", 4);
    next[old_len + extra] = '\0';

    for (int i = 0; i < node->child_count; ++i)
        print_node(node->children[i], next, i == node->child_count - 1, 0);
    free(next);
}

void ast_print(const ASTNode *root) { print_node(root, "", 1, 1); }

void ast_free(ASTNode *root) {
    if (!root) return;
    for (int i = 0; i < root->child_count; ++i) ast_free(root->children[i]);
    free(root->children);
    free(root->label);
    free(root);
}
