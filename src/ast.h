#ifndef _H_AST
#define _H_AST

#include "sym.h"

typedef enum token {
	IdentToken,
	LiteralToken,
	Type,

	IdentList,
	Declaration,
	ExprList,
	Assign,
	Read,
	Write,
	If,
	Else,
	While,
	Return,
	StmtList,
	Function,
	FnCall,
	
	UnPlusOp,
	UnMinusOp,
	UnNotOp,
	BinPlusOp,
	BinMinusOp,
	BinMultOp,
	BinRealDivOp,
	BinIntDivOp,
	BinModOp,
	BinEqOp,
	BinGtOp,
	BinGeOp,
	BinLtOp,
	BinLeOp,
	BinNeOp,
	BinAndOp,
	BinOrOp,
} Token;

typedef struct ast {
	Token token;
	Sym* sym;
	struct ast* l_op;
	struct ast* r_op;
} AST;

#endif
