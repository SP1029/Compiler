%top{
    extern "C" int yylex();
    #include "parser.tab.h"
    int myerror(const char* s);
}

%top{
    #include<iostream>
    #include<stdlib.h>
    #include<string>
    #include<vector>
    #include<map>
    #include<algorithm>
    #include<stack>
    using namespace std;
    
    // Lexer
    map<string,int> keyword_to_token = {{"break",BREAK},{"continue",CONTINUE},{"return",RETURN},{"global",GLOBAL},{"nonlocal",NONLOCAL},{"assert",ASSERT},{"is",IS},{"not",NOT},{"and",AND},{"or",OR},{"in",IN},{"class",CLASS},{"def",DEF},{"if",IF},{"elif",ELIF},{"else",ELSE},{"while",WHILE},{"for",FOR},{"None",NONE},{"True",TRUE},{"False",FALSE}};
    map<string,int> non_single_operator_to_token = {{"->", ARROW}, {"+=", PLUS_EQ}, {"-=", MINUS_EQ}, {"*=", MUL_EQ}, {"/=", DIV_EQ}, {"%=", PERCENT_EQ}, {"&=", AND_EQ}, {"|=", OR_EQ}, {"^=", XOR_EQ}, {"<<", LEFTSHIFT}, {"<<=", LEFTSHIFT_EQ}, {">>", RIGHTSHIFT}, {">>=", RIGHTSHIFT_EQ}, {"**", DOUBLE_STAR}, {"**=", POW_EQ}, {"//", FLOORDIV}, {"//=", FLOORDIV_EQ}, {"==", EQ_EQ}, {"!=", NEQ}, {"<=", LE_EQ}, {">=", GT_EQ}};

    // INDENT-DEDENT
    stack<int> indent_stack;
    int curr_indent = 0;    

    // String
    void puthex();
    void putoct();
    char quote_type = 0;
    bool multiline = false;
    string string_sem_val;

    // Compound Statements
    bool return_newline = 1;
    int num_open_brackets = 0;

    // AST
    void ast_functions(int token);

    // Basic IO
    char * INPUT_FILE;
    char * OUTPUT_FILE;
    int VERBOSE;
}

    /* Keywords */
keywords "break"|"continue"|"return"|"global"|"nonlocal"|"assert"|"is"|"not"|"and"|"or"|"in"|"class"|"def"|"if"|"elif"|"else"|"while"|"for"|"None"|"True"|"False"
single_operators ":"|","|";"|"="|"<"|">"|"*"|"|"|"^"|"&"|"+"|"-"|"/"|"%"|"~"|"."
non_single_operators "->"|"+="|"-="|"*="|"/="|"@="|"%="|"&="|"|="|"^="|"<<"|"<<="|">>"|">>="|"**"|"**="|"//"|"//="|"=="|"!="|"<="|">="|"..."|"<>"
open_brac   "("|"["|"{"
close_brac  ")"|"]"|"}"

    /* Name */
name [a-zA-Z_][a-zA-Z0-9_]*

    /* String and Byte Literals */
stringprefix ["]|[']|["]["]["]|[']['][']
r_stringprefix [rR](["]|[']|["]["]["]|['][']['])
comment [#](.)*\n

    /* 2.4.4 Numerical Literals */

numerical_literal {integer}|{floatnumber}|{imagnumber}

    /* 2.4.5 Integer Literals */

integer         {decinteger}|{bininteger}|{octinteger}|{hexinteger}
decinteger      {nonzerodigit}(["_"]?{digit})*|"0"+(["_"]?"0")*
bininteger      "0"[bB](["_"]?{bindigit})+
octinteger      "0"[oO](["_"]?{octdigit})+
hexinteger      "0"[xX](["_"]?{hexdigit})+
nonzerodigit    [1-9]
digit           [0-9]
bindigit        [0-1]
octdigit        [0-7]
hexdigit        {digit}|[a-f]|[A-F]

    /* 2.4.6 Floating Point Literals */
    
floatnumber     {pointfloat}|{exponentfloat}
pointfloat      {digitpart}?{fraction}|{digitpart}"."
exponentfloat   ({digitpart}|{pointfloat}){exponent}
digitpart       {digit}([_]?{digit})*
fraction        "."{digitpart}
exponent        ("e"|"E")("+"|"-")?{digitpart}


imagnumber      ({floatnumber}|{digitpart})("j"|"J")

    /* Whitespace */

whitespace " "|"\t"|"\f"|"\r"



%x non_initial_state
%x string_state
%x rstring_state
%x multiline_string_state
%x multiline_rstring_state

%option yylineno 

%%

" " {
    curr_indent++;
}

\n|{comment}    {
    curr_indent = 0;
}

\t  {
    myerror("Tab characters are currently not allowed for indentation in input file");
}

\r  {
    ;
}

. {
    if (curr_indent > indent_stack.top()){
        indent_stack.push(curr_indent);
        yyless(0);
        BEGIN(non_initial_state);
        yylval.node_ptr=NULL;
        return INDENT;
    }
    else if (curr_indent<indent_stack.top()) {
        yyless(0);
        indent_stack.pop();
        if (curr_indent>indent_stack.top()) {
            myerror("Inconsistent Indent");
        }
        yylval.node_ptr=NULL;
        return DEDENT;
    }
    else
    {
        yyless(0);
        BEGIN(non_initial_state);
    }
}

<non_initial_state>{

    /* String */
{stringprefix}  {
    yymore();
    string_sem_val = "";
    quote_type = yytext[0];
    if (yyleng == 3) {
        BEGIN(multiline_string_state);
        multiline = true;
    }
    else {
        multiline = false;
        BEGIN(string_state);
    }
}
{r_stringprefix}    {
    yymore();
    string_sem_val = "";
    quote_type = yytext[1];
    if (yyleng == 4) 
    {
        multiline = true;
        BEGIN(multiline_rstring_state);
    }
    else 
    {
        multiline = false;
        BEGIN(rstring_state);
    }
}
    /* Keywords */
{keywords}  {
    int token =  keyword_to_token[yytext];
    ast_functions(token);
    return token;
}
{comment}   {
        if (num_open_brackets==0){
            yylval.node_ptr = NULL;
            BEGIN(INITIAL);
            curr_indent = 0;
            return NEWLINE;
    }
}
    /* Non Single Operators */
{non_single_operators} {
    int token = non_single_operator_to_token[yytext];
    ast_functions(token);
    return token;
}

    /* Single Operators */
{single_operators} {
    int token = yytext[0];
    ast_functions(token);
    return token;
}

    /* Name */
{name}  {
    ast_functions(NAME);
    return NAME;
}

    /* Number */
{numerical_literal} {
    ast_functions(NUMBER);
    return  NUMBER;
}

    /* Backslashed Newline */
\\\n {
    ;
}

{open_brac} {
    num_open_brackets++;
    int token = yytext[0];
    ast_functions(token);
    return token;
}

{close_brac} {
    num_open_brackets--;
    int token = yytext[0];
    ast_functions(token);
    return token;
}

\n {
    if (num_open_brackets==0){
        yylval.node_ptr=NULL;
        BEGIN(INITIAL);
        curr_indent = 0;
        return NEWLINE;
    }
}

{whitespace} {
    ;
}

. {
    char buf[50];
    sprintf(buf , "Invalid character %c (char code %d)",yytext[0],(int)yytext[0]);
    myerror(buf);
}

    /* EOF */
<<EOF>> {
    if (indent_stack.top()!=0)
    {
        indent_stack.pop();
        yylval.node_ptr = NULL;
        return DEDENT;
    }
    else
    {
        yylval.node_ptr = NULL;
        return YYEOF;
    }
}
}

<string_state>{
["]     {if(quote_type==39){string_sem_val.push_back(yytext[yyleng-1]); yymore();} else{ BEGIN(non_initial_state); ast_functions(STRING); return STRING;}}
[']     {if(quote_type==34){string_sem_val.push_back(yytext[yyleng-1]); yymore();} else{ BEGIN(non_initial_state); ast_functions(STRING); return STRING;}}
\\\n    {yymore();}
\\\\    {string_sem_val.push_back('\\'); yymore();}
\\'     {string_sem_val.push_back('\'') ; yymore();}
\\["]   {string_sem_val.push_back('\"') ; yymore();}
\\a     {string_sem_val.push_back('\a') ; yymore();}
\\b     {string_sem_val.push_back('\b') ; yymore();}
\\f     {string_sem_val.push_back('\f') ; yymore();}
\\n     {string_sem_val.push_back('\n') ; yymore();}
\\r     {string_sem_val.push_back('\r') ; yymore();}
\\t     {string_sem_val.push_back('\t') ; yymore();}
\\v     {string_sem_val.push_back('\v') ; yymore();}
\\[0-9]{1,3}        {putoct(); yymore();}
\\x[0-9a-fA-F]{2,2}  {puthex(); yymore();}
\n      {myerror("unterminated string literal");}
.       {string_sem_val.push_back(yytext[yyleng-1]) ; yymore();}
<<EOF>> {myerror("unterminated string literal");}
}

<multiline_string_state>{
["]["]["]   {if(quote_type==39){string_sem_val.append("\"\"\""); yymore();} else{ BEGIN(non_initial_state); ast_functions(STRING); return STRING;}}
[']['][']   {if(quote_type==34){string_sem_val.append("''''"); yymore();} else{ BEGIN(non_initial_state); ast_functions(STRING); return STRING;}}
\\\n    {yymore();}
\\\\    {string_sem_val.push_back('\\'); yymore();}
\\'     {string_sem_val.push_back('\'') ; yymore();}
\\["]   {string_sem_val.push_back('\"') ; yymore();}
\\a     {string_sem_val.push_back('\a') ; yymore();}
\\b     {string_sem_val.push_back('\b') ; yymore();}
\\f     {string_sem_val.push_back('\f') ; yymore();}
\\n     {string_sem_val.push_back('\n') ; yymore();}
\\r     {string_sem_val.push_back('\r') ; yymore();}
\\t     {string_sem_val.push_back('\t') ; yymore();}
\\v     {string_sem_val.push_back('\v') ; yymore();}
\\[0-9]{1,3}        {putoct(); yymore();}
\\x[0-9a-fA-F]{2,2}  {puthex(); yymore();}
\n      {string_sem_val.push_back('\n'); yymore();}
.       {string_sem_val.push_back(yytext[yyleng-1]) ;yymore();}
<<EOF>> {myerror("unterminated string literal");}
}

<rstring_state>{
["]     {if(quote_type==39){string_sem_val.push_back('\"'); yymore();} else{ BEGIN(non_initial_state); ast_functions(STRING); return STRING;}}
[']     {if(quote_type==34){string_sem_val.push_back('\''); yymore();} else{ BEGIN(non_initial_state); ast_functions(STRING); return STRING;}}
\\\\    {string_sem_val.append("\\\\"); yymore();}
\\\"    {string_sem_val.append("\\\""); yymore();}
\\\'    {string_sem_val.append("\\\'"); yymore();}
\n      {myerror("unterminated string literal");}
\\\n    {string_sem_val.append("\\\n"); yymore();}
.       {string_sem_val.push_back(yytext[yyleng-1]); yymore();}
<<EOF>> {myerror("unterminated string literal");}
}

<multiline_rstring_state>{
["]["]["]   {if(quote_type==39){string_sem_val.append("\"\"\""); yymore();} else{ BEGIN(non_initial_state); ast_functions(STRING); return STRING;}}
[']['][']   {if(quote_type==34){string_sem_val.append("''''"); yymore();} else{ BEGIN(non_initial_state); ast_functions(STRING); return STRING;}}    
\\\\    {string_sem_val.append("\\\\"); yymore();}
\\\"    {string_sem_val.append("\\\""); yymore();}
\\\'    {string_sem_val.append("\\\'"); yymore();}
\n      {string_sem_val.append("\n"); yymore();}
\\\n    {string_sem_val.append("\\\n"); yymore();}
.       {string_sem_val.push_back(yytext[yyleng-1]); yymore();}
<<EOF>> {myerror("unterminated string literal");}
}

    /* EOF */
<<EOF>> {
    if (indent_stack.top()!=0)
    {
        indent_stack.pop();
        yylval.node_ptr = NULL;
        return DEDENT;
    }
    else
    {
        yylval.node_ptr = NULL;
        return YYEOF;
    }
}

%%

void ast_functions(int token)
{
    if (VERBOSE)
    {
        cout<<"Making Node of ##  "<<yytext<<"  ##"<<endl;
    }
    yylval.node_ptr = make_new_node(yytext);
    yylval.node_ptr->set_terminal();
    yylval.node_ptr->set_token(token);
}

int myerror (const char* s){
    printf("Line %d: %s\n",yylineno, s );
    exit(0);
}

void putoct(){
    int val = 0 , i;
    for(i=yyleng-1 ; yytext[i]!='\\' ; i--) val+= yytext[i]-'0';
    if (val >= 256) myerror("Unicode not supported");
    string_sem_val.push_back(val);
}

void puthex(){
    int val = 0 , i;
    for(i=yyleng-1 ; yytext[i]!='\\' ; i--) {
        if ('0'<=yytext[i] && yytext[i]<='9') val+= yytext[i]-'0';
        else if ('a'<=yytext[i] && yytext[i]<='f') val+= yytext[i]-'a'+10;
        else if ('A'<=yytext[i] && yytext[i]<='F') val+= yytext[i]-'A'+10;
    }
    string_sem_val.push_back(val);
}

int main( int argc, char **argv ) {

    /* Global Variables */
    VERBOSE = argv[1][0] - '0';
    INPUT_FILE = argv[2];
    OUTPUT_FILE = argv[3];
    
    indent_stack.push(0);
    yyin = fopen(INPUT_FILE, "r" );
    if (yyin == NULL)
    {
        cout<<"Unable to open input file"<<endl;
        exit(1);
    }
    yyparse();
}