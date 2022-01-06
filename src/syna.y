%{
#define SYMTABLE_SIZE 1024

#include <stdio.h>
#include <string.h>
#include "sym.h"
#include "ast.h"

int yylex(void);
void yyerror(const char*);

Sym symtable[SYMTABLE_SIZE];
int symtable_count;
Sym* search_sym(char* name);
int add_sym(char* name, SymType type);

AST* root;
AST* new_ast(Token token, AST* l_op, AST* r_op);
void free_ast(AST* ast);

char* tmp_identlist[256];
int tmp_identlist_count;
%}

%union {
	char* ident;
	SymType type;
	AST* parse;
}

%token COMMA
%token COLON
%token LPAREN
%token RPAREN
%token VAR

%token COMMENT
%token <ident> IDENT
%token <type> TYPE

%type <parse> declaration identlist identlist_tail

%start declaration

%%
identlist_tail : 
	COMMA IDENT identlist_tail {
		tmp_identlist[tmp_identlist_count++] = $2;
		AST* ident_ast = new_ast(Ident, NULL, NULL);
		$$ = new_ast(IdentList, ident_ast, $3);
	}
	| { $$ = NULL; };
identlist : IDENT identlist_tail {
	tmp_identlist[tmp_identlist_count++] = $1;
	AST* ident_ast = new_ast(Ident, NULL, NULL);
	$$ = new_ast(IdentList, ident_ast, $2);
};
declaration : VAR identlist COLON TYPE {
	SymType type = $4;
	if (type == _error) {
		yyerror("Unknown type");
		$$ = NULL;
	} else {
		int i;
		for (i = 0; i < tmp_identlist_count; i++) {
			if (!add_sym(tmp_identlist[i], type)) {
				YYNOMEM;
			}
		}
		AST* type_ast = new_ast(Type, NULL, NULL);
		$$ = new_ast(Declaration, $2, type_ast);
	}
	root = $$;
};
%%

Sym* search_sym(char* name) {
	int i;
	for (i = symtable_count - 1; i >= 0; i--) {
		if (strcmp(symtable[i].name, name) == 0) {
			return &symtable[i];
		}
	}
	return NULL;
}
int add_sym(char* name, SymType type) {
	Sym* sym = search_sym(name);
	if (sym == NULL) {
		if (symtable_count >= SYMTABLE_SIZE) {
			return 0;
		}
		sym = &symtable[symtable_count++];
	}
	char* namecpy = (char*) malloc(sizeof(name) + 1);
	sym->name = strcpy(namecpy, name);
	sym->type = type;
	return 1;
}

AST* new_ast(Token token, AST* l_op, AST* r_op) {
	AST* newast = (AST*) malloc(sizeof(AST));
	newast->token = token;
	newast->l_op = l_op;
	newast->r_op = r_op;
	return newast;
}
void free_ast(AST* ast) {
	if (ast->l_op != NULL) {
		free_ast(ast->l_op);
	}
	if (ast->r_op != NULL) {
		free_ast(ast->r_op);
	}
	free(ast);
}

void yyerror(const char* s) {
	fprintf(stderr, "%s\n", s);
}
int yywrap(void) {
	return 1;
}
int main(void) {
	return yyparse();
}
