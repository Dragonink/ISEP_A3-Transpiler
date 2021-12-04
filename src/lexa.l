%{
#include <stdio.h>
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
{comment}	printf("COMMENT");

{declaration}	printf("DECLARATION");

{value}	printf("VALUE");
{expr}	printf("EXPRESSION");

{assign}	printf("ASSIGN");
{read}	printf("READ");
{write}	printf("WRITE");
{block} printf("BLOCK");
{if} printf("IF BLOCK");
{while} printf("WHILE BLOCK");

{fn}	printf("FUNCTION");

{program}	printf("PROGRAM");
%%
