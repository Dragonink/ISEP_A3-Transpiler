#ifndef _H_SYM
#define _H_SYM

#define SYMTABLE_SIZE 1024

typedef enum type {
	IdentSym,
	LiteralSym,
} SymType;

typedef struct sym {
	char* name;
	SymType type;
	struct symtable* scoped;
} Sym;

typedef struct symtable {
	Sym table[SYMTABLE_SIZE];
	int len;
	struct symtable* parent;
} SymTable;

#endif
