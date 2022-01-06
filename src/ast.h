#ifndef _H_AST
#define _H_AST

typedef enum token {
	Ident,
	Type,
	IdentList,
	Declaration,
} Token;

typedef struct ast {
	Token token;
	struct ast* l_op;
	struct ast* r_op;
} AST;

#endif
