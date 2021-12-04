out :
	mkdir out

build_LEX_OUT := out/lex.yy.c
$(build_LEX_OUT) : src/lexa.l | out
	flex -o $@ $<

out/lexa : $(build_LEX_OUT) | out
	gcc -lfl -o $@ $<

.DEFAULT_GOAL := out/lexa
