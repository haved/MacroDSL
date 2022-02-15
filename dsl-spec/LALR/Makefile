LEX=flex
YACC=bison
CFLAGS+=-std=c99 -g -D_POSIX_C_SOURCE=200809L
YFLAGS+=-Wcounterexamples

Y_TAB_H=y.tab.h

.PHONY: all clean purge

all: dsl-lalr

dsl-lalr: main.o parser.o scanner.o
	${CC} ${LDFLAGS} $^ -o $@

%.o: %.c ${Y_TAB_H}
	${CC} ${CFLAGS} -c $< -o $@

${Y_TAB_H} src/parser.c: src/parser.y
	${YACC} ${YFLAGS} --defines=${Y_TAB_H} -o parser.c $<

scanner.c: scanner.l ${Y_TAB_H}
	${LEX} -o $@ $<

clean:
	-rm -f parser.c scanner.c y.tab.h *.o

purge: clean
	-rm -f dsl-lalr
