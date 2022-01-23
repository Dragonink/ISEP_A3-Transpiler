%{
#include <stdio.h>
#include <string.h>
#include "sym.h"
#include "ast.h"

int yylex(void);
void yyerror(const char*);

static SymTable symtable;
static SymTable* curr_symtable;
ValType get_valtype(const char* s);
Sym* search_sym(const char* name, SymTable* table);
Sym* add_sym(const char* name, SymType type);
SymTable* scoped_symtable(void);

static AST* root;
AST* new_ast(Token token, AST* l_op, AST* r_op);
void free_ast(AST* ast);
%}

%union {
	char* type;
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

%token COMMENT 
%token <type> TYPE
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
		$$->sym = search_sym($1, curr_symtable);
		if ($$->sym == NULL) {
			yyerror("Undefined function");
			YYERROR;
		}
	}
	| IDENT {
		$$ = new_ast(IdentToken, NULL, NULL);
		if ($$ == NULL) YYNOMEM;
		$$->sym = search_sym($1, curr_symtable);
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
		if ($2 != NULL) {
			AST* ast = $2;
			ValType valtype = get_valtype($4);
			while (ast != NULL) {
				ast->l_op->sym->valtype = valtype;
				ast = ast->r_op;
			}
		}
	}
	| IDENT ASSIGNEQ expr {
		AST* ident_ast = new_ast(IdentToken, NULL, NULL);
		$$ = new_ast(Assign, ident_ast, $3);
		if ($$ == NULL) YYNOMEM;
		ident_ast->sym = search_sym($1, curr_symtable);
		if (ident_ast->sym == NULL) {
			yyerror("Undeclared identifier");
			YYERROR;
		}
	}
	| READ LPAREN expr COMMA IDENT RPAREN {
		AST* ident_ast = new_ast(IdentToken, NULL, NULL);
		$$ = new_ast(Read, $3, ident_ast);
		if ($$ == NULL) YYNOMEM;
		ident_ast->sym = search_sym($5, curr_symtable);
		if (ident_ast->sym == NULL) {
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
	SymTable* ref_curr_symtable = curr_symtable;
	curr_symtable = curr_symtable->parent;
	$$->sym = add_sym($2, IdentSym);
	$$->sym->scoped = ref_curr_symtable;
	if ($$->sym == NULL || $$->sym->scoped == NULL) YYNOMEM;
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

ValType get_valtype(const char* s) {
	if (strcmp(s, "integer") == 0) return Integer;
	else if (strcmp(s, "real") == 0) return Real;
	else if (strcmp(s, "boolean") == 0) return Boolean;
	else if (strcmp(s, "char") == 0) return Char;
	else return String;
}

Sym* search_sym(const char* name, SymTable* table) {
	for (int i = table->len - 1; i >= 0; i--) {
		Sym* sym = &table->table[i];
		if (strcmp(sym->name, name) == 0) {
			return sym;
		}
	}
	if (table->parent != NULL) {
		return search_sym(name, table->parent);
	} else {
		return NULL;
	}
}
Sym* add_sym(const char* name, SymType symtype) {
	Sym* sym = search_sym(name, curr_symtable);
	if (sym == NULL) {
		if (curr_symtable->len >= SYMTABLE_SIZE) {
			return NULL;
		} else {
			sym = &curr_symtable->table[curr_symtable->len++];
			char* namecpy = malloc(strlen(name) + 1);
			sym->name = strcpy(namecpy, name);
		}
	}
	sym->symtype = symtype;
	return sym;
}
SymTable* scoped_symtable(void) {
	SymTable* subtable = malloc(sizeof(SymTable));
	subtable->parent = curr_symtable;
	return subtable;
}

AST* new_ast(Token token, AST* l_op, AST* r_op) {
	AST* newast = malloc(sizeof(AST));
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
int main(int argc, char* argv[]) {
#if YYDEBUG
	extern int yydebug;
	yydebug = 1;
#endif

	curr_symtable = &symtable;
	add_sym("abs", IdentSym);
	add_sym("exp", IdentSym);
	add_sym("log", IdentSym);
	add_sym("pow", IdentSym);
	add_sym("sqrt", IdentSym);
	add_sym("floor", IdentSym);
	add_sym("ceil", IdentSym);

	int ret = yyparse();
	if (ret > 0) return ret;
	else {
		char* py = "from math import exp, log, pow, sqrt, floor, ceil\n";
		const char* transpiled = transpile(root, 0);
		py = strconcat(py, transpiled);
		FILE* f = fopen(argv[1], "w");
		fputs(py, f);
		fclose(f);
	}
}
