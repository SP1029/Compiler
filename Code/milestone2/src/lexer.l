%top{
    #include "parser.tab.h"
    #include "lexer.h"
}

%top{
    #include "depend.h"

    extern int for_iter_count;
        // Lexer Constants
    map<string,int> keyword_to_token = {{"break",BREAK},{"continue",CONTINUE},{"return",RETURN},{"global",GLOBAL},{"nonlocal",NONLOCAL},{"assert",ASSERT},{"is",IS},{"not",NOT},{"and",AND},{"or",OR},{"in",IN},{"class",CLASS},{"def",DEF},{"if",IF},{"elif",ELIF},{"else",ELSE},{"while",WHILE},{"for",FOR},{"None",NONE},{"True",TRUE},{"False",FALSE},{"self",SELF},{"int",INT},{"float",FLOAT},{"bool",BOOL},{"str",STR},{"range",RANGE},{"len",LEN},{"print",PRINT}};
    map<string,int> non_single_operator_to_token = {{"->", ARROW}, {"+=", PLUS_EQ}, {"-=", MINUS_EQ}, {"*=", MUL_EQ}, {"/=", DIV_EQ}, {"%=", PERCENT_EQ}, {"&=", AND_EQ}, {"|=", OR_EQ}, {"^=", XOR_EQ}, {"<<", LEFTSHIFT}, {"<<=", LEFTSHIFT_EQ}, {">>", RIGHTSHIFT}, {">>=", RIGHTSHIFT_EQ}, {"**", DOUBLE_STAR}, {"**=", POW_EQ}, {"//", FLOORDIV}, {"//=", FLOORDIV_EQ}, {"==", EQ_EQ}, {"!=", NEQ}, {"<=", LE_EQ}, {">=", GT_EQ}};
    // Basic IO
    char * INPUT_FILE;
    string OUTPUT_PFX;
    int VERBOSE;
    // String
    string string_sem_val;
    char quote_type;
    bool multiline;
    // Indent-Dedent
    int curr_indent;
    stack<int> indent_stack;
    int line_pad_count;
    // Compound Statements
    bool return_newline;
    int num_open_brackets;

    // PARSE NO
    int PARSE_NO;

        // Lexer Functions
    // String
    void puthex();
    void putoct();
    // Terminal Functions
    void terminal_functions(int token);
}

    /* Keywords */
keywords "break"|"continue"|"return"|"global"|"nonlocal"|"assert"|"is"|"not"|"and"|"or"|"in"|"class"|"def"|"if"|"elif"|"else"|"while"|"for"|"None"|"True"|"False"|"self"|"int"|"float"|"bool"|"str"|"range"|"len"|"print"
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
    myerror("Tab characters are currently not allowed for indentation in input file", yylineno);
}

\r  {
    ;
}

. {
    if (curr_indent > indent_stack.top()){
        indent_stack.push(curr_indent);
        yyless(0);
        BEGIN(non_initial_state);
        terminal_functions(INDENT);
        return INDENT;
    }
    else if (curr_indent<indent_stack.top()) {
        yyless(0);
        indent_stack.pop();
        if (curr_indent>indent_stack.top()) {
            myerror("Inconsistent Indent", yylineno);
        }
        terminal_functions(DEDENT);
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
    terminal_functions(token);
    return token;
}
{comment}   {
        if (num_open_brackets==0){
            BEGIN(INITIAL);
            curr_indent = 0;
            terminal_functions(NEWLINE);
            return NEWLINE;
    }
}
    /* Non Single Operators */
{non_single_operators} {
    int token = non_single_operator_to_token[yytext];
    terminal_functions(token);
    if (PARSE_NO == 1) current_symbol_table->operators.push_back({yytext , yylineno});
    return token;
}

    /* Single Operators */
{single_operators} {
    int token = yytext[0];
    if (token == ';') line_pad_count++;
    terminal_functions(token);
    if (PARSE_NO == 1) current_symbol_table->operators.push_back({yytext , yylineno});
    return token;
}

    /* Name */
{name}  {
    terminal_functions(NAME);
    return NAME;
}

    /* Number */
{integer}   {
    yylval_ptr->data_type = {false, "int"};
    terminal_functions(NUMBER);
    if (PARSE_NO == 1) current_symbol_table->constants.push_back({yytext , yylineno});
    return NUMBER;
}

{floatnumber}   {
    yylval_ptr->data_type = {false, "float"};
    terminal_functions(NUMBER);
    if (PARSE_NO == 1) current_symbol_table->constants.push_back({yytext , yylineno});
    return NUMBER;
}

    /* Backslashed Newline */
\\\n {
    line_pad_count--;
}

{open_brac} {
    num_open_brackets++;
    int token = yytext[0];
    terminal_functions(token);
    return token;
}

{close_brac} {
    num_open_brackets--;
    int token = yytext[0];
    terminal_functions(token);
    return token;
}

\n {
    if (num_open_brackets==0){
        BEGIN(INITIAL);
        curr_indent = 0;
        terminal_functions(NEWLINE);
        return NEWLINE;
    }
    else{
        line_pad_count--;
    }
}

{whitespace} {
    ;
}

. {
    char buf[50];
    sprintf(buf , "Invalid character %c (char code %d)",yytext[0],(int)yytext[0]);
    myerror(buf, yylineno);
}

    /* EOF */
<<EOF>> {
    if (indent_stack.top()!=0)
    {
        indent_stack.pop();
        terminal_functions(DEDENT);
        return DEDENT;
    }
    else
    {
        return YYEOF;
    }
}
}

<string_state>{
["]     {if(quote_type==39){string_sem_val.push_back(yytext[yyleng-1]); yymore();} else{ BEGIN(non_initial_state); terminal_functions(STRING); yylval_ptr->string_semantic_val=string_sem_val; return STRING;}}
[']     {if(quote_type==34){string_sem_val.push_back(yytext[yyleng-1]); yymore();} else{ BEGIN(non_initial_state); terminal_functions(STRING); yylval_ptr->string_semantic_val=string_sem_val; return STRING;}}
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
\n      {myerror("unterminated string literal", yylineno);}
.       {string_sem_val.push_back(yytext[yyleng-1]) ; yymore();}
<<EOF>> {myerror("unterminated string literal", yylineno);}
}

<multiline_string_state>{
["]["]["]   {if(quote_type==39){string_sem_val.append("\"\"\""); yymore();} else{ BEGIN(non_initial_state); terminal_functions(STRING); yylval_ptr->string_semantic_val=string_sem_val; return STRING;}}
[']['][']   {if(quote_type==34){string_sem_val.append("''''"); yymore();} else{ BEGIN(non_initial_state); terminal_functions(STRING); yylval_ptr->string_semantic_val=string_sem_val; return STRING;}}
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
<<EOF>> {myerror("unterminated string literal", yylineno);}
}

<rstring_state>{
["]     {if(quote_type==39){string_sem_val.push_back('\"'); yymore();} else{ BEGIN(non_initial_state); terminal_functions(STRING); yylval_ptr->string_semantic_val=string_sem_val; return STRING;}}
[']     {if(quote_type==34){string_sem_val.push_back('\''); yymore();} else{ BEGIN(non_initial_state); terminal_functions(STRING); yylval_ptr->string_semantic_val=string_sem_val; return STRING;}}
\\\\    {string_sem_val.append("\\\\"); yymore();}
\\\"    {string_sem_val.append("\\\""); yymore();}
\\\'    {string_sem_val.append("\\\'"); yymore();}
\n      {myerror("unterminated string literal", yylineno);}
\\\n    {string_sem_val.append("\\\n"); yymore();}
.       {string_sem_val.push_back(yytext[yyleng-1]); yymore();}
<<EOF>> {myerror("unterminated string literal", yylineno);}
}

<multiline_rstring_state>{
["]["]["]   {if(quote_type==39){string_sem_val.append("\"\"\""); yymore();} else{ BEGIN(non_initial_state); terminal_functions(STRING); yylval_ptr->string_semantic_val=string_sem_val; return STRING;}}
[']['][']   {if(quote_type==34){string_sem_val.append("''''"); yymore();} else{ BEGIN(non_initial_state); terminal_functions(STRING); yylval_ptr->string_semantic_val=string_sem_val; return STRING;}}    
\\\\    {string_sem_val.append("\\\\"); yymore();}
\\\"    {string_sem_val.append("\\\""); yymore();}
\\\'    {string_sem_val.append("\\\'"); yymore();}
\n      {string_sem_val.append("\n"); yymore();}
\\\n    {string_sem_val.append("\\\n"); yymore();}
.       {string_sem_val.push_back(yytext[yyleng-1]); yymore();}
<<EOF>> {myerror("unterminated string literal", yylineno);}
}

    /* EOF */
<<EOF>> {
    if (indent_stack.top()!=0)
    {
        indent_stack.pop();
        terminal_functions(DEDENT);
        return DEDENT;
    }
    else
    {
        return YYEOF;
    }
}

%%

void terminal_functions(int token)
{
    if (VERBOSE)
    {
        cout<<"Making Node of ##  "<<yytext<<"  ##"<<yylineno<<endl;
    }
    yylval_ptr->lexeme = yytext;
    yylval_ptr->lexemes.clear();
    yylval_ptr->lexemes.push_back(yytext);
    yylval_ptr->virtual_line_no = yylineno + line_pad_count;
    yylval_ptr->line_no = yylineno;
}

void putoct(){
    int val = 0 , i;
    for(i=yyleng-1 ; yytext[i]!='\\' ; i--) val+= yytext[i]-'0';
    if (val >= 256) myerror("Unicode not supported", yylineno);
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

void init_functions()
{
    /* Global Symbol Table Details */
    global_symbol_table->name = "Global";
    global_symbol_table->type = GLOBAL_SYMBOL_TABLE;

    /* Dunder __name__ */
    global_symbol_table->add_entry("__name__", -1, {false, "str"} , false , -1 );

    /* Indent-Dedent */
    indent_stack.push(0);

    alloc_mem_arg->type=IMMEDIATE_POINTER ;
    alloc_mem_arg->text="allocmem";
    alloc_mem_arg->stackptr_change_amount = 4;

    print_arg->type=IMMEDIATE_POINTER ;
    print_arg->text="print";
    print_arg->stackptr_change_amount = 8;

}

void reset_parse(int parse_no)
{
        /* RESETING THE LEXER */
    /* Resetting Input File */
    yyin = fopen(INPUT_FILE, "r" );
    if (yyin == NULL)
    {
        cout<<"Unable to open input file"<<endl;
        exit(1);
    }

    PARSE_NO = parse_no;

    /* Virtual Line Number */
    Primitive_Attribute->virtual_line_no = -1;
    yylineno = 1;
    // line padding count
    line_pad_count = 0;
    // INDENT-DEDENT
    curr_indent = 0; 
    /* String */
    quote_type = 0;
    multiline = false;
    // Compound Statements
    return_newline = 1;
    num_open_brackets = 0;

    /* Data Type Node */
    node_count = 0;

    /* yylval */
    switch(parse_no)
    {
        case 1:
        {
            yylval_ptr = &yy1lval;
            yylloc_ptr = &yy1lloc;
            break;
        }
        case 2:
        {
            yylval_ptr = &yy2lval;
            yylloc_ptr = &yy2lloc;
            break;
        }
        case 3:
        {
            yylval_ptr = &yy3lval;
            yylloc_ptr = &yy3lloc;
            current_symbol_table = global_symbol_table;
            for_iter_count = 0;
            break;
        }
    }
}

void testing()
{
    /* cout<<"### Global Symbol Table ###"<<endl;
    global_symbol_table->write_to_file();
    cout<<endl; */
    /* cout<<"### Function Symbol Table ###"<<endl;
    for (auto f : Function_Sym_Tbl_list)
    {
        f->write_to_file();
    }
    cout<<endl; */
    // cout<<"### Class Symbol Table ###"<<endl;
    // for (auto f : Class_Sym_Tbl_map)
    // {
    //     if (f.second!=NULL)
    //     f.second->write_to_file();
    // }
    // cout<<endl; 
}

void print_3ac(vector<IR_instruction*> &vec_3ac , ofstream & fout){
    for (auto &it: vec_3ac){
        switch (it->op_type) {
            case RES_ARG1_OP_ARG2:
                fout <<'\t'<< it->res->text << "\t=\t" << it->arg1->text << "\t" << it->op << "\t" << it->arg2->text << '\n';
                break;
            case RES_OP_ARG1:
                fout <<'\t'<< it->res->text << "\t=\t" << it->op << "\t" << it->arg1->text << '\n';
                break;
            case MOV:
                fout <<'\t'<< it->res->text<< "\t=\t" << it->arg1->text << '\n';
                break;
            case MOV_TO_REFERENCE:
                fout <<"\t("<< it->res->text<< ")\t=\t" << it->arg1->text << '\n';
                break;
            case MOV_FROM_REFERENCE:
                fout <<"\t"<< it->res->text<< "\t=\t(" << it->arg1->text << ")\n";
                break;
            case ifFalse_Goto:
                fout <<'\t'<< "ifFalse\t" << it->arg1->text << "\tGoto\t" << it->arg2->text << '\n';
                break;
            case Goto:
                fout <<'\t'<< "Goto\t" <<  it->arg2->text << '\n';
                break;
            case LABEL:
                fout <<"L"<< it->op ; 
                break;
            case COMMAND_ARG1:
                fout <<'\t'<< it->op << "\t" << it->arg1->text << '\n';
                break;
            case COMMAND:
                fout <<'\t'<< it->op << '\n';
                break;
            case COMMAND_RES:
                fout <<'\t'<< it->res->text << "\t=\t" << it->op << '\n';
                break;
            case COMMAND_ARG1_ARG2:
                fout <<'\t'<< it->op << "\t" << it->arg1->text <<"\t"<< it->arg2->text <<'\n';
                break;
            case CONVERT_ARG:
                fout <<'\t'<< it->res->text << "\t=\t" << it->op <<"\t"<< it->arg1->text <<'\n';
                break;
            default:
                // Handle any other cases if needed
                break;
        }
    }
}

void dump_3ac(){
    ofstream fout(OUTPUT_PFX + ".txt");
    fout<<".data:\n";
    for (auto &it:global_symbol_table->string_args){
        fout<<"\t"<<it->text<<"\n";
    }
    fout<<'\n';

    fout<<".globl main:\n";
    fout<<"\t__name__\t=\t\"__main__\" \n";
    print_3ac (global_symbol_table->final_3ac , fout);
    fout<<"\n\n";

    for (auto &it: Function_Sym_Tbl_list){
        fout<<it->print_name<<":\n\tbeginfunc\n";
        print_3ac (it->final_3ac , fout);
        fout<<"\tendfunc\n\n";
    }
    fout.close();
}

void dump_symbol_tables(){
    ofstream fout(OUTPUT_PFX + ".csv");
    fout<<"######, ######, ######, ######, ######\n";
    global_symbol_table->write_to_file(fout);
    fout<<"\n\n";
    for (auto &it : Function_Sym_Tbl_list){
        fout<<"######, ######, ######, ######, ######\n";
        it->write_to_file(fout);
    }
    fout<<"######, ######, ######, ######, ######\n";
    fout.close();
}   

int main( int argc, char **argv ) {

    /* Global Variables */
    VERBOSE = argv[1][0] - '0';
    INPUT_FILE = argv[2];
    OUTPUT_PFX = argv[3];
    
    /* Parsing */

    /* Begin */
    init_functions();

    /* Parse 1 */
    reset_parse(1);
    yy1parse();
    if (VERBOSE)
        cout<<"Parse 1 Completed"<<endl;

    /* Parse 2 */
    reset_parse(2);
    yy2parse();
    if (VERBOSE)
        cout<<"Parse 2 Completed"<<endl;

    /* Parse 3 */
    reset_parse(3);
    yy3parse();
    if (VERBOSE)
        cout<<"Parse 3 Completed"<<endl;

    /* Final Output Functions */
    dump_3ac();
    dump_symbol_tables(); 
    if (VERBOSE)
        cout<<"Output Files Created"<<endl;
}