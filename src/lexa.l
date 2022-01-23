%{
#include <stdio.h>
#include <string.h>
#include "ast.h"
#include "y.tab.h"
%}

letter [a-zA-Z]
digit [0-9]

comment \{[^}]*\}
ident {letter}({letter}|{digit}|"_")*
type "integer"|"real"|"boolean"|"char"|"string"

number {digit}+("."{digit}+)?("e"[+-]?{digit}+)?
bool "true"|"false"
char '[^']'
string \"[^"]*\"
literal {number}|{bool}|{char}|{string}

%%
{comment}	return COMMENT;

"\n"	return NEWLINE;
","	return COMMA;
":"	return COLON;
"("	return LPAREN;
")"	return RPAREN;
"var"	return VAR;
"read"	return READ;
"write"	return WRITE;
"begin"	return BEGINBLK;
"end"	return ENDBLK;
"if"	return IF;
"then"	return THEN;
"else"	return ELSE;
"while"	return WHILE;
"do"	return DO;
"function"	return FUNCTION;
"return"	return RETURN;
"+"	return PLUS;
"-"	return MINUS;
"*"	return MULT;
"/"	return REAL_DIV;
"div"	return INT_DIV;
"mod"	return MOD;
"="	return EQ;
">"	return GT;
">="	return GE;
"<"	return LT;
"<="	return LE;
"<>"	return NE;
"and"	return AND;
"or"	return OR;
"not"	return NOT;
":="	return ASSIGNEQ;

{type}	{
	char* yytextcpy = malloc(sizeof(yytext) + 1);
	yylval.type = strcpy(yytextcpy, yytext);
	return TYPE;
}
{ident}	{
	char* yytextcpy = malloc(sizeof(yytext) + 1);
	yylval.ident = strcpy(yytextcpy, yytext);
	return IDENT;
};
{literal}	{
	char* yytextcpy = malloc(sizeof(yytext) + 1);
	yylval.literal = strcpy(yytextcpy, yytext);
	return LITERAL;
};
%%
