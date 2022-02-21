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
          | LET IDENTIFIER ':' type '=' expression;
          | LET IDENTIFIER '=' expression;
          | MUT IDENTIFIER ':' type '=' expression;
          | MUT IDENTIFIER '=' expression;
          | MUT IDENTIFIER ':' type;

expression: expression5;
          | ending_in_expr5;

expression5: expression6;
           | expression6 '=' expression5; //right-to-left

ending_in_expr5: ending_in_expr6;
           | expression6 '=' ending_in_expr5; //right-to-left

expression6: expression7;
           | expression6 EQ expression7; //left-to-right
           | expression6 NEQ expression7; //left-to-right

ending_in_expr6: ending_in_expr7;
           | expression6 EQ ending_in_expr7;
           | expression6 NEQ ending_in_expr7;

expression7: expression8;
           | expression7 '<' expression8; //left-to-right
           | expression7 LE expression8; //left-to-right
           | expression7 '>' expression8; //left-to-right
           | expression7 GE expression8; //left-to-right

ending_in_expr7: ending_in_expr8;
           | expression7 '<' ending_in_expr8; //left-to-right
           | expression7 LE ending_in_expr8; //left-to-right
           | expression7 '>' ending_in_expr8; //left-to-right
           | expression7 GE ending_in_expr8; //left-to-right

expression8: expression9;
           | expression8 '+' expression9; //left-to-right
           | expression8 '-' expression9; //left-to-right

ending_in_expr8: ending_in_expr9;
           | expression8 '+' ending_in_expr9; //left-to-right
           | expression8 '-' ending_in_expr9; //left-to-right

expression9: expression10;
           | expression9 '*' expression10; //left-to-right
           | expression9 '/' expression10; //left-to-right

ending_in_expr9: ending_in_expr10;
           | expression9 '*' ending_in_expr10; //left-to-right
           | expression9 '/' ending_in_expr10; //left-to-right

expression10: expression11;
            | '-' expression10;

ending_in_expr10: IF '(' expression ')' expression %prec IF;
                | IF '(' expression ')' expression ELSE expression %prec ELSE;
                | SEARCH search_action;
                | RSEARCH search_action;
                | MATCH search_action;
                | RMATCH search_action;
                | RETURN expression;
                | REPEATER expression;
                | '-' ending_in_expr10;

type: expression11;
expression11: expression12;
            | expression11 '.' IDENTIFIER;
            | expression11 '(' argument_list ')';

expression12: '{' scopebody '}';
            | '(' expression ')';
            | IDENTIFIER;
            | NUMBER;
            | STRING;
            | REF_STRING;
            | REGEX;
            | MACRO IDENTIFIER '{' scopebody '}';
            | SEARCH '{' search_list '}';
            | RSEARCH '{' search_list '}';
            | MATCH '{' search_list '}';
            | RMATCH '{' search_list '}';

argument_list: ;
             | expression;
             | expression ',' argument_list;

search_list: search_action;
           | search_action ','; // Allow trailing comma
           | search_action ',' search_list;
           | ELSE ARROW expression;
           | ELSE ARROW expression ','; // Allow trailing comma

search_action: search_term;
             | search_term ARROW expression;

search_term: STRING; | REGEX; | REF_STRING; | IDENTIFIER;


%%

int yyerror ( const char *error )
{
    fprintf ( stderr, "%s on line %d\n", error, yylineno );
    exit ( EXIT_FAILURE );
}
