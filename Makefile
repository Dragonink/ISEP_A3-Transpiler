out :
	mkdir out

src/ast.h : src/sym.h

src/y.tab.c src/y.tab.h $(if $(DEBUG),src/y.output) : src/syna.y src/sym.h src/ast.h | out
	bison $(if $(DEBUG),-tv) -o src/y.tab.c -d $<

src/lex.yy.c : src/lexa.l src/y.tab.h src/ast.h | out
	flex $(if $(DEBUG),-d) -o $@ $<

out/lexa : src/lex.yy.c | out
	gcc -lfl -o $@ $<

out/psblmc : src/y.tab.c src/lex.yy.c src/ast.c | out
	gcc $(if $(DEBUG),-g) -o $@ $(filter-out %.h,$^)
.DEFAULT_GOAL := out/psblmc

tests/%.py : tests/%.psblm out/psblmc
	out/psblmc $@ <$<
tests : $(patsubst %.psblm,%.py,$(wildcard tests/*.psblm))
.PHONY : tests
