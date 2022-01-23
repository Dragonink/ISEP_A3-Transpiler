#ifndef _H_SYM
#define _H_SYM

#define SYMTABLE_SIZE 256

typedef enum symtype {
	IdentSym,
	LiteralSym,
} SymType;

typedef enum valtype {
	Integer,
	Real,
	Boolean,
	Char,
	String,
} ValType;

typedef struct sym {
	char* name;
	SymType symtype;
	ValType valtype;
	struct symtable* scoped;
} Sym;

typedef struct symtable {
	Sym table[SYMTABLE_SIZE];
	int len;
	struct symtable* parent;
} SymTable;

#endif
