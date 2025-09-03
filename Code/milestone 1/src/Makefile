parser: lex.yy.c parser.tab.c
	g++ lex.yy.c parser.tab.c -o parser -ll -lfl

lex.yy.c: lexer.l
	flex lexer.l

parser.tab.c: parser.y
	bison -d -t parser.y