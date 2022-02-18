%{
#include "main.h"
#include <stdlib.h>
#include <stdio.h>

%}

%token LET MUT MACRO SEARCH RSEARCH MATCH RMATCH IF ELSE WHILE CONTINUE BREAK RETURN ARROW
%token EQ NEQ LE GE
%token NUMBER REPEATER IDENTIFIER STRING REF_STRING REGEX

%nonassoc IF
%nonassoc ELSE

%%
program: scopebody { finished = true; };

scopebody: expression;
expression: expression1;
          | expression1 ';'; //Allow trailing semicolon
          | expression1 ';' expression;

expression1: expression2;
          | LET IDENTIFIER ':' type '=' letvalue;
          | LET IDENTIFIER '=' letvalue;
          | MUT IDENTIFIER ':' type '=' letvalue;
          | MUT IDENTIFIER '=' letvalue;
          | MUT IDENTIFIER ':' type;

ifcondition: expression2;
ifbody: expression2;
letvalue: expression2;
assignmentvalue: expression2;
argument: expression2;
repeatee: expression2;
search_action_body: expression2;
returnvalue: expression2;
expression2: expression5;
           | IF '(' ifcondition ')' ifbody %prec IF;
           | IF '(' ifcondition ')' ifbody ELSE ifbody %prec ELSE;
           | MACRO IDENTIFIER '{' scopebody '}';
           | SEARCH search_body;
           | RSEARCH search_body;
           | MATCH search_body;
           | RMATCH search_body;
           | REPEATER repeatee;
           | RETURN returnvalue;

expression5: expression6;
           | expression6 '=' assignmentvalue; //right-to-left

search_body: search_action;
           | '{' search_list '}';

search_list: search_action;
           | search_action ','; // Allow trailing comma
           | search_action ',' search_list;
           | ELSE ARROW search_action_body;
           | ELSE ARROW search_action_body ','; // Allow trailing comma

search_action: search_term;
             | search_term ARROW search_action_body;

search_term: STRING; | REGEX; | REF_STRING; | IDENTIFIER;

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
