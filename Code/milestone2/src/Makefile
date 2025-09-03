parser: lex.yy.c parser.tab.c parser_1_declaration.tab.c parser_2.tab.c parser_3.tab.c depend.o
	g++ depend.o lex.yy.c parser.tab.c parser_1_declaration.tab.c parser_2.tab.c parser_3.tab.c -o parser -ll -lfl -g

lex.yy.c: lexer.l parser.tab.h
	flex lexer.l

parser.tab.c: parser.y
	bison parser.y 

parser.tab.h: parser.y
	bison -d parser.y

parser_1_declaration.tab.c: parser_1_declaration.y
	bison parser_1_declaration.y 

parser_2.tab.c: parser_2.y
	bison -d -t parser_2.y

parser_3.tab.c: parser_3.y
	bison parser_3.y

depend.o: depend.h depend.cpp
	g++ -c depend.cpp -o depend.o

clean:
	rm -f *.tab.c 
	rm -f *.tab.h 
	rm -f *.yy.c
	rm -f parser
	rm -f *.txt
	rm -f *.csv
	rm -f *.o