%{
#include "main.h"
#include <stdlib.h>
#include <stdio.h>

%}

%token FUNC PRINT RETURN CONTINUE IF THEN ELSE WHILE DO OPENBLOCK CLOSEBLOCK
%token VAR NUMBER IDENTIFIER STRING

%left '|'
%left '^'
%left '&'
%left '+' '-'
%left '*' '/'
%right '~' UMINUS

%nonassoc IF THEN
%nonassoc ELSE

%%
program:
global_list {
    finished = true;
};

global_list: '.' {}
%%

int
yyerror ( const char *error )
{
    fprintf ( stderr, "%s on line %d\n", error, yylineno );
    exit ( EXIT_FAILURE );
}
