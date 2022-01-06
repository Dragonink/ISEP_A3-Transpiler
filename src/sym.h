#ifndef _H_SYM
#define _H_SYM

typedef enum symtype {
	Integer,
	Real,
	Boolean,
	Char,
	String,
	_error,
} SymType;

typedef struct sym {
	char* name;
	SymType type;
} Sym;

#endif
