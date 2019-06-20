.class public compiler_hw3
.super java/lang/Object
.method public static main([Ljava/lang/String;)V
.limit stack 50
.limit locals 50
ldc 40
istore 0
iload 0
ldc 40
isub
ifeq LABEL_EQ1
ldc 666
getstatic java/lang/System/out Ljava/io/PrintStream;
swap
invokevirtual java/io/PrintStream/println(I)V
goto EXIT_0
LABEL_EQ1:
ldc "a is equal to 40"
getstatic java/lang/System/out Ljava/io/PrintStream;
swap
invokevirtual java/io/PrintStream/println(Ljava/lang/String;)V
goto EXIT_0
EXIT_0:
return
.end method
