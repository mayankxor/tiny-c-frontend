CC      := gcc
FLEX    := flex
BISON   := bison
CFLAGS  := -std=c11 -Wall -Wextra -Wpedantic -g
TARGET  := tinycc

.PHONY: all clean test

all: $(TARGET)

parser.tab.c parser.tab.h: parser.y ast.h
	$(BISON) -Wall -d -o parser.tab.c parser.y

lex.yy.c: lexer.l parser.tab.h
	$(FLEX) -o lex.yy.c lexer.l

$(TARGET): main.c ast.c parser.tab.c lex.yy.c ast.h
	$(CC) $(CFLAGS) -o $@ main.c ast.c parser.tab.c lex.yy.c

clean:
	rm -f $(TARGET) lex.yy.c parser.tab.c parser.tab.h

test: $(TARGET)
	./$(TARGET) examples/basic.c
	./$(TARGET) examples/loops.c
