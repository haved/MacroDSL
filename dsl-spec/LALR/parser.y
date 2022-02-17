%{
#include "main.h"
#include <stdlib.h>
#include <stdio.h>

%}

%token LET MUT MACRO SEARCH RSEARCH MATCH IF ELSE WHILE CONTINUE BREAK RETURN ARROW
%token NUMBER IDENTIFIER STRING REF_STRING REGEX

%right '='

%left '|'
%left '^'
%left '&'
%left '+' '-'
%left '*' '/'
%right '~' UMINUS
%left '.'

%nonassoc IF THEN
%nonassoc ELSE

%%
program: statement_list { finished = true; };

statement_list: statement {}
              | statement ';' statement_list {};

statement: expression {}
         | IF expression statement %prec THEN {}
         | IF expression statement ELSE statement {}
         | MACRO IDENTIFIER expression {}
         | variable_declaration {};

variable_declaration: LET IDENTIFIER optional_type '=' expression {}
                    | MUT IDENTIFIER optional_type '=' expression {}
                    | MUT IDENTIFIER ':' type {};

optional_type: ':' type {}
             | {};

type: atomic_expression {};

expression: op_expression {}
          | IDENTIFIER '=' expression {};

op_expression: atomic_expression {}
             | statement '+' statement {}
             | statement '-' statement {}
             | statement '*' statement {}
             | statement '/' statement {}
             | statement '.' IDENTIFIER {}
             | atomic_expression '(' argument_list ')' {};

atomic_expression: '{' statement_list '}' {}
                 | '(' statement ')' {}
                 | IDENTIFIER {};

argument_list: {}
             | statement {}
             | statement ',' argument_list {};
%%

int yyerror ( const char *error )
{
    fprintf ( stderr, "%s on line %d\n", error, yylineno );
    exit ( EXIT_FAILURE );
}
