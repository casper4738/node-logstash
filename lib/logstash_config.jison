
/* lexical grammar */
%lex
%%

\"[^\"]*\"            yytext = yytext.substr(1,yyleng-2); return 'VALUE'
\s+                   /* skip whitespace */
"#".*                 /* ignore comment */
[0-9]+\.[0-9]+        yytext = parseFloat(yytext, 10); return 'VALUE'
[0-9]+                yytext = parseInt(yytext, 10); return 'VALUE'
"true"                yytext = true; return 'VALUE'
"false"               yytext = false; return 'VALUE'
"{"                   return 'START'
"}"                   return 'STOP'
"["                   return 'ARRAY_START'
"]"                   return 'ARRAY_STOP'
"=>"                  return 'SET'
","                   return 'COMA'
"if"                  return 'IF'
"else"                return 'ELSE'
"=="                  return 'BINARY_OPERATOR'
"!="                  return 'BINARY_OPERATOR'
"<"                   return 'BINARY_OPERATOR'
">"                   return 'BINARY_OPERATOR'
"<="                  return 'BINARY_OPERATOR'
">="                  return 'BINARY_OPERATOR'
"=~"                  return 'BINARY_OPERATOR'
"!~"                  return 'BINARY_OPERATOR'
"and"                 return 'CONDITION_OPERATOR'
"or"                  return 'CONDITION_OPERATOR'
"nand"                return 'CONDITION_OPERATOR'
"xor"                 return 'CONDITION_OPERATOR'
[0-9a-zA-Z]+          return 'ID'
<<EOF>>               return 'EOF'
.                     return 'INVALID'

/lex

%left "and" "or" "nand" "xor"

%start logstash_config

%% /* language grammar */

logstash_config
  : main_lines EOF
  { return $1; }
  ;

main_lines
  : main_line
  { $$ = $1 }
  | main_lines main_line
  { $$ = $1; k = Object.keys($2); $$[k] = $2[k] }
  ;

main_line
  : ID START lines STOP
  { $$ = {}; $$[$1] = $3}
  ;

lines
  : lines line
  { $$ = $1.concat($2) }
  | line
  { $$ = [$1] }
  | if
  { $$ = [$1] }
  ;

if
  : IF condition START lines STOP
  { $$ = {__if__: {ifs: [{cond: $2, then: $4}]}}}
  | IF condition START lines STOP ELSE if
  { $$ = $7; $$.__if__.ifs = [{cond: $2, then: $4}].concat($$.__if__.ifs) }
  | IF condition START lines STOP ELSE START lines STOP
  { $$ = {__if__: {ifs: [{cond: $2, then: $4}], else: $8}}}
  ;

condition
  : sub_condition CONDITION_OPERATOR condition
  { $$ = {op: $2, left: $1, right: $3}}
  | sub_condition
  { $$ = $1 }
  ;

sub_condition
  : condition_member BINARY_OPERATOR condition_member
  { $$ = {op: $2, left: $1, right: $3}}
  ;

condition_member
  : ARRAY_START ID ARRAY_STOP
  { $$ = {field: $2} }
  | value
  { $$ = {value: $1} }
  ;

line
  : ID plugin_params
  { $$ = {}; $$[$1] = $2}
  ;

plugin_params
  : START STOP
  { $$ = {} }
  | START params STOP
  { $$ = $2 }
  ;

params
  : params param
  { $$ = $1; k = Object.keys($2); $$[k] = $2[k] }
  | params COMA param
  { $$ = $1; k = Object.keys($3); $$[k] = $3[k] }
  | param
  { $$ = $1 }
  ;

param
  : ID SET value
  { $$ = {}; $$[$1] = $3}
  ;

value
  : VALUE
  { $$ = $1 }
  | ID
  { $$ = $1 }
  | ARRAY_START values ARRAY_STOP
  { $$ = $2 }
  ;

values
  : VALUE
  { $$ = [$1] }
  | values COMA VALUE
  { $$ = $1.concat($3) }
  ;
