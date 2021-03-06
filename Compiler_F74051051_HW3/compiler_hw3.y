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
FILE *file_label; // To generate .j file for label

void yyerror(char *s);
void print_error(char* msg, char* Name);
void print_error_after_line();

/* symbol table functions */
int lookup_symbol(char* id, int scope);
void create_symbol_table();
void free_symbol_table();
int insert_symbol(int type, char* id, int scope_level, int entry_type);
void dump_symbol(int scope);
void dump_all();
void remove_symbol(int rm_scope_level);
int get_local_var_index(char* id,int scope);
int use_id_scope_get_type(char* id, int scope);
int get_symbol_table_index(char* id);

/* code generation functions, just an example! */
void gencode_function(char* codeline);
void gencode_labelcode_function(char* codeline);
void gencode_string_function(char* codeline);
void gencode_right_value_function(float*);
void gencode_ADD_SUB_MUL_DIV_MOD_function(float*,float*);

// variable declaration

int dump_flag = -1;
int var_no;
int scope_level;
int function_return_type;
int gencode_label_flag = 0;
int return_goto_flag = 0;
int while_flag = 0;
int after_while_section_flag = 0;
char STR_CONST_buf[64];
int label_count = 0;

char error_buf[256];
int print_error_flag = 0;
int syntax_error_flag = 0;
int had_print_flag = 0;
int file_delete_flag = 0;

struct data{
    char id[30];
    int entry_type;
    char type_name[10];
    int scope;
    char attribute[32];
    // int type;
    // int int_value;
    // double dou_value;
    // int forward;
}symbol_table[100];

%}

/* Use variable or self-defined structure to represent
 * nonterminal and token type
 */
%union {
    int i_val;
    double f_val;
    char* string;
    float exp_ret[3];
    // 1:value 2:type 3:ID const other
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

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

/* Nonterminal with return, which need to sepcify type */
%type <i_val> type
%type <i_val> unary_operator
%type <i_val> assignment_operator
%type <exp_ret> primary_expression
%type <exp_ret> postfix_expression
%type <exp_ret> unary_expression
%type <exp_ret> multiplicative_expression
%type <exp_ret> additive_expression
%type <exp_ret> equality_expression
%type <exp_ret> logical_AND_expression
%type <exp_ret> logical_OR_expression
%type <exp_ret> relational_expression
%type <exp_ret> conditional_expression
%type <exp_ret> assignment_expression
%type <exp_ret> initializer
%type <exp_ret> expression
%type <exp_ret> cast_expression
%type <exp_ret> argument_expression_list_opt
%type <exp_ret> argument_expression_list
%type <exp_ret> const
%type <exp_ret> ID_assignment_expression
%type <string> parameter
%type <string> parameter_list
%type <string> parameter_list_opt
%type <exp_ret> function_declaration

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
    {
        if(lookup_symbol($2, scope_level) == -1){
            insert_symbol($1, $2, scope_level,1);
            //  ++variable_declare_count;
            // set_symbol_value($2, $4[0]);
            // set_symbol_type($1);
            if(scope_level==0){
                char tmp[16];
                gencode_function(".field public static ");
                gencode_function($2);
                gencode_function(" ");
                switch($1) {
                    case 1:
                        gencode_function("I = ");
                        sprintf(tmp, "%d\n", (int)$4[0]);
                        gencode_function(tmp);
                        break;
                    case 2:
                        gencode_function("F = ");
                        sprintf(tmp, "%f\n", (float)$4[0]);
                        gencode_function(tmp);
                        break;
                    case 3:
                        gencode_function("Z = ");
                        sprintf(tmp, "%d\n", (int)$4[0]);
                        gencode_function(tmp);
                        break;
                    case 4:
                        gencode_function("Ljava/lang/String; = \"");
                        gencode_function(STR_CONST_buf);
                        gencode_function("\"\n");
                        break;
                    case 5:
                        gencode_function("V = ");
                        sprintf(tmp, "%f\n", (float)$4[0]);
                        gencode_function(tmp);
                        break;
                    default:
                        gencode_function("V = ");
                }
            } else if(scope_level>0){
                char tmp[16];
                gencode_right_value_function($4);
                if($1 == 1 && $4[1] == 2)
                    gencode_function("f2i\n");
                else if($1 == 2 && $4[1] == 1)
                    gencode_function("i2f\n");
                switch($1) {
                    case 1:
                        sprintf(tmp, "istore %d\n",get_local_var_index($2,scope_level));
                        gencode_function(tmp);
                        break;
                    case 2:
                        sprintf(tmp, "fstore %d\n",get_local_var_index($2,scope_level));
                        gencode_function(tmp);
                        break;
                    case 3:
                        sprintf(tmp, "istore %d\n",get_local_var_index($2,scope_level));
                        gencode_function(tmp);
                        break;
                    case 4:
                        sprintf(tmp, "astore %d\n", get_local_var_index($2,scope_level));
                        gencode_function(tmp);
                        break;
                    case 5:
                        sprintf(tmp, "istore %d\n", get_local_var_index($2,scope_level));
                        gencode_function(tmp);
                        break;
                    default:
                        sprintf(tmp, "istore %d\n", get_local_var_index($2,scope_level));
                        gencode_function(tmp);
                }
            } else{
                printf("error pccur in declaration");
            }
        }
    }
    | type ID SEMICOLON
    {
        if(lookup_symbol($2, scope_level) == -1){
            insert_symbol($1, $2, scope_level,1);
            if(scope_level==0){
                char tmp[16];
                gencode_function(".field public static ");
                gencode_function($2);
                gencode_function(" ");
                switch($1) {
                    case 1:
                        gencode_function("I\n");
                        break;
                    case 2:
                        gencode_function("F\n");
                        break;
                    case 3:
                        gencode_function("Z\n");
                        break;
                    case 4:
                        gencode_function("Ljava/lang/String;\n");
                        break;
                    case 5:
                        gencode_function("V\n");
                        break;
                    default:
                        gencode_function("V\n");
                }
            }else{
                char tmp[16];
                switch($1) {
                    case 1:
                        gencode_function("ldc 0\n");
                        sprintf(tmp, "istore %d\n",get_local_var_index($2,scope_level));
                        gencode_function(tmp);
                        // sprintf(tmp, "%d\nistore 0", (int)$4[0]);
                        // gencode_function(tmp);
                        break;
                    case 2:
                        gencode_function("ldc 0.0\n");
                        sprintf(tmp, "fstore %d\n",get_local_var_index($2,scope_level));
                        gencode_function(tmp);
                        break;
                    default:
                        gencode_function("ldc 0.0\n");
                        sprintf(tmp, "fstore %d\n",get_local_var_index($2,scope_level));
                        gencode_function(tmp);
                }
            }
        }
    }
    | function_declaration LB parameter_list_opt RB SEMICOLON
;

function_definition
    : function_definition_1 compound_statement
    {
        if(return_goto_flag)
            gencode_labelcode_function(".end method\n");
        else
            gencode_function(".end method\n");
    }
;

function_definition_1
    : function_declaration LB parameter_list_opt RB
    {
        // $1[0] = type
        // $1[1] = ID symbol table index
        int index = $1[1];
        int type = $1[0];
        // printf("parameter %s\n",$3);
        // printf("index: %d; type: %d\n",index,type);
        strcpy(symbol_table[index].attribute,$3);
        switch(type) {
            case 1:
                gencode_function("I\n");
                break;
            case 2:
                gencode_function("F\n");
                break;
            case 3:
                gencode_function("Z\n");
                break;
            case 4:
                gencode_function("Ljava/lang/String;\n");
                break;
            case 5:
                gencode_function("V\n");
                break;
            default:
                gencode_function("V\n");
        }
        gencode_function(".limit stack 50\n");
        gencode_function(".limit locals 50\n");
    }
;

function_declaration
    : type ID
    {
        int tmp ;
        if( lookup_symbol($2, scope_level) == -1){
            tmp = insert_symbol($1, $2, scope_level,0);
            $$[0] = $1;//type
            $$[1] = tmp;//ID symbol table index
            $$[2] = 0;
            switch($1) {
                case 1:
                    function_return_type = 1;
                    break;
                case 2:
                    function_return_type = 2;
                    break;
                case 3:
                    function_return_type = 3;
                    break;
                case 4:
                    function_return_type = 4;
                    break;
                case 5:
                    function_return_type = 5;
                    break;
                default:
                    function_return_type = 1;
            }
            gencode_function(".method public static ");
            gencode_function($2);
            gencode_function("(");
        }
    }
;

parameter_list_opt
    : parameter_list
    {
        $$ = $1;
    }
    |
    {
        $$ = "";
        gencode_function("[Ljava/lang/String;)");
    }
;

parameter_list
    : parameter
    {
        gencode_function(")");
        $$ = $1;
    }
    | parameter_list COMMA parameter
    {
        $$  = strcat(strcat($1,", "),$3);
    }
;

parameter
    : type ID
    {
        insert_symbol($1, $2, scope_level+1,2);
        switch($1) {
            case 1:
                gencode_function("I");
                $$="int";
                break;
            case 2:
                gencode_function("F");
                $$="float";
                break;
            case 3:
                gencode_function("Z");
                $$="bool";
                break;
            case 4:
                gencode_function("Ljava/lang/String;");
                $$="string";
                break;
            case 5:
                gencode_function("V");
                $$="void";
                break;
            default:
                gencode_function("V");
        }

    }
;

initializer
    : assignment_expression
    {
        $$[0] = $1[0];
        $$[1] = $1[1];
        $$[2] = $1[2];
    }
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
    {

    }
    | expression_statement
    | iteration_block
    | jump_block
    | print_func
;

jump_block
    : CONT SEMICOLON
    | BREAK SEMICOLON
    | RET expression_opt SEMICOLON
    {
        if(function_return_type == 1)
            gencode_function("ireturn\n");
        else if(function_return_type==2)
            gencode_function("freturn\n");
    }
    | RET SEMICOLON
    {
        if(return_goto_flag&&!after_while_section_flag){
            // gencode_function("goto EXIT_0\n");
            // gencode_labelcode_function("EXIT_0:\n");
            gencode_labelcode_function("return\n");
            // gencode_function("EXIT_0:\nreturn\n");
        } else if(after_while_section_flag){
            gencode_function("return\n");
        } else{
            gencode_function("return\n");
        }
    }
;

expression_statement
    : expression_opt
;

WHILE_token
    : WHILE
    {
        gencode_function("LABEL_BEGIN:\n");
        while_flag = 1;
    }
;

iteration_block
    : WHILE_token LB expression RB statement
    {
    }
    | FOR LB expression_opt SEMICOLON expression_opt SEMICOLON expression_opt RB statement %prec LOWER_THAN_ELSE ;
    | FOR LB declaration SEMICOLON expression_opt SEMICOLON expression_opt RB statement
;

expression_opt
    : expression
    | SEMICOLON
    |
;

print_func
    : PRINT LB ID RB SEMICOLON
    {
        char tmp[16];
        int index = get_symbol_table_index($3);
        int scope = symbol_table[index].scope;
        // int index = get_local_var_index($3);
        int type;
        if(scope == 0){
            type = use_id_scope_get_type($3,0);
            gencode_function("getstatic compiler_hw3/");
            gencode_function($3);
            switch(type) {
                case 1:
                    gencode_function(" I\n");
                    break;
                case 2:
                    gencode_function(" F\n");
                    break;
                case 3:
                    gencode_function(" Z\n");
                    break;
                case 4:
                    gencode_function(" Ljava/lang/String;\n");
                    break;
                case 5:
                    gencode_function(" V\n");
                    break;
                default:
                    gencode_function(" V\n");
            }
        }
        else{
            int index = get_symbol_table_index($3);
            type = use_id_scope_get_type($3,scope);
            switch(type) {
                case 1:
                    gencode_function("i");
                    break;
                case 2:
                    gencode_function("f");
                    break;
                case 3:
                    gencode_function("i");
                    break;
                case 4:
                    gencode_function("a");
                    break;
                case 5:
                    gencode_function("i");
                    break;
                default:
                    gencode_function("i");
            }
            sprintf(tmp, "load %d\n",get_local_var_index($3,symbol_table[index].scope));
            gencode_function(tmp);
        }
        gencode_function("getstatic java/lang/System/out Ljava/io/PrintStream;\n");
        gencode_function("swap\n");
        gencode_function("invokevirtual java/io/PrintStream/println(");
        switch(type) {
            case 1:
                gencode_function("I");
                break;
            case 2:
                gencode_function("F");
                break;
            case 3:
                gencode_function("I");
                break;
            case 4:
                gencode_function("Ljava/lang/String;");
                break;
            case 5:
                gencode_function("V");
                break;
            default:
                gencode_function("V");
        }
        gencode_function(")V\n");
    }
    | PRINT LB STR_CONST RB SEMICOLON
    {
        char tmp[16];
        if(gencode_label_flag){
            gencode_labelcode_function("ldc ");
            sprintf(tmp,"\"%s\"\n",$3);
            gencode_labelcode_function(tmp);
            gencode_labelcode_function("getstatic java/lang/System/out Ljava/io/PrintStream;\n");
            gencode_labelcode_function("swap\n");
            gencode_labelcode_function("invokevirtual java/io/PrintStream/println(Ljava/lang/String;)V\n");
        } else{
            gencode_function("ldc ");
            sprintf(tmp,"\"%s\"\n",$3);
            gencode_function(tmp);
            gencode_function("getstatic java/lang/System/out Ljava/io/PrintStream;\n");
            gencode_function("swap\n");
            gencode_function("invokevirtual java/io/PrintStream/println(Ljava/lang/String;)V\n");
        }

    }
    | PRINT LB const RB SEMICOLON
    {
        char tmp[16];
        int type = $3[1];
        gencode_function("ldc ");
        switch(type) {
            case 1:
                sprintf(tmp, "%d\n", (int)$3[0]);
                break;
            case 2:
                sprintf(tmp, "%f\n", (float)$3[0]);
                break;
            case 3:
                sprintf(tmp, "%d\n", (int)$3[0]);
                break;
            default:
                sprintf(tmp, "%d\n", (int)$3[0]);
        }
        gencode_function(tmp);
        gencode_function("getstatic java/lang/System/out Ljava/io/PrintStream;\n");
        gencode_function("swap\n");
        if(type==1)
            gencode_function("invokevirtual java/io/PrintStream/println(I)V\n");
        if(type==2)
            gencode_function("invokevirtual java/io/PrintStream/println(F)V\n");
        if(type==3)
            gencode_function("invokevirtual java/io/PrintStream/println(I)V\n");
    }
;

ELSE_IF_statement
    : ELSE IF LB expression RB compound_statement ELSE_IF_statement
    {
        // printf("B\n");
    }
    | ELSE compound_statement
    {
        // printf("A\n");
        gencode_function("goto EXIT_0\n");
        gencode_labelcode_function("EXIT_0:\n");
    }
    ;

if_block
    : IF LB expression RB compound_statement
    {
        gencode_function("goto EXIT_0\n");
        gencode_labelcode_function("EXIT_0:\n");
        // printf("D\n");
    }
    | IF LB expression RB compound_statement ELSE_IF_statement
    {
        // printf("C\n");
    }
;

expression
    : assignment_expression
    {
        $$[0] = $1[0];
        $$[1] = $1[1];
        $$[2] = $1[2];
    }
    | expression COMMA assignment_expression
    {
        $$[0] = $1[0];
        $$[1] = $1[1];
        $$[2] = $1[2];
    }
;

argument_expression_list
    : assignment_expression
    {
        // int type = $1[1];
        // char tmp[16];
        // if(type==1){
        //     gencode_function("ldc ");
        //     sprintf(tmp,"%d\n",(int)$1[0]);
        //     gencode_function(tmp);
        // }
    }
    | argument_expression_list COMMA assignment_expression
;
// constant_expression
//     : conditional_expression
// ;
ID_assignment_expression
    : ID
    {
        if(lookup_symbol($1,scope_level) == -1)
            print_error("Undeclared variable ", $1);
        else{
            int type;
            // int entry_type;
            int index;
            for(int i = scope_level;i>=0;i--){
                index = lookup_symbol($1, i);
                // entry_type = symbol_table[index].entry_type;
                if( index != -1){
                    char *type_name = symbol_table[index].type_name;
                    // printf("id= %s\n",symbol_table[index].id);
                    // printf("type_name= %s\n",type_name);
                    // printf("Scope= %d\n",var_scope_level);
                    // printf("entry type= %d\n",entry_type);
                    if(!strcmp(type_name, "int")){
                        type = 1;
                    }else if(!strcmp(type_name, "float")){
                        type = 2;
                    }else if(!strcmp(type_name, "bool")){
                        type = 3;
                    }else if(!strcmp(type_name, "string")){
                        type = 4;
                    }else if(!strcmp(type_name, "void")){
                        type = 5;
                    }else{
                        type = 6;
                    }
                    break;
                }
            }
            $$[0] = -1;
            $$[1] = type;
            $$[2] = get_local_var_index($1,scope_level);;//var_index
        }
    }
;
assignment_expression
    : conditional_expression
    {
        $$[0] = $1[0];
        $$[1] = $1[1];
        $$[2] = $1[2];
    }
    | ID_assignment_expression assignment_operator assignment_expression
    {
        char tmp[16];
        int tmp3 = $3[1];
        if($2==0){
            gencode_function("istore ");
            sprintf(tmp,"%d\n",(int)$1[2]);
            gencode_function(tmp);
        } else if($2==4&&$3[0]==0){
            print_error("divide by zero", "");
        } else if($2==5&&((int)$1[1] != 1 || $3[1] != 1)){
            print_error("% with floating point operands", "");
        } else{
            switch((int)$1[1]) {
                case 1:
                    gencode_function("i");
                    break;
                case 2:
                    gencode_function("f");
                    break;
                case 3:
                    gencode_function("i");
                    break;
                case 4:
                    gencode_function("a");
                    break;
                case 5:
                    gencode_function("i");
                    break;
                default:
                    gencode_function("i");
            }
            sprintf(tmp, "load %d\n",(int)$1[2]);
            gencode_function(tmp);
            gencode_function("ldc ");
            switch(tmp3) {
                case 1:
                    sprintf(tmp, "%d\n", (int)$3[0]);
                    break;
                case 2:
                    sprintf(tmp, "%f\n", (float)$3[0]);
                    break;
                case 3:
                    sprintf(tmp, "%d\n", (int)$3[0]);
                    break;
                case 4:
                    gencode_function("Ljava/lang/String;\n");
                    break;
                case 5:
                    sprintf(tmp, "%f\n", (float)$3[0]);
                    break;
                default:
                    sprintf(tmp, "%f\n", (float)$3[0]);
            }
            gencode_function(tmp);
            if($1[1]==2||tmp3==2)
                gencode_function("f");
            else
                gencode_function("i");
            switch($2) {
                case 1:
                    gencode_function("add");
                    break;
                case 2:
                    gencode_function("sub");
                    break;
                case 3:
                    gencode_function("mul");
                    break;
                case 4:
                    gencode_function("div");
                    break;
                case 5:
                    gencode_function("rem");
                    break;
                default:
                    printf("dont know += -= ....");
            }
            gencode_function("\n");
            gencode_function("istore ");
            sprintf(tmp,"%d\n",(int)$1[2]);
            gencode_function(tmp);
        }

        $$[0] = $1[0];
        $$[1] = $1[1];
        $$[2] = $1[2];
    }
;

assignment_operator
    : ASGN
    {
        $$ = 0;
    }
    | ADDASGN { $$ = 1; }
    | SUBASGN { $$ = 2; }
    | MULASGN { $$ = 3; }
    | DIVASGN { $$ = 4; }
    | MODASGN { $$ = 5; }
;

conditional_expression
    : logical_OR_expression
    {
        $$[0] = $1[0];
        $$[1] = $1[1];
        $$[2] = $1[2];
    }
;

logical_OR_expression
    : logical_AND_expression
    {
        $$[0] = $1[0];
        $$[1] = $1[1];
        $$[2] = $1[2];
    }
    | logical_OR_expression OR logical_AND_expression
    {
        $$[0] = $1[0];
        $$[1] = $1[1];
        $$[2] = $1[2];
    }
;

logical_AND_expression
    : equality_expression
    {
        $$[0] = $1[0];
        $$[1] = $1[1];
        $$[2] = $1[2];
    }
    | logical_AND_expression AND equality_expression
    {
        $$[0] = $1[0];
        $$[1] = $1[1];
        $$[2] = $1[2];
    }
;

equality_expression
    : relational_expression
    {
        $$[0] = $1[0];
        $$[1] = $1[1];
        $$[2] = $1[2];
    }
    | equality_expression EQ relational_expression
    {
        // gencode_function("isub\n");
        char tmp[16];
        gencode_ADD_SUB_MUL_DIV_MOD_function($1,$3);
        if($1[1]==2 || $3[1]==2){
            gencode_function("fsub\n");
            gencode_function("f2i\n");
        } else{
            gencode_function("isub\n");
        }
        label_count++;
        sprintf(tmp,"ifeq LABEL_EQ%d\n",label_count);
        gencode_function(tmp);
        gencode_label_flag = 1;
        return_goto_flag = 1;
        sprintf(tmp,"LABEL_EQ%d:\n",label_count);
        gencode_function(tmp);
        if($1[0]==$3[0]){
            $$[0] = 1;
            $$[1] = 3;
            $$[2] = 1;
        } else{
            $$[0] = 0;
            $$[1] = 3;
            $$[2] = 1;
        }

    }
    | equality_expression NE relational_expression
    {
        char tmp[16];
        gencode_ADD_SUB_MUL_DIV_MOD_function($1,$3);
        if($1[1]==2 || $3[1]==2){
            gencode_function("fsub\n");
            gencode_function("f2i\n");
        } else{
            gencode_function("isub\n");
        }
        label_count++;
        sprintf(tmp,"ifeq LABEL_NE%d\n",label_count);
        gencode_function(tmp);
        gencode_label_flag = 1;
        return_goto_flag = 1;
        sprintf(tmp,"LABEL_NE%d:\n",label_count);
        gencode_function(tmp);
        if($1[0]!=$3[0]){
            $$[0] = 1;
            $$[1] = 3;
            $$[2] = 1;
        } else{
            $$[0] = 0;
            $$[1] = 3;
            $$[2] = 1;
        }

    }
;

relational_expression
    : additive_expression { $$[0] = $1[0];  $$[1] = $1[1]; $$[2] = $1[2];}
    | relational_expression MT additive_expression
    {
        char tmp[16];
        gencode_ADD_SUB_MUL_DIV_MOD_function($1,$3);
        if($1[1]==2 || $3[1]==2){
            gencode_function("fsub\n");
            gencode_function("f2i\n");
        } else{
            gencode_function("isub\n");
        }
        if(while_flag){
            gencode_function("ifgt LABEL_TRUE\n");
            gencode_function("goto LABEL_FALSE\n");
        } else{

            gencode_function("ifgt LABEL_GT\n");
            gencode_label_flag = 1;
            return_goto_flag = 1;
            gencode_labelcode_function("LABEL_GT:\n");
        }

        if($1[0]>$3[0]){
            $$[0] = 1;
            $$[1] = 3;
            $$[2] = 1;
        } else{
            $$[0] = 0;
            $$[1] = 3;
            $$[2] = 1;
        }

    }
    | relational_expression LT additive_expression
    {
        char tmp[16];
        gencode_ADD_SUB_MUL_DIV_MOD_function($1,$3);
        if($1[1]==2 || $3[1]==2){
            gencode_function("fsub\n");
            gencode_function("f2i\n");
        } else{
            gencode_function("isub\n");
        }

        if(while_flag){
            gencode_function("iflt LABEL_TRUE\n");
            gencode_function("goto LABEL_FALSE\n");
        } else{
            gencode_function("iflt LABEL_LT\n");
            gencode_label_flag = 1;
            return_goto_flag = 1;
            gencode_labelcode_function("LABEL_LT:\n");
        }
        if($1[0]<$3[0]){
            $$[0] = 1;
            $$[1] = 3;
            $$[2] = 1;
        } else{
            $$[0] = 0;
            $$[1] = 3;
            $$[2] = 1;
        }

    }
    | relational_expression MTE additive_expression
    {
        char tmp[16];
        gencode_ADD_SUB_MUL_DIV_MOD_function($1,$3);
        if($1[1]==2 || $3[1]==2){
            gencode_function("fsub\n");
            gencode_function("f2i\n");
        } else{
            gencode_function("isub\n");
        }

        if(while_flag){
            gencode_function("ifge LABEL_TRUE\n");
            gencode_function("goto LABEL_FALSE\n");
        } else{
            gencode_function("ifge LABEL_MTE\n");
            gencode_label_flag = 1;
            return_goto_flag = 1;
            gencode_labelcode_function("LABEL_MTE:\n");
        }
        if($1[0]>=$3[0]){
            $$[0] = 1;
            $$[1] = 3;
            $$[2] = 1;
        } else{
            $$[0] = 0;
            $$[1] = 3;
            $$[2] = 1;
        }

    }
    | relational_expression LTE additive_expression
    {
        char tmp[16];
        gencode_ADD_SUB_MUL_DIV_MOD_function($1,$3);
        if($1[1]==2 || $3[1]==2){
            gencode_function("fsub\n");
            gencode_function("f2i\n");
        } else{
            gencode_function("isub\n");
        }
        if(while_flag){
            gencode_function("ifle LABEL_TRUE\n");
            gencode_function("goto LABEL_FALSE\n");
        } else{
            gencode_function("ifle LABEL_LTE\n");
            gencode_label_flag = 1;
            return_goto_flag = 1;
            gencode_labelcode_function("LABEL_LTE:\n");
        }
        if($1[0]<=$3[0]){
            $$[0] = 1;
            $$[1] = 3;
            $$[2] = 1;
        } else{
            $$[0] = 0;
            $$[1] = 3;
            $$[2] = 1;
        }

    }
;

additive_expression
    : multiplicative_expression
    {
        $$[0] = $1[0];
        $$[1] = $1[1];
        $$[2] = $1[2];
    }
    | additive_expression ADD multiplicative_expression
    {
        gencode_ADD_SUB_MUL_DIV_MOD_function($1,$3);
        if($1[1]==2 || $3[1]==2){
            gencode_function("fadd\n");
        } else{
            gencode_function("iadd\n");
        }

        $$[0] = $1[0]+$3[0];
        $$[1] = ($1[1]==2 || $3[1]==2)? 2:1;;
        $$[2] = 2;

    }
    | additive_expression SUB multiplicative_expression
    {

        gencode_ADD_SUB_MUL_DIV_MOD_function($1,$3);
        if($1[1]==2 || $3[1]==2){
            gencode_function("fsub\n");
        } else{
            gencode_function("isub\n");
        }

        $$[0] = $1[0]-$3[0];
        $$[1] = ($1[1]==2 || $3[1]==2)? 2:1;;
        $$[2] = 2;
    }
;

multiplicative_expression
    : cast_expression
    {
        $$[0] = $1[0];
        $$[1] = $1[1];
        $$[2] = $1[2];
    }
    | multiplicative_expression MUL unary_expression
    {

        gencode_ADD_SUB_MUL_DIV_MOD_function($1,$3);
        if($1[1]==2 || $3[1]==2){
            gencode_function("fmul\n");
        } else{
            gencode_function("imul\n");
        }

        $$[0] = $1[0]*$3[0];
        $$[1] = ($1[1]==2 || $3[1]==2)? 2:1;
        $$[2] = 2;
    }
    | multiplicative_expression DIV unary_expression
    {
        if($3[0] == 0) {
            print_error("divide by zero", "");
            $$[0] = 0;
        }
        else{
            $$[0] = $1[0]/$3[0];
        }
        gencode_ADD_SUB_MUL_DIV_MOD_function($1,$3);
        if($1[1]==2 || $3[1]==2){
            gencode_function("fdiv\n");
        } else{
            gencode_function("idiv\n");
        }


        $$[1] = ($1[1]==2 || $3[1]==2)? 2:1;
        $$[2] = 2;
    }
    | multiplicative_expression MOD unary_expression
    {
        if ($1[1] != 1 || $3[1] != 1){
            print_error("% with floating point operands", "");
        }
        if($3[0] == 0) {
            print_error("Mod by Zero", "");
        }
        gencode_ADD_SUB_MUL_DIV_MOD_function($1,$3);
        if($1[1]==2 || $3[1]==2){
            gencode_function("frem\n");
        } else{
            gencode_function("irem\n");
        }

        $$[0] = (int)$1[0]%(int)$3[0];
        $$[1] = 1;
        $$[2] = 2;
    }
;

cast_expression
    : unary_expression { $$[0] = $1[0];  $$[1] = $1[1]; $$[2] = $1[2];}
    | LB type RB cast_expression { $$[0] = $4[0];  $$[1] = $2; $$[2] = 2;}
;

unary_expression
    : postfix_expression { $$[0] = $1[0];  $$[1] = $1[1]; $$[2] = $1[2];}
    | INC unary_expression { $$[0] = $2[0]+1;  $$[1] = $2[1]; $$[2] = $2[2];}
    | DEC unary_expression { $$[0] = $2[0]-1;  $$[1] = $2[1]; $$[2] = $2[2];}
    | unary_operator cast_expression { $$[0] = $2[0]*$1;  $$[1] = $2[1]; $$[2] = $2[2];}
;

unary_operator
    : ADD { $$ = 1; }
    | SUB { $$ = -1; }
    | NOT { $$ = 2; }
;

postfix_expression
    : primary_expression { $$[0] = $1[0];  $$[1] = $1[1]; $$[2] = $1[2];}
    | postfix_expression LB argument_expression_list_opt RB
    {
        char tmp[16];
        if((int)$3[1]==1&&(int)$3[0]!=10){
            gencode_function("ldc ");
            sprintf(tmp,"%d\n",(int)$3[0]);
            gencode_function(tmp);
        }else{
            //var
            // gencode_function("KK iload 0\n");
        }
        gencode_function("invokestatic compiler_hw3/");
        gencode_function(symbol_table[(int)$1[1]].id);
        gencode_function("(");
        if(!strcmp(symbol_table[(int)$1[1]].attribute, "int")){
            gencode_function("I");
        }else if(!strcmp(symbol_table[(int)$1[1]].attribute, "float")){
            gencode_function("F");
        }
        gencode_function(")");
        switch((int)$1[0]) {
            case 1:
                gencode_function("I\n");
                break;
            case 2:
                gencode_function("F\n");
                break;
            case 3:
                gencode_function("Z\n");
                break;
            default:
                gencode_function("V\n");
        }
        $$[0] = -1;
        $$[1] = (int)$1[0];
        $$[2] = 4;

        // printf("id = %s\n",symbol_table[(int)$1[1]].id);
        // printf("type= %d\n",(int)$1[0]);
    }
    | postfix_expression INC
    {
        gencode_function("ldc 1\niadd\n");
    }
    | postfix_expression DEC
    {
        gencode_function("ldc 1\nisub\n");
    }
;

argument_expression_list_opt
    : argument_expression_list
    |
    {
        $$[0] = 2000;
        $$[1] = 2000;
        $$[2] = 3000;
    }
;

primary_expression
    : STR_CONST
    {
        gencode_string_function($1);
        sprintf(STR_CONST_buf, "%s", $1);
        $$[0] = -1;
        $$[1] = 4;
        $$[2] = 3;
    }
    | ID
    {
        int found_flag = 0;
        int type;
        int var_scope_level;
        int entry_type;
        int index;
        char tmp[16];
        for(int i = scope_level;i>=0;i--){
            index = lookup_symbol($1, i);
            entry_type = symbol_table[index].entry_type;
            if( index != -1){
                char *type_name = symbol_table[index].type_name;
                var_scope_level = symbol_table[index].scope;
                entry_type = symbol_table[index].entry_type;
                // printf("id= %s\n",symbol_table[index].id);
                // printf("type_name= %s\n",type_name);
                // printf("Scope= %d\n",var_scope_level);
                // printf("entry type= %d\n",entry_type);
                if(!strcmp(type_name, "int")){
                    type = 1;
                }else if(!strcmp(type_name, "float")){
                    type = 2;
                }else if(!strcmp(type_name, "bool")){
                    type = 3;
                }else if(!strcmp(type_name, "string")){
                    type = 4;
                }else if(!strcmp(type_name, "void")){
                    type = 5;
                }else{
                    type = 6;
                }
                found_flag = 1;
                break;
            }
        }

        if(found_flag){
            // printf("entrytype: %d\n",entry_type);
            if(var_scope_level==0&&entry_type==1){
                gencode_function("getstatic compiler_hw3/");
                gencode_function($1);
                switch(type) {
                    case 1:
                        gencode_function(" I\n");
                        break;
                    case 2:
                        gencode_function(" F\n");
                        break;
                    case 3:
                        gencode_function(" Z\n");
                        break;
                    default:
                        gencode_function(" V\n");
                }
                $$[0] = 10;
                $$[1] = type;
                $$[2] = 0;
            }else if(entry_type==0){
                $$[0] = type;// function return type
                $$[1] = index;//id index
                $$[2] = 4;
            }else if(entry_type==1||entry_type==2){
                int index = get_symbol_table_index($1);

                switch(type) {
                    case 1:
                        gencode_function("iload ");
                        break;
                    case 2:
                        gencode_function("fload ");
                        break;
                    case 3:
                        gencode_function("iload ");
                        break;
                    default:
                        gencode_function("vload ");
                }
                sprintf(tmp,"%d\n",get_local_var_index($1,symbol_table[index].scope));
                gencode_function(tmp);
                $$[0] = 10;
                $$[1] = type;
                $$[2] = 5;
            }
        } else{
            printf("not found var!\n");
             $$[0] = 10;
             $$[1] = type;
             $$[2] = 0;
        }

    }
    | const
    {
        $$[0] = $1[0];
        $$[1] = $1[1];
        $$[2] = $1[2];
    }
    | LB expression RB
    {
        $$[0] = $2[0];
        $$[1] = $2[1];
        $$[2] = $2[2];
    }
;

const
    : I_CONST
    {
        // char tmp[16];
        // gencode_function("ldc ");
        // fprintf(tmp,"%d\n",$1);
        // gencode_function(tmp);
        $$[0] = $1;
        $$[1] = 1;
        $$[2] = 1;
    }
    | F_CONST{
        $$[0] = $1;
        $$[1] = 2;
        $$[2] = 1;
    }
    | TRUE
    {
        $$[0] = 1;
        $$[1] = 3;
        $$[2] = 1;
    }
    | FALSE
    {
        $$[0] = 0;
        $$[1] = 3;
        $$[2] = 1;
    }
;

lcb
    : LCB
    {
        scope_level++;
        if(while_flag==1)
            gencode_function("LABEL_TRUE:\n");
    }
;

rcb
    : RCB
    {
        dump_flag = scope_level;
        scope_level--;
        if(gencode_label_flag&&!while_flag){
            gencode_labelcode_function("goto EXIT_0\n");
            gencode_label_flag = 0;
        } else if(while_flag){
            gencode_function("goto LABEL_BEGIN\n");
            while_flag = 0;
            after_while_section_flag = 1;
            gencode_function("LABEL_FALSE:\ngoto EXIT_0\nEXIT_0:\n");
        }

    }
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
    var_no = 0;
    scope_level = 0;

    file = fopen("compiler_hw3.j","w");
    file_label = fopen("label.j","w");

    gencode_function(   ".class public compiler_hw3\n"
                        ".super java/lang/Object\n");

    // fprintf(file,   ".class public compiler_hw3\n"
    //                 ".super java/lang/Object\n"
    //                 ".method public static main([Ljava/lang/String;)V\n");

    yyparse();
    if(syntax_error_flag == 0){

        if(buf[0] != '\0'){
            printf("%d: %s\n", yylineno+1, buf);
            ++yylineno;
        }

    }
    dump_all();
    printf("\nTotal lines: %d \n",yylineno);

    // fprintf(file, "\treturn\n"
    //               ".end method\n");

    fclose(file);
    fclose(file_label);

    if(return_goto_flag){
        FILE *source, *file_main;
        char c;
        source = fopen("label.j","r");
        file_main =  fopen("compiler_hw3.j","a");
         // Read content from file
        c = fgetc(source);
        while (c != EOF){
            fputc(c,file_main);
            c = fgetc(source);
        }
        fclose(source);
        fclose(file_main);
    }

    return 0;
}

void yyerror(char *s)
{
    if(strstr(s, "syntax") != NULL)
        syntax_error_flag = 1;

    if(print_error_flag != 0){
        if(had_print_flag == 0){
            if(buf[0] == '\n')
                printf("%d:%s", yylineno, buf);
            else
                printf("%d: %s\n", yylineno+1, buf);
            had_print_flag = 1;
        }
        print_error_flag = 0;
        printf("\n|-----------------------------------------------|\n");
        if(syntax_error_flag == 1)
            printf("| Error found in line %d: %s\n", yylineno+1, buf);
        else
            printf("| Error found in line %d: %s", yylineno, buf);
        printf("| %s", error_buf);
        printf("\n|-----------------------------------------------|\n\n");
    }

    if(had_print_flag == 0 && syntax_error_flag == 1){
        if(buf[0] == '\n')
            printf("%d:%s", yylineno, buf);
        else
            printf("%d: %s\n", yylineno+1, buf);
        had_print_flag = 1;
    }

    printf("\n|-----------------------------------------------|\n");
    if(syntax_error_flag == 1)
        printf("| Error found in line %d: %s\n", yylineno+1, buf);
    else
        printf("| Error found in line %d: %s", yylineno, buf);
    printf("| %s", s);
    printf("\n|-----------------------------------------------|\n\n");

    fclose(file);
    fclose(file_label);
    remove("compiler_hw3.j");
    file_delete_flag = 1;
    if(syntax_error_flag == 1) exit(-1);
}

void print_error(char* msg, char* Name){
    sprintf(error_buf, "%s%s", msg, Name);
    print_error_flag = 1;
}

void print_error_after_line(){
    if(print_error_flag != 0){
        print_error_flag = 0;
        yyerror(error_buf);
    }
    print_error_flag = 0;
}

/* stmbol table functions */
void create_symbol() {
    printf("Create a symbol table \n");
}
int insert_symbol(int type, char* id, int scope_level, int entry_type) {

    if(var_no == 0){
        create_symbol();
    }
    switch(type) {
            case 1:
                strcpy(symbol_table[var_no].type_name,"int");
                break;
            case 2:
                strcpy(symbol_table[var_no].type_name,"float");
                break;
            case 3:
                strcpy(symbol_table[var_no].type_name,"bool");
                break;
            case 4:
                strcpy(symbol_table[var_no].type_name,"string");
                break;
            case 5:
                strcpy(symbol_table[var_no].type_name,"void");
                break;
            default:
                strcpy(symbol_table[var_no].type_name,"not");
    }
    strcpy(symbol_table[var_no].id,id);
    symbol_table[var_no].entry_type = entry_type;
    symbol_table[var_no].scope = scope_level;
    // if(entry_type==0)
    //     function_index = var_no;
    // printf("Insert %s\n",symbol_table[var_no].id);
    var_no++;
    return var_no-1;
}
int lookup_symbol(char* id, int scope) {
    int i;
    // if(check == 1){
        for(i = 0;i < var_no;i++){
            if(strcmp(symbol_table[i].id, id) == 0 && symbol_table[i].scope == scope){
                return i;
            }
        }
        return -1;
    // }
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
void dump_symbol(int scope) {
    int i;
    int j = 0;
    int flag = 0;
    char kind[10];
    for(i = 0;i < var_no;i++){
        if(symbol_table[i].scope == scope){
            if(!flag){
                printf("\n%-10s%-10s%-12s%-10s%-10s%-10s\n\n",
                    "Index", "Name", "Kind", "Type", "Scope", "Attribute");
                flag = 1;
            }
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
                printf("%-10d%-10s%-12s%-10s%-10d\n", j,symbol_table[i].id,kind,symbol_table[i].type_name,symbol_table[i].scope);
            else
                printf("%-10d%-10s%-12s%-10s%-10d%s\n", j,symbol_table[i].id,kind,symbol_table[i].type_name,symbol_table[i].scope,symbol_table[i].attribute);
            j += 1;
        }
    }
    if(flag)
        printf("\n");
    remove_symbol(scope);
}

int get_local_var_index(char* id,int scope){

    int i;
    int j = 0;

    for(i = 0;i < var_no;i++){
        if(symbol_table[i].scope == scope&&!strcmp(symbol_table[i].id, id)){
            return j;
        }
        if(symbol_table[i].scope == scope&&strcmp(symbol_table[i].id, id)){
            j = j+1;
        }
    }
    return -1;
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
            // symbol_table[i].type = 0;
            symbol_table[i].entry_type = 0;
            // symbol_table[i].forward = 0;
            temp++;
        }
    }
    var_no -= temp;
}
int get_symbol_table_index(char* id){
    for(int j = scope_level;j>=0;j--){
        for(int i = 0;i < var_no;i++){
            if(!strcmp(symbol_table[i].id,id)&&symbol_table[i].scope==j)
                return i;
        }
    }
    return -1;
}
int use_id_scope_get_type(char* id, int scope){
    int type,i,index;
    for(i = 0;i < var_no;i++){
        if(symbol_table[i].scope == scope&&!strcmp(symbol_table[i].id, id)){
            char *type_name = symbol_table[i].type_name;
            if(!strcmp(type_name, "int")){
                type = 1;
            }else if(!strcmp(type_name, "float")){
                type = 2;
            }else if(!strcmp(type_name, "bool")){
                type = 3;
            }else if(!strcmp(type_name, "string")){
                type = 4;
            }else if(!strcmp(type_name, "void")){
                type = 5;
            }else{
                type = 6;
            }
        }
    }
    return type;
}
/* code generation functions */
void gencode_function(char* codeline) {
    if(gencode_label_flag){
        gencode_labelcode_function(codeline);
    }
    else if(file_delete_flag == 0){
        fprintf(file, codeline);
    }

}

void gencode_labelcode_function(char* codeline){
    fprintf(file_label, codeline);
}

void gencode_string_function(char* codeline){
    if(scope_level > 0){
        gencode_function("ldc \"");
        gencode_function(codeline);
        gencode_function("\"\n");
    }
}

void gencode_right_value_function(float* nonterminal){
    if(nonterminal[2]==1){
        gencode_function("ldc ");
        char tmp[16];
        if(nonterminal[1] == 1 || nonterminal[1] == 3 || nonterminal[1] == 4){
            sprintf(tmp, "%d\n", (int)nonterminal[0]);
            gencode_function(tmp);
        }
        else if(nonterminal[1] == 2){
            sprintf(tmp, "%f\n", (float)nonterminal[0]);
            gencode_function(tmp);
        }
    }
}

void gencode_ADD_SUB_MUL_DIV_MOD_function(float* var1, float* var2){

    char tmp[16];
    int tmp1 = var2[2];
    int tmp2 = var1[2];
    int tmp3 = var2[1];
    int tmp4 = var1[1];
    if(tmp2==1){
        gencode_function("ldc ");
        switch(tmp4) {
            case 1:
                sprintf(tmp, "%d\n", (int)var1[0]);
                break;
            case 2:
                sprintf(tmp, "%f\n", (float)var1[0]);
                break;
            case 3:
                sprintf(tmp, "%d\n", (int)var1[0]);
                break;
            case 4:
                gencode_function("Ljava/lang/String;\n");
                break;
            case 5:
                sprintf(tmp, "%f\n", (float)var1[0]);
                break;
            default:
                sprintf(tmp, "%f\n", (float)var1[0]);
        }
        gencode_function(tmp);
        if(var1[1] == 1 && var2[1] == 2)
            gencode_function("i2f\n");
    } else if(tmp2==0){
        if(var1[1] == 1 && var2[1] == 2)
            gencode_function("i2f\n");
    } else if(tmp2==5){
        // gencode_function("swap\n");
        if(var1[1] == 1 && var2[1] == 2)
            gencode_function("i2f\n");
    }
    if(tmp1==1){
        gencode_function("ldc ");
        switch(tmp3) {
            case 1:
                sprintf(tmp, "%d\n", (int)var2[0]);
                break;
            case 2:
                sprintf(tmp, "%f\n", (float)var2[0]);
                break;
            case 3:
                sprintf(tmp, "%d\n", (int)var2[0]);
                break;
            case 4:
                gencode_function("Ljava/lang/String;\n");
                break;
            case 5:
                sprintf(tmp, "%f\n", (float)var2[0]);
                break;
            default:
                sprintf(tmp, "%f\n", (float)var2[0]);
        }
        gencode_function(tmp);
        if(var1[1] == 2 && var2[1] == 1)
            gencode_function("i2f\n");
    } else if(tmp1==0){
        if(var1[1] == 2 && var2[1] == 1)
            gencode_function("i2f\n");
    } else if(tmp1==5){
        // gencode_function("swap\n");
        if(var1[1] == 2 && var2[1] == 1)
            gencode_function("i2f\n");
    }
}

