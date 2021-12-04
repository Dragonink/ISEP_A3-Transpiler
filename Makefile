out :
	mkdir out

prebuild_LEX_OUT := out/lex.yy.c
$(prebuild_LEX_OUT) : src/lexa.l | out
	flex -o $@ $<

out/lexa : $(prebuild_LEX_OUT) | out
	gcc -lfl -o $@ $<

.PHONY : all
all : out/lexa
.DEFAULT_GOAL := all
