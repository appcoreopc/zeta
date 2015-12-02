D_SRCS=     \
runtime.d   \
ast.d       \
parser.d    \
vars.d      \
codegen.d   \
main.d      \

all: debug

test: debug
	dmd -gc -debug -unittest -ofzeta-test $(D_SRCS)
	./zeta-test --test
	rm ./zeta-test

debug: *.d
	dmd -debug -ofzeta $(D_SRCS)

clean:
	rm -f *.o

# Tells make which targets are not files. 
.PHONY: test debug all clean

