#ifndef _H_SYM
#define _H_SYM

typedef enum type {
	IdentSym,
	LiteralSym,
} SymType;

typedef struct sym {
	char* name;
	SymType type;
	struct sym* scoped;
} Sym;

#endif
