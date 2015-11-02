#include <stdio.h>
#include <string.h>
#include "vm.h"
#include "parser.h"
#include "interp.h"
#include "util.h"

void run_repl()
{
    printf("Zeta Read-Eval-Print Loop (REPL). Press Ctrl+C to exit.\n");
    printf("\n");
    printf("Please note that the Zeta VM is at the early prototype ");
    printf("stage, language semantics and implementation details will ");
    printf("change often.\n");
    printf("\n");
    printf("NOTE: the interpreter is currently *very much incomplete*. It will ");
    printf("likely crash on you or give cryptic error messages.\n");
    printf("\n");

    for (;;)
    {
        printf("z> ");

        char* cstr = read_line();

        // Evaluate the code string
        value_t value = eval_str(cstr, "shell");

        free(cstr);

        // Print the value
        value_print(value);
        putchar('\n');
    }
}

int main(int argc, char** argv)
{
    vm_init();
    parser_init();
    interp_init();

    // Test mode
    if (argc == 2 && strcmp(argv[1], "--test") == 0)
    {
        test_vm();
        test_parser();
        test_interp();
        return 0;
    }

    // File name passed
    if (argc == 2)
    {
        eval_file(argv[1]);
    }

    // No file names passed. Read-eval-print loop.
    if (argc == 1)
    {
        run_repl();
    }

    return 0;
}

