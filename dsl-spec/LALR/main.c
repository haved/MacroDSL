#include "main.h"
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>

/* Global state */
bool finished = false;          // Set to true when parser completes the parse

int main ( int argc, char **argv )
{
    assert(argc == 0);

    yyparse ();                 // Generated from grammar/bison, constructs syntax tree
    yylex_destroy ();           // free lex buffers

    if (!finished) {
        printf("parsing failed!");
        return EXIT_FAILURE;
    }
    printf("Parsing successfull!");
    return EXIT_SUCCESS;
}
