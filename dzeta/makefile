D_SRCS=     \
ast.d       \
parser.d    \
main.d      \

all: debug

test: debug
	time ./zeta --test

debug: *.d
	dmd -debug -ofzeta $(D_SRCS)

clean:
	rm -f *.o

# Tells make which targets are not files. 
.PHONY: test debug all clean

