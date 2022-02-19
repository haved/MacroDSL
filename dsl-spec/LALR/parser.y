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

scopebody: statement_list;
statement_list: statement;
          | statement ';'; //Allow trailing semicolon
          | statement ';' statement_list;

statement: expression;
          | LET IDENTIFIER ':' type '=' letvalue;
          | LET IDENTIFIER '=' letvalue;
          | MUT IDENTIFIER ':' type '=' letvalue;
          | MUT IDENTIFIER '=' letvalue;
          | MUT IDENTIFIER ':' type;

ifcondition: expression;
ifbody: expression;
letvalue: expression;
assignmentvalue: expression;
argument: expression;
repeatee: expression;
search_action_body: expression;
returnvalue: expression;
expression: expression5;
           | IF '(' ifcondition ')' ifbody %prec IF;
           | IF '(' ifcondition ')' ifbody ELSE ifbody %prec ELSE;
           | SEARCH search_body;
           | RSEARCH search_body;
           | MATCH search_body;
           | RMATCH search_body;
           | RETURN returnvalue;
           | REPEATER repeatee;

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
            | '(' statement ')';
            | IDENTIFIER;
            | NUMBER;
            | STRING;
            | REF_STRING;
            | REGEX;
            | MACRO IDENTIFIER '{' scopebody '}';

argument_list: ;
             | argument;
             | argument ',' argument_list;

%%

int yyerror ( const char *error )
{
    fprintf ( stderr, "%s on line %d\n", error, yylineno );
    exit ( EXIT_FAILURE );
}
