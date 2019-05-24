CC=gcc
YFLAG=-d -v
FNAME=compiler_hw2
EXE=myparser

compile: scanner parser
	${CC} lex.yy.c y.tab.c -o ${EXE}

scanner:
	lex ${FNAME}.l

parser: 
	yacc ${YFLAG} ${FNAME}.y

test: compile
	./${EXE} < input/zero_error.c > ans1.out
	./${EXE} < input/syntactic_error.c > ans2.out
	./${EXE} < input/semantic_error.c > ans3.out

clean:
	rm ${EXE} y.tab* lex.* y.output

