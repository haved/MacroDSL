%{
#include "main.h"
#include <stdlib.h>
#include <stdio.h>

%}

%token LET MUT MACRO SEARCH RSEARCH MATCH IF ELSE WHILE CONTINUE BREAK RETURN ARROW
%token EQ NEQ LE GE
%token NUMBER IDENTIFIER STRING REF_STRING REGEX

%nonassoc IF
%nonassoc ELSE

%%
program: scopebody { finished = true; };

scopebody: expression;
expression: expression1;
          | expression1 ';' expression;

expression1: expression2;
          | LET IDENTIFIER ':' type '=' letvalue;
          | LET IDENTIFIER '=' letvalue;
          | MUT IDENTIFIER ':' type '=' letvalue;
          | MUT IDENTIFIER '=' letvalue;
          | MUT IDENTIFIER ':' type;

ifcondition: expression2;
ifbody: expression2;
searchbody: expression2;
letvalue: expression2;
assignmentvalue: expression2;
argument: expression2;
expression2: expression4;
           | IF '(' ifcondition ')' ifbody %prec IF;
           | IF '(' ifcondition ')' ifbody ELSE ifbody %prec ELSE;

expression4: expression5;
           | MACRO IDENTIFIER '{' scopebody '}';

expression5: expression6;
           | expression6 '=' assignmentvalue; //right-to-left

expression6: expression7;
           | expression6 EQ expression7; //left-to-right
           | expression6 NEQ expression7; //left-to-right

expression7: expression8;
           | expression7 '<' expression8; //left-to-right
           | expression7 LE expression8; //left-to-right
           | expression7 '>' expression8; //left-to-right
           | expression7 GE expression8; //left-to-right

expression8: expression9;
           | expression8 '+' expression9; //left-to-right
           | expression8 '-' expression9; //left-to-right

expression9: expression10;
           | expression9 '*' expression10; //left-to-right
           | expression9 '/' expression10; //left-to-right

expression10: expression11;
           | '-' expression10;

type: expression11;
expression11: expression12;
            | expression11 '.' IDENTIFIER;
            | expression11 '(' argument_list ')';

expression12: '{' scopebody '}';
            | '(' scopebody ')';
            | IDENTIFIER;
            | NUMBER;
            | STRING;
            | REF_STRING;
            | REGEX;

argument_list: ;
             | argument;
             | argument ',' argument_list;

%%

int yyerror ( const char *error )
{
    fprintf ( stderr, "%s on line %d\n", error, yylineno );
    exit ( EXIT_FAILURE );
}
