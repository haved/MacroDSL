#ifndef MAIN_H_
#define MAIN_H_

#include <stdbool.h>

// Token definitions and other things from bison, needs def. of node type
#include "y.tab.h"

// This is generated from the bison grammar, calls on the flex specification
int yyerror ( const char *error );
int yylex_destroy (); // flex cleanup function

// Global variables
extern bool finished;

#endif // MAIN_H_
