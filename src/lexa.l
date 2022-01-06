%{
#include <stdio.h>
#include <string.h>
#include "sym.h"
#include "ast.h"
#include "y.tab.h"

SymType symtype_from_str(char*);
%}

blank [ \t]
comment \{[^}]*\}

letter [a-zA-Z]
digit [0-9]
ident {letter}({letter}|{digit}|_)*

type integer|real|boolean|char|string
declaration var{blank}+{ident}(","{blank}*{ident})*{blank}*":"{blank}*{type}

number {digit}+("."{digit}+)?(e[+-]?{digit}+)?
bool true|false
char '[^']'
string \"[^"]*\"
literal {number}|{bool}|{char}|{string}
value {ident}|{literal}
unop "+"|"-"|not
biop "+"|"-"|"*"|"/"|div|mod|"="|"<"|"<="|">"|">="|"<>"|and|or
expr {value}|{unop}{blank}*{value}|{value}{blank}*{biop}{blank}*{value}

assign {ident}{blank}*:={blank}*({expr}|{call})
read read"("{blank}*{string}{blank}*","{blank}*{ident}{blank}*")"
write write"("{blank}*{string}{blank}*(","{blank}*{expr}{blank}*)?")"
stmt {blank}*|{comment}|{declaration}|{assign}|{read}|{write}
block begin{blank}*\n({blank}*{stmt}{blank}*\n)*{blank}*end
if if{blank}+{expr}{blank}+then{blank}+{block}({blank}+else{blank}+{block})?
while while{blank}+{expr}{blank}+do{blank}+{block}
instr {stmt}|{if}|{while}

fn function{blank}+{ident}"("{blank}*({ident}(","{blank}*{ident})*)?{blank}*")"{blank}*":"{blank}*{type}{blank}*\n({blank}*{instr}{blank}*\n)*{blank}*return{blank}+{expr}
call {ident}"("{blank}*({expr}(","{blank}*{expr})*)?{blank}*")"

program ({blank}*({instr}|{fn}){blank}*\n)*

%%
","	return COMMA;
":"	return COLON;
"("	return LPAREN;
")"	return RPAREN;
"var"	return VAR;

{comment}	return COMMENT;
{type}	{
	yylval.type = symtype_from_str(yytext);
	return TYPE;
};
{ident}	{
	char* yytextcpy = (char*) malloc(sizeof(yytext) + 1);
	yylval.ident = strcpy(yytextcpy, yytext);
	return IDENT;
};
%%

SymType symtype_from_str(char* s) {
	if (strcmp(s, "integer") == 0) {
		return Integer;
	} else if (strcmp(s, "real") == 0) {
		return Real;
	} else if (strcmp(s, "boolean") == 0) {
		return Boolean;
	} else if (strcmp(s, "char") == 0) {
		return Char;
	} else if (strcmp(s, "string") == 0) {
		return String;
	} else {
		return _error;
	}
}
