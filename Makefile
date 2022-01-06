out :
	mkdir out

prebuild_YACC_OUT := $(addprefix src/y.tab,.c .h)
$(prebuild_YACC_OUT) : src/syna.y | out
	yacc $(if $(DEBUG),-tv) -o src/y.tab.c -d $<

prebuild_LEX_OUT := src/lex.yy.c
$(prebuild_LEX_OUT) : src/lexa.l src/y.tab.h | out
	flex -o $@ $<

out/lexa : $(prebuild_LEX_OUT) | out
	gcc -lfl -o $@ $<

out/syna : $(prebuild_YACC_OUT) $(prebuild_LEX_OUT) | out
	gcc $(if $(DEBUG),-g) -o $@ $(filter-out %.h,$^)

.DEFAULT_GOAL := out/syna
