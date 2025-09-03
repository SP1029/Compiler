%{
    extern "C" int yylex();
    extern int yylineno;
    void yyerror (char const * s){
        printf("Line %d: %s\n",yylineno,s);
    }
%}

%code requires{
    #include "depend.h"
}

%code top{
    #include "depend.h"

    // AST
    vector<Node *> ast_nodes;
    vector<pair<int,int>> ast_edges;
    int Node::node_count = 0;

    // Basic IO
    extern char * OUTPUT_FILE;
}

%define api.value.type {Semantic_Data}
%define parse.error detailed
  
/* Official */
 
%token NAME
%token INDENT
%token STRING
%token DEDENT
%token NUMBER
%token NEWLINE
 
/* Keywods */
%token BREAK     
%token CONTINUE     
%token RETURN       
%token GLOBAL
%token NONLOCAL
%token ASSERT
%token IS
%token NOT
%token AND
%token OR
%token IN
%token CLASS
%token DEF
%token IF
%token ELIF
%token ELSE
%token WHILE
%token FOR
%token NONE
%token TRUE
%token FALSE
 
/* Operator with more than 1 symbol */
%token ARROW            /* -> */
%token PLUS_EQ          /* += */
%token MINUS_EQ         /* -= */
%token MUL_EQ           /* *= */
%token DIV_EQ           /* /= */
%token PERCENT_EQ       /* %= */
%token AND_EQ           /* &= */     
%token OR_EQ            /* |= */
%token XOR_EQ           /* ^= */
%token LEFTSHIFT        /* << */
%token LEFTSHIFT_EQ     /* <<= */
%token RIGHTSHIFT       /* >> */ 
%token RIGHTSHIFT_EQ    /* >>= */ 
%token DOUBLE_STAR      /* ** */
%token POW_EQ           /* **= */ 
%token FLOORDIV         /* // */
%token FLOORDIV_EQ      /* //= */
%token EQ_EQ            /* == */
%token NEQ              /* != */
%token LE_EQ            /* <= */
%token GT_EQ            /* >= */
 
%%

file_input:
    Statements
    {
        $<node_ptr>$=make_new_node("Input"); 
        add_edge($<node_ptr>$,$<node_ptr>1);
        make_ast();
    }

Statements:
    Statements NEWLINE
    {
        if ($<node_ptr>1==NULL)
        {
            $<node_ptr>$=NULL;
        }
        else
        {
            $<node_ptr>$=$<node_ptr>1;
        }        
    }
|   Statements stmt
    {
        if ($<node_ptr>1==NULL)
        {
            $<node_ptr>$=$<node_ptr>2;
        }
        else
        {
            $<node_ptr>$=make_new_node("Statements"); 
            add_edge($<node_ptr>$,{$<node_ptr>1, $<node_ptr>2});
        }   
    }
|   %empty
    {
        $<node_ptr>$=NULL;
    }

Base_Class_List:
    %empty
    {
        $<node_ptr>$=NULL;
    }
|   '(' opt_arglist ')'
    {
        $<node_ptr>$=make_new_node("Base_Class_List"); 
        add_edge($<node_ptr>$,{$<node_ptr>1, $<node_ptr>2, $<node_ptr>3});
    }

opt_arglist:
    %empty
    {
        $<node_ptr>$=NULL;
    }
|   Argument_List
    {
        $<node_ptr>$=$<node_ptr>1;
    }

Function_Defination: 
    DEF NAME Parameters ARROW Test ':' Block
    {
        $<node_ptr>$=make_new_node("Function_Defination"); 
        add_edge($<node_ptr>$,{$<node_ptr>1, $<node_ptr>2, $<node_ptr>3, $<node_ptr>4, $<node_ptr>5, $<node_ptr>6, $<node_ptr>7});
    }
|   DEF NAME Parameters ':' Block
    {
        $<node_ptr>$=make_new_node("Function_Defination"); 
        add_edge($<node_ptr>$,{$<node_ptr>1, $<node_ptr>2, $<node_ptr>3, $<node_ptr>4, $<node_ptr>5});
    }

Parameters: 
    '(' ')'
    {
        $<node_ptr>$=make_new_node("Parameters"); 
        add_edge($<node_ptr>$,{$<node_ptr>1, $<node_ptr>2});
    }
|   '(' Defination_Parameter_List ')'
    {
        $<node_ptr>$=make_new_node("Parameters"); 
        add_edge($<node_ptr>$,{$<node_ptr>1, $<node_ptr>2, $<node_ptr>3});
    }

Defination_Parameter_List: 
    Parameter
    {
        $<node_ptr>$=$<node_ptr>1;
    }
|   Defination_Parameter_List ',' Parameter
    {
        $<node_ptr>$=make_new_node("Defination_Parameter_List"); 
        add_edge($<node_ptr>$,{$<node_ptr>1, $<node_ptr>2, $<node_ptr>3});
    }

Parameter:
    NAME
    {
        $<node_ptr>$=$<node_ptr>1;
    }
|   NAME ':' Test   
    {
        $<node_ptr>$=$<node_ptr>2; 
        add_edge($<node_ptr>$,{$<node_ptr>1, $<node_ptr>3});
    }
|   NAME '=' Test
    {
        $<node_ptr>$=$<node_ptr>2; 
        add_edge($<node_ptr>$,{$<node_ptr>1, $<node_ptr>3});
    }
|   NAME ':' Test '=' Test
    {
        $<node_ptr>$=$<node_ptr>4; 
        add_edge($<node_ptr>$,{$<node_ptr>2, $<node_ptr>5});
        add_edge($<node_ptr>2,{$<node_ptr>1, $<node_ptr>3});
    }

opt_comma:
    %empty
    {
        $<node_ptr>$=NULL;
    }
|   ','
    {
        $<node_ptr>$=$<node_ptr>1;
    }

opt_semi_colon:
    %empty
    {
        $<node_ptr>$=NULL;
    }
|   ';'
    {
        $<node_ptr>$=$<node_ptr>1;
    }

stmt: 
    One_Line_Statement 
    {
        $<node_ptr>$=$<node_ptr>1;
    }
|   compound_stmt
    {
        $<node_ptr>$=$<node_ptr>1;
    }

One_Line_Statement: 
    Partial_Line_Statements opt_semi_colon NEWLINE
    {
        if ($<node_ptr>2==NULL)
        {
            $<node_ptr>$ = $<node_ptr>1;
        }
        else
        {
            $<node_ptr>$=make_new_node("One_Line_Statement"); 
            add_edge($<node_ptr>$,{$<node_ptr>1, $<node_ptr>2});
        }
    }

Partial_Line_Statements:
    Partial_Line_Statement
    {
        $<node_ptr>$=$<node_ptr>1;
    }
|   Partial_Line_Statements ';' Partial_Line_Statement
    {
        $<node_ptr>$=make_new_node("Partial_Line_Statements"); add_edge($<node_ptr>$,{$<node_ptr>1, $<node_ptr>2, $<node_ptr>3});
    }

Partial_Line_Statement: 
    Expression 
    {
        $<node_ptr>$=$<node_ptr>1;
    }
|   flow_stmt 
    {
        $<node_ptr>$=$<node_ptr>1;
    }
|   Global_Statement 
    {
        $<node_ptr>$=$<node_ptr>1;
    }
|   Nonlocal_Statement 
    {
        $<node_ptr>$=$<node_ptr>1;
    }
|   Assert_Statement
    {
        $<node_ptr>$=$<node_ptr>1;
    }

Expression: 
    Test_List ':' Test 
    {
        $<node_ptr>$ = $<node_ptr>2;
        add_edge($<node_ptr>$,{$<node_ptr>1, $<node_ptr>3});
    }
|   Test_List ':' Test '=' Test
    {
        $<node_ptr>$ = $<node_ptr>4;
        add_edge($<node_ptr>$,{$<node_ptr>2, $<node_ptr>5});
        add_edge($<node_ptr>2,{$<node_ptr>1, $<node_ptr>3});
    }
|   Test_List augassign Test_List
    {
        $<node_ptr>$=$<node_ptr>2;
        add_edge($<node_ptr>$,{$<node_ptr>1, $<node_ptr>3});
    }
|   Test_List 
    {
        $<node_ptr>$ = $<node_ptr>1;
    }
|   Test_List '=' eq_Test_List
    {
        $<node_ptr>$ = $<node_ptr>2;
        add_edge($<node_ptr>$, {$<node_ptr>1, $<node_ptr>3});
    }

eq_Test_List:
    Test_List
    {
        $<node_ptr>$=$<node_ptr>1;
    }
|   Test_List '=' eq_Test_List
    {
        $<node_ptr>$ = $<node_ptr>2;
        add_edge($<node_ptr>$, {$<node_ptr>1, $<node_ptr>3});
    }

Optional_Test:
    %empty
    {
        $<node_ptr>$=NULL;
    }
|   ',' Test
    {
        $<node_ptr>$=make_new_node("Optional_Test"); 
        add_edge($<node_ptr>$,{$<node_ptr>1, $<node_ptr>2});
    }

augassign: 
    PLUS_EQ
    {
        $<node_ptr>$=$<node_ptr>1;
    }
|   MINUS_EQ
    {
        $<node_ptr>$=$<node_ptr>1;
    } 
|   MUL_EQ
    {
        $<node_ptr>$=$<node_ptr>1;
    }
|   DIV_EQ
    {
        $<node_ptr>$=$<node_ptr>1;
    }
|   PERCENT_EQ
    {
        $<node_ptr>$=$<node_ptr>1;
    } 
|   AND_EQ
    {
        $<node_ptr>$=$<node_ptr>1;
    }
|   OR_EQ
    {
        $<node_ptr>$=$<node_ptr>1;
    }
|   XOR_EQ
    {
        $<node_ptr>$=$<node_ptr>1;
    }
|   LEFTSHIFT_EQ
    {
        $<node_ptr>$=$<node_ptr>1;
    }
|   RIGHTSHIFT_EQ
    {
        $<node_ptr>$=$<node_ptr>1;
    }
|   POW_EQ
    {
        $<node_ptr>$=$<node_ptr>1;
    }
|   FLOORDIV_EQ
    {
        $<node_ptr>$=$<node_ptr>1;
    }

flow_stmt: 
    break_stmt 
    {
        $<node_ptr>$=$<node_ptr>1;
    }
|   continue_stmt 
    {
        $<node_ptr>$=$<node_ptr>1;
    }
|   Return_Statement 
    {
        $<node_ptr>$=$<node_ptr>1;
    }
break_stmt: 
    BREAK
    {
        $<node_ptr>$=$<node_ptr>1;
    }
continue_stmt: 
    CONTINUE
    {
        $<node_ptr>$=$<node_ptr>1;
    }
Return_Statement: 
    RETURN 
    {
        $<node_ptr>$=$<node_ptr>1;
    }
|   RETURN Test
    {
        $<node_ptr>$=make_new_node("Return_Statement"); 
        add_edge($<node_ptr>$,{$<node_ptr>1, $<node_ptr>2});
    }

Global_Statement: 
    GLOBAL NAME Names
    {
        $<node_ptr>$=make_new_node("Global_Statement"); add_edge($<node_ptr>$,{$<node_ptr>1, $<node_ptr>2, $<node_ptr>3});
    }
Nonlocal_Statement: 
    NONLOCAL NAME Names
    {
        $<node_ptr>$=make_new_node("Nonlocal_Statement"); add_edge($<node_ptr>$,{$<node_ptr>1, $<node_ptr>2, $<node_ptr>3});
    }
Names:
    %empty
    {
        $<node_ptr>$=NULL;
    }
|   Names ',' NAME
    {
        $<node_ptr>$=make_new_node("Names"); add_edge($<node_ptr>$,{$<node_ptr>1, $<node_ptr>2, $<node_ptr>3});
    }
Assert_Statement: 
    ASSERT Test Optional_Test
    {
        $<node_ptr>$=make_new_node("Assert_Statement"); add_edge($<node_ptr>$,{$<node_ptr>1, $<node_ptr>2, $<node_ptr>3});
    }

compound_stmt: 
    IF_Statement
    {
        $<node_ptr>$=$<node_ptr>1;
    } 
|   While_Statement
    {
        $<node_ptr>$=$<node_ptr>1;
    } 
|   For_Statement
    {
        $<node_ptr>$=$<node_ptr>1;
    } 
|   Function_Defination
    {
        $<node_ptr>$=$<node_ptr>1;
    } 
|   Class_Defination
    {
        $<node_ptr>$=$<node_ptr>1;
    } 

Optional_Else_Statement:
    %empty
    {
        $<node_ptr>$=NULL;
    }
|   ELSE ':' Block
    {
        $<node_ptr>$=make_new_node("Optional_Else_Statement"); add_edge($<node_ptr>$,{$<node_ptr>1, $<node_ptr>2, $<node_ptr>3});
    }

IF_Statement: 
    IF Test ':' Block Elif_Statements Optional_Else_Statement
    {
        $<node_ptr>$=make_new_node("IF_Statement"); add_edge($<node_ptr>$,{$<node_ptr>1, $<node_ptr>2, $<node_ptr>3, $<node_ptr>4, $<node_ptr>5, $<node_ptr>6});
    }
Elif_Statements:
    %empty
    {
        $<node_ptr>$=NULL;
    }
|   Elif_Statements ELIF Test ':' Block
    {
        $<node_ptr>$=make_new_node("Elif_Statements"); add_edge($<node_ptr>$,{$<node_ptr>1, $<node_ptr>2, $<node_ptr>3, $<node_ptr>4, $<node_ptr>5});
    }
While_Statement: 
    WHILE Test ':' Block Optional_Else_Statement
    {
        $<node_ptr>$=make_new_node("While_Statement"); add_edge($<node_ptr>$,{$<node_ptr>1, $<node_ptr>2, $<node_ptr>3, $<node_ptr>4, $<node_ptr>5});
    }
For_Statement: 
    FOR Expression_List IN Test_List ':' Block Optional_Else_Statement
    {
        $<node_ptr>$=make_new_node("For_Statement"); add_edge($<node_ptr>$,{$<node_ptr>1, $<node_ptr>2, $<node_ptr>3, $<node_ptr>4, $<node_ptr>5, $<node_ptr>6, $<node_ptr>7});
    }

Block: 
    One_Line_Statement 
    {
        $<node_ptr>$=$<node_ptr>1;
    }
|   NEWLINE INDENT stmt Block_Statements DEDENT
    {
        if ($<node_ptr>4==NULL)
        {
            $<node_ptr>$ = $<node_ptr>3;
        }
        else
        {
            $<node_ptr>$=make_new_node("Block"); add_edge($<node_ptr>$,{$<node_ptr>1, $<node_ptr>2, $<node_ptr>3, $<node_ptr>4, $<node_ptr>5});
        }
    }
Block_Statements:
    %empty
    {
        $<node_ptr>$=NULL;
    }
|   Block_Statements stmt
    {
        if($<node_ptr>1==NULL)
        {
            $<node_ptr>$=$<node_ptr>2;
        }
        else
        {
            $<node_ptr>$=make_new_node("Block_Statements"); add_edge($<node_ptr>$,{$<node_ptr>1, $<node_ptr>2});
        }
    }

Test: 
    or_Test 
    {
        $<node_ptr>$=$<node_ptr>1;
    }
|   or_Test IF or_Test ELSE Test 
    {
        $<node_ptr>$=make_new_node("Test"); add_edge($<node_ptr>$,{$<node_ptr>1, $<node_ptr>2, $<node_ptr>3, $<node_ptr>4, $<node_ptr>5});
    }
or_Test: 
    and_Test
    {
        $<node_ptr>$=$<node_ptr>1;
    }
|   or_Test OR and_Test
    {
        $<node_ptr>$=$<node_ptr>2;
        add_edge($<node_ptr>$,{$<node_ptr>1, $<node_ptr>3});
    }
    
and_Test: 
    not_Test
    {
        $<node_ptr>$=$<node_ptr>1;
    }
|   and_Test AND not_Test
    {
        $<node_ptr>$=$<node_ptr>2;
        add_edge($<node_ptr>$,{$<node_ptr>1, $<node_ptr>3});
    }
    
not_Test: 
    NOT not_Test 
    {
        $<node_ptr>$=$<node_ptr>1; 
        add_edge($<node_ptr>1,$<node_ptr>2);
    }
|   comparison
    {
        $<node_ptr>$=$<node_ptr>1;
    }
comparison: 
    expr
    {
        $<node_ptr>$=$<node_ptr>1;
    }
|   comparison Comparison_Operator expr
    {
        $<node_ptr>$=$<node_ptr>2;
        add_edge($<node_ptr>$,{$<node_ptr>1, $<node_ptr>3});
    }
    
Comparison_Operator: 
    '<'
    {
        $<node_ptr>$=$<node_ptr>1;
    }
|   '>'
    {
        $<node_ptr>$=$<node_ptr>1;
    }
|   EQ_EQ
    {
        $<node_ptr>$=$<node_ptr>1;
    }
|   GT_EQ
    {
        $<node_ptr>$=$<node_ptr>1;
    }
|   LE_EQ
    {
        $<node_ptr>$=$<node_ptr>1;
    }
|   NEQ
    {
        $<node_ptr>$=$<node_ptr>1;
    }
|   IN
    {
        $<node_ptr>$=$<node_ptr>1;
    }
|   NOT IN
    {
        $<node_ptr>$=make_new_node("Comparison_Operator"); add_edge($<node_ptr>$,{$<node_ptr>1, $<node_ptr>2});
    }
|   IS
    {
        $<node_ptr>$=$<node_ptr>1;
    }
|   IS NOT
    {
        $<node_ptr>$=make_new_node("Comparison_Operator"); add_edge($<node_ptr>$,{$<node_ptr>1, $<node_ptr>2});
    }

expr:
    xor_expr
    {
        $<node_ptr>$=$<node_ptr>1;
    }
|   expr '|' xor_expr
    {
        $<node_ptr>$=$<node_ptr>2;
        add_edge($<node_ptr>$,{$<node_ptr>1, $<node_ptr>3});
    }
xor_expr: 
    and_expr
    {
        $<node_ptr>$=$<node_ptr>1;
    }
|   xor_expr '^' and_expr
    {
        $<node_ptr>$=$<node_ptr>2;
        add_edge($<node_ptr>$,{$<node_ptr>1, $<node_ptr>3});
    }
and_expr: 
    shift_expr
    {
        $<node_ptr>$=$<node_ptr>1;
    }
|   and_expr '&' shift_expr
    {
        $<node_ptr>$=$<node_ptr>2;
        add_edge($<node_ptr>$,{$<node_ptr>1, $<node_ptr>3});
    }
shift_expr: 
    arith_expr 
    {
        $<node_ptr>$=$<node_ptr>1;
    }
|   shift_expr LEFTSHIFT arith_expr
    {
        $<node_ptr>$=$<node_ptr>2;
        add_edge($<node_ptr>$,{$<node_ptr>1, $<node_ptr>3});
    }
|   shift_expr RIGHTSHIFT arith_expr
    {
        $<node_ptr>$=$<node_ptr>2;
        add_edge($<node_ptr>$,{$<node_ptr>1, $<node_ptr>3});
    }
arith_expr: 
    term
    {
        $<node_ptr>$=$<node_ptr>1;
    }
|   arith_expr '+' term
    {
        $<node_ptr>$=$<node_ptr>2;
        add_edge($<node_ptr>$,{$<node_ptr>1, $<node_ptr>3});
    }
|   arith_expr '-' term
    {
        $<node_ptr>$=$<node_ptr>2;
        add_edge($<node_ptr>$,{$<node_ptr>1, $<node_ptr>3});
    }
term: 
    Factor
    {
        $<node_ptr>$=$<node_ptr>1;
    }
|   term '*' Factor
    {
        $<node_ptr>$=$<node_ptr>2;
        add_edge($<node_ptr>$,{$<node_ptr>1, $<node_ptr>3});
    }
|   term '/' Factor
    {
        $<node_ptr>$=$<node_ptr>2;
        add_edge($<node_ptr>$,{$<node_ptr>1, $<node_ptr>3});
    }
|   term '%' Factor
    {
        $<node_ptr>$=$<node_ptr>2;
        add_edge($<node_ptr>$,{$<node_ptr>1, $<node_ptr>3});
    }
|   term FLOORDIV Factor
    {
        $<node_ptr>$=$<node_ptr>2;
        add_edge($<node_ptr>$,{$<node_ptr>1, $<node_ptr>3});
    }
Factor: 
    power
    {
        $<node_ptr>$=$<node_ptr>1;
    }
|   '+' Factor
    {
        $<node_ptr>$=make_new_node("Factor"); add_edge($<node_ptr>$,{$<node_ptr>1, $<node_ptr>2});
    }
|   '-' Factor
    {
        $<node_ptr>$=make_new_node("Factor"); add_edge($<node_ptr>$,{$<node_ptr>1, $<node_ptr>2});
    }
|   '~' Factor
    {
        $<node_ptr>$=make_new_node("Factor"); add_edge($<node_ptr>$,{$<node_ptr>1, $<node_ptr>2});
    } 
power: 
    Atomic_Expression 
    {
        $<node_ptr>$=$<node_ptr>1;
    }
|   Atomic_Expression DOUBLE_STAR Factor
    {
        $<node_ptr>$=$<node_ptr>2;
        add_edge($<node_ptr>$,{$<node_ptr>1, $<node_ptr>3});
    }
Atomic_Expression: 
    Atom Trailers
    {
        if ($<node_ptr>2==NULL)
        {
            $<node_ptr>$=$<node_ptr>1;
        }
        else
        {
            $<node_ptr>$=make_new_node("Atomic_Expression"); add_edge($<node_ptr>$,{$<node_ptr>1, $<node_ptr>2});
        }
    }
Trailers:
    %empty
    {
        $<node_ptr>$=NULL;
    }
|   Trailers Trailer
    {
        if ($<node_ptr>1==NULL)
        {
            $<node_ptr>$=$<node_ptr>2;
        }
        else
        {
            $<node_ptr>$=make_new_node("Trailers"); add_edge($<node_ptr>$,{$<node_ptr>1, $<node_ptr>2});
        }
    }
Atom: 
    '(' ')' 
    {
        $<node_ptr>$=make_new_node("Atom"); add_edge($<node_ptr>$,{$<node_ptr>1, $<node_ptr>2});
    }
|   '(' Test_List ')' 
    {
        $<node_ptr>$=make_new_node("Atom"); add_edge($<node_ptr>$,{$<node_ptr>1, $<node_ptr>2, $<node_ptr>3});
    }
|   '[' ']' 
    {
        $<node_ptr>$=make_new_node("Atom"); add_edge($<node_ptr>$,{$<node_ptr>1, $<node_ptr>2});
    }
|   '[' Test_List ']' 
    {
        $<node_ptr>$=make_new_node("Atom"); add_edge($<node_ptr>$,{$<node_ptr>1, $<node_ptr>2, $<node_ptr>3});
    }
|   '{' '}' 
    {
        $<node_ptr>$=make_new_node("Atom"); add_edge($<node_ptr>$,{$<node_ptr>1, $<node_ptr>2});
    }
|   NAME
    {
        $<node_ptr>$=$<node_ptr>1;
    } 
|   NUMBER
    {
        $<node_ptr>$=$<node_ptr>1;
    } 
|   Strings
    {
        $<node_ptr>$=$<node_ptr>1;
    }
|   NONE
    {
        $<node_ptr>$=$<node_ptr>1;
    } 
|   TRUE
    {
        $<node_ptr>$=$<node_ptr>1;
    } 
|   FALSE
    {
        $<node_ptr>$=$<node_ptr>1;
    }

Strings:
    STRING
    {
        $<node_ptr>$=$<node_ptr>1;
    }
|   Strings STRING
    {
        $<node_ptr>$=make_new_node("Strings"); add_edge($<node_ptr>$,{$<node_ptr>1, $<node_ptr>2});
    }

Test_List: 
    Test Tests opt_comma
    {
        if ($<node_ptr>2==NULL && $<node_ptr>3==NULL)
        {
            $<node_ptr>$=$<node_ptr>1;
        }
        else
        {
            $<node_ptr>$=make_new_node("Test_List"); add_edge($<node_ptr>$,{$<node_ptr>1, $<node_ptr>2, $<node_ptr>3});
        }
    }

Trailer: 
    '(' opt_arglist ')' 
    {
        $<node_ptr>$=make_new_node("Trailer"); add_edge($<node_ptr>$,{$<node_ptr>1, $<node_ptr>2, $<node_ptr>3});
    }
|   '[' Subscript_List ']' 
    {
        $<node_ptr>$=make_new_node("Trailer"); add_edge($<node_ptr>$,{$<node_ptr>1, $<node_ptr>2, $<node_ptr>3});
    }
|   '.' NAME
    {
        $<node_ptr>$=make_new_node("Trailer"); add_edge($<node_ptr>$,{$<node_ptr>1, $<node_ptr>2});
    }

Subscript_List: 
    Subscript Subscript_Items opt_comma
    {
        if($<node_ptr>2==NULL && $<node_ptr>3==NULL)
        {
            $<node_ptr>$=$<node_ptr>1;
        }
        else
        {
            $<node_ptr>$=make_new_node("Subscript_List"); add_edge($<node_ptr>$,{$<node_ptr>1, $<node_ptr>2, $<node_ptr>3});
        }
    }
Subscript_Items:
    %empty
    {
        $<node_ptr>$=NULL;
    }
|   Subscript_Items ',' Subscript
    {
        $<node_ptr>$=make_new_node("Subscript_Items"); add_edge($<node_ptr>$,{$<node_ptr>1, $<node_ptr>2, $<node_ptr>3});
    }
Subscript: 
    Test 
    {
        $<node_ptr>$=$<node_ptr>1;
    }
Expression_List: 
    Expressions opt_comma
    {
        if ($<node_ptr>2==NULL)
        {
            $<node_ptr>$ = $<node_ptr>1;
        }
        else
        {     
            $<node_ptr>$=make_new_node("Expression_List"); add_edge($<node_ptr>$,{$<node_ptr>1, $<node_ptr>2});
        }
    }

Expressions:
    expr
    {
        $<node_ptr>$=$<node_ptr>1;
    }
|   Expressions ',' expr
    {
        $<node_ptr>$=make_new_node("Expressions"); add_edge($<node_ptr>$,{$<node_ptr>1, $<node_ptr>2, $<node_ptr>3});
    }

Tests:
    %empty
    {
        $<node_ptr>$=NULL;
    }
|   Tests ',' Test
    {
        $<node_ptr>$=make_new_node("Tests"); add_edge($<node_ptr>$,{$<node_ptr>1, $<node_ptr>2, $<node_ptr>3});
    }

Class_Defination: 
    CLASS NAME Base_Class_List ':' Block
    {
        $<node_ptr>$=make_new_node("Class_Defination"); add_edge($<node_ptr>$,{$<node_ptr>1, $<node_ptr>2, $<node_ptr>3, $<node_ptr>4, $<node_ptr>5});
    }

Argument_List: 
    Argument Arguments opt_comma
    {
        if ($<node_ptr>2==NULL && $<node_ptr>3==NULL)
        {
            $<node_ptr>$ = $<node_ptr>1;
        }
        else
        {
            $<node_ptr>$=make_new_node("Argument_List"); add_edge($<node_ptr>$,{$<node_ptr>1, $<node_ptr>2, $<node_ptr>3});
        }
    }
Arguments:
    %empty
    {
        $<node_ptr>$=NULL;
    }
|   Arguments ',' Argument
    {
        $<node_ptr>$=make_new_node("Arguments"); add_edge($<node_ptr>$,{$<node_ptr>1, $<node_ptr>2, $<node_ptr>3});
    }

Argument: 
    Test
    {
        $<node_ptr>$=$<node_ptr>1;
    }
|   Test '=' Test 
    {
        $<node_ptr>$=$<node_ptr>2;
        add_edge($<node_ptr>$,{$<node_ptr>1, $<node_ptr>3});
    }

%%

map<int, string> token_val_to_token_name = {{NAME, "NAME"},{INDENT, "INDENT"},{STRING, "STRING"},{DEDENT, "DEDENT"},{NUMBER, "NUMBER"},{NEWLINE, "NEWLINE"},{BREAK, "BREAK"},{CONTINUE, "CONTINUE"},{RETURN, "RETURN"},{GLOBAL, "GLOBAL"},{NONLOCAL, "NONLOCAL"},{ASSERT, "ASSERT"},{IS, "IS"},{NOT, "NOT"},{AND, "AND"},{OR, "OR"},{IN, "IN"},{CLASS, "CLASS"},{DEF, "DEF"},{IF, "IF"},{ELIF, "ELIF"},{ELSE, "ELSE"},{WHILE, "WHILE"},{FOR, "FOR"},{NONE, "NONE"},{TRUE, "TRUE"},{FALSE, "FALSE"},{ARROW, "ARROW"},{PLUS_EQ, "PLUS_EQ"},{MINUS_EQ, "MINUS_EQ"},{MUL_EQ, "MUL_EQ"},{DIV_EQ, "DIV_EQ"},{PERCENT_EQ, "PERCENT_EQ"},{AND_EQ, "AND_EQ"},{OR_EQ, "OR_EQ"},{XOR_EQ, "XOR_EQ"},{LEFTSHIFT, "LEFTSHIFT"},{LEFTSHIFT_EQ, "LEFTSHIFT_EQ"},{RIGHTSHIFT, "RIGHTSHIFT"},{RIGHTSHIFT_EQ, "RIGHTSHIFT_EQ"},{DOUBLE_STAR, "DOUBLE_STAR"},{POW_EQ, "POW_EQ"},{FLOORDIV, "FLOORDIV"},{FLOORDIV_EQ, "FLOORDIV_EQ"},{EQ_EQ, "EQ_EQ"},{NEQ, "NEQ"},{LE_EQ, "LE_EQ"},{GT_EQ, "GT_EQ"},{'(', "("},{')', ")"},{':', ":"},{',', ","},{';', ";"},{'=', "="},{'<', "<"},{'>', ">"},{'*', "*"},{'|', "|"},{'^', "^"},{'&', "&"},{'+', "+"},{'-', "-"},{'/', "/"},{'%', "%"},{'~', "~"},{'[', "["},{']', "]"},{'{', "{"},{'}', "}"},{'.', "."}};

Node * make_new_node(string label)
{
    Node * node_ptr = new Node;
    node_ptr->set_label(label);
    node_ptr->is_terminal = false;
    ast_nodes.push_back(node_ptr);
    return node_ptr;
}
void add_edge(Node * from_node_ptr, Node * to_node_ptr)
{
    if (from_node_ptr!=NULL && to_node_ptr!=NULL)
    {
        ast_edges.push_back({from_node_ptr->node_index, to_node_ptr->node_index});
    }
}
void add_edge(Node * from_node_ptr, vector<Node *> to_node_ptr_vec)
{
    for (Node * to_node_ptr : to_node_ptr_vec)
    {
        if (from_node_ptr!=NULL && to_node_ptr!=NULL)
        {
            ast_edges.push_back({from_node_ptr->node_index, to_node_ptr->node_index});
        }
    }
}
void Node::set_label(string label)
{
    node_label = label;
    node_index = node_count;
    node_count++;
}
void Node::set_terminal()
{
    is_terminal = true;
}
void Node::set_token(int token)
{
    node_token = token; 
}
void write__content(ofstream &myfile, string lexeme)
{
    for (char ch : lexeme)
    {
        if (ch=='\\')
        {
            myfile << '\\' << '\\';
        }
        else if (ch=='\"')
        {
            myfile << "\\" << '\"';
        }
        else
        {
            myfile << ch;
        }
    }
}
void make_ast()
{
    // Open File
    ofstream myfile;
    myfile.open("graph.dot");

    // Starting Line
    myfile << "digraph\n{\n";
    myfile << "node [ordering=\"out\"]\n";

    // Make Nodes
    for (Node * node_ptr : ast_nodes)
    {
        myfile << node_ptr->node_index<<" ";
        myfile << "[label=\"";
        if (node_ptr->is_terminal==true)
        {
            /* Token Name */
            write__content(myfile, token_val_to_token_name[node_ptr->node_token]);
            myfile << "\\n(";
            write__content(myfile, node_ptr->node_label);
            myfile << ")";
            myfile << "\"]\n";
        }
        else
        {
            write__content(myfile, node_ptr->node_label);
            myfile << "\"";
            myfile << "shape=box";
            myfile << "]\n";
        }
    }

    // Make Edges
    for (pair<int,int> p : ast_edges)
    {
        myfile << p.first <<" ";
        myfile << "-> ";
        myfile << p.second << endl;
    }

    // Ending Line
    myfile << "}";

    // Close File
    myfile.close();

    // Make PDF
    string op_file = OUTPUT_FILE;
    string ast_command = "dot -Tpdf graph.dot -o ";
    string final_ast_command = ast_command + op_file;
    system(final_ast_command.c_str());
}
 