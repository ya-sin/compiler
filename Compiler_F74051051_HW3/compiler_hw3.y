/*	Definition section */
%{

#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>
#include <math.h>
#include <stdbool.h>

extern int yylineno;
extern int yylex();
extern char *yytext; // Get current token from lex
extern char buf[256]; // Get current code line from lex

FILE *file; // To generate .j file for Jasmin

void yyerror(char *s);

/* symbol table functions */
int lookup_symbol();
void create_symbol_table();
void free_symbol_table();
void insert_symbol();
void dump_symbol(int scope);

/* code generation functions, just an example! */
void gencode_function();

// variable declaration
int had_print_flag = 0;
int dump_flag = -1;
%}

/* Use variable or self-defined structure to represent
 * nonterminal and token type
 */
%union {
    int i_val;
    double f_val;
    char* string;
}
/* Token without return */
%token PRINT COMMENT
%token TRUE FALSE RET CONT BREAK
%token IF ELSE FOR WHILE
%token  SEMICOLON COMMA
%token ADD SUB MUL DIV MOD
%token INC DEC MT LT MTE LTE EQ NE
%token ASGN ADDASGN SUBASGN MULASGN DIVASGN MODASGN
%token AND OR NOT
%token LB RB LCB RCB LSB RSB
%token BOOL INT STRING FLOAT VOID

/* Token with return, which need to sepcify type */
%token <i_val> I_CONST
%token <f_val> F_CONST
%token <string> STR_CONST
%token <string> ID

/* Nonterminal with return, which need to sepcify type */
%type <i_val> type
%type <i_val> unary_operator
%type <f_val> const

/* Yacc will start at this nonterminal */
%start translation_unit

/* Grammar section */
%%

translation_unit
    : external_declaration
    | translation_unit external_declaration
;

external_declaration
    : declaration
    | function_definition
;

declaration
    : type ID ASGN initializer SEMICOLON
    | type ID SEMICOLON
    | function_declaration LB parameter_list_opt RB SEMICOLON
;

function_definition
    : function_declaration LB parameter_list_opt RB compound_statement
;

function_declaration
    : type ID
;

parameter_list_opt
    : parameter_list
    |
;

parameter_list
    : parameter
    | parameter_list COMMA parameter
;

parameter
    : type ID
;

initializer
    : assignment_expression
;

compound_statement
    : lcb block_item_list_opt rcb
;

block_item_list_opt
    : block_item_list
    |
;

block_item_list
    : block_item
    | block_item_list block_item
;

block_item
    : declaration
    | statement
;

statement
    : compound_statement
    | if_block
    | expression_statement
    | iteration_block
    | jump_block
    | print_func
;

jump_block
    : CONT SEMICOLON
    | BREAK SEMICOLON
    | RET expression_opt SEMICOLON
    | RET SEMICOLON
;

expression_statement
    : expression_opt
;

iteration_block
    : WHILE LB expression RB statement
    | FOR LB expression_opt SEMICOLON expression_opt SEMICOLON expression_opt RB statement
    | FOR LB declaration SEMICOLON expression_opt SEMICOLON expression_opt RB statement
;

expression_opt
    : expression
    | SEMICOLON
    |
;

print_func
    : PRINT LB ID RB SEMICOLON
    | PRINT LB STR_CONST RB SEMICOLON
;

if_block
    : IF LB expression RB statement
    | IF LB expression RB statement ELSE statement
;

expression
    : assignment_expression
    | expression COMMA assignment_expression
;

argument_expression_list
    : assignment_expression
    | argument_expression_list COMMA assignment_expression
;
// constant_expression
//     : conditional_expression
// ;
assignment_expression
    : conditional_expression
    | unary_expression assignment_operator assignment_expression
;

assignment_operator
    : ASGN
    | ADDASGN
    | SUBASGN
    | MULASGN
    | DIVASGN
    | MODASGN
;

conditional_expression
    : logical_OR_expression
;

logical_OR_expression
    : logical_AND_expression
    | logical_OR_expression OR logical_AND_expression
;

logical_AND_expression
    : equality_expression
    | logical_AND_expression AND equality_expression
;

equality_expression
    : relational_expression
    | equality_expression EQ relational_expression
    | equality_expression NE relational_expression
;

relational_expression
    : additive_expression
    | relational_expression MT additive_expression
    | relational_expression LT additive_expression
    | relational_expression MTE additive_expression
    | relational_expression LTE additive_expression
;

additive_expression
    : multiplicative_expression
    | additive_expression ADD multiplicative_expression
    | additive_expression SUB multiplicative_expression
;

multiplicative_expression
    : cast_expression
    | multiplicative_expression MUL unary_expression
    | multiplicative_expression DIV unary_expression
    | multiplicative_expression MOD unary_expression
;

cast_expression
    : unary_expression
    | LB type RB cast_expression
;

unary_expression
    : postfix_expression
    | INC unary_expression
    | DEC unary_expression
    | unary_operator cast_expression
;

unary_operator
    : ADD { $$ = 0; }
    | SUB { $$ = 1; }
    | NOT { $$ = 2; }
;

postfix_expression
    : primary_expression
    | postfix_expression LB argument_expression_list_opt RB SEMICOLON
    | postfix_expression INC
    | postfix_expression DEC
;

argument_expression_list_opt
    : argument_expression_list
    |
;

primary_expression
    : STR_CONST
    | ID
    | const
    | LB expression RB
;

const
    : I_CONST { $$ = $1; }
    | F_CONST { $$ = $1; }
    | TRUE { $$ = 1; }
    | FALSE { $$ = 0; }
;

lcb
    : LCB
;

rcb
    : RCB
;
/* actions can be taken when meet the token or rule */
type
    : INT { $$ = 1; }
    | FLOAT { $$ = 2; }
    | BOOL  { $$ = 3; }
    | STRING { $$ = 4; }
    | VOID { $$ = 5; }
;

%%

/* C code section */

/* C code section */
int main(int argc, char** argv)
{
    yylineno = 0;

    file = fopen("compiler_hw3.j","w");

    fprintf(file,   ".class public compiler_hw3\n"
                    ".super java/lang/Object\n"
                    ".method public static main([Ljava/lang/String;)V\n");

    yyparse();
    printf("\nTotal lines: %d \n",yylineno);

    fprintf(file, "\treturn\n"
                  ".end method\n");

    fclose(file);

    return 0;
}

void yyerror(char *s)
{
    printf("\n|-----------------------------------------------|\n");
    printf("| Error found in line %d: %s\n", yylineno, buf);
    printf("| %s", s);
    printf("\n| Unmatched token: %s", yytext);
    printf("\n|-----------------------------------------------|\n");
    exit(-1);
}

/* stmbol table functions */
void create_symbol() {}
void insert_symbol() {}
int lookup_symbol() {}
void dump_symbol(int scope) {}

/* code generation functions */
void gencode_function() {}
