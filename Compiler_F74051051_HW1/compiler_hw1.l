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

/* Define regular expression label */

letter [a-zA-Z]
digit [0-9]
id {letter}+({letter}|{digit})*
number {digit}+
C_PLUS_COMMENT     ("//".*)


/* Rules section */
%%

{C_PLUS_COMMENT}	{ printf("%s \t C++ Comment\n", yytext); ++no_of_comments; }
"/*"            	{ printf("%s", yytext); BEGIN COMMENT; }
<COMMENT>.      	{ printf("%s", yytext); }
<COMMENT>\n     	{ printf("%s", yytext); ++no_of_comments; ++no_of_lines; }
<COMMENT>"*/"   	{ 
						printf("%s", yytext);
						printf("\t C Comment\n");
						comment_newline = 1;
						BEGIN INITIAL;
                	}
"+" 				{ printf("%s \t ADD\n", yytext); }
"-"					{ printf("%s \t SUB\n", yytext); }
\n					{ number_of_lines(); }
{id}				{ printf("%s \t ID\n", yytext); }
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
// {letter}	{ printf("%s letter\n", yytext); count++; }
// .			{ printf("%s not letter\n", yytext); }
	yyin = fopen(argv[1],"r");
	yylex();
	// printf("number of letter %d\n",count);
	printf("\nParse over, the line number is %d.\n\n", no_of_lines);
	printf("comment: %d lines\n\n",no_of_comments);

	return 0;
}
