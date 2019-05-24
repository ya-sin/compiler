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
extern char* yytext;   // Get current token from lex
extern char buf[256];  // Get current code line from lex
extern int dump_flag;
extern int semantic_flag;

/* Symbol table function - you can add new function if needed. */
int lookup_symbol();
void create_symbol();
void insert_symbol();
void dump_symbol();
void dump_all();
void remove_symbol(int rm_scope_level);
void remove_symbol_ID(char* id, int rm_scope_level);
void yyerror(char *s);
void semantic_error(char *s);

int scope_level = 0;
int var_no;
int function_index = 0;
int string_tag = 0;
char text[30];
char global_error_msg[30];
int function_declaration_flag = 0;
int redeclared_function_flag = 0;
int redeclared_function_flag_2 = 0;
int forward_declaration_flag = 0;
int normal_id_lookup_flag = 0;
int dump_scope = 0;
int tmp = 0;

struct data{
	char id[30];
    int entry_type;
    char type_name[10];
	int scope;
    char attribute[30];
	int type;
    int int_value;
    double dou_value;
    int forward;
}symbol_table[100];

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

/* Token with return, which need to sepcify type */
%token <i_val> I_CONST
%token <f_val> F_CONST
%token <string> BOOL INT STRING FLOAT VOID
%token <string> STR_CONST
%token <string> ID

/* Nonterminal with return, which need to sepcify type */
%type <string> type
%type <f_val> const
%type <f_val> primary_expression
%type <f_val> postfix_expression
%type <f_val> unary_expression
%type <f_val> multiplicative_expression
%type <f_val> additive_expression
%type <f_val> equality_expression
%type <f_val> logical_AND_expression
%type <f_val> logical_OR_expression
%type <f_val> relational_expression
%type <f_val> conditional_expression
%type <f_val> assignment_expression
%type <f_val> cast_expression
%type <f_val> initializer
%type <i_val> unary_operator
%type <string> parameter
%type <string> parameter_list
%type <string> function_declaration

/* Yacc will start at this nonterminal */
// %start program
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
    {
        if(lookup_symbol($2, scope_level, 1) == -1){
            insert_symbol($1, $2, scope_level,1);
        }
        else if(lookup_symbol($2, scope_level, 1) > -1){
            char error_msg[30];
            strcpy(error_msg,"Redeclared variable ");
            strcat(error_msg,$2);
            normal_id_lookup_flag = 1;
            semantic_error(error_msg);
        }
    }
    | type ID SEMICOLON
    {
        if(lookup_symbol($2, scope_level, 1) == -1){
            insert_symbol($1, $2, scope_level,1);
        }
        else if(lookup_symbol($2, scope_level, 1) > -1){
            char error_msg[30];
            strcpy(error_msg,"Redeclared variable ");
            strcat(error_msg,$2);
            normal_id_lookup_flag = 1;
            semantic_error(error_msg);
        }
    }
    | function_declaration LB parameter_list_opt RB SEMICOLON
    {
        if(redeclared_function_flag_2){
            normal_id_lookup_flag = 1;
            semantic_error(global_error_msg);
            redeclared_function_flag_2 = 0;
            remove_symbol(scope_level+1);

        } else{
            remove_symbol(scope_level+1);
            remove_symbol_ID($1,scope_level);
        }
    }
;

function_definition
    : function_declaration LB parameter_list_opt RB compound_statement
    {

    }
;

function_declaration
    : type ID
    {
        int tmp = lookup_symbol($2, scope_level, 1);
        if(tmp == -1){
            insert_symbol($1, $2, scope_level,0);
            $$ = $2;
        }
        else if(tmp > -1){
            redeclared_function_flag_2 = 1;
            strcpy(global_error_msg,"Redeclared function ");
            strcat(global_error_msg,$2);
            if(symbol_table[tmp].forward!=1){
                function_index = tmp;
                strcpy(global_error_msg,"Redeclared function ");
                strcat(global_error_msg,$2);
                redeclared_function_flag = 1;
            }else{

                forward_declaration_flag = 1;
            }
        }
    }
;

parameter_list_opt
    : parameter_list 
    {   if(!redeclared_function_flag  && !forward_declaration_flag && !redeclared_function_flag_2){
            strcpy(symbol_table[function_index].attribute,$1);
        } 
    }
    | { strcpy(symbol_table[function_index].attribute,""); }
;

parameter_list
    : parameter { $$ = $1; }
    | parameter_list COMMA parameter { $$  = strcat(strcat($1,", "),$3);  }
;

parameter
    : type ID
    {
        // printf("type= %s, ID= %s\n",$1,$2);
        if(lookup_symbol($2, scope_level, 1) == -1){
            // printf("%d %d\n",redeclared_function_flag,redeclared_function_flag_2);
            if(!redeclared_function_flag || !redeclared_function_flag_2)
                insert_symbol($1, $2, scope_level+1,2);
            $$ = $1;
        }
    }
;

initializer
    : assignment_expression { $$ = $1; }
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
    {}
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
    {

    }
    | FOR LB expression_opt SEMICOLON expression_opt SEMICOLON expression_opt RB statement 
    {

    }
    | FOR LB declaration SEMICOLON expression_opt SEMICOLON expression_opt RB statement
    {

    }
;

expression_opt
    : expression
    | SEMICOLON 
    |
;

print_func
    : PRINT LB ID RB SEMICOLON
    {
        int flag = 0;
        int i;
        for(i = 0; i < var_no; i++){
            if(!strcmp(symbol_table[i].id, $3) && symbol_table[i].scope<=scope_level && symbol_table[i].entry_type==1)
                flag = 1;
        }
        if(!flag){
            char error_msg[30];
            strcpy(error_msg,"Undeclared variable ");
            strcat(error_msg,$3);
            normal_id_lookup_flag = 1;
            semantic_error(error_msg);
        }

    }
    | PRINT LB STR_CONST RB SEMICOLON
    {

    }
;

if_block
    : IF LB expression RB statement
    {
    }
    | IF LB expression RB statement ELSE statement
    {
    }
;

expression
    : assignment_expression
    | expression COMMA assignment_expression
    {
        // printf("COMMA here\n");
    }
;

argument_expression_list
    : assignment_expression
    | argument_expression_list COMMA assignment_expression
    {
        
    }
;
// constant_expression
//     : conditional_expression
// ;
assignment_expression
    : conditional_expression 
    {
        // printf("COMMA here %lf \n",$1);        
        $$ = $1;
    }
    | unary_expression assignment_operator assignment_expression 
    { 
        $$ = 1; 
    }
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
    : logical_OR_expression { $$ = $1; }
;

logical_OR_expression
    : logical_AND_expression { $$ = $1; }
    | logical_OR_expression OR logical_AND_expression { $$ = 1; }
;

logical_AND_expression
    : equality_expression { $$ = $1; }
    | logical_AND_expression AND equality_expression { $$ = 1; }
;

equality_expression
    : relational_expression { $$ = $1; }
    | equality_expression EQ relational_expression { $$ = 1; }
    | equality_expression NE relational_expression { $$ = 1; }
;

relational_expression
    : additive_expression { $$ = $1; }
    | relational_expression MT additive_expression { $$ = 1000; }
    | relational_expression LT additive_expression { $$ = 1; }
    | relational_expression MTE additive_expression { $$ = 1; }
    | relational_expression LTE additive_expression { $$ = 1; }
;

additive_expression
    : multiplicative_expression { $$ = $1; }
    | additive_expression ADD multiplicative_expression { $$ = $1 + $3; }
    | additive_expression SUB multiplicative_expression { $$ = $1 - $3; }
;

multiplicative_expression
    : cast_expression { $$ = $1; }
    | multiplicative_expression MUL unary_expression { $$ = $1 * $3; }
    | multiplicative_expression DIV unary_expression { $$ = $1 / $3; }
    | multiplicative_expression MOD unary_expression 
    { 
        if($3 == 0){
            printf("The remainder can't be 0");
        }
        else if($1 == 19){
            printf("Float can't be mod");
        }
        else{
            /*printf("Remain \n");*/ $$ = (int)$1 % (int)$3;
        } 
    }
;

cast_expression
    : unary_expression { $$ = $1; }
    | LB type RB cast_expression 
    { 
        $$ = 1; 
    }
;

unary_expression
    : postfix_expression { $$ = $1; }
    | INC unary_expression { $$ = 5; }
    | DEC unary_expression { $$ = 4; }
    | unary_operator cast_expression { $$ = 1; }
;

unary_operator
    : ADD { $$ = 0; }
    | SUB { $$ = 1; }
    | NOT { $$ = 2; }
;

postfix_expression
    : primary_expression
    { 
        strcpy(global_error_msg,"Undeclared variable ");
        strcat(global_error_msg,text);
        $$ = $1; 
    }
    | postfix_expression LB argument_expression_list_opt RB SEMICOLON
    {
        strcpy(global_error_msg,"Undeclared function ");
        strcat(global_error_msg,text);
    }
    | postfix_expression INC { $$ = 1; }
    | postfix_expression DEC { $$ = 1; }
;

argument_expression_list_opt
    : argument_expression_list
    |
;

primary_expression
    : STR_CONST 
    { 
        // char text[30];
        // strcpy(text,$1);
        // $$ = atoi (text);
        strcpy(text,$1);
        string_tag = 1;
        $$ = 1;
    }
    | ID
    {
        int i;
        int flag = 0;
        for(i = 0; i < var_no; i++){
            if(!strcmp(symbol_table[i].id, $1)&&strcmp(symbol_table[i].id, "main")){
                flag = 1;
            }
        }
        if(!flag){
            strcpy(text,$1);
            function_declaration_flag = 1;
            // printf("find function name%d\n",function_declaration_flag);
        }else{
            // printf("find function name\n");
        }
        $$ = 1;

    }
    | const { $$ = $1 ;}
    | LB expression RB 
    {
        $$ = 1; 
    }
;

/* actions can be taken when meet the token or rule */
type
    : INT { $$ = $1; }
    | FLOAT { $$ = $1; }
    | BOOL  { $$ = $1; }
    | STRING { $$ = $1; }
    | VOID { $$ = $1; }
;

const
    : I_CONST { $$ = $1; }
    | F_CONST { $$ = $1; }
    | TRUE { $$ = 1; }
    | FALSE { $$ = 0; }
;

lcb
    : LCB
    {
        scope_level++;
    }
;
rcb
    : RCB
    {
        dump_flag = 1; 
        scope_level--; 
        dump_scope = scope_level;
    }
;

%%

/* C code section */
int main(int argc, char** argv)
{
    yylineno = 0;
    var_no = 0;
    dump_flag = 0;
    semantic_flag = 1;
    yyparse();
    if(!function_declaration_flag){
        dump_all();
	    printf("\nTotal lines: %d \n",yylineno);
    }

    return 0;
}

void yyerror(char *s)
{
    if(!strcmp(buf, "\n")){
        printf("%d:",yylineno+1);
    }else{
        printf("%d: ",yylineno+1);
    }
    printf("%s\n",buf);

    if(function_declaration_flag){
        tmp = 1;
        char error_msg[30];
        strcpy(error_msg,"Undeclared function ");
        strcat(error_msg,text);
        semantic_error(error_msg);
    }
    printf("\n|-----------------------------------------------|\n");
    printf("| Error found in line %d: %s\n", yylineno+1, buf);
    printf("| %s", s);
    printf("\n|-----------------------------------------------|\n\n");
}

void semantic_error(char *s)
{
    // if(!function_declaration_flag){
        // printf("%d: ",yylineno+1);
    int yylineno_tmp = yylineno;
    if(!tmp){
        if(!strcmp(buf, "\n")){
            printf("%d:",yylineno+1);
            yylineno_tmp = yylineno+1;
        } else if(normal_id_lookup_flag){
            yylineno_tmp = yylineno+1;
            printf("%d: ",yylineno_tmp);
        } else{
            printf("%d: ",yylineno);
        }
            printf("%s\n",buf);
    } else {
        yylineno_tmp = yylineno+1;
    }

    // }
    printf("\n|-----------------------------------------------|\n");
    printf("| Error found in line %d: %s\n", yylineno_tmp, buf);
    printf("| %s", s);
    printf("\n|-----------------------------------------------|\n\n");
    if(!tmp)
        memset( buf, '\0', strlen(buf) );
    semantic_flag = 0;
}

void create_symbol() {
    // printf("Create a symbol table \n");
}
void insert_symbol(char* type, char* id, int scope_level, int entry_type) {
    if(var_no == 0){
		create_symbol();
	}
    strcpy(symbol_table[var_no].id,id);
    strcpy(symbol_table[var_no].type_name,type);
	symbol_table[var_no].entry_type = entry_type;
    symbol_table[var_no].scope = scope_level;
    if(entry_type==0)
        function_index = var_no;
    // printf("Insert %s\n",symbol_table[var_no].id);
	var_no++;
}
int lookup_symbol(char* id, int flag, int check) {
    int i;
    int temp = flag;
    if(check == 1){
        for(i = 0;i < var_no;i++){
            if(strcmp(symbol_table[i].id, id) == 0 && symbol_table[i].scope == temp){
                return i;
            }
        }
        return -1;
    }
}
void dump_all() {
    int i;
    char kind[10];
    printf("\n%-10s%-10s%-12s%-10s%-10s%-10s\n\n",
            "Index", "Name", "Kind", "Type", "Scope", "Attribute");
    for(i = 0;i < var_no;i++){

        switch(symbol_table[i].entry_type) { 
            case 0: 
                strcpy(kind,"function");
                break;
            case 1: 
                strcpy(kind,"variable");
                break; 
            case 2: 
                strcpy(kind,"parameter");                
                break; 
            default: 
                strcpy(kind,"not");
        }
        if(!strcmp(symbol_table[i].attribute,""))
            printf("%-10d%-10s%-12s%-10s%-10d\n", i,symbol_table[i].id,kind,symbol_table[i].type_name,symbol_table[i].scope);
        else
            printf("%-10d%-10s%-12s%-10s%-10d%s\n", i,symbol_table[i].id,kind,symbol_table[i].type_name,symbol_table[i].scope,symbol_table[i].attribute);

	}
    printf("\n");
}
void dump_symbol() {
    int i;
    int j = 0;
    char kind[10];
    int empty = 1;
    int dump_level;
    if(dump_flag)
        dump_level = dump_scope;
    else
        dump_level = scope_level;

    // printf("present scopr= %d\n",scope_level);
	for(i = 0;i < var_no;i++){
        if(symbol_table[i].scope == dump_level+1){
            empty = 0;
            break;
        }
    }
    if(empty==1){
        return;
    }
    else{
        printf("\n%-10s%-10s%-12s%-10s%-10s%-10s\n\n",
            "Index", "Name", "Kind", "Type", "Scope", "Attribute");
        for(i = 0;i < var_no;i++){
            if(symbol_table[i].scope == dump_level+1){
                switch(symbol_table[i].entry_type) { 
                    case 0: 
                        strcpy(kind,"function");
                        break;
                    case 1: 
                        strcpy(kind,"variable");
                        break; 
                    case 2: 
                        strcpy(kind,"parameter");                
                        break; 
                    default: 
                        strcpy(kind,"variable");
                }
                if(!strcmp(symbol_table[i].attribute,""))
                    printf("%-10d%-10s%-12s%-10s%-10d\n", j,symbol_table[i].id,kind,symbol_table[i].type_name,symbol_table[i].scope);
                else
                    printf("%-10d%-10s%-12s%-10s%-10d%s\n", j,symbol_table[i].id,kind,symbol_table[i].type_name,symbol_table[i].scope,symbol_table[i].attribute);
                j += 1;
            }
        }
        printf("\n");
    }
    remove_symbol(dump_level+1);
}

void remove_symbol(int rm_scope_level){
    int i;
    int temp = 0;
    for(i = 0; i < var_no; i++){
        if(symbol_table[i].scope == rm_scope_level){
            // printf("Remove %s\n",symbol_table[i].id);
            memset(symbol_table[i].id, 0, sizeof(symbol_table[i].id));
            memset(symbol_table[i].type_name, 0, sizeof(symbol_table[i].type_name));
            memset(symbol_table[i].attribute, 0, sizeof(symbol_table[i].attribute));
            //strcpy(symbol_table[i].id,id);
            //strcpy(symbol_table[i].type_name,type);
            symbol_table[i].scope = 0;
	        symbol_table[i].type = 0;
            symbol_table[i].entry_type = 0;
            symbol_table[i].forward = 0;
            temp++;
        }
    }
    var_no -= temp;
}

void remove_symbol_ID(char* id, int rm_scope_level){
    int i;
    // int temp = 0;
    // dump_all();
    for(i = 0; i < var_no; i++){
        if(!strcmp(symbol_table[i].id, id) && symbol_table[i].scope == rm_scope_level){
            // printf("Remove ID %s\n",symbol_table[i].id);       
            // memset(symbol_table[i].id, 0, sizeof(symbol_table[i].id));
            // memset(symbol_table[i].type_name, 0, sizeof(symbol_table[i].type_name));
            // memset(symbol_table[i].attribute, 0, sizeof(symbol_table[i].attribute));
            // memset(symbol_table[i].scope, 0, sizeof(symbol_table[i].scope));
            //strcpy(symbol_table[i].id,id);
            //strcpy(symbol_table[i].type_name,type);
            // symbol_table[i].scope = 0;
	        // symbol_table[i].type = 0;
            // symbol_table[i].entry_type = 0;
            // symbol_table[i].assign_bit = 0;
            symbol_table[i].forward = 1;
            function_index = i;
            // temp++;
        }
    }
    // var_no -= temp;
    // dump_all();
}
