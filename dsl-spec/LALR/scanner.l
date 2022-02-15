%{
#include "main.h"
%}
%option noyywrap
%option array
%option yylineno

%x COMMENT
%x COMMENT_ENDING

WHITESPACE [\ \t\v\r\n]
%%
{WHITESPACE}+           ; // Eliminate whitespace

// OCaml style comments
\(\*                    BEGIN(COMMENT);
<COMMENT>[^\*]*         ;
<COMMENT>\*             BEGIN(COMMENT_ENDING);
<COMMENT_ENDING>[^\*\)] BEGIN(COMMENT);
<COMMENT_ENDING>\*      ;
<COMMENT_ENDING>\)      BEGIN(INITIAL);

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
"=>"                    return ARROW;

[0-9]+                  return NUMBER;
[0-9]+x                 return REPEATER;
[a-zA-Z_][a-zA-Z0-9_]*  return IDENTIFIER;
\"[^\"]*\"              return STRING;
#\"[^\"]*\"             return REF_STRING;
/[^\"]/                 return REGEX;
.                       return yytext[0];
%%
