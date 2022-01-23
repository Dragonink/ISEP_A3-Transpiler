#include <stdlib.h>
#include <string.h>
#include "ast.h"

char* strconcat(char* s1, const char* s2) {
	char* dest = malloc((strlen(s1) + strlen(s2) + 1) * sizeof(char));
	if (dest != NULL) {
		strcat(dest, s1);
		strcat(dest, s2);
	}
	return dest;
}

char* indent(char* s, unsigned int indent_lvl) {
	for (int t = 0; t < indent_lvl; t++) {
		s = strconcat(s, "    ");
	}
	return s;
}

char* transpile(AST* ast, unsigned int indent_lvl) {
	switch (ast->token) {
		case IdentToken:
		case LiteralToken:
			return ast->sym->name;
		case IdentList: {
			if (ast->l_op != NULL) {
				char* s = ast->l_op->sym->name;
				if (ast->r_op != NULL) {
					const char* tail = transpile(ast->r_op, indent_lvl);
					s = strconcat(s, ", ");
					s = strconcat(s, tail);
				}
				return s;
			} else {
				return "";
			}
		}
		case ExprList: {
			if (ast->l_op != NULL) {
				char* s = transpile(ast->l_op, indent_lvl);
				if (ast->r_op != NULL) {
					const char* tail = transpile(ast->r_op, indent_lvl);
					s = strconcat(s, ", ");
					s = strconcat(s, tail);
				}
				return s;
			} else {
				return "";
			}
		}
		case Assign: {
			char* s = "";
			s = indent(s, indent_lvl);
			const char* ident = transpile(ast->l_op, indent_lvl);
			s = strconcat(s, ident);
			s = strconcat(s, " = ");
			const char* expr = transpile(ast->r_op, indent_lvl);
			s = strconcat(s, expr);
			return s;
		}
		case Read: {
			char* s = "";
			s = indent(s, indent_lvl);
			s = strconcat(s, "print(");
			const char* expr = transpile(ast->l_op, indent_lvl);
			s = strconcat(s, expr);
			s = strconcat(s, ")\n");
			s = indent(s, indent_lvl);
			const char* ident = transpile(ast->r_op, indent_lvl);
			s = strconcat(s, ident);
			s = strconcat(s, " = ");
			switch (ast->r_op->sym->valtype) {
				case Integer: 
					s = strconcat(s, "int(");
					break;
				case Real:
					s = strconcat(s, "float(");
					break;
				case Boolean:
					s = strconcat(s, "input() == 'true'\n");
					return s;
				default: s = strconcat(s, "str(");
			}
			s = strconcat(s, "input())");
			return s;
		}
		case Write: {
			char* s = "";
			s = indent(s, indent_lvl);
			s = strconcat(s, "print(");
			const char* exprlist = transpile(ast->l_op, indent_lvl);
			s = strconcat(s, exprlist);
			s = strconcat(s, ")");
			return s;
		}
		case If: {
			if (ast->r_op != NULL) {
				char* s = "";
				s = indent(s, indent_lvl);
				s = strconcat(s, "if ");
				const char* cond = transpile(ast->l_op, indent_lvl);
				s = strconcat(s, cond);
				s = strconcat(s, ":\n");
				const char* block = transpile(ast->r_op, indent_lvl + 1);
				s = strconcat(s, block);
				return s;
			} else {
				return "";
			}
		}
		case Else: {
			char* s = "";
			if (ast->l_op != NULL) {
				const char* if_block = transpile(ast->l_op, indent_lvl);
				s = strconcat(s, if_block);
			} else {
				s = indent(s, indent_lvl);
				s = strconcat(s, "pass");
			}
			s = strconcat(s, "\n");
			if (ast->r_op != NULL) {
				const char* else_block = transpile(ast->r_op, indent_lvl);
				s = indent(s, indent_lvl - 1);
				s = strconcat(s, "else:\n");
				s = strconcat(s, else_block);
			}
			return s;
		}
		case While: {
			char* s = "";
			s = indent(s, indent_lvl);
			s = strconcat(s, "while ");
			const char* cond = transpile(ast->l_op, indent_lvl);
			s = strconcat(s, cond);
			s = strconcat(s, ":\n");
			if (ast->r_op != NULL) {
				const char* block = transpile(ast->r_op, indent_lvl + 1);
				s = strconcat(s, block);
			} else {
				s = indent(s, indent_lvl + 1);
				s = strconcat(s, "pass");
			}
			return s;
		}
		case Return: {
			char* s = "";
			s = indent(s, indent_lvl);
			s = strconcat(s, "return ");
			const char* expr = transpile(ast->l_op, indent_lvl);
			s = strconcat(s, expr);
			return s;
		}
		case StmtList: {
			if (ast->l_op != NULL) {
				char* s = transpile(ast->l_op, indent_lvl);
				if (ast->r_op != NULL) {
					const char* tail = transpile(ast->r_op, indent_lvl);
					s = strconcat(s, "\n");
					s = strconcat(s, tail);
				}
				return s;
			} else {
				return "";
			}
		}
		case Function: {
			char* s = "def ";
			s = strconcat(s, ast->sym->name);
			s = strconcat(s, "(");
			const char* args = transpile(ast->l_op, indent_lvl);
			s = strconcat(s, args);
			s = strconcat(s, "):\n");
			if (ast->r_op != NULL) {
				const char* stmtlist = transpile(ast->r_op, indent_lvl + 1);
				s = strconcat(s, stmtlist);
			} else {
				s = indent(s, indent_lvl + 1);
				s = strconcat(s, "pass");
			}
			return s;
		}
		case FnCall: {
			char* s = ast->sym->name;
			s = strconcat(s, "(");
			const char* args = transpile(ast->l_op, indent_lvl);
			s = strconcat(s, args);
			s = strconcat(s, ")");
			return s;
		}
		case UnPlusOp: {
			char* s = "+";
			const char* expr = transpile(ast->l_op, indent_lvl);
			s = strconcat(s, expr);
			return s;
		}
		case UnMinusOp: {
			char* s = "-";
			const char* expr = transpile(ast->l_op, indent_lvl);
			s = strconcat(s, expr);
			return s;
		}
		case UnNotOp: {
			char* s = "not ";
			const char* expr = transpile(ast->l_op, indent_lvl);
			s = strconcat(s, expr);
			return s;
		}
		case BinPlusOp: {
			char* s = transpile(ast->l_op, indent_lvl);
			s = strconcat(s, " + ");
			const char* rhs = transpile(ast->r_op, indent_lvl);
			s = strconcat(s, rhs);
			return s;
		}
		case BinMinusOp: {
			char* s = transpile(ast->l_op, indent_lvl);
			s = strconcat(s, " - ");
			const char* rhs = transpile(ast->r_op, indent_lvl);
			s = strconcat(s, rhs);
			return s;
		}
		case BinMultOp: {
			char* s = transpile(ast->l_op, indent_lvl);
			s = strconcat(s, " * ");
			const char* rhs = transpile(ast->r_op, indent_lvl);
			s = strconcat(s, rhs);
			return s;
		}
		case BinRealDivOp: {
			char* s = transpile(ast->l_op, indent_lvl);
			s = strconcat(s, " / ");
			const char* rhs = transpile(ast->r_op, indent_lvl);
			s = strconcat(s, rhs);
			return s;
		}
		case BinIntDivOp: {
			char* s = transpile(ast->l_op, indent_lvl);
			s = strconcat(s, " // ");
			const char* rhs = transpile(ast->r_op, indent_lvl);
			s = strconcat(s, rhs);
			return s;
		}
		case BinModOp: {
			char* s = transpile(ast->l_op, indent_lvl);
			s = strconcat(s, " % ");
			const char* rhs = transpile(ast->r_op, indent_lvl);
			s = strconcat(s, rhs);
			return s;
		}
		case BinEqOp: {
			char* s = transpile(ast->l_op, indent_lvl);
			s = strconcat(s, " == ");
			const char* rhs = transpile(ast->r_op, indent_lvl);
			s = strconcat(s, rhs);
			return s;
		}
		case BinGtOp: {
			char* s = transpile(ast->l_op, indent_lvl);
			s = strconcat(s, " > ");
			const char* rhs = transpile(ast->r_op, indent_lvl);
			s = strconcat(s, rhs);
			return s;
		}
		case BinGeOp: {
			char* s = transpile(ast->l_op, indent_lvl);
			s = strconcat(s, " >= ");
			const char* rhs = transpile(ast->r_op, indent_lvl);
			s = strconcat(s, rhs);
			return s;
		}
		case BinLtOp: {
			char* s = transpile(ast->l_op, indent_lvl);
			s = strconcat(s, " < ");
			const char* rhs = transpile(ast->r_op, indent_lvl);
			s = strconcat(s, rhs);
			return s;
		}
		case BinLeOp: {
			char* s = transpile(ast->l_op, indent_lvl);
			s = strconcat(s, " <= ");
			const char* rhs = transpile(ast->r_op, indent_lvl);
			s = strconcat(s, rhs);
			return s;
		}
		case BinNeOp: {
			char* s = transpile(ast->l_op, indent_lvl);
			s = strconcat(s, " != ");
			const char* rhs = transpile(ast->r_op, indent_lvl);
			s = strconcat(s, rhs);
			return s;
		}
		case BinAndOp: {
			char* s = transpile(ast->l_op, indent_lvl);
			s = strconcat(s, " and ");
			const char* rhs = transpile(ast->r_op, indent_lvl);
			s = strconcat(s, rhs);
			return s;
		}
		case BinOrOp: {
			char* s = transpile(ast->l_op, indent_lvl);
			s = strconcat(s, " or ");
			const char* rhs = transpile(ast->r_op, indent_lvl);
			s = strconcat(s, rhs);
			return s;
		}
		case Declaration:
		default:
			return "";
	}
}
