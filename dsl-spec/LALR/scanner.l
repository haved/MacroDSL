%{
#include "main.h"
%}
%option noyywrap
%option array
%option yylineno

WHITESPACE [\ \t\v\r\n]
COMMENT //[^\n]*
%%
{WHITESPACE}+           { /* Eliminate whitespace */ }
COMMENT                 { }

let                     return LET;
mut                     return MUT;
macro                   return MACRO;
search                  return SEARCH;
rsearch                 return RSEARCH;
match                   return MATCH;
if                      return IF;
else                    return ELSE;
while                   return WHILE;
continue                return CONTINUE;
break                   return BREAK;
return                  return RETURN;
"=>"                      return ARROW;
"=="                      return EQ;
"!="                      return NEQ;
"<="                      return LE;
">="                      return GE;

[0-9]+                  return NUMBER;
[a-zA-Z_][a-zA-Z0-9_]*  return IDENTIFIER;
\"[^\"]*\"              return STRING;
#\"[^\"]*\"             return REF_STRING;
"/[^/]/"                return REGEX;
.                       return yytext[0];
%%
