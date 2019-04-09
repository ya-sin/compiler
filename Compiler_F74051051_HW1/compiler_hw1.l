/* Definition section */
%{
	#include <stdio.h>
	#include <stdlib.h>
	#include <stdbool.h>

	// variable
	int count = 0;
	int no_of_lines = 0;
	int no_of_comments = 0;
	bool comment_newline = 0;

	// function
	void number_of_lines();
%}
/* start condition */
%x COMMENT
%x STRING

/* Define regular expression label */

letter [a-zA-Z]
digit [0-9]
id {letter}+({letter}|{digit})*
number {digit}+
C_PLUS_COMMENT     ("//".*)
FLOAT               ([0-9]+.[0-9]+)
INTEGER             ([0-9]+)


/* Rules section */
%%
	/* ignore all spaces */ 
[ \t\r\a]+          {             }

	/* Comment */
{C_PLUS_COMMENT}	{ printf("%s \t C++ Comment\n", yytext); ++no_of_comments; }
"/*"            	{ printf("%s", yytext); BEGIN COMMENT; }
<COMMENT>.      	{ printf("%s", yytext); }
<COMMENT>\n     	{ printf("%s", yytext); ++no_of_comments; ++no_of_lines; }
<COMMENT>"*/"   	{ 
						printf("%s", yytext);
						printf(" \t C Comment\n");
						comment_newline = 1;
						BEGIN INITIAL;
                	}

	/* Delimiters */
"("						{ printf("%s \t LB\n", yytext); }
")"						{ printf("%s \t RB\n", yytext); }
"{"						{ printf("%s \t LCB\n", yytext); }
"}"						{ printf("%s \t RCB\n", yytext); }
"["						{ printf("%s \t LSB\n", yytext); }
"]"						{ printf("%s \t RSB\n", yytext); }
";"						{ printf("%s \t SEMICOLON\n", yytext); }
","						{ printf("%s \t COMMA\n", yytext); }
"\042"					{ printf("%s \t QUOTA\n", yytext); BEGIN STRING; }
<STRING>[ \t\r\a\n]+		{	}
<STRING>[^\042]*    	{ printf("%s \t STR_CONST\n", yytext); }
<STRING>"\042"   		{ 
							printf("%s \t QUOTA\n", yytext);
							BEGIN INITIAL;
                		}
\n						{ number_of_lines(); }

	/* Arithmetic, Relational, and Logical Operators */
"+" 				{ printf("%s \t ADD\n", yytext); }
"-"					{ printf("%s \t SUB\n", yytext); }
"*"					{ printf("%s \t MUL\n", yytext); }
"/"					{ printf("%s \t DIV\n", yytext); }
"%"					{ printf("%s \t MOD\n", yytext); }
"++" 				{ printf("%s \t INC\n", yytext); }
"--" 				{ printf("%s \t DEC\n", yytext); }

"<" 				{ printf("%s \t LT\n", yytext); }
">"					{ printf("%s \t MT\n", yytext); }
"<="				{ printf("%s \t LTE\n", yytext); }
">="				{ printf("%s \t MTE\n", yytext); }
"=="				{ printf("%s \t EQ\n", yytext); }
"!=" 				{ printf("%s \t NE\n", yytext); }

"=" 				{ printf("%s \t ASGN\n", yytext); }
"+="				{ printf("%s \t ADDASGN\n", yytext); }
"-="				{ printf("%s \t SUBASGN\n", yytext); }
"*="				{ printf("%s \t MULASGN\n", yytext); }
"/="				{ printf("%s \t DIVASGN\n", yytext); }
"%=" 				{ printf("%s \t MODASGN\n", yytext); }

"&&" 				{ printf("%s \t AND\n", yytext); }
"||"				{ printf("%s \t OR\n", yytext); }
"!"					{ printf("%s \t NOT\n", yytext); }

	/* Keywords */
"int" 				{ printf("%s \t INT\n", yytext); }
"float"				{ printf("%s \t FLOAT\n", yytext); }
"bool"				{ printf("%s \t BOOL\n", yytext); }
"string"				{ printf("%s \t STRING\n", yytext); }
"void"				{ printf("%s \t VOID\n", yytext); }
"print" 			{ printf("%s \t PRINT\n", yytext); }
"if" 				{ printf("%s \t IF\n", yytext); }
"else"				{ printf("%s \t ELSE\n", yytext); }
"for"				{ printf("%s \t FOR\n", yytext); }
"while"				{ printf("%s \t WHILE\n", yytext); }
"true"				{ printf("%s \t TRUE\n", yytext); }
"false" 			{ printf("%s \t FALSE\n", yytext); }
"return"			{ printf("%s \t RET\n", yytext); }
"continue"			{ printf("%s \t CONT\n", yytext); }
"break" 			{ printf("%s \t BREAK\n", yytext); }
{id}				{ printf("%s \t ID\n", yytext); }

	/* Constants */
{INTEGER}			{ printf("%s \t I_CONST\n", yytext); }
{FLOAT}				{ printf("%s \t F_CONST\n", yytext); }

<<EOF>>     		{ return 0; }


%%

/*	C Code section */
int yywrap(void)
{
    return 1;
}

void number_of_lines(){
	if(comment_newline){
		++no_of_comments;
		comment_newline = 0;
	}
	++no_of_lines;

}

int main(int argc,char *argv[])
{
	yyin = fopen(argv[1],"r");
	yylex();
	// printf("number of letter %d\n",count);
	printf("\nParse over, the line number is %d.\n\n", no_of_lines);
	printf("comment: %d lines\n\n",no_of_comments);

	return 0;
}
