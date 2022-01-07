%{
#include <stdio.h>
#include <string.h>
#include "sym.h"
#include "ast.h"

int yylex(void);
void yyerror(const char*);

SymTable symtable;
SymTable* curr_symtable;
Sym* search_sym(char* name, SymTable* table, int search_parents);
Sym* add_sym(char* name, SymType type);
SymTable* scoped_symtable(void);

AST* root;
AST* new_ast(Token token, AST* l_op, AST* r_op);
void free_ast(AST* ast);
%}

%union {
	char* ident;
	char* literal;
	AST* parse;
}
%destructor { free_ast($$); } <parse>
%destructor { free($$); } <*>

%token BLANK NEWLINE COMMA COLON
%token LPAREN RPAREN
%token VAR READ WRITE BEGINBLK ENDBLK IF THEN ELSE WHILE DO FUNCTION RETURN
%token PLUS MINUS MULT REAL_DIV INT_DIV MOD
%token UNPLUS UNMINUS
%token EQ GT GE LT LE NE AND OR NOT ASSIGNEQ

%left PLUS MINUS
%left MULT REAL_DIV INT_DIV MOD
%left AND OR
%precedence UNPLUS UNMINUS NOT
%precedence THEN
%precedence ELSE

%token COMMENT TYPE
%token <ident> IDENT
%token <literal> LITERAL

%type <parse> expr identlist identlist_tail exprlist exprlist_tail stmtlist stmtlist_tail stmt function program_tail program_head program
%start program

%%
expr:
	LPAREN expr RPAREN { $$ = $2; }
	| expr PLUS expr {
		$$ = new_ast(BinPlusOp, $1, $3);
		if ($$ == NULL) YYNOMEM;
	}
	| expr MINUS expr {
		$$ = new_ast(BinMinusOp, $1, $3);
		if ($$ == NULL) YYNOMEM;
	}
	| expr MULT expr {
		$$ = new_ast(BinMultOp, $1, $3);
		if ($$ == NULL) YYNOMEM;
	}
	| expr REAL_DIV expr {
		$$ = new_ast(BinRealDivOp, $1, $3);
		if ($$ == NULL) YYNOMEM;
	}
	| expr INT_DIV expr {
		$$ = new_ast(BinIntDivOp, $1, $3);
		if ($$ == NULL) YYNOMEM;
	}
	| expr MOD expr {
		$$ = new_ast(BinModOp, $1, $3);
		if ($$ == NULL) YYNOMEM;
	}
	| expr EQ expr {
		$$ = new_ast(BinEqOp, $1, $3);
		if ($$ == NULL) YYNOMEM;
	}
	| expr GT expr {
		$$ = new_ast(BinGtOp, $1, $3);
		if ($$ == NULL) YYNOMEM;
	}
	| expr GE expr {
		$$ = new_ast(BinGeOp, $1, $3);
		if ($$ == NULL) YYNOMEM;
	}
	| expr LT expr {
		$$ = new_ast(BinLtOp, $1, $3);
		if ($$ == NULL) YYNOMEM;
	}
	| expr LE expr {
		$$ = new_ast(BinLeOp, $1, $3);
		if ($$ == NULL) YYNOMEM;
	}
	| expr NE expr {
		$$ = new_ast(BinNeOp, $1, $3);
		if ($$ == NULL) YYNOMEM;
	}
	| expr AND expr {
		$$ = new_ast(BinAndOp, $1, $3);
		if ($$ == NULL) YYNOMEM;
	}
	| expr OR expr {
		$$ = new_ast(BinOrOp, $1, $3);
		if ($$ == NULL) YYNOMEM;
	}
	| PLUS expr %prec UNPLUS {
		$$ = new_ast(UnPlusOp, $2, NULL);
		if ($$ == NULL) YYNOMEM;
	}
	| MINUS expr %prec UNMINUS {
		$$ = new_ast(UnMinusOp, $2, NULL);
		if ($$ == NULL) YYNOMEM;
	}
	| NOT expr {
		$$ = new_ast(UnNotOp, $2, NULL);
		if ($$ == NULL) YYNOMEM;
	}
	| IDENT LPAREN exprlist RPAREN {
		$$ = new_ast(FnCall, $3, NULL);
		if ($$ == NULL) YYNOMEM;
		$$->sym = search_sym($1, curr_symtable, 1);
		if ($$->sym = NULL) {
			yyerror("Undefined function");
			YYERROR;
		}
	}
	| IDENT {
		$$ = new_ast(IdentToken, NULL, NULL);
		if ($$ == NULL) YYNOMEM;
		$$->sym = search_sym($1, curr_symtable, 1);
		if ($$->sym == NULL) {
			yyerror("Undeclared identifier");
			YYERROR;
		}
	}
	| LITERAL {
		$$ = new_ast(LiteralToken, NULL, NULL);
		if ($$ == NULL) YYNOMEM;
		$$->sym = add_sym($1, LiteralSym);
		if ($$->sym == NULL) YYNOMEM;
	};

identlist_tail:
	COMMA IDENT identlist_tail {
		AST* ident_ast = new_ast(IdentToken, NULL, NULL);
		$$ = new_ast(IdentList, ident_ast, $3);
		if ($$ == NULL) YYNOMEM;
		ident_ast->sym = add_sym($2, IdentSym);
		if (ident_ast->sym == NULL) YYNOMEM;
	}
	| { $$ = NULL; };
identlist: 
	IDENT identlist_tail {
		AST* ident_ast = new_ast(IdentToken, NULL, NULL);
		$$ = new_ast(IdentList, ident_ast, $2);
		if ($$ == NULL) YYNOMEM;
		ident_ast->sym = add_sym($1, IdentSym);
		if (ident_ast->sym == NULL) YYNOMEM;
	}
	| { 
		$$ = new_ast(IdentList, NULL, NULL);
		if ($$ == NULL) YYNOMEM;
	};

exprlist_tail:
	COMMA expr exprlist_tail {
		$$ = new_ast(ExprList, $2, $3);
		if ($$ == NULL) YYNOMEM;
	}
	| { $$ = NULL; };
exprlist: 
	expr exprlist_tail {
		$$ = new_ast(ExprList, $1, $2);
		if ($$ == NULL) YYNOMEM;
	}
	| {
		$$ = new_ast(ExprList, NULL, NULL);
		if ($$ == NULL) YYNOMEM;
	};

stmtlist_tail:
	NEWLINE stmt stmtlist_tail {
		if ($2 == NULL) {
			$$ = $3;
		} else {
			$$ = new_ast(StmtList, $2, $3);
			if ($$ == NULL) YYNOMEM;
		}
	}
	| NEWLINE ENDBLK { $$ = NULL; };
stmtlist: BEGINBLK NEWLINE stmt stmtlist_tail {
	if ($3 == NULL) {
		$$ = $4;
	} else {
		$$ = new_ast(StmtList, $3, $4);
		if ($$ == NULL) YYNOMEM;
	}
};

stmt:
	stmtlist { $$ = $1; }
	| VAR identlist COLON TYPE {
		AST* type_ast = new_ast(Type, NULL, NULL);
		$$ = new_ast(Declaration, $2, type_ast);
		if ($$ == NULL) YYNOMEM;
	}
	| IDENT ASSIGNEQ expr {
		AST* ident_ast = new_ast(IdentToken, NULL, NULL);
		$$ = new_ast(Assign, ident_ast, $3);
		if ($$ == NULL) YYNOMEM;
		$$->sym = search_sym($1, curr_symtable, 1);
		if ($$->sym == NULL) {
			yyerror("Undeclared identifier");
			YYERROR;
		}
	}
	| READ LPAREN expr COMMA IDENT RPAREN {
		AST* ident_ast = new_ast(IdentToken, NULL, NULL);
		$$ = new_ast(Read, $3, ident_ast);
		if ($$ == NULL) YYNOMEM;
		$$->sym = search_sym($5, curr_symtable, 1);
		if ($$->sym == NULL) {
			yyerror("Undeclared identifier");
			YYERROR;
		}
	}
	| WRITE LPAREN exprlist RPAREN {
		$$ = new_ast(Write, $3, NULL);
		if ($$ == NULL) YYNOMEM;
	}
	| IF expr THEN stmt ELSE stmt {
		AST* else_ast = new_ast(Else, $4, $6);
		$$ = new_ast(If, $2, else_ast);
		if ($$ == NULL) YYNOMEM;
	}
	| IF expr THEN stmt {
		$$ = new_ast(If, $2, $4);
		if ($$ == NULL) YYNOMEM;
	}
	| WHILE expr DO stmt {
		$$ = new_ast(While, $2, $4);
		if ($$ == NULL) YYNOMEM;
	}
	| RETURN expr {
		if (curr_symtable == &symtable) {
			yyerror("Return statement outside function");
			YYERROR;
		}
		$$ = new_ast(Return, $2, NULL);
		if ($$ == NULL) YYNOMEM;
	}
	| COMMENT { $$ = NULL; }
	| { $$ = NULL; };

function: FUNCTION IDENT LPAREN {
	curr_symtable = scoped_symtable();
} identlist RPAREN COLON TYPE stmtlist {
	$$ = new_ast(Function, $5, $9);
	if ($$ == NULL) YYNOMEM;
	$$->sym = add_sym($2, IdentSym);
	$$->sym->scoped = curr_symtable;
	if ($$->sym == NULL || $$->sym->scoped == NULL) YYNOMEM;
	curr_symtable = &symtable;
};

program_tail:
	NEWLINE stmt program_tail {
		if ($2 == NULL) {
			$$ = $3;
		} else {
			$$ = new_ast(StmtList, $2, $3);
			if ($$ == NULL) YYNOMEM;
		}
	}
	| NEWLINE function program_tail {
		$$ = new_ast(StmtList, $2, $3);
		if ($$ == NULL) YYNOMEM;
	}
	| NEWLINE program_tail { $$ = $2; }
	| { $$ = NULL; };
program_head:
	stmt program_tail {
		if ($1 == NULL) {
			$$ = $2;
		} else {
			$$ = new_ast(StmtList, $1, $2);
			if ($$ == NULL) YYNOMEM;
		}
	}
	| function program_tail {
		$$ = new_ast(StmtList, $1, $2);
		if ($$ == NULL) YYNOMEM;
	}
	| program_tail { $$ = $1; };
program: program_head {
	root = $$ = $1;
	YYACCEPT;
};
%%

Sym* search_sym(char* name, SymTable* table, int search_parents) {
	int i;
	for (i = table->len - 1; i >= 0; i--) {
		Sym* sym = &table->table[i];
		if (strcmp(sym->name, name) == 0) {
			return sym;
		}
	}
	if (search_parents && table->parent != NULL) {
		return search_sym(name, table->parent, search_parents);
	} else {
		return NULL;
	}
}
Sym* add_sym(char* name, SymType type) {
	Sym* sym;
	if (type == LiteralSym) {
		sym = search_sym(name, curr_symtable, 1);
	} else {
		sym = search_sym(name, curr_symtable, 0);
	}
	if (sym == NULL) {
		if (curr_symtable->len >= SYMTABLE_SIZE) {
			return NULL;
		} else {
			sym = &curr_symtable->table[curr_symtable->len++];
			char* namecpy = (char*) malloc(sizeof(name) + 1);
			sym->name = strcpy(namecpy, name);
		}
	}
	sym->type = type;
	return sym;
}
SymTable* scoped_symtable(void) {
	return (SymTable*) malloc(sizeof(SymTable));
}

AST* new_ast(Token token, AST* l_op, AST* r_op) {
	AST* newast = (AST*) malloc(sizeof(AST));
	newast->token = token;
	newast->l_op = l_op;
	newast->r_op = r_op;
	return newast;
}
void free_ast(AST* ast) {
	if (ast != NULL) {
		if (ast->l_op != NULL) free_ast(ast->l_op);
		if (ast->r_op != NULL) free_ast(ast->r_op);
		free(ast);
	}
}

void yyerror(const char* s) {
	fprintf(stderr, "%s\n", s);
}
int yywrap(void) {
	return 1;
}
int main(void) {
#if YYDEBUG
	extern int yydebug;
	yydebug = 1;
#endif

	curr_symtable = &symtable;
	return yyparse();
}
